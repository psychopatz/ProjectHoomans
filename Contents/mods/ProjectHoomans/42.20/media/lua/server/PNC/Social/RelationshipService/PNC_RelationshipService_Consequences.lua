-- Server-authoritative consequences for directed personal relationships.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}
PNC.RelationshipConsequences = PNC.RelationshipConsequences or {}

local Consequences = PNC.RelationshipConsequences
local Core = PNC.Core
local EntityRef = PNC.EntityRef

local function debugEnabled()
    return PNC.Config
        and PNC.Config.Relationships
        and PNC.Config.Relationships.DebugSocialEvents == true
end

local function log(message, force)
    if not force and not debugEnabled() then return end
    message = "[PNC RelationshipConsequence] " .. tostring(message)
    if Core and Core.LogInfo then
        Core.LogInfo(message)
    elseif print then
        print(message)
    end
end

local function stateOf(value)
    return tostring(type(value) == "table" and value.state or "unknown")
end

local function playerOwned(record)
    if record.recruited == true then
        return true, "recruited"
    end
    if tostring(record.ownerUsername or "") ~= "" then
        return true, "owner_username"
    end
    if record.ownerOnlineID ~= nil then
        return true, "owner_online_id"
    end
    return false, nil
end

local function wake(record)
    local now = Core and Core.Now and Core.Now() or 0
    if PNC.SimulationClock and PNC.SimulationClock.Wake then
        PNC.SimulationClock.Wake(record, nil, now)
    end
    if PNC.Scheduler and PNC.Scheduler.Schedule then
        PNC.Scheduler.Schedule(
            record,
            now + (tonumber(PNC.Scheduler.SLOT_MS) or 50)
        )
    end
end

-- The relationship state remains directed and target-specific.  We do not
-- convert the whole NPC to tacticalClass=hostile here: that would make an
-- NPC attack unrelated players and faction reconciliation could overwrite it.
-- FactionBehavior.ResolveIntent consumes the resulting personal enemy state
-- for this exact player target.
function Consequences.OnRelationshipChanged(
    record,
    targetKey,
    before,
    after,
    changeSpec
)
    local beforeState
    local afterState
    local crossedEnemy
    local owned
    local ownershipReason
    local action = "none"
    local reason
    if not Core or not Core.IsAuthority
        or Core.IsAuthority() ~= true
    then
        return false, "not_authority"
    end
    if not record or record.alive == false then
        return false, "invalid_record"
    end
    if not EntityRef or not EntityRef.IsPlayer
        or not EntityRef.IsPlayer(targetKey)
    then
        return false, "not_player_target"
    end
    beforeState = stateOf(before)
    afterState = stateOf(after)
    crossedEnemy = afterState == "enemy"
        and beforeState ~= "enemy"
    if afterState ~= "enemy" then
        reason = "state_not_enemy"
    elseif not crossedEnemy then
        reason = "already_enemy"
    else
        owned, ownershipReason = playerOwned(record)
        if owned then
            reason = ownershipReason
        else
            action = "personal_enemy_intent"
            reason = "enemy_threshold_crossed"
            wake(record)
        end
    end
    log(
        "npc=" .. tostring(record.id)
            .. " target=" .. tostring(targetKey)
            .. " event=" .. tostring(
                type(changeSpec) == "table" and changeSpec.eventID or nil
            )
            .. " state=" .. beforeState .. "->" .. afterState
            .. " approval=" .. tostring(
                tonumber(after and after.approval) or 0
            )
            .. " respect=" .. tostring(
                tonumber(after and after.respect) or 0
            )
            .. " action=" .. action
            .. " reason=" .. tostring(reason),
        crossedEnemy
    )
    return crossedEnemy, action, reason
end

return Consequences
