--[[
    PNC Networking - server payload budget

    Project Zomboid serializes each server command into a fixed per-connection
    packet buffer (`ByteBuffer.allocate(1000000)` in the supported baseline).
    `TableNetworkUtils.save` throws BufferOverflowException once that buffer is
    full, and `GameServer.sendServerCommand` only catches IOException, so the
    exception escapes, the packet is never sent, and the connection's packet
    lock is left held. The client keeps its previous - or empty - state with no
    error to report, which makes a transport failure look like empty gameplay
    data (for example an empty colonist roster).

    This module gives every mod-owned server command a cheap, bounded size
    estimate and refuses the doomed send. The client receives a small envelope
    instead, so the UI can report an explicit sync failure.

    Ownership:
    - `Budget` owns estimation, the oversize envelope, and rejection counters.
    - `Internal.SendGuarded` owns the decision to send or refuse.
    - `Internal.InstallSendGuard` owns the global safety net so direct
      `sendServerCommand` callers in the mod cannot bypass the budget.

    The budget applies only where a real socket send happens. Single-player and
    the hosted player's local routing use `triggerEvent("OnServerCommand", ...)`
    and are never size-limited by the engine, so they keep their current
    behavior.
]]

PNC = PNC or {}
PNC.Network = PNC.Network or {}
PNC.Network.Internal = PNC.Network.Internal or {}

local Network = PNC.Network
local Internal = Network.Internal
local Const = PNC.Const

local Budget = Network.PayloadBudget or {}
Network.PayloadBudget = Budget
Internal.PayloadBudget = Budget

-- 768 KiB. The engine buffer is 1,000,000 bytes and also carries the module
-- and command strings, so the mod keeps a deliberate margin under it.
local DEFAULT_BUDGET_BYTES = 786432
local DEFAULT_ENVELOPE_KEY = "pncOversize"
local DEFAULT_CHUNK_KEY = "pncChunk"
local MAX_DEPTH = 24
-- The walk spends one node per visited key/value. At the cost model below a
-- node is at least ~12 bytes, so this proves roughly 3.6 MB - far above the
-- budget. Exhausting it therefore means "already far over budget", which
-- keeps the conservative verdict correct while bounding worst-case work.
local MAX_NODES = 300000
local MAX_SECTIONS = 24
local REJECT_LOG_INTERVAL_MS = 10000

local function clockNow()
    local core = PNC.Core
    if core and type(core.Now) == "function" then
        return tonumber(core.Now()) or 0
    end
    if type(getTimestampMs) == "function" then
        return tonumber(getTimestampMs()) or 0
    end
    return 0
end

local function logWarn(message)
    local core = PNC.Core
    if core and type(core.LogWarn) == "function" then
        core.LogWarn(message)
        return
    end
    print("[PNC][WARN] " .. tostring(message))
end

local function isModModule(value)
    return Const ~= nil and value == Const.MODULE
end

function Budget.GetEnvelopeKey()
    local configured = Const and Const.NETWORK_PAYLOAD_ENVELOPE
    if type(configured) == "string" and configured ~= "" then
        return configured
    end
    return DEFAULT_ENVELOPE_KEY
end

function Budget.GetBudgetBytes()
    local override = tonumber(Budget.OverrideBytes)
    if override ~= nil and override > 0 then return math.floor(override) end
    local configured = Const and tonumber(Const.NETWORK_PAYLOAD_BUDGET_BYTES)
    if configured ~= nil and configured > 0 then
        return math.floor(configured)
    end
    return DEFAULT_BUDGET_BYTES
end

local function auditEnabled()
    local diagnostics = PNC.PerformanceScalingDiagnostics
    return diagnostics ~= nil
        and diagnostics.NetworkPayloadAuditEnabled == true
end

local function incrementCounter(name)
    local diagnostics = PNC.PerformanceScalingDiagnostics
    if diagnostics and type(diagnostics.Increment) == "function" then
        diagnostics.Increment(name)
    end
end

--[[
    Iterative size estimate. Returns bytes, capped at `limit + 1`, so a caller
    can compare `bytes > limit` without walking the rest of a huge payload.

    The cost model mirrors what the engine actually writes: a fixed tag per
    value, the raw length of strings, and a small per-entry overhead. It
    deliberately over-counts slightly rather than under-counting, because an
    under-estimate would let an oversized packet reach the engine.
]]
local function estimateValue(root, limit, work)
    local values = { root }
    local depths = { 0 }
    local top = 1
    local bytes = 0
    local overBudget = false
    local exhausted = false
    local maxNodes = tonumber(work.max) or MAX_NODES
    while top > 0 and not overBudget and not exhausted do
        local current = values[top]
        local depth = depths[top]
        values[top] = nil
        depths[top] = nil
        top = top - 1
        work.nodes = work.nodes + 1
        if work.nodes > maxNodes then
            exhausted = true
        else
            local valueType = type(current)
            if valueType == "string" then
                bytes = bytes + #current + 8
            elseif valueType == "number" or valueType == "boolean" then
                bytes = bytes + 12
            elseif valueType == "table" then
                bytes = bytes + 8
                if depth >= MAX_DEPTH then
                    -- A payload nested deeper than the engine serializer can
                    -- safely walk is treated as over budget instead of risking
                    -- a native stack failure.
                    bytes = limit + 1
                    overBudget = true
                else
                    for key, child in pairs(current) do
                        work.nodes = work.nodes + 1
                        if work.nodes > maxNodes then
                            exhausted = true
                            break
                        end
                        if type(key) == "string" then
                            bytes = bytes + #key + 8
                        else
                            bytes = bytes + 12
                        end
                        local childType = type(child)
                        if childType == "string" then
                            bytes = bytes + #child + 8
                        elseif childType == "table" then
                            top = top + 1
                            values[top] = child
                            depths[top] = depth + 1
                        else
                            bytes = bytes + 12
                        end
                        if bytes > limit then
                            overBudget = true
                            break
                        end
                    end
                end
            else
                -- nil, functions, threads, and unsupported Java objects are
                -- filtered out by the engine serializer's own canSave() pass,
                -- which skips them instead of throwing. Charge a fixed cost and
                -- leave that existing behavior alone rather than refusing a
                -- whole send the engine would have sent.
                bytes = bytes + 16
            end
        end
    end
    if exhausted or bytes > limit then return limit + 1 end
    return bytes
end

--[[
    Returns `bytes, sections, oversize`.

    `sections` attributes the estimate to the payload's top-level keys so an
    over-budget command can be split by evidence instead of guesswork. Each
    section is measured against the full limit and the loop stops as soon as
    the running total is over budget, so a whole call stays bounded by roughly
    one limit's worth of work plus one section's overshoot.
]]
function Budget.Estimate(payload, limit)
    limit = tonumber(limit)
    if limit == nil or limit <= 0 then limit = Budget.GetBudgetBytes() end
    local sections = {}
    local work = { nodes = 0 }
    if type(payload) ~= "table" then
        local bytes = estimateValue(payload, limit, work)
        return bytes, sections, bytes > limit
    end
    local bytes = 8
    local measured = 0
    local total = 0
    local complete = true
    for key, value in pairs(payload) do
        total = total + 1
        if measured < MAX_SECTIONS then
            local size = estimateValue(value, limit, work)
            bytes = bytes + size
            if type(key) == "string" then
                bytes = bytes + #key + 8
            else
                bytes = bytes + 12
            end
            sections[key] = size
            measured = measured + 1
            if bytes > limit then
                complete = false
                break
            end
        end
    end
    if complete and total > measured then
        sections._omittedSections = total - measured
    end
    if bytes > limit then bytes = limit + 1 end
    return bytes, sections, bytes > limit
end

local function sectionText(sections, maximum)
    local parts = {}
    local count = 0
    for key, value in pairs(sections or {}) do
        if count >= maximum then break end
        count = count + 1
        parts[#parts + 1] = tostring(key) .. ":" .. tostring(value)
    end
    table.sort(parts)
    if #parts == 0 then return "-" end
    return table.concat(parts, ",")
end

function Budget.BuildOversizeReply(command, args, bytes, limit, sections)
    local reply = {
        estimatedBytes = math.floor(tonumber(bytes) or 0),
        budgetBytes = math.floor(tonumber(limit) or 0),
    }
    reply[Budget.GetEnvelopeKey()] = true
    local arguments = type(args) == "table" and args or nil
    if arguments then
        if arguments.snapshotScope ~= nil then
            reply.scope = tostring(arguments.snapshotScope)
        end
        if arguments.requestId ~= nil then
            reply.requestId = tostring(arguments.requestId)
        end
        if arguments.action ~= nil then
            -- Preserve an explicit authoritative failure so an action UI
            -- resolves instead of appearing to hang.
            reply.actionResult = {
                ok = false,
                reason = "payload_too_large",
                action = tostring(arguments.action),
                requestId = arguments.requestId,
            }
        end
    end
    local limited = {}
    local count = 0
    for key, value in pairs(sections or {}) do
        if count >= MAX_SECTIONS then break end
        count = count + 1
        limited[key] = value
    end
    if count > 0 then reply.sections = limited end
    return reply
end

local lastRejectLogAt = {}


function Budget.RecordRejection(command, bytes, limit, sections)
    incrementCounter("Network.PayloadBudgetRejected")
    local key = tostring(command or "")
    local at = clockNow()
    local previous = lastRejectLogAt[key]
    if previous == nil or (at > 0
        and at - (tonumber(previous) or 0) >= REJECT_LOG_INTERVAL_MS)
    then
        lastRejectLogAt[key] = at
        logWarn("network_payload event=rejected command=" .. key
            .. " estimatedBytes=" .. tostring(math.floor(tonumber(bytes) or 0))
            .. " budgetBytes=" .. tostring(math.floor(tonumber(limit) or 0))
            .. " sections=" .. sectionText(sections, 8))
    end
    local diagnostics = PNC.PerformanceScalingDiagnostics
    if diagnostics and type(diagnostics.LogNetworkPayload) == "function" then
        diagnostics.LogNetworkPayload("rejected", {
            "command=" .. key,
            "estimatedBytes=" .. tostring(math.floor(tonumber(bytes) or 0)),
            "budgetBytes=" .. tostring(math.floor(tonumber(limit) or 0)),
            "sections=" .. sectionText(sections, MAX_SECTIONS),
        })
    end
end

function Budget.RecordAccepted(command, bytes, limit, sections)
    incrementCounter("Network.PayloadBudgetSends")
    if not auditEnabled() then return end
    local diagnostics = PNC.PerformanceScalingDiagnostics
    if diagnostics and type(diagnostics.LogNetworkPayload) == "function" then
        diagnostics.LogNetworkPayload("sent", {
            "command=" .. tostring(command or ""),
            "estimatedBytes=" .. tostring(math.floor(tonumber(bytes) or 0)),
            "budgetBytes=" .. tostring(math.floor(tonumber(limit) or 0)),
            "sections=" .. sectionText(sections, MAX_SECTIONS),
        })
    end
end

local function rawSend(player, module, command, args)
    local sender = Internal.RawSendServerCommand
    if type(sender) ~= "function" then return false end
    if player ~= nil then
        sender(player, module, command, args)
    else
        sender(module, command, args)
    end
    return true
end

function Internal.RawSend(player, module, command, args)
    return rawSend(player, module, command, args)
end

local SPLIT_TARGET = 0.7
local MAX_SPLIT_DEPTH = 3
local MAX_TRANSPORT_CHUNKS = 64
-- Splitting measures every part, so it needs a far larger node allowance than
-- the refusal estimate. At the cost model below this covers payloads well past
-- 20 MB; anything larger is refused explicitly rather than mis-measured.
local SPLIT_NODE_BUDGET = 2000000



-- Shared dependencies for the ordered chunking and guard providers.
Internal.PayloadBudgetCore = {
    clockNow = clockNow,
    logWarn = logWarn,
    isModModule = isModModule,
    incrementCounter = incrementCounter,
    estimateValue = estimateValue,
    rawSend = rawSend,
    sectionText = sectionText,
}

return Budget
