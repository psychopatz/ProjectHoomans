-- Client-side, read-only fact sources for semantic dialogue.
--
-- The roster is a server-authoritative projection. It is safe for local
-- presentation, but it is not an action API and never mutates the simulation.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Facts = PNC.Semantics.DialogueFacts
if type(Facts) ~= "table" then
    Facts = require "PNC/Semantics/PNC_SemanticDialogueFacts"
end

local Sources = PNC.Semantics.DialogueFactSources or {}
PNC.Semantics.DialogueFactSources = Sources
Sources.VERSION = 2

local function finite(value)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return nil
    end
    return value
end

local function targetID(target)
    if type(target) ~= "table" then return nil end
    local value = target.id or target.entityID or target.npcID
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function idVariants(id)
    local output = {}
    local seen = {}
    local function add(value)
        value = tostring(value or "")
        if value ~= "" and not seen[value] then
            seen[value] = true
            output[#output + 1] = value
        end
    end
    add(id)
    local npcID = string.match(tostring(id or ""), "^npc:(.+)$")
    if npcID then add(npcID) end
    return output
end

local function snapshotFor(target, context)
    local id = targetID(target)
    local variants = idVariants(id)
    local state = PNC.Network and PNC.Network.ClientState or nil
    local snapshots = context and context.semanticFactSnapshots
        or state and state.snapshots or nil
    local entry = context and context.entry or nil
    local index
    local candidate
    if type(snapshots) == "table" then
        for index = 1, #variants do
            candidate = snapshots[variants[index]]
                or snapshots[tostring(variants[index])]
            if type(candidate) == "table" then return candidate end
        end
    end
    if type(entry) == "table" then
        local entryID = tostring(entry.id or "")
        for index = 1, #variants do
            if entryID ~= "" and entryID == variants[index] then
                return entry.snapshot or entry.record or entry
            end
        end
    end
    return nil
end

local function targetName(target, snapshot)
    local value = type(target) == "table" and (
        target.name or target.text or target.value
    ) or nil
    if value == nil and type(snapshot) == "table" then
        value = snapshot.displayName or snapshot.name
    end
    value = tostring(value or "")
    return value ~= "" and value or "them"
end

local function locationLabel(snapshot)
    if type(snapshot) ~= "table" then return nil end
    local value = snapshot.locationLabel or snapshot.locationName
        or snapshot.placeName or snapshot.areaName
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function distanceBand(snapshot, context)
    local position = context and context.worldContext
        and context.worldContext.environment
        and context.worldContext.environment.position or nil
    local x = finite(snapshot and (snapshot.x or snapshot.lastKnownX))
    local y = finite(snapshot and (snapshot.y or snapshot.lastKnownY))
    local playerX = finite(position and position.x)
    local playerY = finite(position and position.y)
    local distanceSquared
    if x == nil or y == nil or playerX == nil or playerY == nil then
        return nil
    end
    distanceSquared = (x - playerX) * (x - playerX)
        + (y - playerY) * (y - playerY)
    if distanceSquared <= 18 * 18 then return "nearby" end
    if distanceSquared <= 80 * 80 then return "not_far" end
    return "far"
end

local function hasPosition(snapshot)
    return finite(snapshot and (snapshot.x or snapshot.lastKnownX)) ~= nil
        and finite(snapshot and (snapshot.y or snapshot.lastKnownY)) ~= nil
end

local function freshness(snapshot)
    local state = string.lower(tostring(snapshot and snapshot.presenceState or ""))
    if state == "live" then return "current" end
    return "last_known"
end

local function bodyHealthFrom(value)
    if type(value) ~= "table" then return nil end
    if type(value.bodyHealth) == "table" then
        return value.bodyHealth
    end
    if type(value.snapshot) == "table"
        and type(value.snapshot.bodyHealth) == "table"
    then
        return value.snapshot.bodyHealth
    end
    return nil
end

local function ownBodyHealth(context)
    local candidates = {
        context,
        context and context.entry,
        context and context.npcState,
        context and context.npcSnapshot,
        context and context.npcRecord,
    }
    local index
    local snapshot
    for index = 1, #candidates do
        snapshot = bodyHealthFrom(candidates[index])
        if snapshot then return snapshot end
    end
    return nil
end

local function biteStatus(snapshot)
    if type(snapshot) ~= "table" then return nil end
    if type(snapshot.biteStatus) == "boolean" then
        return snapshot.biteStatus
    end
    if type(snapshot.bitten) == "boolean" then
        return snapshot.bitten
    end
    if type(snapshot.wounds) ~= "table" then
        return nil
    end

    local inspected = 0
    local _, wound
    for _, wound in pairs(snapshot.wounds) do
        inspected = inspected + 1
        if inspected > 32 then break end
        if type(wound) == "table"
            and string.lower(tostring(wound.type or "")) == "bite"
        then
            return true
        end
    end
    -- A complete Wounds.BuildSnapshot projection has a wounds table. An
    -- empty table is therefore a known negative; a missing table above is
    -- deliberately unknown rather than a fabricated no.
    return false
end

Facts.RegisterProvider("client_roster_projection", {
    priority = 100,
    subjects = { LOCATION = true },
    Resolve = function(ir, state, context)
        local target = ir and ir.target
        local snapshot = snapshotFor(target, context)
        local id = targetID(target)
        local label
        local band
        -- A roster snapshot is the player's view of the simulation, not the
        -- NPC's private memory. Keep this provider opt-in for UI/debug
        -- consumers that explicitly want ambient player knowledge; ordinary
        -- NPC dialogue must wait for an authoritative cognition fact.
        if not context or context.allowAmbientRosterFacts ~= true then
            return nil, "npc_cognition_required"
        end
        if type(target) ~= "table" or target.unresolved == true then
            return nil, "target_unresolved"
        end
        if not snapshot then return nil, "roster_snapshot_unavailable" end
        label = locationLabel(snapshot)
        if not label and not hasPosition(snapshot) then
            return nil, "roster_position_unavailable"
        end
        band = distanceBand(snapshot, context)
        return {
            status = "known",
            targetID = id,
            targetName = targetName(target, snapshot),
            freshness = freshness(snapshot),
            observedAt = snapshot.observedAt or snapshot.updatedAt
                or snapshot.lastSeenAt,
            location = {
                label = label,
                distanceBand = band,
                precision = label and "named" or "position",
            },
            confidence = freshness(snapshot) == "current" and .94 or .78,
        }
    end,
})

Facts.RegisterProvider("client_npc_health_projection", {
    priority = 175,
    subjects = { NPC_BITE_STATUS = true },
    Resolve = function(ir, state, context)
        local snapshot = ownBodyHealth(context)
        local value
        if not snapshot then
            return {
                status = "unknown",
                reason = "npc_health_projection_unavailable",
            }
        end
        value = biteStatus(snapshot)
        if value == nil then
            return {
                status = "unknown",
                reason = "npc_bite_status_unavailable",
            }
        end
        return {
            status = "known",
            value = value,
            factRef = "npc.health.body.wounds",
            observedAt = snapshot.observedAt or snapshot.updatedAt,
            freshness = snapshot.freshness or "authoritative_projection",
            provenance = "PNC.NPCWounds.BuildSnapshot",
            confidence = 0.96,
        }
    end,
})

pcall(require, "PNC/Semantics/PNC_SemanticDialogueCognitionFactSource")

return Sources
