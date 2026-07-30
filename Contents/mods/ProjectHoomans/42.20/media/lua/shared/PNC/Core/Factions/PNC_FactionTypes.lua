-- Pure serialization-safe faction and affiliation constructors/normalizers.

PNC = PNC or {}
PNC.FactionTypes = PNC.FactionTypes or {}

local Types = PNC.FactionTypes
local Constants = PNC.FactionConstants
local Archetypes = PNC.FactionArchetypes
local EntityRef = PNC.EntityRef

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
    return {
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
        tags = normalizeTags(source.tags),
        revision = revision(source.revision),
    }
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
        diplomacy = {},
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
    for pairKey, raw in pairs(
        type(source.diplomacy) == "table"
            and source.diplomacy or {}
    ) do
        local diplomacy = Types.NormalizeDiplomacy(raw, pairKey)
        if diplomacy
            and output.byID[diplomacy.factionAID]
            and output.byID[diplomacy.factionBID]
        then
            output.diplomacy[pairKey] = diplomacy
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
