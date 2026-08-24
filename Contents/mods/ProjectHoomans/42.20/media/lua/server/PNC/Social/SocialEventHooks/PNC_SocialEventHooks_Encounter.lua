if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEventHooks = PNC.SocialEventHooks or {}
PNC.SocialEventHooksInternal = PNC.SocialEventHooksInternal or {}

local Hooks = PNC.SocialEventHooks
local H = PNC.SocialEventHooksInternal
local EntityRef = PNC.EntityRef
local Core = PNC.Core

function Hooks.OnThreatNeutralized(spec)
    if PNC.PlayerCharacterDebug
        and PNC.PlayerCharacterDebug.LogCombat
    then
        PNC.PlayerCharacterDebug.LogCombat({
            callback = "threat_neutralization",
            event = "OnThreatNeutralized",
            worldAgeHours = spec and spec.occurredAt
                or H.WorldAgeHours(),
            threatID = spec and spec.threatID,
            result = "received",
        })
    end
    if not H.Enabled()
        or not PNC.SocialEncounterTracker
        or not PNC.SocialEncounterTracker.OnThreatNeutralized
    then
        return false, "feature_disabled"
    end
    return PNC.SocialEncounterTracker.OnThreatNeutralized(spec)
end

function Hooks.OnCombatEncounterEnded(encounterID, occurredAt)
    if not H.Enabled()
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

return Hooks

