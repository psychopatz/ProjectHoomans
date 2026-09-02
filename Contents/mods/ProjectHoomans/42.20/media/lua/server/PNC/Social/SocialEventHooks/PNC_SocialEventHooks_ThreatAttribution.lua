if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEventHooks = PNC.SocialEventHooks or {}
PNC.SocialEventHooksInternal = PNC.SocialEventHooksInternal or {}

local Hooks = PNC.SocialEventHooks
local H = PNC.SocialEventHooksInternal
local EntityRef = PNC.EntityRef
local Core = PNC.Core
local Detector = PsychopatzCore
    and PsychopatzCore.ZombieKillDetector
    or require "PsychopatzCore/ZombieKillDetector/PsychopatzZombieKillDetector"

function H.IsPlayer(character)
    if not character then
        return false
    end
    if instanceof then
        return instanceof(character, "IsoPlayer")
    end
    return character.getObjectName
        and tostring(character:getObjectName() or "") == "Player"
end

function H.IsZombie(character)
    if not character then
        return false
    end
    if instanceof then
        return instanceof(character, "IsoZombie")
    end
    return character.getObjectName
        and tostring(character:getObjectName() or "") == "Zombie"
end

function H.ThreatIDFor(zombie)
    return Detector.Internal.ThreatIDFor(zombie)
end

function H.ProtectedNPCKeyFor(zombie)
    local target = zombie
        and zombie.getTarget
        and zombie:getTarget() or nil
    local record = target
        and PNC.Registry
        and PNC.Registry.FindRecordByZombie
        and PNC.Registry.FindRecordByZombie(target) or nil
    return record and EntityRef.ForNPC(record.id) or nil
end

function Hooks.OnPlayerWeaponHitThreat(attacker, target)
    local actorKey
    local threatID
    local targetKey
    local now
    if not H.Enabled()
        or not H.IsPlayer(attacker)
        or not H.IsZombie(target)
        or not PNC.SocialEncounterTracker
        or (Core and Core.IsManagedNPCBody
            and Core.IsManagedNPCBody(target))
    then
        return false, "not_qualifying_threat_hit"
    end
    actorKey = Hooks.ResolvePlayerKey(attacker)
    threatID = H.ThreatIDFor(target)
    if not actorKey or threatID == nil then
        return false, "stable_attribution_unavailable"
    end
    threatID = tostring(threatID)
    targetKey = H.ProtectedNPCKeyFor(target)
    now = H.WorldAgeHours()
    PNC.SocialEncounterTracker.RecordActivity({
        actorKey = actorKey,
        targetKey = targetKey,
        threatID = threatID,
        threatWasTargeting = targetKey ~= nil,
        occurredAt = now,
        actorX = attacker.getX and attacker:getX() or nil,
        actorY = attacker.getY and attacker:getY() or nil,
        actorZ = attacker.getZ and attacker:getZ() or nil,
        x = target.getX and target:getX() or nil,
        y = target.getY and target:getY() or nil,
        z = target.getZ and target:getZ() or nil,
    })
    if PNC.PlayerCharacterDebug
        and PNC.PlayerCharacterDebug.LogCombat
    then
        PNC.PlayerCharacterDebug.LogCombat({
            callback = "zombie_damage_attribution",
            event = "player_threat_hit",
            worldAgeHours = now,
            onlineID = attacker.getOnlineID
                and attacker:getOnlineID() or nil,
            threatID = threatID,
            result = "recorded",
        })
    end
    Hooks.ThreatAttributions[threatID] = {
        actorKey = actorKey,
        targetKey = targetKey,
        lastAt = now,
    }
    if target.isDead and target:isDead() then
        return Hooks.OnThreatDied(target)
    end
    return true, "threat_hit_recorded"
end

function Hooks.OnThreatDied(zombie)
    local threatID = H.ThreatIDFor(zombie)
    local attribution
    if threatID == nil then
        return false, "missing_threat_id"
    end
    threatID = tostring(threatID)
    attribution = Hooks.ThreatAttributions[threatID]
    Hooks.ThreatAttributions[threatID] = nil
    if not attribution then
        return false, "unattributed_threat"
    end
    return Hooks.OnThreatNeutralized({
        actorKey = attribution.actorKey,
        targetKey = attribution.targetKey,
        threatID = threatID,
        threatWasTargeting = attribution.targetKey ~= nil,
        occurredAt = H.WorldAgeHours(),
        x = zombie.getX and zombie:getX() or nil,
        y = zombie.getY and zombie:getY() or nil,
        z = zombie.getZ and zombie:getZ() or nil,
    })
end

function Hooks.PruneThreatAttributions(occurredAt)
    local threatID
    local attribution
    local removed = 0
    occurredAt = tonumber(occurredAt) or H.WorldAgeHours()
    for threatID, attribution in pairs(Hooks.ThreatAttributions) do
        if occurredAt - (tonumber(attribution.lastAt) or 0)
            >= (15 / 3600)
        then
            Hooks.ThreatAttributions[threatID] = nil
            removed = removed + 1
        end
    end
    return removed
end

return Hooks
