PNC = PNC or {}
PNC.Network = PNC.Network or {}
PNC.Network.Internal = PNC.Network.Internal or {}

local Network = PNC.Network
local Internal = Network.Internal
local Const = PNC.Const
local Budget = Network.PayloadBudget or {}
Network.PayloadBudget = Budget
Internal.PayloadBudget = Budget
local Deps = Internal.PayloadBudgetCore or {}
local clockNow = Deps.clockNow
local incrementCounter = Deps.incrementCounter
local estimateValue = Deps.estimateValue
local rawSend = Deps.rawSend
local sectionText = Deps.sectionText
local DEFAULT_CHUNK_KEY = "pncChunk"
local MAX_SECTIONS = 24
local SPLIT_TARGET = 0.7
local MAX_SPLIT_DEPTH = 3
local MAX_TRANSPORT_CHUNKS = 64
local SPLIT_NODE_BUDGET = 2000000

function Budget.GetChunkKey()
    local configured = Const and Const.NETWORK_PAYLOAD_CHUNK
    if type(configured) == "string" and configured ~= "" then
        return configured
    end
    return DEFAULT_CHUNK_KEY
end

local function isEmptyTable(value)
    for _ in pairs(value) do return false end
    return true
end

local function isArrayIndex(key, arrayCount)
    return type(key) == "number"
        and key >= 1
        and key <= arrayCount
        and key == math.floor(key)
end

-- Shallow copy without the array part, so scalars and child tables can travel
-- separately from the slices that carry the bulk of a mixed table.
local function hashOnly(value)
    local output = {}
    local arrayCount = #value
    for key, child in pairs(value) do
        if not isArrayIndex(key, arrayCount) then output[key] = child end
    end
    return output
end

local function appendPath(path, key)
    local output = {}
    for index = 1, #path do output[index] = path[index] end
    output[#output + 1] = key
    return output
end

--[[
    Emits array slices of `value` that each fit `budget`. Each entry records its
    own estimated size so chunk packing never has to re-walk a part.
]]
local function pushSlices(entries, path, value, budget, limit, work)
    local total = #value
    local index = 1
    while index <= total do
        local slice = {}
        local size = 24
        local count = 0
        while index + count <= total do
            local child = value[index + count]
            local childSize = 8 + estimateValue(child, limit, work)
            if count > 0 and size + childSize > budget then break end
            slice[count + 1] = child
            size = size + childSize
            count = count + 1
        end
        if count == 0 then
            -- A single element exceeds the budget on its own. Emit it so the
            -- caller reports an explicit refusal instead of losing the entry.
            slice[1] = value[index]
            count = 1
            size = 8 + estimateValue(slice[1], limit, work)
        end
        if size > budget then return false, "element_too_large" end
        entries[#entries + 1] = {
            part = { path = path, start = index, slice = slice },
            bytes = size,
        }
        index = index + count
    end
    return true
end

local function splitTable(entries, path, value, budget, limit, work, depth)
    for key, child in pairs(value) do
        local childPath = appendPath(path, key)
        local childSize = estimateValue(child, limit, work) + 16
        if childSize <= budget then
            entries[#entries + 1] = {
                part = { path = childPath, value = child },
                bytes = childSize,
            }
        elseif type(child) == "table" and depth < MAX_SPLIT_DEPTH then
            local arrayCount = #child
            if arrayCount > 0 then
                local scalars = hashOnly(child)
                if not isEmptyTable(scalars) then
                    local ok, reason = splitTable(entries, childPath, scalars,
                        budget, limit, work, depth + 1)
                    if ok ~= true then return ok, reason end
                end
                local ok, reason = pushSlices(entries, childPath, child,
                    budget, limit, work)
                if ok ~= true then return ok, reason end
            else
                local ok, reason = splitTable(entries, childPath, child,
                    budget, limit, work, depth + 1)
                if ok ~= true then return ok, reason end
            end
        else
            return false, "value_too_large"
        end
    end
    return true
end

--[[
    Returns `nil` when a single packet already fits, or a list of
    `{ part = ..., bytes = ... }` entries when the payload must be decomposed.
    Returns `false, reason` when one value cannot be reduced below the budget.
]]
function Budget.Split(payload, limit)
    if type(payload) ~= "table" then return nil end
    limit = tonumber(limit) or Budget.GetBudgetBytes()
    local budget = math.floor(limit * SPLIT_TARGET)
    if budget <= 0 then return false, "budget_too_small" end
    local entries = {}
    local work = { nodes = 0, max = SPLIT_NODE_BUDGET }
    local ok, reason = splitTable(entries, {}, payload, budget, limit, work, 1)
    if ok ~= true then return false, reason or "unsplittable" end
    if #entries == 0 then return nil end
    return entries
end

--[[
    Sends a payload, decomposing it across several packets when one packet is
    not enough. Same `true` / `false, reason, bytes, limit` contract as
    Internal.SendGuarded.
]]
function Internal.SendChunked(player, module, command, args)
    if Internal.SendGuardInstalled ~= true then Internal.InstallSendGuard() end
    local limit = Budget.GetBudgetBytes()
    local bytes, sections, oversize = Budget.Estimate(args, limit)
    if oversize ~= true then
        Budget.RecordAccepted(command, bytes, limit, sections)
        return rawSend(player, module, command, args)
    end
    local function refuse(reason)
        Budget.RecordRejection(command, bytes, limit, sections)
        if player ~= nil then
            rawSend(player, module, command,
                Budget.BuildOversizeReply(
                    command, args, bytes, limit, sections))
        end
        return false, reason or "payload_too_large", bytes, limit
    end
    if player == nil then
        -- A broadcast has no single owner to report a failure to, so refuse
        -- rather than writing a doomed packet to an arbitrary connection.
        return refuse("payload_too_large")
    end
    local entries, reason = Budget.Split(args, limit)
    if entries == nil or entries == false then
        return refuse(reason or "unsplittable_payload")
    end
    local budget = math.floor(limit * SPLIT_TARGET)
    local chunks = {}
    local current = {}
    local currentSize = 24
    for index = 1, #entries do
        local entry = entries[index]
        if #current > 0 and currentSize + entry.bytes > budget then
            chunks[#chunks + 1] = current
            current = {}
            currentSize = 24
        end
        current[#current + 1] = entry.part
        currentSize = currentSize + entry.bytes
    end
    if #current > 0 then chunks[#chunks + 1] = current end
    if #chunks == 0 or #chunks > MAX_TRANSPORT_CHUNKS then
        return refuse("payload_requires_too_many_packets")
    end
    Budget.ChunkSerial = (tonumber(Budget.ChunkSerial) or 0) + 1
    local chunkID = tostring(command or "payload") .. ":"
        .. tostring(clockNow()) .. ":" .. tostring(Budget.ChunkSerial)
    local chunkKey = Budget.GetChunkKey()
    for index = 1, #chunks do
        local envelope = {}
        envelope[chunkKey] = {
            id = chunkID,
            index = index,
            count = #chunks,
            parts = chunks[index],
        }
        rawSend(player, module, command, envelope)
    end
    incrementCounter("Network.PayloadChunkSends")
    local diagnostics = PNC.PerformanceScalingDiagnostics
    if diagnostics and type(diagnostics.LogNetworkPayload) == "function" then
        diagnostics.LogNetworkPayload("chunked", {
            "command=" .. tostring(command or ""),
            "estimatedBytes=" .. tostring(math.floor(bytes)),
            "budgetBytes=" .. tostring(math.floor(limit)),
            "chunks=" .. tostring(#chunks),
            "parts=" .. tostring(#entries),
            "sections=" .. sectionText(sections, MAX_SECTIONS),
        })
    end
    return true, "chunked", bytes, limit
end

--[[
    The single decision point for mod-owned server traffic.

    Returns `true` when the payload was handed to the engine, or
    `false, reason, bytes, limit` when it was refused and replaced by the
    bounded oversize envelope. Callers that run outside a server socket (for
    example single-player local routing) must not use this function.
]]
function Internal.SendGuarded(player, module, command, args)
    if Internal.SendGuardInstalled ~= true then Internal.InstallSendGuard() end
    local limit = Budget.GetBudgetBytes()
    local bytes, sections, oversize = Budget.Estimate(args, limit)
    if oversize ~= true then
        Budget.RecordAccepted(command, bytes, limit, sections)
        return rawSend(player, module, command, args)
    end
    Budget.RecordRejection(command, bytes, limit, sections)
    local reply = Budget.BuildOversizeReply(command, args, bytes, limit, sections)
    if player ~= nil then
        rawSend(player, module, command, reply)
    end
    return false, "payload_too_large", bytes, limit
end



return Budget
