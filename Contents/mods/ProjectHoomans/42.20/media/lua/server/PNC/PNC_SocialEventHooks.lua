-- Narrow adapters from authoritative gameplay milestones to social events.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then
    return
end

PNC = PNC or {}
PNC.SocialEventHooks = PNC.SocialEventHooks or {}

local Hooks = PNC.SocialEventHooks
local EntityRef = PNC.EntityRef
local Core = PNC.Core

Hooks.RescueContributions = Hooks.RescueContributions or {}
Hooks.ThreatAttributions = Hooks.ThreatAttributions or {}

local function worldAgeHours()
    if getGameTime and getGameTime()
        and getGameTime().getWorldAgeHours
    then
        return math.max(
            0,
            tonumber(getGameTime():getWorldAgeHours()) or 0
        )
    end
    return 0
end

local function enabled()
    return PNC.Config
        and PNC.Config.Relationships
        and PNC.Config.Relationships.EnableSocialEvents ~= false
end

local function debugWarning(message)
    if not (PNC.Config
        and PNC.Config.Relationships
        and PNC.Config.Relationships.DebugSocialEvents == true)
    then
        return
    end
    if Core and Core.LogDebug then
        Core.LogDebug("[PNC SocialEvent] " .. tostring(message))
    elseif print then
        print("[PNC SocialEvent] " .. tostring(message))
    end
end

function Hooks.WorldAgeHours()
    return worldAgeHours()
end

function Hooks.ResolveNPCKey(recordOrID)
    local id = type(recordOrID) == "table"
        and recordOrID.id or recordOrID
    return EntityRef.ForNPC(id)
end

function Hooks.ResolvePlayerKey(player)
    local key
    local reason
    if not PNC.PlayerCharacters
        or not PNC.PlayerCharacters.GetEntityKey
    then
        return nil, "player_character_service_unavailable"
    end
    key, reason = PNC.PlayerCharacters.GetEntityKey(player, {
        callback = "social_event_player_resolution",
        worldAgeHours = worldAgeHours(),
    })
    if PNC.PlayerCharacterDebug
        and PNC.PlayerCharacterDebug.LogCombat
    then
        PNC.PlayerCharacterDebug.LogCombat({
            callback = "player_identity_resolution",
            event = "social_event",
            worldAgeHours = worldAgeHours(),
            onlineID = player and player.getOnlineID
                and player:getOnlineID() or nil,
            result = key and "resolved" or "rejected",
            reason = reason,
        })
    end
    if not key then
        debugWarning(
            "player social attribution skipped: stable "
            .. "player-character identity is unavailable ("
            .. tostring(reason) .. ")"
        )
        return nil, reason or "player_character_identity_unavailable"
    end
    return key
end

function Hooks.GetDownedEpisodeID(record, downedAt)
    downedAt = tonumber(downedAt)
        or tonumber(record and record.health and record.health.downedAt)
    if not record or not record.id or not downedAt or downedAt <= 0 then
        return nil
    end
    return "downed:" .. tostring(record.id)
        .. ":" .. tostring(math.floor(downedAt))
end

function Hooks.RecordRescueContribution(
    targetRecord,
    actorKey,
    occurredAt
)
    local episodeID = Hooks.GetDownedEpisodeID(targetRecord)
    local contributors
    local entry
    if not episodeID or not EntityRef.IsValid(actorKey) then
        return false, "invalid_rescue_contribution"
    end
    contributors = Hooks.RescueContributions[episodeID] or {}
    entry = contributors[actorKey] or {
        actorKey = actorKey,
        actionCount = 0,
        lastAt = 0,
    }
    entry.actionCount = entry.actionCount + 1
    entry.lastAt = math.max(
        tonumber(entry.lastAt) or 0,
        tonumber(occurredAt) or worldAgeHours()
    )
    contributors[actorKey] = entry
    Hooks.RescueContributions[episodeID] = contributors
    return true, episodeID
end

function Hooks.DiscardRescueContributions(targetRecord)
    local prefix = targetRecord and targetRecord.id
        and ("downed:" .. tostring(targetRecord.id) .. ":") or nil
    local episodeID
    local removed = 0
    if not prefix then
        return 0
    end
    for episodeID, _ in pairs(Hooks.RescueContributions) do
        if string.sub(episodeID, 1, #prefix) == prefix then
            Hooks.RescueContributions[episodeID] = nil
            removed = removed + 1
        end
    end
    return removed
end

function Hooks.OnTreatmentCompleted(
    player,
    targetRecord,
    partID,
    context
)
    local actorKey
    local reason
    local targetKey
    local occurredAt
    local actionID
    local event
    if not enabled() or not PNC.SocialEvents then
        return { ok = false, reason = "feature_disabled" }
    end
    actorKey, reason = Hooks.ResolvePlayerKey(player)
    if not actorKey then
        return { ok = false, reason = reason }
    end
    targetKey = Hooks.ResolveNPCKey(targetRecord)
    if not targetKey then
        return { ok = false, reason = "invalid_target_key" }
    end
    occurredAt = tonumber(context and context.occurredAt)
        or worldAgeHours()
    actionID = context and context.actionID
    if actionID == nil then
        actionID = tostring(
            targetRecord.runtime
                and targetRecord.runtime.bandageCompletionAt
                or (Core and Core.Now and Core.Now())
                or 0
        ) .. ":" .. tostring(
            targetRecord.runtime
                and targetRecord.runtime.bandageCompletionRevision
                or 0
        )
    end
    actionID = tostring(actionID)
    if targetRecord.health
        and targetRecord.health.state == "incapacitated"
    then
        Hooks.RecordRescueContribution(
            targetRecord,
            actorKey,
            occurredAt
        )
    end
    event = {
        id = "social:treated_wound:"
            .. tostring(targetRecord.id) .. ":" .. actionID
            .. ":" .. tostring(partID),
        type = "treated_wound",
        actorKey = actorKey,
        targetKey = targetKey,
        occurredAt = occurredAt,
        sourceSystem = "wounds",
        x = tonumber(targetRecord.x),
        y = tonumber(targetRecord.y),
        z = tonumber(targetRecord.z),
        context = {
            bodyPart = tostring(partID or ""),
            woundType = context and context.woundType or nil,
            severity = tonumber(context and context.severity),
        },
    }
    return PNC.SocialEvents.Emit(event)
end

function Hooks.OnIncapacitationRecovered(
    targetRecord,
    episodeID,
    occurredAt
)
    local contributors = Hooks.RescueContributions[episodeID]
    local selected
    local actorKey
    local entry
    local targetKey
    local output
    if not enabled() or not PNC.SocialEvents then
        Hooks.RescueContributions[episodeID] = nil
        return { ok = false, reason = "feature_disabled" }
    end
    for actorKey, entry in pairs(contributors or {}) do
        if not selected
            or entry.lastAt > selected.lastAt
            or (entry.lastAt == selected.lastAt
                and actorKey < selected.actorKey)
        then
            selected = entry
        end
    end
    Hooks.RescueContributions[episodeID] = nil
    if not selected then
        return { ok = false, reason = "unverified_rescuer" }
    end
    targetKey = Hooks.ResolveNPCKey(targetRecord)
    output = PNC.SocialEvents.Emit({
        id = "social:save:" .. tostring(episodeID)
            .. ":" .. tostring(selected.actorKey),
        type = "saved_from_incapacitation",
        actorKey = selected.actorKey,
        targetKey = targetKey,
        occurredAt = tonumber(occurredAt) or worldAgeHours(),
        sourceSystem = "health",
        x = tonumber(targetRecord.x),
        y = tonumber(targetRecord.y),
        z = tonumber(targetRecord.z),
        context = {
            episodeID = episodeID,
            treatmentActions = selected.actionCount,
            attribution = "completed_treatment_contribution",
        },
    })
    return output
end

function Hooks.OnThreatNeutralized(spec)
    if PNC.PlayerCharacterDebug
        and PNC.PlayerCharacterDebug.LogCombat
    then
        PNC.PlayerCharacterDebug.LogCombat({
            callback = "threat_neutralization",
            event = "OnThreatNeutralized",
            worldAgeHours = spec and spec.occurredAt
                or worldAgeHours(),
            threatID = spec and spec.threatID,
            result = "received",
        })
    end
    if not enabled()
        or not PNC.SocialEncounterTracker
        or not PNC.SocialEncounterTracker.OnThreatNeutralized
    then
        return false, "feature_disabled"
    end
    return PNC.SocialEncounterTracker.OnThreatNeutralized(spec)
end

function Hooks.OnCombatEncounterEnded(encounterID, occurredAt)
    if not enabled()
        or not PNC.SocialEncounterTracker
        or not PNC.SocialEncounterTracker.EndEncounter
    then
        return false, "feature_disabled"
    end
    return PNC.SocialEncounterTracker.EndEncounter(
        encounterID,
        occurredAt
    )
end

local function isPlayer(character)
    if not character then
        return false
    end
    if instanceof then
        return instanceof(character, "IsoPlayer")
    end
    return character.getObjectName
        and tostring(character:getObjectName() or "") == "Player"
end

local function isZombie(character)
    if not character then
        return false
    end
    if instanceof then
        return instanceof(character, "IsoZombie")
    end
    return character.getObjectName
        and tostring(character:getObjectName() or "") == "Zombie"
end

local function threatIDFor(zombie)
    if not zombie then
        return nil
    end
    return zombie.getOnlineID and zombie:getOnlineID()
        or zombie.getPersistentOutfitID
            and zombie:getPersistentOutfitID()
        or nil
end

local function protectedNPCKeyFor(zombie)
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
    if not enabled()
        or not isPlayer(attacker)
        or not isZombie(target)
        or not PNC.SocialEncounterTracker
        or (Core and Core.IsManagedNPCBody
            and Core.IsManagedNPCBody(target))
    then
        return false, "not_qualifying_threat_hit"
    end
    actorKey = Hooks.ResolvePlayerKey(attacker)
    threatID = threatIDFor(target)
    if not actorKey or threatID == nil then
        return false, "stable_attribution_unavailable"
    end
    threatID = tostring(threatID)
    targetKey = protectedNPCKeyFor(target)
    now = worldAgeHours()
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
    local threatID = threatIDFor(zombie)
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
        occurredAt = worldAgeHours(),
        x = zombie.getX and zombie:getX() or nil,
        y = zombie.getY and zombie:getY() or nil,
        z = zombie.getZ and zombie:getZ() or nil,
    })
end

function Hooks.PruneThreatAttributions(occurredAt)
    local threatID
    local attribution
    local removed = 0
    occurredAt = tonumber(occurredAt) or worldAgeHours()
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

local function onWeaponHitCharacter(attacker, target)
    if PNC.PlayerCharacterDebug
        and PNC.PlayerCharacterDebug.LogCombat
    then
        PNC.PlayerCharacterDebug.LogCombat({
            callback = "OnWeaponHitCharacter",
            event = "weapon_hit",
            worldAgeHours = worldAgeHours(),
            onlineID = attacker and attacker.getOnlineID
                and attacker:getOnlineID() or nil,
            result = "received",
        })
    end
    Hooks.OnPlayerWeaponHitThreat(attacker, target)
end

local function onZombieDead(zombie)
    if PNC.PlayerCharacterDebug
        and PNC.PlayerCharacterDebug.LogCombat
    then
        PNC.PlayerCharacterDebug.LogCombat({
            callback = "OnZombieDead",
            event = "zombie_death",
            worldAgeHours = worldAgeHours(),
            threatID = threatIDFor(zombie),
            result = "received",
        })
    end
    Hooks.OnThreatDied(zombie)
end

if Events and Events.OnWeaponHitCharacter
    and not Hooks.WeaponHitHookRegistered
then
    Events.OnWeaponHitCharacter.Add(onWeaponHitCharacter)
    Hooks.WeaponHitHookRegistered = true
end

if Events and Events.OnZombieDead
    and not Hooks.ZombieDeadHookRegistered
then
    Events.OnZombieDead.Add(onZombieDead)
    Hooks.ZombieDeadHookRegistered = true
end

return Hooks
