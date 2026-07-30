-- Pure serialization-safe faction and affiliation constructors/normalizers.

PNC = PNC or {}
PNC.FactionTypes = PNC.FactionTypes or {}

local Types = PNC.FactionTypes
local Constants = PNC.FactionConstants
local Archetypes = PNC.FactionArchetypes
local EntityRef = PNC.EntityRef
local DiplomacyMath = PNC.FactionDiplomacyMath
local IncidentDefinitions = PNC.FactionIncidentDefinitions
local Balance = PNC.FactionBalance

local function tuning(name, fallback)
    local value = Balance and Balance.Get and Balance.Get(name)
    return value == nil and fallback or value
end

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        value = tonumber(fallback)
    end
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return 0
    end
    return value
end

local function timestamp(value, fallback)
    return math.max(0, finite(value, fallback))
end

local function revision(value)
    return math.max(0, math.floor(finite(value, 0)))
end

local function safeString(value, maximum)
    if type(value) ~= "string" then return nil end
    value = string.match(value, "^%s*(.-)%s*$")
    if value == "" or #value > maximum or string.find(value, "%c") then
        return nil
    end
    return value
end

function Types.IsValidFactionID(value)
    return type(value) == "string"
        and #value > #Constants.ID_PREFIX
        and #value <= Constants.ID_MAX_LENGTH
        and string.sub(value, 1, #Constants.ID_PREFIX)
            == Constants.ID_PREFIX
        and string.match(value, "^faction_[%w_%-]+$") ~= nil
end

function Types.IsValidNPCID(value)
    return type(value) == "string"
        and value ~= ""
        and #value <= 192
        and string.find(value, "%c") == nil
end

function Types.IsValidFactionArchetype(value)
    return Archetypes.Exists(value)
end

function Types.IsValidMembershipStatus(value)
    return type(value) == "string"
        and Constants.VALID_MEMBERSHIP_STATUSES[value] == true
end

function Types.IsValidFactionRole(value)
    return type(value) == "string"
        and Constants.VALID_ROLES[value] == true
end

function Types.IsValidFactionRank(value)
    return type(value) == "string"
        and Constants.VALID_RANKS[value] == true
end

local function normalizeTags(value)
    local output = {}
    if type(value) ~= "table" then return output end
    for key, item in pairs(value) do
        local normalizedKey = safeString(
            key,
            Constants.TAG_KEY_MAX_LENGTH
        )
        if normalizedKey and (item == true or item == false) then
            output[normalizedKey] = item
        elseif normalizedKey and type(item) == "string" then
            local normalizedValue = safeString(
                item,
                Constants.TAG_VALUE_MAX_LENGTH
            )
            if normalizedValue then
                output[normalizedKey] = normalizedValue
            end
        end
    end
    return output
end

local function normalizeIDSet(value, validator)
    local output = {}
    if type(value) ~= "table" then return output end
    for key, enabled in pairs(value) do
        if enabled == true and validator(key) then
            output[key] = true
        end
    end
    return output
end

local function clamp(value, minimum, maximum)
    return DiplomacyMath and DiplomacyMath.Clamp
        and DiplomacyMath.Clamp(value, minimum, maximum)
        or math.max(minimum, math.min(maximum, finite(value, 0)))
end

local function deterministicUnit(seedText)
    local hash = 2166136261
    local index
    seedText = tostring(seedText or "")
    for index = 1, #seedText do
        hash = (
            hash * 16777619
            + string.byte(seedText, index)
        ) % 2147483647
    end
    return (hash % 10001) / 10000
end

local function policyVariation(factionID, field)
    return (deterministicUnit(
        tostring(factionID) .. ":" .. tostring(field)
    ) * 0.16) - 0.08
end

function Types.NormalizePolicy(value, archetypeID, factionID)
    local source = type(value) == "table" and value or {}
    local defaults = Archetypes.GetPolicyDefaults(archetypeID)
        or {
            aggression = 0.5,
            retaliation = 0.5,
            caution = 0.5,
            hospitality = 0.5,
            opportunism = 0.5,
            outsiderPolicy = "neutral",
            warThreshold = 70,
            peaceThreshold = 25,
        }
    local function dimension(field)
        if source[field] ~= nil then
            return clamp(source[field], 0, 1)
        end
        return clamp(
            (tonumber(defaults[field]) or 0.5)
                + policyVariation(factionID, field),
            0,
            1
        )
    end
    local outsiderPolicy =
        Constants.VALID_OUTSIDER_POLICIES[
            source.outsiderPolicy
        ] and source.outsiderPolicy
        or defaults.outsiderPolicy
    return {
        schemaVersion = Constants.POLICY_SCHEMA_VERSION,
        aggression = dimension("aggression"),
        retaliation = dimension("retaliation"),
        caution = dimension("caution"),
        hospitality = dimension("hospitality"),
        opportunism = dimension("opportunism"),
        outsiderPolicy =
            Constants.VALID_OUTSIDER_POLICIES[
                outsiderPolicy
            ] and outsiderPolicy or "neutral",
        warThreshold = clamp(
            source.warThreshold ~= nil
                and source.warThreshold
                or defaults.warThreshold,
            0,
            100
        ),
        peaceThreshold = clamp(
            source.peaceThreshold ~= nil
                and source.peaceThreshold
                or defaults.peaceThreshold,
            0,
            100
        ),
        generatedFromArchetype =
            source.generatedFromArchetype ~= false,
        generationVersion =
            Constants.POLICY_GENERATION_VERSION,
    }
end

function Types.NewPolicy(archetypeID, factionID, overrides)
    return Types.NormalizePolicy(
        overrides,
        archetypeID,
        factionID
    )
end

local function isValidPlayerKey(value)
    return EntityRef and EntityRef.IsPlayer
        and EntityRef.IsPlayer(value) == true
end

function Types.MakeDiplomacyKey(firstFactionID, secondFactionID)
    if not Types.IsValidFactionID(firstFactionID)
        or not Types.IsValidFactionID(secondFactionID)
        or firstFactionID == secondFactionID
    then
        return nil
    end
    if firstFactionID < secondFactionID then
        return firstFactionID .. "|" .. secondFactionID
    end
    return secondFactionID .. "|" .. firstFactionID
end

function Types.NormalizeDiplomacy(value, pairKey)
    local source = type(value) == "table" and value or {}
    local first = Types.IsValidFactionID(source.factionAID)
        and source.factionAID or nil
    local second = Types.IsValidFactionID(source.factionBID)
        and source.factionBID or nil
    local expected = Types.MakeDiplomacyKey(first, second)
    if not expected or (pairKey ~= nil and pairKey ~= expected) then
        return nil
    end
    if second < first then
        first, second = second, first
    end
    return {
        factionAID = first,
        factionBID = second,
        state = Constants.VALID_DIPLOMACY_STATES[source.state]
            and source.state or Constants.DIPLOMACY_PEACE,
        changedAt = timestamp(source.changedAt, 0),
        reason = safeString(
            source.reason,
            Constants.DIPLOMACY_REASON_MAX_LENGTH
        ) or "unspecified",
        instigatorFactionID =
            (
                source.instigatorFactionID == first
                or source.instigatorFactionID == second
            ) and source.instigatorFactionID or nil,
        revision = revision(source.revision),
    }
end

local function normalizeIncidentTags(value)
    local output = {}
    if type(value) ~= "table" then return output end
    for key, enabled in pairs(value) do
        key = safeString(key, Constants.TAG_KEY_MAX_LENGTH)
        if key and enabled == true then output[key] = true end
    end
    return output
end

function Types.NormalizeIncident(
    value,
    relationSourceFactionID,
    relationTargetFactionID
)
    local source = type(value) == "table" and value or {}
    local id = safeString(
        source.id,
        Constants.INCIDENT_ID_MAX_LENGTH
    )
    local incidentType = safeString(
        source.type,
        Constants.INCIDENT_TYPE_MAX_LENGTH
    )
    local definition = IncidentDefinitions
        and IncidentDefinitions.Get(incidentType) or nil
    local incidentSourceFactionID =
        Types.IsValidFactionID(source.sourceFactionID)
        and source.sourceFactionID or nil
    local incidentTargetFactionID =
        Types.IsValidFactionID(source.targetFactionID)
        and source.targetFactionID or nil
    local pairMatches = (
        incidentSourceFactionID == relationSourceFactionID
        and incidentTargetFactionID == relationTargetFactionID
    ) or (
        incidentSourceFactionID == relationTargetFactionID
        and incidentTargetFactionID == relationSourceFactionID
    )
    if not id or not definition
        or not Types.IsValidFactionID(relationSourceFactionID)
        or not Types.IsValidFactionID(relationTargetFactionID)
        or relationSourceFactionID == relationTargetFactionID
        or not pairMatches
    then
        return nil
    end
    local actorKey = EntityRef.IsValid(source.actorKey)
        and source.actorKey or nil
    local subjectKey = EntityRef.IsValid(source.subjectKey)
        and source.subjectKey or nil
    return {
        id = id,
        type = incidentType,
        sourceFactionID = incidentSourceFactionID,
        targetFactionID = incidentTargetFactionID,
        actorKey = actorKey,
        subjectKey = subjectKey,
        occurredAt = timestamp(source.occurredAt, 0),
        standingEffect = clamp(
            source.standingEffect,
            Constants.STANDING_MIN,
            Constants.STANDING_MAX
        ),
        trustEffect = clamp(
            source.trustEffect,
            Constants.TRUST_MIN,
            Constants.TRUST_MAX
        ),
        fearEffect = clamp(
            source.fearEffect,
            -Constants.FEAR_MAX,
            Constants.FEAR_MAX
        ),
        grievanceEffect = clamp(
            source.grievanceEffect,
            -Constants.GRIEVANCE_MAX,
            Constants.GRIEVANCE_MAX
        ),
        severity = clamp(source.severity, 0, 1),
        public = source.public == true,
        witnessed = source.witnessed == true,
        preserve = source.preserve == true
            or definition.preserve == true,
        tags = normalizeIncidentTags(source.tags),
    }
end

local function normalizeRecentIncidentIDs(value)
    local output = {}
    local seen = {}
    if type(value) ~= "table" then return output end
    for index = 1, #value do
        local id = safeString(
            value[index],
            Constants.INCIDENT_ID_MAX_LENGTH
        )
        if id and not seen[id] then
            seen[id] = true
            output[#output + 1] = id
        end
    end
    while #output > tuning(
        "recentIncidentIDLimit",
        Constants.RECENT_INCIDENT_ID_LIMIT
    ) do
        table.remove(output, 1)
    end
    return output
end

local function normalizeIncidents(
    value,
    sourceFactionID,
    targetFactionID
)
    local output = {}
    local seen = {}
    for _, raw in pairs(type(value) == "table" and value or {}) do
        local incident = Types.NormalizeIncident(
            raw,
            sourceFactionID,
            targetFactionID
        )
        if incident and not seen[incident.id] then
            seen[incident.id] = true
            output[#output + 1] = incident
        end
    end
    table.sort(output, function(left, right)
        if left.occurredAt ~= right.occurredAt then
            return left.occurredAt < right.occurredAt
        end
        return left.id < right.id
    end)
    while #output > tuning(
        "incidentHistoryLimit", Constants.INCIDENT_LIMIT
    ) do
        local weakestIndex
        for index, incident in ipairs(output) do
            if incident.preserve ~= true
                and (
                    not weakestIndex
                    or incident.severity
                        < output[weakestIndex].severity
                    or (
                        incident.severity
                            == output[weakestIndex].severity
                        and incident.occurredAt
                            < output[weakestIndex].occurredAt
                    )
                    or (
                        incident.severity
                            == output[weakestIndex].severity
                        and incident.occurredAt
                            == output[weakestIndex].occurredAt
                        and incident.id
                            < output[weakestIndex].id
                    )
                )
            then
                weakestIndex = index
            end
        end
        table.remove(output, weakestIndex or 1)
    end
    return output
end

function Types.NormalizeRelation(
    value,
    sourceFactionID,
    targetFactionID
)
    if not Types.IsValidFactionID(sourceFactionID)
        or not Types.IsValidFactionID(targetFactionID)
        or sourceFactionID == targetFactionID
    then
        return nil
    end
    local source = type(value) == "table" and value or {}
    local relation = {
        schemaVersion = Constants.RELATION_SCHEMA_VERSION,
        targetFactionID = targetFactionID,
        standing = DiplomacyMath.ClampStanding(
            source.standing
        ),
        trust = DiplomacyMath.ClampTrust(source.trust),
        fear = DiplomacyMath.ClampFear(source.fear),
        grievance = DiplomacyMath.ClampGrievance(
            source.grievance
        ),
        state = Constants.VALID_RELATION_STATES[source.state]
            and source.state or "unknown",
        previousState =
            Constants.VALID_RELATION_STATES[
                source.previousState
            ] and source.previousState or "unknown",
        atWar = source.atWar == true,
        allied = source.allied == true,
        truceUntil = timestamp(source.truceUntil, 0),
        warStartedAt = timestamp(source.warStartedAt, 0),
        warEndedAt = timestamp(source.warEndedAt, 0),
        warReason = Constants.WAR_REASONS[source.warReason]
            and source.warReason or nil,
        initiatingFactionID =
            Types.IsValidFactionID(
                source.initiatingFactionID
            ) and source.initiatingFactionID or nil,
        triggeringIncidentID = safeString(
            source.triggeringIncidentID,
            Constants.INCIDENT_ID_MAX_LENGTH
        ),
        incidents = normalizeIncidents(
            source.incidents,
            sourceFactionID,
            targetFactionID
        ),
        recentIncidentIDs = normalizeRecentIncidentIDs(
            source.recentIncidentIDs
        ),
        lastEvaluatedAt = timestamp(
            source.lastEvaluatedAt,
            0
        ),
        revision = revision(source.revision),
    }
    if relation.atWar then
        relation.allied = false
        relation.truceUntil = 0
    elseif relation.allied then
        relation.truceUntil = 0
    end
    relation.state = DiplomacyMath.ResolveState(
        relation,
        relation.lastEvaluatedAt
    )
    return relation
end

function Types.NewRelation(sourceFactionID, targetFactionID)
    return Types.NormalizeRelation(
        nil,
        sourceFactionID,
        targetFactionID
    )
end

local function normalizeFormerFaction(value)
    if type(value) ~= "table"
        or not Types.IsValidFactionID(value.factionID)
    then
        return nil
    end
    local joinedAt = timestamp(value.joinedAt, 0)
    return {
        factionID = value.factionID,
        joinedAt = joinedAt,
        leftAt = math.max(
            joinedAt,
            timestamp(value.leftAt, joinedAt)
        ),
        reason = Constants.VALID_LEAVE_REASONS[value.reason]
            and value.reason or "unknown",
    }
end

local function normalizeFormerFactions(value)
    local output = {}
    local seen = {}
    local entry
    for _, raw in pairs(type(value) == "table" and value or {}) do
        entry = normalizeFormerFaction(raw)
        if entry then
            local key = entry.factionID .. ":"
                .. tostring(entry.joinedAt) .. ":"
                .. tostring(entry.leftAt) .. ":"
                .. entry.reason
            if not seen[key] then
                seen[key] = true
                output[#output + 1] = entry
            end
        end
    end
    table.sort(output, function(left, right)
        if left.leftAt ~= right.leftAt then
            return left.leftAt < right.leftAt
        end
        if left.joinedAt ~= right.joinedAt then
            return left.joinedAt < right.joinedAt
        end
        if left.factionID ~= right.factionID then
            return left.factionID < right.factionID
        end
        return left.reason < right.reason
    end)
    while #output > Constants.FORMER_FACTION_LIMIT do
        table.remove(output, 1)
    end
    return output
end

function Types.NormalizeAffiliation(value, faction)
    local source = type(value) == "table" and value or {}
    local factionID = Types.IsValidFactionID(source.factionID)
        and source.factionID or nil
    if faction == false then factionID = nil end
    local archetypeID = faction and faction.archetypeID or nil
    local status = Types.IsValidMembershipStatus(
        source.membershipStatus
    ) and source.membershipStatus or nil
    local role = Types.IsValidFactionRole(source.role)
        and source.role or nil
    local rank = Types.IsValidFactionRank(source.rank)
        and source.rank or "member"
    if not factionID then
        status = "unaffiliated"
        role = "civilian"
        rank = "member"
    else
        status = status == "unaffiliated" and "member"
            or status or "member"
        if archetypeID and not Archetypes.IsRoleAllowed(
            archetypeID,
            role
        ) then
            role = Archetypes.GetDefaultRole(archetypeID)
        end
        role = role or "civilian"
    end
    return {
        schemaVersion = Constants.AFFILIATION_SCHEMA_VERSION,
        factionID = factionID,
        membershipStatus = status,
        role = role,
        rank = rank,
        joinedAt = factionID and timestamp(source.joinedAt, 0) or 0,
        leftAt = factionID and 0 or timestamp(source.leftAt, 0),
        originArchetypeID =
            Archetypes.Exists(source.originArchetypeID)
                and source.originArchetypeID or nil,
        formerFactionIDs = normalizeFormerFactions(
            source.formerFactionIDs
        ),
        revision = revision(source.revision),
    }
end

function Types.NewAffiliation(value)
    return Types.NormalizeAffiliation(value)
end

function Types.AppendFormerFaction(
    affiliation,
    factionID,
    leftAt,
    reason
)
    local normalized = Types.NormalizeAffiliation(affiliation)
    normalized.formerFactionIDs[
        #normalized.formerFactionIDs + 1
    ] = {
        factionID = factionID,
        joinedAt = normalized.joinedAt,
        leftAt = timestamp(leftAt, normalized.joinedAt),
        reason = Constants.VALID_LEAVE_REASONS[reason]
            and reason or "unknown",
    }
    normalized.formerFactionIDs = normalizeFormerFactions(
        normalized.formerFactionIDs
    )
    return normalized
end

function Types.NormalizeFaction(value, factionID)
    local source = type(value) == "table" and value or {}
    local id = Types.IsValidFactionID(factionID)
        and factionID
        or Types.IsValidFactionID(source.id) and source.id
        or nil
    local name = safeString(source.name, Constants.NAME_MAX_LENGTH)
    local archetypeID = Archetypes.Exists(source.archetypeID)
        and source.archetypeID or nil
    if not id or not name or not archetypeID then return nil end
    local output = {
        id = id,
        name = name,
        archetypeID = archetypeID,
        status = Constants.VALID_FACTION_STATUSES[source.status]
            and source.status or "active",
        createdAt = timestamp(source.createdAt, 0),
        archivedAt = timestamp(source.archivedAt, 0),
        leaderNPCID = Types.IsValidNPCID(source.leaderNPCID)
            and source.leaderNPCID or nil,
        ownerPlayerKey = isValidPlayerKey(source.ownerPlayerKey)
            and source.ownerPlayerKey or nil,
        memberIDs = normalizeIDSet(
            source.memberIDs,
            Types.IsValidNPCID
        ),
        playerMemberKeys = normalizeIDSet(
            source.playerMemberKeys,
            isValidPlayerKey
        ),
        policy = Types.NormalizePolicy(
            source.policy,
            archetypeID,
            id
        ),
        relations = {},
        tags = normalizeTags(source.tags),
        revision = revision(source.revision),
    }
    for targetFactionID, rawRelation in pairs(
        type(source.relations) == "table"
            and source.relations or {}
    ) do
        local relation = Types.NormalizeRelation(
            rawRelation,
            id,
            targetFactionID
        )
        if relation then
            output.relations[targetFactionID] = relation
        end
    end
    return output
end

function Types.NewFaction(spec)
    return Types.NormalizeFaction(spec, spec and spec.id)
end

function Types.NormalizeFactionRegistry(value)
    local source = type(value) == "table" and value or {}
    local output = {
        schemaVersion = Constants.REGISTRY_SCHEMA_VERSION,
        revision = revision(source.revision),
        byID = {},
        byArchetype = {},
        byPlayerKey = {},
    }
    local faction
    local factionIDs = {}
    for id, raw in pairs(
        type(source.byID) == "table" and source.byID or {}
    ) do
        faction = Types.NormalizeFaction(raw, id)
        if faction and faction.id == id then
            output.byID[id] = faction
            factionIDs[#factionIDs + 1] = id
            output.byArchetype[faction.archetypeID] =
                output.byArchetype[faction.archetypeID] or {}
            output.byArchetype[faction.archetypeID][id] = true
        end
    end
    table.sort(factionIDs)
    for _, id in ipairs(factionIDs) do
        faction = output.byID[id]
        for playerKey, _ in pairs(
            faction.playerMemberKeys or {}
        ) do
            if output.byPlayerKey[playerKey] == nil then
                output.byPlayerKey[playerKey] = id
            else
                faction.playerMemberKeys[playerKey] = nil
                if faction.ownerPlayerKey == playerKey then
                    faction.ownerPlayerKey = nil
                end
            end
        end
        if faction.ownerPlayerKey
            and faction.playerMemberKeys[
                faction.ownerPlayerKey
            ] ~= true
        then
            faction.ownerPlayerKey = nil
        end
    end
    -- V2 stored one symmetric pair record. V3 migrates it into two directed
    -- relations while preserving the official war/peace state.
    for pairKey, raw in pairs(
        type(source.diplomacy) == "table"
            and source.diplomacy or {}
    ) do
        local diplomacy = Types.NormalizeDiplomacy(raw, pairKey)
        if diplomacy
            and output.byID[diplomacy.factionAID]
            and output.byID[diplomacy.factionBID]
        then
            local first = output.byID[diplomacy.factionAID]
            local second = output.byID[diplomacy.factionBID]
            local atWar =
                diplomacy.state == Constants.DIPLOMACY_WAR
            local function migrateRelation(
                sourceFaction,
                targetFaction
            )
                if sourceFaction.relations[targetFaction.id] then
                    return
                end
                sourceFaction.relations[targetFaction.id] =
                    Types.NormalizeRelation({
                        atWar = atWar,
                        state = atWar and "war" or "neutral",
                        previousState = "unknown",
                        warStartedAt = atWar
                            and diplomacy.changedAt or 0,
                        warEndedAt = atWar
                            and 0 or diplomacy.changedAt,
                        warReason = atWar and "unknown" or nil,
                        initiatingFactionID =
                            diplomacy.instigatorFactionID,
                        lastEvaluatedAt =
                            diplomacy.changedAt,
                        revision = diplomacy.revision,
                    }, sourceFaction.id, targetFaction.id)
            end
            migrateRelation(first, second)
            migrateRelation(second, first)
        end
    end
    return output
end

function Types.NewFactionRegistry(value)
    return Types.NormalizeFactionRegistry(value)
end

function Types.NormalizeTags(value)
    return normalizeTags(value)
end

function Types.AreEqual(left, right, seen)
    if type(left) ~= type(right) then return false end
    if type(left) ~= "table" then return left == right end
    seen = seen or {}
    if seen[left] == right then return true end
    seen[left] = right
    for key, item in pairs(left) do
        if not Types.AreEqual(item, right[key], seen) then
            return false
        end
    end
    for key, _ in pairs(right) do
        if left[key] == nil then return false end
    end
    return true
end

return Types
