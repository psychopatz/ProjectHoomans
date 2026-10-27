-- Semantic conversational address selection.
--
-- This module never creates or mutates identity facts. It only projects an
-- authoritative identity/relationship context into a bounded player-facing
-- address. Transport/debug placeholders are rejected before they can reach
-- dialogue text.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

if not PNC.Identity or not PNC.Identity.NormalizeSeed then
    require "PNC/Core/Identity/PNC_Identity"
end

local Resolver = PNC.Semantics.AddressResolver or {}
PNC.Semantics.AddressResolver = Resolver

Resolver.VERSION = 1
Resolver.MAX_RECENT = 4

local PLACEHOLDERS = {
    ["unknown survivor"] = true,
    ["unknown"] = true,
    ["stranger"] = false,
    ["unknown background"] = true,
    ["unknown faction"] = true,
}

local TERMS = {
    stranger = {
        id = "stranger",
        key = "UI_PNC_SemanticAddress_Unknown_Stranger",
        fallback = "stranger",
    },
    mate = {
        id = "mate",
        key = "UI_PNC_SemanticAddress_Unknown_Mate",
        fallback = "mate",
    },
    pal = {
        id = "pal",
        key = "UI_PNC_SemanticAddress_Unknown_Pal",
        fallback = "pal",
    },
    bro = {
        id = "bro",
        key = "UI_PNC_SemanticAddress_Unknown_Bro",
        fallback = "bro",
    },
    mister = {
        id = "mister",
        key = "UI_PNC_SemanticAddress_Unknown_Mister",
        fallback = "mister",
    },
    miss = {
        id = "miss",
        key = "UI_PNC_SemanticAddress_Unknown_Miss",
        fallback = "miss",
    },
}

local function clean(value, limit)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    if value == "" then return nil end
    return string.sub(value, 1, limit or 96)
end

local function lower(value)
    return string.lower(clean(value, 96) or "")
end

local function translated(term, language)
    local translation = PNC.Translation
    if translation and type(translation.GetKey) == "function" then
        local value = translation.GetKey(term.key, term.fallback, language)
        value = clean(value, 64)
        if value and value ~= term.key then return value end
    end
    return term.fallback
end

local function recentContains(recent, id)
    if type(recent) ~= "table" then return false end
    for index = 1, math.min(#recent, Resolver.MAX_RECENT) do
        local value = recent[index]
        if type(value) == "table" then value = value.id or value.term end
        if lower(value) == lower(id) then return true end
    end
    return false
end

local function identityName(spec)
    local target = type(spec.target) == "table" and spec.target or {}
    local name = spec.knownName or spec.name or target.knownName
        or target.name or target.displayName
    name = clean(name, 96)
    if not name or PLACEHOLDERS[lower(name)] == true then return nil end
    return name
end

local function identityKnown(spec, name)
    if type(spec.identityKnown) == "boolean" then
        return spec.identityKnown and name ~= nil
    end
    if type(spec.nameKnown) == "boolean" then
        return spec.nameKnown and name ~= nil
    end
    return name ~= nil and PLACEHOLDERS[lower(name)] ~= true
end

local function gender(spec)
    local target = type(spec.target) == "table" and spec.target or {}
    local value = lower(spec.gender or spec.sex or target.gender or target.sex)
    if spec.isFemale == true or value == "female" or value == "woman" then
        return "female"
    end
    if spec.isMale == true or value == "male" or value == "man" then
        return "male"
    end
    return "neutral"
end

local function contextCandidates(spec)
    local relationship = lower(
        spec.relationshipKind or spec.relationship or spec.relationshipState
    )
    local tone = lower(spec.tone or spec.beatTone or spec.speechStyle)
    local persona = lower(spec.persona or spec.personaStyle)
    local familiarity = tonumber(spec.familiarity)
    local sex = gender(spec)
    local formal = tone == "formal" or tone == "guarded"
        or persona == "formal"
    local hostile = tone == "hostile" or relationship == "hostile"
    local friendly = relationship == "friend" or relationship == "companion"
        or relationship == "colonist" or relationship == "family"
        or relationship == "lover" or relationship == "partner"
        or relationship == "spouse" or (familiarity and familiarity >= 30)
    local slang = persona == "slang" or persona == "casual"
        or tone == "casual" or tone == "friendly"
    if hostile or not friendly and formal then
        if sex == "female" and formal then return { "miss", "stranger" } end
        if sex == "male" and formal then return { "mister", "stranger" } end
        return { "stranger", "mate" }
    end
    if friendly and slang and sex == "male" then
        return { "bro", "mate", "pal" }
    end
    if friendly then
        return { "mate", "pal", "stranger" }
    end
    if formal and sex == "female" then return { "miss", "stranger" } end
    if formal and sex == "male" then return { "mister", "stranger" } end
    return { "stranger", "mate", "pal" }
end

function Resolver.IsPlaceholder(value)
    return PLACEHOLDERS[lower(value)] == true
end

function Resolver.Remember(history, resolved)
    if type(history) ~= "table" or type(resolved) ~= "table"
        or resolved.known == true or not resolved.id
    then
        return history
    end
    history[#history + 1] = resolved.id
    while #history > Resolver.MAX_RECENT do
        table.remove(history, 1)
    end
    return history
end

function Resolver.Resolve(spec)
    spec = type(spec) == "table" and spec or {}
    local name = identityName(spec)
    if identityKnown(spec, name) then
        return {
            known = true,
            kind = "name",
            id = "known_name",
            address = name,
            name = name,
            language = clean(spec.language, 16) or "en",
            repeated = false,
        }
    end

    local candidates = contextCandidates(spec)
    -- Candidate order is a style decision, not a random pool. Recent history
    -- advances only within the already-constrained family when repetition is
    -- undesirable.
    local offset = 1
    local selected
    local selectedIndex
    for step = 0, #candidates - 1 do
        local index = ((offset + step - 1) % #candidates) + 1
        local candidate = candidates[index]
        if not recentContains(spec.recentAddresses, candidate) then
            selected = candidate
            selectedIndex = index
            break
        end
    end
    selected = selected or candidates[offset]
    selectedIndex = selectedIndex or offset
    local term = TERMS[selected] or TERMS.stranger
    return {
        known = false,
        kind = "term",
        id = term.id,
        address = translated(term, spec.language),
        name = nil,
        language = clean(spec.language, 16) or "en",
        repeated = recentContains(spec.recentAddresses, term.id),
        candidateIndex = selectedIndex,
    }
end

function Resolver.Apply(context, spec)
    context = type(context) == "table" and context or {}
    local resolved = Resolver.Resolve(spec)
    context.semanticAddress = resolved.address
    context.address = resolved.address
    context.addressID = resolved.id
    context.addressKind = resolved.kind
    context.identityKnown = resolved.known
    return context, resolved
end

-- The identity projection below is the same bounded addressing authority used
-- by conversation, speech, PBrainZ, and radio context. It preserves the
-- existing name-knowledge gate while keeping identity facts separate from the
-- semantic term resolver above.
local NAME_NICKNAMES = {
    female = {
        { id = "babe", key = "UI_PNC_SemanticAddressing_Female_Babe", fallback = "Babe" },
        { id = "darling", key = "UI_PNC_SemanticAddressing_Female_Darling", fallback = "Darling" },
        { id = "sweetheart", key = "UI_PNC_SemanticAddressing_Female_Sweetheart", fallback = "Sweetheart" },
        { id = "stranger", key = "UI_PNC_SemanticAddressing_Female_Stranger", fallback = "Stranger" },
    },
    default = {
        { id = "buddy", key = "UI_PNC_SemanticAddressing_Default_Buddy", fallback = "Buddy" },
        { id = "friend", key = "UI_PNC_SemanticAddressing_Default_Friend", fallback = "Friend" },
        { id = "stranger", key = "UI_PNC_SemanticAddressing_Default_Stranger", fallback = "Stranger" },
        { id = "pal", key = "UI_PNC_SemanticAddressing_Default_Pal", fallback = "Pal" },
    },
}

local function call(object, method)
    local objectType = type(object)
    if (objectType ~= "table" and objectType ~= "userdata")
        or type(object[method]) ~= "function"
    then
        return nil
    end
    local ok, value = pcall(object[method], object)
    return ok and value or nil
end

local function firstNonEmpty(...)
    for index = 1, select("#", ...) do
        local value = clean(select(index, ...), 96)
        if value then return value end
    end
    return nil
end

local function knownFromMap(map, npcID, playerUUID)
    if type(map) ~= "table" then return nil end
    npcID = clean(npcID, 96)
    playerUUID = clean(playerUUID, 96)
    if not npcID then return nil end
    local direct = map[npcID]
    if type(direct) == "boolean" then return direct end
    if type(direct) == "table" and playerUUID
        and type(direct[playerUUID]) == "boolean"
    then
        return direct[playerUUID]
    end
    if playerUUID and type(map[playerUUID]) == "table"
        and type(map[playerUUID][npcID]) == "boolean"
    then
        return map[playerUUID][npcID]
    end
    return nil
end

function Resolver.ResolveNPCSeed(source, fallback)
    source = type(source) == "table" and source or {}
    local candidates = {
        source,
        type(source.snapshot) == "table" and source.snapshot or nil,
        type(source.record) == "table" and source.record or nil,
    }
    for index = 1, #candidates do
        local value = candidates[index]
        local identity = value and value.identity or nil
        local seed = value and (value.identitySeed or value.npcIdentitySeed) or nil
        seed = seed or identity and (identity.identitySeed or identity.seed) or nil
        if seed ~= nil then
            return PNC.Identity.NormalizeSeed(seed, fallback or "npc")
        end
    end
    return PNC.Identity.NormalizeSeed(nil, fallback or "npc")
end

function Resolver.ResolvePlayerIsFemale(player, explicit)
    if type(explicit) == "boolean" then return explicit end
    local value = player and call(player, "isFemale") or nil
    if type(value) == "boolean" then return value end
    local descriptor = player and call(player, "getDescriptor") or nil
    value = descriptor and call(descriptor, "isFemale") or nil
    if type(value) == "boolean" then return value end
    return false
end

function Resolver.IsPlayerNameKnown(npcID, playerUUID, state)
    state = type(state) == "table" and state
        or PNC.Network and PNC.Network.ClientState or {}
    local maps = {
        state.playerNameKnowledge,
        state.npcPlayerKnowledge,
        state.playerIdentityKnowledge,
    }
    for index = 1, #maps do
        local value = knownFromMap(maps[index], npcID, playerUUID)
        if value ~= nil then return value end
    end
    return false
end

local function readKnownName(options)
    options = type(options) == "table" and options or {}
    local player = options.player
    local context = type(options.playerContext) == "table"
        and options.playerContext or {}
    local authoritative = type(options.authoritative) == "table"
        and options.authoritative or {}
    local descriptor = player and call(player, "getDescriptor") or nil
    local firstName = firstNonEmpty(
        authoritative.firstName, authoritative.forename,
        options.playerFirstName, options.playerForename,
        context.firstName, context.forename,
        descriptor and call(descriptor, "getForename"),
        player and call(player, "getForename")
    )
    local lastName = firstNonEmpty(
        authoritative.lastName, authoritative.surname,
        options.playerLastName, options.playerSurname,
        context.lastName, context.surname,
        descriptor and call(descriptor, "getSurname"),
        player and call(player, "getSurname")
    )
    local fullName = firstNonEmpty(
        authoritative.fullName, authoritative.displayName,
        options.playerFullName,
        context.fullName, context.displayName,
        player and call(player, "getDisplayName"),
        player and call(player, "getFullName"),
        player and call(player, "getUsername")
    )
    if not fullName and (firstName or lastName) then
        fullName = clean((firstName or "") .. " " .. (lastName or ""), 96)
    end
    if not firstName and fullName then firstName = string.match(fullName, "^(%S+)") end
    if not lastName and fullName then lastName = string.match(fullName, "^%S+%s+(.+)$") end
    return fullName, firstName, lastName
end

function Resolver.ResolveForNPC(options)
    options = type(options) == "table" and options or {}
    local playerUUID = clean(options.playerUUID, 96)
    local npcID = clean(options.npcID, 96) or "unknown-npc"
    local isFemale = Resolver.ResolvePlayerIsFemale(options.player, options.isFemale)
    local seed = PNC.Identity.NormalizeSeed(options.npcIdentitySeed, npcID)
    local nicknameSeed = playerUUID and PNC.Identity.HashText(playerUUID, seed) or seed
    local pool = isFemale and NAME_NICKNAMES.female or NAME_NICKNAMES.default
    local nickname = pool[PNC.Identity.Index(
        nicknameSeed, "semantic-addressing:v" .. tostring(Resolver.VERSION), #pool
    )] or pool[1]
    local nicknameText = nickname and translated(nickname, options.language) or "Stranger"
    local known = options.playerNameKnown
    if type(known) ~= "boolean" then
        known = Resolver.IsPlayerNameKnown(npcID, playerUUID, options.state)
    end
    if known then
        local fullName, firstName, lastName = readKnownName(options)
        known = fullName ~= nil or firstName ~= nil
        if known then
            return {
                known = true,
                isFemale = isFemale,
                addressName = firstName or fullName or nicknameText,
                firstName = firstName or fullName or nicknameText,
                fullName = fullName or firstName or nicknameText,
                surname = lastName or "",
                lastName = lastName or "",
                nicknameID = nil,
            }
        end
    end
    return {
        known = false,
        isFemale = isFemale,
        addressName = nicknameText,
        firstName = nicknameText,
        fullName = nicknameText,
        surname = "",
        lastName = "",
        nicknameID = nickname and nickname.id or "stranger",
    }
end

function Resolver.ResolvePlayer(options)
    options = type(options) == "table" and options or {}
    local resolved = {}
    for key, value in pairs(options) do resolved[key] = value end
    resolved.playerNameKnown = options.playerNameKnown == true
    return Resolver.ResolveForNPC(resolved)
end

function Resolver.ApplyPlayer(context, options)
    context = type(context) == "table" and context or {}
    local address = Resolver.ResolveForNPC(options)
    context.player = address.addressName
    context.playerName = address.addressName
    context.playerAddressName = address.addressName
    context.playerFullName = address.fullName
    context.playerFirstName = address.firstName
    context.playerSurname = address.surname
    context.playerLastName = address.lastName
    context.playerNameKnown = address.known
    context.playerIsFemale = address.isFemale
    context.playerNicknameID = address.nicknameID
    return context, address
end

return Resolver
