-- Client command dispatch. Owns the single inbound choke point so that:
--
--  * a server-side payload-budget refusal is reported as an explicit sync
--    failure instead of being delivered to a command handler as data, and
--  * a payload the server had to decompose across several packets is rebuilt
--    in full and dispatched exactly once.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState
local Handlers = Internal.ServerCommandHandlers or {}

Internal.ServerCommandHandlers = Handlers

-- A partially received payload older than this is abandoned so a lost packet
-- cannot leak memory or leave a command permanently pending.
local CHUNK_TIMEOUT_MS = 15000
local MAX_PENDING_CHUNKS = 8

local cachedEnvelopeKey
local cachedChunkKey

local function constantKey(name, fallback)
    local configured = Const and Const[name]
    if type(configured) == "string" and configured ~= "" then
        return configured
    end
    return fallback
end

local function envelopeKey()
    if cachedEnvelopeKey == nil then
        cachedEnvelopeKey = constantKey("NETWORK_PAYLOAD_ENVELOPE", "pncOversize")
    end
    return cachedEnvelopeKey
end

local function chunkKey()
    if cachedChunkKey == nil then
        cachedChunkKey = constantKey("NETWORK_PAYLOAD_CHUNK", "pncChunk")
    end
    return cachedChunkKey
end

local function payloadSyncKey(command, scope)
    return tostring(command or "") .. ":" .. tostring(scope or "")
end

function Internal.RegisterServerCommand(command, handler)
    if command == nil or type(handler) ~= "function" then return false end
    Handlers[command] = handler
    return true
end

--[[
    Bounded description of the last payload-budget refusal for one command and
    snapshot scope. Returns nil when the last delivery for that key succeeded.
]]
function Client.GetPayloadSync(command, scope)
    local statuses = ClientState.payloadSync
    if type(statuses) ~= "table" then return nil end
    local status = statuses[payloadSyncKey(command, scope)]
    if type(status) ~= "table" then return nil end
    return status
end

local function recordPayloadSync(command, args)
    local statuses = ClientState.payloadSync
    if type(statuses) ~= "table" then
        statuses = {}
        ClientState.payloadSync = statuses
    end
    local key = payloadSyncKey(command, args.scope)
    if statuses[key] == nil then
        ClientState.payloadSyncCount =
            (tonumber(ClientState.payloadSyncCount) or 0) + 1
    end
    statuses[key] = {
        state = "unavailable",
        reason = "payload_too_large",
        command = tostring(command or ""),
        scope = args.scope,
        estimatedBytes = tonumber(args.estimatedBytes) or 0,
        budgetBytes = tonumber(args.budgetBytes) or 0,
        sections = args.sections,
        receivedAt = ClientState.lastSyncReceiveAt,
    }
end

-- Clears only the matching command and scope, so a healthy full snapshot does
-- not hide a still-broken base snapshot. The healthy path pays one numeric
-- compare and never builds a key string.
local function clearPayloadSync(command, args)
    if (tonumber(ClientState.payloadSyncCount) or 0) <= 0 then return end
    local statuses = ClientState.payloadSync
    if type(statuses) ~= "table" then return end
    local key = payloadSyncKey(command, args.scope)
    if statuses[key] == nil then return end
    statuses[key] = nil
    ClientState.payloadSyncCount =
        math.max(0, (tonumber(ClientState.payloadSyncCount) or 1) - 1)
end

-- --------------------------------------------------------------- reassembly

local function pendingChunks()
    local pending = ClientState.pendingChunks
    if type(pending) ~= "table" then
        pending = {}
        ClientState.pendingChunks = pending
    end
    return pending
end

local function nodeAt(payload, path)
    local node = payload
    for index = 1, #path - 1 do
        local key = path[index]
        local child = node[key]
        if type(child) ~= "table" then
            child = {}
            node[key] = child
        end
        node = child
    end
    return node
end

local function assignPart(payload, path, value)
    local node = nodeAt(payload, path)
    node[path[#path]] = value
end

local function appendPart(payload, path, start, slice)
    local node = nodeAt(payload, path)
    local key = path[#path]
    local array = node[key]
    if type(array) ~= "table" then
        array = {}
        node[key] = array
    end
    for offset = 1, #slice do
        array[start + offset - 1] = slice[offset]
    end
end

-- Parts are applied in packet order, so a mixed table's scalars land before the
-- slices that extend its array.
local function rebuildPayload(parts, count)
    local payload = {}
    for index = 1, count do
        local batch = parts[index]
        for partIndex = 1, #(batch or {}) do
            local part = batch[partIndex]
            if type(part) == "table" and type(part.path) == "table"
                and #part.path > 0
            then
                if part.start ~= nil then
                    appendPart(payload, part.path,
                        tonumber(part.start) or 1, part.slice or {})
                else
                    assignPart(payload, part.path, part.value)
                end
            end
        end
    end
    return payload
end

local function sweepChunks(pending, now)
    for id, entry in pairs(pending) do
        if type(entry) ~= "table" then
            pending[id] = nil
        elseif now - (tonumber(entry.at) or now) >= CHUNK_TIMEOUT_MS then
            pending[id] = nil
        end
    end
end

local function countChunks(pending)
    local count = 0
    for _ in pairs(pending) do count = count + 1 end
    return count
end

local function incrementCounter(name)
    local diagnostics = PNC.PerformanceScalingDiagnostics
    if diagnostics and type(diagnostics.Increment) == "function" then
        diagnostics.Increment(name)
    end
end

local function dispatchCommand(command, args)

    if args[envelopeKey()] == true then
        recordPayloadSync(command, args)
        -- The envelope is transport metadata. Never hand it to a command
        -- handler, which would overwrite good state with an empty payload.
        return false
    end
    clearPayloadSync(command, args)
    local handler = Handlers[command]
    if handler then handler(args) end
    return true
end

local function receiveChunk(command, chunk)
    local id = tostring(chunk.id or "")
    local count = tonumber(chunk.count) or 0
    local index = tonumber(chunk.index) or 0
    local parts = chunk.parts
    if id == "" or count <= 0 or index < 1 or index > count
        or type(parts) ~= "table"
    then
        return false
    end
    local pending = pendingChunks()
    local now = Core.Now()
    sweepChunks(pending, now)
    local entry = pending[id]
    if entry == nil then
        if countChunks(pending) >= MAX_PENDING_CHUNKS then
            -- Bounded memory: abandon the oldest partial payload.
            local oldestId
            local oldestAt
            for candidateId, candidate in pairs(pending) do
                local at = tonumber(candidate and candidate.at) or 0
                if oldestAt == nil or at < oldestAt then
                    oldestId, oldestAt = candidateId, at
                end
            end
            if oldestId ~= nil then pending[oldestId] = nil end
        end
        entry = { command = command, count = count, parts = {}, received = 0 }
        pending[id] = entry
    end
    entry.at = now
    if entry.parts[index] == nil then
        entry.parts[index] = parts
        entry.received = entry.received + 1
    end
    if entry.received < entry.count then return false end
    pending[id] = nil
    incrementCounter("Network.PayloadChunkRebuilds")
    return dispatchCommand(command, rebuildPayload(entry.parts, entry.count))
end

function Client.HandleServerCommand(command, args)
    ClientState.lastSyncReceiveAt = Core.Now()
    if type(args) ~= "table" then
        args = {}
    end
    local chunk = args[chunkKey()]
    if type(chunk) == "table" then
        return receiveChunk(command, chunk)
    end
    return dispatchCommand(command, args)
end

return Client
