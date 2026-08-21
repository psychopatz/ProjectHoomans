if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local WorldLoot = require "PsychopatzCore/WorldLoot/PsychopatzWorldLoot"

PNC = PNC or {}
PNC.ScavengeService = PNC.ScavengeService or {}

local Service = PNC.ScavengeService
local Const = PNC.Const
local Policy = PNC.ScavengePolicy

Service.Sessions = Service.Sessions or {}
Service.ByNPC = Service.ByNPC or {}
Service.NextSessionId = Service.NextSessionId or 1
Service.Diagnostics = Service.Diagnostics or {
    counters = {}, timings = {}, lastFailure = nil,
}
Service.Listeners = Service.Listeners or {}
Service.MAX_RUNTIME_SESSIONS = 48

local ACTIVE_STATES = {
    DISCOVERING = true,
    TRAVELING_TO_SEARCH_SOURCE = true,
    SEARCHING_SOURCE = true,
    COLLECTION_QUEUED = true,
    TRAVELING_TO_LOOT_SOURCE = true,
    COLLECTING = true,
    ATOMIC_TRANSFER = true,
}

local TERMINAL_STATES = {
    COMPLETED = true, CANCELLED = true, FAILED = true,
}

local function copy(value)
    return PNC.Core and PNC.Core.DeepCopy and PNC.Core.DeepCopy(value) or value
end

local function increment(name, amount)
    local counters = Service.Diagnostics.counters
    counters[name] = (tonumber(counters[name]) or 0) + (tonumber(amount) or 1)
    if PNC.PerformanceScalingDiagnostics then
        PNC.PerformanceScalingDiagnostics.Increment("Scavenge." .. name,
            tonumber(amount) or 1)
    end
end

local function emit(eventName, session, details)
    for _, listener in ipairs(Service.Listeners[eventName] or {}) do
        pcall(listener, copy(details), copy(session and {
            sessionId = session.id, npcId = session.npcId,
            state = session.state, revision = session.revision,
        } or nil))
    end
end

function Service.On(eventName, listener)
    if type(listener) ~= "function" then return false end
    eventName = tostring(eventName or "")
    Service.Listeners[eventName] = Service.Listeners[eventName] or {}
    Service.Listeners[eventName][#Service.Listeners[eventName] + 1] = listener
    return true
end

local function normalizePolicy(value)
    value = type(value) == "table" and value or {}
    return {
        containers = value.containers == true,
        floorItems = value.floorItems == true or value.floor == true,
        corpses = value.corpses == true,
    }
end

local function policyEnabled(value)
    return value.containers or value.floorItems or value.corpses
end

local function sessionForNPC(npcId)
    local id = Service.ByNPC[tostring(npcId or "")]
    return id and Service.Sessions[id] or nil
end

local function ownerMatches(session, player)
    local ownerKey = Policy and Policy.OwnerKey and Policy.OwnerKey(player) or nil
    return ownerKey and tostring(ownerKey) == tostring(session.ownerKey)
end

local followsPlayer

local function authorizeNPC(player, npcId)
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(tostring(npcId or "")) or nil
    if not record then return nil, "npc_not_found" end
    local allowed, reason = PNC.CompanionCommands.CanPlayerCommand(
        record, player, Const.COMPANION_COMMAND_RADIUS)
    if not allowed then return nil, reason end
    return record
end

local function teamRecords(player, arguments)
    local ids = type(arguments.npcIds) == "table"
        and arguments.npcIds or { arguments.npcId }
    local records, seen = {}, {}
    for _, value in ipairs(ids) do
        local id = tostring(value or "")
        if id ~= "" and not seen[id] then
            local record, reason = authorizeNPC(player, id)
            if not record then return nil, reason end
            local existing = sessionForNPC(id)
            local assignedToOwnedRun = existing
                and ownerMatches(existing, player)
                and existing.workers
                and existing.workers[id] ~= nil
            if not followsPlayer(record, player) and not assignedToOwnedRun then
                return nil, "npc_not_following_player"
            end
            seen[id] = true
            records[#records + 1] = record
        end
    end
    if #records < 1 then return nil, "scavenger_team_empty" end
    return records
end

followsPlayer = function(record, player)
    local order = record and record.orderSpec or {}
    if tostring(order.kind or "") ~= tostring(Const.ORDER_FOLLOW or "follow")
    then return false end
    local onlineID = player and player.getOnlineID
        and tonumber(player:getOnlineID()) or nil
    local username = player and player.getUsername
        and tostring(player:getUsername() or "") or ""
    local targetOnlineID = tonumber(order.ownerOnlineID
        or record and record.ownerOnlineID)
    local targetUsername = tostring(order.ownerUsername
        or record and record.ownerUsername or "")
    if onlineID ~= nil and targetOnlineID ~= nil then
        return onlineID == targetOnlineID
    end
    return username ~= "" and targetUsername == username
end

Service.Internal = Service.Internal or {}
local Internal = Service.Internal
Internal.ACTIVE_STATES = ACTIVE_STATES
Internal.TERMINAL_STATES = TERMINAL_STATES
Internal.Copy = copy
Internal.Increment = increment
Internal.Emit = emit
Internal.SessionForNPC = sessionForNPC
Internal.OwnerMatches = ownerMatches
Internal.AuthorizeNPC = authorizeNPC
Internal.TeamRecords = teamRecords
Internal.NormalizePolicy = normalizePolicy
Internal.PolicyEnabled = policyEnabled

return Service
