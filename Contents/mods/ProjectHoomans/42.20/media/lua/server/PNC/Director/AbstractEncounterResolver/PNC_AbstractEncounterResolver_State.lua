if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AbstractEncounterResolver = PNC.AbstractEncounterResolver or {}
PNC.AbstractEncounterResolverInternal =
    PNC.AbstractEncounterResolverInternal or {}

local Resolver = PNC.AbstractEncounterResolver
local H = PNC.AbstractEncounterResolverInternal
local Config = PNC.DirectorConfig
local Store = PNC.AbstractWorldStore
local Groups = PNC.AbstractGroups
local Locations = PNC.AbstractLocations
local Evaluator = PNC.AbstractEncounterEvaluator
local Combat = PNC.AbstractCombatResolver

function H.SaveState(group)
    return { state = group.state, startedAt = group.stateStartedAt,
        endsAt = group.stateEndsAt }
end

function H.RestoreState(group, saved, at)
    if group.state ~= "ENGAGED" then return end
    if group.action then
        Groups.SetState(group, "PERFORMING_ACTION", saved.startedAt,
            group.action.endsAt)
    else
        Groups.SetState(group, saved.state == "ENGAGED" and "IDLE" or saved.state,
            saved.startedAt or at, saved.endsAt or at)
    end
end

return Resolver

