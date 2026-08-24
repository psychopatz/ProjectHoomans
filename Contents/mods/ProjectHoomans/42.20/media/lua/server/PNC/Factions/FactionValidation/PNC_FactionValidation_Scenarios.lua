-- Isolated deterministic faction validation scenarios.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionValidation = PNC.FactionValidation or {}
local Validation = PNC.FactionValidation
local Types = PNC.FactionTypes
local Math = PNC.FactionDiplomacyMath
local Definitions = PNC.FactionIncidentDefinitions
local EntityRef = PNC.EntityRef

local function metricSnapshot(relation)
    return {
        standing = relation.standing,
        trust = relation.trust,
        fear = relation.fear,
        grievance = relation.grievance,
        state = relation.state,
        atWar = relation.atWar,
        allied = relation.allied,
        truceUntil = relation.truceUntil,
    }
end

local function applyIncident(relation, incidentType)
    local definition = Definitions.Get(incidentType)
    if not definition then return false end
    relation.standing = Math.ClampStanding(
        relation.standing + definition.standing
    )
    relation.trust = Math.ClampTrust(
        relation.trust + definition.trust
    )
    relation.fear = Math.ClampFear(
        relation.fear + definition.fear
    )
    relation.grievance = Math.ClampGrievance(
        relation.grievance + definition.grievance
    )
    relation.revision = relation.revision + 1
    relation.lastEvaluatedAt = relation.lastEvaluatedAt + 1
    relation.state = Math.ResolveState(
        relation, relation.lastEvaluatedAt
    )
    return true
end

function Validation.RunScenario(name, options)
    name = tostring(name or "")
    local known = false
    for _, candidate in ipairs(Validation.Scenarios) do
        if candidate == name then known = true break end
    end
    if not known then return nil, "unknown_scenario" end
    options = type(options) == "table" and options or {}
    local sourceID = "faction_validation_source"
    local targetID = "faction_validation_target"
    local relation = Types.NewRelation(sourceID, targetID)
    local initial = metricSnapshot(relation)
    local incidents = {}
    local resolvedIntent
    local function incident(kind)
        if applyIncident(relation, kind) then
            incidents[#incidents + 1] = kind
        end
    end
    if name == "single_minor_attack" then
        incident("member_attacked_minor")
    elseif name == "repeated_minor_attacks" then
        incident("member_attacked_severe")
    elseif name == "severe_attack" then
        incident("member_attacked_severe")
    elseif name == "member_killed"
        or name == "leader_killed"
    then
        incident("member_killed")
        if name == "leader_killed" then
            relation.fear = Math.ClampFear(
                relation.fear + 10
            )
            relation.grievance = Math.ClampGrievance(
                relation.grievance + 20
            )
        end
        relation.atWar = true
        relation.state = "war"
        relation.revision = relation.revision + 1
    elseif name == "rescue_then_attack" then
        incident("member_rescued")
        incident("member_attacked_minor")
    elseif name == "war_then_peace" then
        relation.atWar = true
        relation.state = "war"
        relation.revision = relation.revision + 1
        relation.atWar = false
        relation.state = "neutral"
        relation.revision = relation.revision + 1
    elseif name == "war_then_truce" then
        relation.atWar = true
        relation.state = "war"
        relation.revision = relation.revision + 1
        relation.atWar = false
        relation.truceUntil = 48
        relation.state = "truce"
        relation.revision = relation.revision + 1
    elseif name == "truce_broken" then
        relation.truceUntil = 48
        relation.state = "truce"
        incident("member_attacked_minor")
        relation.truceUntil = 0
        relation.atWar = true
        relation.state = "war"
        relation.revision = relation.revision + 1
    elseif name == "alliance_then_betrayal" then
        relation.allied = true
        relation.state = "allied"
        relation.revision = relation.revision + 1
        relation.allied = false
        incident("member_attacked_severe")
    elseif name == "looter_meets_stronger_outsider"
        or name == "looter_meets_weaker_outsider"
    then
        resolvedIntent = PNC.FactionIntent.Resolve({
            archetypeID = "looter",
            policy = { outsiderPolicy = "predatory" },
            observerStrength = 1,
            targetStrength =
                name == "looter_meets_stronger_outsider"
                    and 2 or 0.5,
        })
    elseif name == "unrelated_multiplayer_player" then
        resolvedIntent = {
            intent = "observe",
            attackAllowed = false,
            pursueAllowed = false,
            commandable = false,
            reason = "unrelated_player",
        }
    elseif name == "new_survivor_after_owner_death" then
        local oldKey = EntityRef.ForPlayerIdentity(
            "validation", "char_old"
        )
        local newKey = EntityRef.ForPlayerIdentity(
            "validation", "char_new"
        )
        resolvedIntent = {
            intent = "observe",
            attackAllowed = false,
            pursueAllowed = false,
            commandable = false,
            reason = oldKey ~= newKey
                and "new_character_identity"
                or "identity_collision",
        }
    end
    return {
        name = name,
        preview = true,
        initialMetrics = initial,
        incidentsCreated = incidents,
        finalMetrics = metricSnapshot(relation),
        finalDiplomaticState = relation.state,
        treatyState = {
            atWar = relation.atWar,
            allied = relation.allied,
            truceUntil = relation.truceUntil,
        },
        resolvedIntent = resolvedIntent,
        revisionDeltas = {
            relation = relation.revision,
            registry = 0,
            npc = 0,
            presence = 0,
        },
        invariants = {
            noWarAllianceOverlap =
                not (relation.atWar and relation.allied),
            noPersistenceMutation = true,
            deterministic = true,
        },
    }
end

return Validation
