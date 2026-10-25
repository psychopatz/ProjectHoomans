-- Semantic conversational address selection.
--
-- This module never creates or mutates identity facts. It only projects an
-- authoritative identity/relationship context into a bounded player-facing
-- address. Transport/debug placeholders are rejected before they can reach
-- dialogue text.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

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

return Resolver
