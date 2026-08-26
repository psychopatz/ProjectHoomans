-- Shared, serialization-safe NPC identity and ownership contract.
-- factionID is authoritative for organizational membership. The separate
-- faction field is only the NPC tactical behavior class.

PNC = PNC or {}
PNC.Identity = PNC.Identity or {}
PNC.Identity.Verifier = PNC.Identity.Verifier or {}

local Verifier = PNC.Identity.Verifier

Verifier.API_VERSION = 1
Verifier.SCHEMA_VERSION = 1

local function sources(value)
    if type(value) ~= "table" then return nil, nil, nil end
    if value.record or value.snapshot then
        return type(value.record) == "table" and value.record or nil,
            type(value.snapshot) == "table" and value.snapshot or nil,
            value
    end
    return value, nil, nil
end

local function read(value, key)
    local first, second, third = sources(value)
    if first and first[key] ~= nil then return first[key] end
    if second and second[key] ~= nil then return second[key] end
    return third and third[key] or nil
end

local function any(value, key)
    local first, second, third = sources(value)
    return first and first[key] ~= nil and first[key]
        or second and second[key] ~= nil and second[key]
        or third and third[key] ~= nil and third[key]
        or nil
end

local function optionalString(value)
    if value == nil or tostring(value) == "" then return nil end
    return tostring(value)
end

local function affiliation(value)
    local first, second, third = sources(value)
    local candidate = first and first.affiliation
        or second and second.affiliation
        or third and third.affiliation
    return type(candidate) == "table" and candidate or nil
end

local function factionIDFromSource(source)
    local nested
    local current
    if not source then return nil end
    nested = type(source.affiliation) == "table"
        and source.affiliation or nil
    current = nested and nested.factionID or source.factionID
    return optionalString(current)
end

local function ownerUsernameFromSource(source)
    local window
    if not source then return nil end
    window = type(source.characterWindow) == "table"
        and source.characterWindow or nil
    return optionalString(source.ownerUsername
        or window and window.ownerUsername)
end

local function ownerOnlineIDFromSource(source)
    local window
    local owner
    if not source then return nil end
    window = type(source.characterWindow) == "table"
        and source.characterWindow or nil
    owner = source.ownerOnlineID
        or window and window.ownerOnlineID
    return owner ~= nil and (tonumber(owner) or owner) or nil
end

function Verifier.GetFactionID(value)
    local first, second, third = sources(value)
    return factionIDFromSource(first) or factionIDFromSource(second)
        or factionIDFromSource(third)
end

function Verifier.GetOwnerUsername(value)
    local first, second, third = sources(value)
    return ownerUsernameFromSource(first)
        or ownerUsernameFromSource(second)
        or ownerUsernameFromSource(third)
end

function Verifier.GetOwnerOnlineID(value)
    local first, second, third = sources(value)
    return ownerOnlineIDFromSource(first)
        or ownerOnlineIDFromSource(second)
        or ownerOnlineIDFromSource(third)
end

function Verifier.IsRecruited(value)
    return any(value, "recruited") == true
end

function Verifier.IsCompanion(value)
    return read(value, "alive") ~= false and Verifier.IsRecruited(value)
end

local function playerKey(player)
    local context
    local uuid
    local character
    if not player then return nil end
    context = PNC.PlayerContext and PNC.PlayerContext.Peek
        and PNC.PlayerContext.Peek(player) or nil
    if context and context.entityKey then return context.entityKey end
    if not PNC.PlayerCharacters
        or not PNC.PlayerCharacters.GetCharacterUUID
    then return nil end
    uuid = PNC.PlayerCharacters.GetCharacterUUID(player)
    character = uuid and PNC.PlayerCharacters.Registry
        and PNC.PlayerCharacters.Registry.byUUID
        and PNC.PlayerCharacters.Registry.byUUID[uuid] or nil
    if not character or not PNC.EntityRef
        or not PNC.EntityRef.ForPlayerIdentity
    then return nil end
    return PNC.EntityRef.ForPlayerIdentity(
        character.accountKey or character.accountIdentity,
        uuid
    )
end

local function factionFor(factionID)
    if not factionID or not PNC.Factions
        or not PNC.Factions.Get
    then return nil end
    return PNC.Factions.Get(factionID)
end

local function factionHasPlayer(faction)
    if not faction then return false end
    if optionalString(faction.ownerPlayerKey) then return true end
    for _, enabled in pairs(faction.playerMemberKeys or {}) do
        if enabled == true then return true end
    end
    return false
end

function Verifier.GetPlayerFactionID(player)
    local key = playerKey(player)
    local faction
    if not key then return nil, "player_identity_unavailable" end
    if not PNC.Factions or not PNC.Factions.GetFactionForPlayerKey then
        return nil, "factions_unavailable"
    end
    faction = PNC.Factions.GetFactionForPlayerKey(key)
    return faction and faction.id or nil,
        faction and "faction_player_member" or "faction_not_found"
end

-- This is the hot-path summary used by presence replication. Keep all
-- identity reads in one pass so a mobile NPC does not trigger four separate
-- ownership scans every time its position is replicated.
function Verifier.BuildOwnershipSummary(value)
    local factionID = Verifier.GetFactionID(value)
    local ownerUsername = Verifier.GetOwnerUsername(value)
    local ownerOnlineID = Verifier.GetOwnerOnlineID(value)
    local recruited = any(value, "recruited") == true
    local declaredColonyOwned = any(value, "colonyOwned") == true
    local colonyOwned = false
    local faction
    if factionID then
        faction = factionFor(factionID)
        if PNC.Factions and PNC.Factions.Get then
            colonyOwned = factionHasPlayer(faction)
        else
            colonyOwned = declaredColonyOwned
        end
    end
    return {
        factionID = factionID,
        recruited = recruited,
        colonyOwned = colonyOwned,
        ownerUsername = ownerUsername,
        ownerOnlineID = ownerOnlineID,
    }
end

function Verifier.ResolveOwnership(value, player)
    local factionID = Verifier.GetFactionID(value)
    local faction = factionFor(factionID)
    local key
    if not value or not player then return false, "player_unavailable" end
    if not factionID then return false, "faction_id_required" end
    if not PNC.Factions or not PNC.Factions.Get then
        return false, "factions_unavailable"
    end
    if not faction then return false, "faction_not_found" end
    key = playerKey(player)
    if not key then return false, "player_identity_unavailable" end
    if faction.ownerPlayerKey == key
        or faction.playerMemberKeys
            and faction.playerMemberKeys[key] == true
    then
        return true, "faction_player_member"
    end
    return false, "not_faction_player_member"
end

function Verifier.IsOwnedByPlayer(value, player)
    local owned = Verifier.ResolveOwnership(value, player)
    return owned == true
end

function Verifier.IsPlayerFaction(value)
    local faction = factionFor(Verifier.GetFactionID(value))
    return factionHasPlayer(faction)
end

function Verifier.IsColonyOwnedNPC(value)
    return Verifier.BuildOwnershipSummary(value).colonyOwned == true
end

function Verifier.Verify(value, options)
    local result = {
        schemaVersion = Verifier.SCHEMA_VERSION,
        ok = true,
        errors = {},
        warnings = {},
        factionID = Verifier.GetFactionID(value),
    }
    local id = read(value, "id") or read(value, "npcID")
    local rawAffiliation = affiliation(value)
    local faction = factionFor(result.factionID)
    options = type(options) == "table" and options or {}
    if type(value) ~= "table" then
        result.errors[#result.errors + 1] = "source_not_table"
    elseif not optionalString(id) then
        result.errors[#result.errors + 1] = "npc_id_missing"
    end
    local types = PNC.FactionTypes
    if result.factionID and types and types.IsValidFactionID
        and not types.IsValidFactionID(result.factionID)
    then
        result.errors[#result.errors + 1] = "invalid_faction_id"
    elseif result.factionID and PNC.Factions and PNC.Factions.Get
        and not faction
    then
        result.errors[#result.errors + 1] = "faction_not_found"
    end
    if rawAffiliation and rawAffiliation.factionID
        and not result.factionID
    then
        result.errors[#result.errors + 1] = "affiliation_id_unreadable"
    end
    if options.requireFaction == true and not result.factionID then
        result.errors[#result.errors + 1] = "faction_id_required"
    end
    result.ok = #result.errors == 0
    return result
end

function Verifier.BuildView(value, options)
    local factionID = Verifier.GetFactionID(value)
    local faction = factionFor(factionID)
    local rawAffiliation = affiliation(value) or {}
    local ownership = Verifier.BuildOwnershipSummary(value)
    local view = {
        schemaVersion = Verifier.SCHEMA_VERSION,
        npcID = tostring(read(value, "id") or read(value, "npcID") or ""),
        factionID = factionID,
        factionName = faction and faction.name or nil,
        factionArchetypeID = faction and faction.archetypeID or nil,
        isFactionMember = factionID ~= nil,
        membershipStatus = rawAffiliation.membershipStatus
            or read(value, "membershipStatus"),
        role = rawAffiliation.role or read(value, "role"),
        rank = rawAffiliation.rank or read(value, "rank"),
        recruited = ownership.recruited,
        companion = Verifier.IsCompanion(value),
        colonyOwned = ownership.colonyOwned,
        identitySource = factionID and "factionID"
            or "none",
    }
    local verification = Verifier.Verify(value)
    view.identityVerified = verification.ok == true
        and factionID ~= nil
    view.identityStatus = verification.ok ~= true and "invalid"
        or factionID and "verified"
        or "unaffiliated"
    options = type(options) == "table" and options or {}
    if options.includeOwner == true then
        view.ownerUsername = Verifier.GetOwnerUsername(value)
        view.ownerOnlineID = Verifier.GetOwnerOnlineID(value)
    end
    if options.player then
        view.viewerFactionID, view.viewerFactionReason =
            Verifier.GetPlayerFactionID(options.player)
        view.viewerOwned, view.viewerOwnershipReason =
            Verifier.ResolveOwnership(value, options.player)
    end
    return view
end

Verifier.Get = Verifier.BuildView
Verifier.VerifyPayload = Verifier.Verify

return Verifier
