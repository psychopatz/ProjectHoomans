-- Read-only faction invariant checks and isolated deterministic previews.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then
    return
end

PNC = PNC or {}
PNC.FactionValidation = PNC.FactionValidation or {}

local Validation = PNC.FactionValidation
local Factions = PNC.Factions
local Types = PNC.FactionTypes
local Math = PNC.FactionDiplomacyMath
local Definitions = PNC.FactionIncidentDefinitions
local Constants = PNC.FactionConstants
local EntityRef = PNC.EntityRef
local Balance = PNC.FactionBalance

Validation.Scenarios = {
    "single_minor_attack",
    "repeated_minor_attacks",
    "severe_attack",
    "member_killed",
    "leader_killed",
    "rescue_then_attack",
    "war_then_peace",
    "war_then_truce",
    "truce_broken",
    "alliance_then_betrayal",
    "looter_meets_stronger_outsider",
    "looter_meets_weaker_outsider",
    "unrelated_multiplayer_player",
    "new_survivor_after_owner_death",
}

local function copy(value)
    return PNC.Core.DeepCopy(value)
end

local function addIssue(result, severity, code, detail)
    local issue = {
        severity = severity,
        code = code,
        detail = tostring(detail or ""),
    }
    if severity == "error" then
        result.errors[#result.errors + 1] = issue
        result.ok = false
    else
        result.warnings[#result.warnings + 1] = issue
    end
end

local function newResult(scope)
    return {
        ok = true,
        scope = scope,
        errors = {},
        warnings = {},
        checks = 0,
    }
end

local function safePersistent(value, path, result, seen)
    local kind = type(value)
    result.checks = result.checks + 1
    if kind == "function" or kind == "userdata"
        or kind == "thread"
    then
        addIssue(result, "error", "unsafe_persistent_value",
            path .. ":" .. kind)
        return
    end
    if kind == "number"
        and (
            value ~= value
            or value == math.huge
            or value == -math.huge
        )
    then
        addIssue(result, "error", "non_finite_number", path)
        return
    end
    if kind ~= "table" then return end
    if getmetatable and getmetatable(value) ~= nil then
        addIssue(result, "error", "persistent_metatable", path)
    end
    if seen[value] then
        addIssue(result, "error", "persistent_cycle", path)
        return
    end
    seen[value] = true
    for key, child in pairs(value) do
        if type(key) ~= "string" and type(key) ~= "number" then
            addIssue(result, "error",
                "unsafe_persistent_key", path)
        end
        safePersistent(
            child,
            path .. "." .. tostring(key),
            result,
            seen
        )
    end
    seen[value] = nil
end

local function checkRelationInto(
    result,
    sourceID,
    targetID,
    relation
)
    result.checks = result.checks + 1
    if relation.targetFactionID ~= targetID then
        addIssue(result, "error", "relation_target_mismatch",
            sourceID .. "->" .. targetID)
    end
    local ranges = {
        standing = {
            Constants.STANDING_MIN, Constants.STANDING_MAX,
        },
        trust = { Constants.TRUST_MIN, Constants.TRUST_MAX },
        fear = { Constants.FEAR_MIN, Constants.FEAR_MAX },
        grievance = {
            Constants.GRIEVANCE_MIN, Constants.GRIEVANCE_MAX,
        },
    }
    for name, limits in pairs(ranges) do
        local value = tonumber(relation[name])
        if not value or value < limits[1] or value > limits[2] then
            addIssue(result, "error", "metric_out_of_range",
                sourceID .. "->" .. targetID .. ":" .. name)
        end
    end
    if relation.atWar == true and relation.allied == true then
        addIssue(result, "error", "war_and_alliance",
            sourceID .. "->" .. targetID)
    end
    if relation.atWar == true
        and (tonumber(relation.truceUntil) or 0) > 0
    then
        addIssue(result, "error", "war_and_truce",
            sourceID .. "->" .. targetID)
    end
    local incidentIDs = {}
    for _, incident in ipairs(relation.incidents or {}) do
        if incidentIDs[incident.id] then
            addIssue(result, "error", "duplicate_incident_id",
                tostring(incident.id))
        end
        incidentIDs[incident.id] = true
    end
    if #(relation.incidents or {}) > (
        Balance and Balance.Get("incidentHistoryLimit")
            or Constants.INCIDENT_LIMIT
    ) then
        addIssue(result, "error", "incident_history_unbounded",
            sourceID .. "->" .. targetID)
    end
    if #(relation.recentIncidentIDs or {})
        > (
            Balance
            and Balance.Get("recentIncidentIDLimit")
            or Constants.RECENT_INCIDENT_ID_LIMIT
        )
    then
        addIssue(result, "error", "recent_incident_cache_unbounded",
            sourceID .. "->" .. targetID)
    end
end

function Validation.CheckRelation(sourceID, targetID)
    local result = newResult(
        "relation:" .. tostring(sourceID)
            .. "->" .. tostring(targetID)
    )
    local source = Factions.Registry.byID[sourceID]
    local target = Factions.Registry.byID[targetID]
    local relation = source and source.relations[targetID]
    if not source or not target or not relation then
        addIssue(result, "error", "relation_missing",
            result.scope)
        return result
    end
    checkRelationInto(result, sourceID, targetID, relation)
    local reverse = target.relations[sourceID]
    if relation.atWar == true
        and (not reverse or reverse.atWar ~= true)
    then
        addIssue(result, "error", "asymmetric_war", result.scope)
    end
    if relation.allied == true
        and (not reverse or reverse.allied ~= true)
    then
        addIssue(result, "error", "asymmetric_alliance",
            result.scope)
    end
    local forwardTruce = tonumber(relation.truceUntil) or 0
    local reverseTruce = tonumber(
        reverse and reverse.truceUntil
    ) or 0
    if forwardTruce ~= reverseTruce then
        addIssue(result, "error", "asymmetric_truce",
            result.scope)
    end
    return result
end

function Validation.CheckFaction(factionID)
    local result = newResult("faction:" .. tostring(factionID))
    local faction = Factions.Registry.byID[factionID]
    if not faction then
        addIssue(result, "error", "faction_missing", factionID)
        return result
    end
    if faction.ownerPlayerKey then
        local parsed = EntityRef.Parse(faction.ownerPlayerKey)
        if not parsed or parsed.kind ~= "player"
            or not parsed.characterUUID
        then
            addIssue(result, "error", "invalid_player_owner_key",
                faction.ownerPlayerKey)
        end
        if Factions.Registry.byPlayerKey[
            faction.ownerPlayerKey
        ] ~= factionID
        then
            addIssue(result, "error",
                "player_owner_index_mismatch",
                faction.ownerPlayerKey)
        end
    end
    for playerKey, enabled in pairs(
        faction.playerMemberKeys or {}
    ) do
        if enabled == true then
            local parsed = EntityRef.Parse(playerKey)
            if not parsed or parsed.kind ~= "player"
                or not parsed.characterUUID
            then
                addIssue(result, "error",
                    "invalid_player_member_key", playerKey)
            elseif Factions.Registry.byPlayerKey[playerKey]
                ~= factionID
            then
                addIssue(result, "error",
                    "player_member_index_mismatch", playerKey)
            end
        end
    end
    if faction.status ~= "active"
        and faction.leaderNPCID ~= nil
    then
        addIssue(result, "error", "archived_active_leader",
            faction.leaderNPCID)
    end
    if faction.leaderNPCID then
        local leader = PNC.Registry.Get(faction.leaderNPCID)
        if not leader or leader.alive == false then
            addIssue(result, "error", "dead_or_missing_leader",
                faction.leaderNPCID)
        end
    end
    for npcID, _ in pairs(faction.memberIDs or {}) do
        local record = PNC.Registry.Get(npcID)
        if not record or not record.affiliation
            or record.affiliation.factionID ~= factionID
        then
            addIssue(result, "error", "member_index_mismatch",
                npcID)
        end
    end
    for targetID, relation in pairs(faction.relations or {}) do
        if not Factions.Registry.byID[targetID] then
            addIssue(result, "warning", "relation_target_missing",
                targetID)
        else
            checkRelationInto(
                result, factionID, targetID, relation
            )
        end
    end
    safePersistent(faction, "faction", result, {})
    return result
end

function Validation.CheckRegistry()
    Factions.EnsureLoaded()
    local result = newResult("registry")
    local memberships = {}
    for factionID, faction in pairs(Factions.Registry.byID or {}) do
        local factionResult = Validation.CheckFaction(factionID)
        result.checks = result.checks + factionResult.checks
        for _, issue in ipairs(factionResult.errors) do
            addIssue(result, "error", issue.code, issue.detail)
        end
        for _, issue in ipairs(factionResult.warnings) do
            addIssue(result, "warning", issue.code, issue.detail)
        end
        for npcID, _ in pairs(faction.memberIDs or {}) do
            local prior = memberships[npcID]
            if prior
                and prior.factionID ~= factionID
                and prior.active == true
                and faction.status == "active"
            then
                addIssue(result, "error",
                    "duplicate_active_membership", npcID)
            else
                memberships[npcID] = {
                    factionID = factionID,
                    active = faction.status == "active",
                }
            end
        end
        for targetID, relation in pairs(faction.relations or {}) do
            local reverse = Factions.Registry.byID[targetID]
                and Factions.Registry.byID[targetID]
                    .relations[factionID] or nil
            if relation.atWar == true
                and (not reverse or reverse.atWar ~= true)
            then
                addIssue(result, "error", "asymmetric_war",
                    factionID .. "->" .. targetID)
            end
            if relation.allied == true
                and (not reverse or reverse.allied ~= true)
            then
                addIssue(result, "error", "asymmetric_alliance",
                    factionID .. "->" .. targetID)
            end
            if (tonumber(relation.truceUntil) or 0)
                ~= (tonumber(reverse and reverse.truceUntil) or 0)
            then
                addIssue(result, "error", "asymmetric_truce",
                    factionID .. "->" .. targetID)
            end
        end
    end
    safePersistent(Factions.Registry, "registry", result, {})
    if PNC.FactionTelemetry then
        PNC.FactionTelemetry.RecordValidation({
            operation = "check_registry",
            worldAgeHours = 0,
            result = result.ok and "valid" or "invalid",
            reason = result.ok and "all_invariants_hold"
                or "invariant_failure",
            errorCount = #result.errors,
            warningCount = #result.warnings,
        })
    end
    return result
end

function Validation.RepairSecondaryIndexes()
    if PNC.Core and PNC.Core.IsAuthority
        and PNC.Core.IsAuthority() ~= true
    then
        return false, "not_authority"
    end
    Factions.EnsureLoaded()
    local registry = Factions.Registry
    local byArchetype = {}
    local byPlayerKey = {}
    local memberIDs = {}
    local factionIDs = {}
    local changed = false
    for factionID, _ in pairs(registry.byID or {}) do
        factionIDs[#factionIDs + 1] = factionID
        memberIDs[factionID] = {}
    end
    table.sort(factionIDs)
    for _, factionID in ipairs(factionIDs) do
        local faction = registry.byID[factionID]
        byArchetype[faction.archetypeID] =
            byArchetype[faction.archetypeID] or {}
        byArchetype[faction.archetypeID][factionID] = true
        for playerKey, enabled in pairs(
            faction.playerMemberKeys or {}
        ) do
            if enabled == true and not byPlayerKey[playerKey] then
                byPlayerKey[playerKey] = factionID
            end
        end
    end
    for npcID, record in pairs(PNC.Registry.Data or {}) do
        local factionID = record.affiliation
            and record.affiliation.factionID or nil
        local faction = factionID and registry.byID[factionID]
        if faction and faction.status == "active" then
            memberIDs[factionID][npcID] = true
        end
    end
    for _, factionID in ipairs(factionIDs) do
        local faction = registry.byID[factionID]
        if not Types.AreEqual(
            faction.memberIDs,
            memberIDs[factionID]
        ) then
            faction.memberIDs = memberIDs[factionID]
            faction.revision =
                (tonumber(faction.revision) or 0) + 1
            changed = true
        end
    end
    if not Types.AreEqual(registry.byArchetype, byArchetype) then
        registry.byArchetype = byArchetype
        changed = true
    end
    if not Types.AreEqual(registry.byPlayerKey, byPlayerKey) then
        registry.byPlayerKey = byPlayerKey
        changed = true
    end
    if not changed then return false, "unchanged" end
    registry.revision = (tonumber(registry.revision) or 0) + 1
    return true, "secondary_indexes_repaired"
end

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
