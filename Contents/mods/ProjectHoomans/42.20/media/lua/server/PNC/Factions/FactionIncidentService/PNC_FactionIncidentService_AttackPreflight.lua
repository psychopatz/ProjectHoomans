if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionIncidentService = PNC.FactionIncidentService or {}
PNC.FactionIncidentService.Internal =
    PNC.FactionIncidentService.Internal or {}

local Service = PNC.FactionIncidentService
local Internal = Service.Internal
local tuning = Internal.tuning
local finiteTimestamp = Internal.finiteTimestamp
local safeEntityKey = Internal.safeEntityKey

local function recordAggregation(payload)
    if PNC.FactionTelemetry
        and PNC.FactionTelemetry.RecordAggregation
    then
        PNC.FactionTelemetry.RecordAggregation(payload)
    end
end

local function episodeKey(
    actorFactionID,
    victimFactionID,
    actorKey,
    subjectKey
)
    return table.concat({
        actorFactionID,
        victimFactionID,
        tostring(actorKey or ""),
        tostring(subjectKey or ""),
    }, "|")
end

local function validateAttack(
    actorFactionID,
    victimFactionID,
    spec
)
    local at = finiteTimestamp(spec.worldAgeHours)
    if not at then return nil, "invalid_world_age" end
    local actorKey = safeEntityKey(spec.actorKey)
    local subjectKey = safeEntityKey(spec.subjectKey)
    if not actorKey or not subjectKey then
        recordAggregation({
            operation = "record_attack",
            worldAgeHours = at,
            result = "rejected",
            reason = "invalid_attack_entity_key",
        })
        return nil, "invalid_attack_entity_key"
    end
    local damage = math.max(0, tonumber(spec.damage) or 0)
    if spec.killed ~= true and spec.severe ~= true
        and damage > 0
        and damage < tuning("minorAttackDamageThreshold", 0)
    then
        recordAggregation({
            operation = "record_attack",
            worldAgeHours = at,
            actorKey = spec.actorKey,
            subjectKey = spec.subjectKey,
            sourceFactionID = actorFactionID,
            targetFactionID = victimFactionID,
            result = "rejected",
            reason = "below_minor_damage_threshold",
            accumulatedDamage = damage,
        })
        return nil, "below_minor_damage_threshold"
    end
    if type(spec.callbackID) == "string"
        and spec.callbackID ~= ""
    then
        if Service.RuntimeCallbackIDs[spec.callbackID] then
            recordAggregation({
                operation = "record_attack",
                worldAgeHours = at,
                sourceFactionID = actorFactionID,
                targetFactionID = victimFactionID,
                result = "duplicate",
                reason = "duplicate_callback",
                callbackID = spec.callbackID,
            })
            return nil, "duplicate_callback"
        end
        Service.RuntimeCallbackIDs[spec.callbackID] = at
        Service.RuntimeCallbackOrder[
            #Service.RuntimeCallbackOrder + 1
        ] = spec.callbackID
        while #Service.RuntimeCallbackOrder
            > tuning("callbackDedupeLimit", 2048)
        do
            local oldest = table.remove(
                Service.RuntimeCallbackOrder, 1
            )
            Service.RuntimeCallbackIDs[oldest] = nil
        end
    end
    return {
        at = at,
        actorKey = actorKey,
        subjectKey = subjectKey,
        damage = damage,
    }
end

Internal.recordAggregation = recordAggregation
Internal.episodeKey = episodeKey
Internal.validateAttack = validateAttack
