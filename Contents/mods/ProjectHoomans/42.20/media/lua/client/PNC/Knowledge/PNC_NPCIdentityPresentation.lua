-- The only client-side presentation gateway for NPC identity. Gameplay UI
-- owns the client-side presentation of the canonical displayName transport
-- field while enforcing what the player has actually learned.

PNC = PNC or {}
PNC.NPCIdentityPresentation = PNC.NPCIdentityPresentation or {}

local Identity = PNC.NPCIdentityPresentation
local ActorNames = require "PsychopatzCore/Actors/PsychopatzActorNames"
local function clientState()
    return PNC.Network and PNC.Network.ClientState or nil
end

-- `Unknown survivor` remains a server transport placeholder.  It must never
-- be presented as if the player learned it; the GUI label for an unknown NPC
-- is always the localized Stranger label.
Identity.UnknownName = "Stranger"
Identity.UnknownTransportName = "Unknown survivor"
Identity.UnknownArchetype = "Unknown background"
Identity.UnknownFaction = "Unknown"

local function normalizeID(value)
    if type(value) == "table" then
        value = value.id or value.npcID
            or value.snapshot and (value.snapshot.id or value.snapshot.npcID)
            or value.record and (value.record.id or value.record.npcID)
            or value.source and (value.source.id or value.source.npcID)
    end
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function sourceFor(npc)
    if type(npc) ~= "table" then
        local state = clientState()
        local id = normalizeID(npc)
        return id and state and state.snapshots
            and state.snapshots[id] or npc
    end
    return npc.snapshot or npc.record or npc.source or npc
end

local function isPlayerCompanion(npc)
    local source = sourceFor(npc)
    local verifier = PNC.Identity
        and PNC.Identity.Verifier or nil
    if type(source) ~= "table" then return false end
    if verifier and verifier.IsColonyOwnedNPC then
        return verifier.IsColonyOwnedNPC(source)
    end
    return source.recruited == true
        or source.colonyOwned == true
        or source.characterWindow
            and source.characterWindow.ownerUsername ~= nil
end

function Identity.GetKnowledge(npc)
    local id = normalizeID(npc)
    local state = clientState()
    return id and state and state.npcKnowledge and state.npcKnowledge[id] or nil
end

function Identity.GetFact(npc, descriptorID)
    local knowledge = Identity.GetKnowledge(npc)
    for _, category in ipairs(knowledge and knowledge.categories or {}) do
        for _, descriptor in ipairs(category.descriptors or {}) do
            if tostring(descriptor.descriptorID) == tostring(descriptorID)
                and descriptor.status ~= nil
            then return descriptor end
        end
    end
    return nil
end

local function factValue(npc, descriptorID)
    local fact = Identity.GetFact(npc, descriptorID)
    local value = fact and fact.value or nil
    if value == nil then return nil end
    value = tostring(value)
    if value == "" or Identity.IsPlaceholderName(value) then return nil end
    return value
end

local function clean(value)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value ~= "" and value or nil
end

local function splitName(value)
    return ActorNames.Split(value)
end

local function appendNickname(fullName, nickname)
    return ActorNames.FormatDisplayName(fullName, nickname)
end

function Identity.GetIdentityParts(npc)
    local fullName = factValue(npc, "identity.name")
        or factValue(npc, "identity.full_name")
    local nickname = factValue(npc, "identity.nickname")
    local firstName = factValue(npc, "identity.forename")
    local surname = factValue(npc, "identity.surname")
    local state = clientState()
    local rawAllowed = not state or isPlayerCompanion(npc)
    local source = rawAllowed and sourceFor(npc) or nil
    local identity = type(source) == "table" and source.identity or source
    local survivor = type(identity) == "table"
        and type(identity.survivor) == "table" and identity.survivor or {}

    if rawAllowed then
        fullName = fullName or clean(identity and identity.displayName
            or source and (source.displayName or source.name))
        firstName = firstName or clean(survivor.forename
            or survivor.firstName or source and source.forename)
        surname = surname or clean(survivor.surname
            or survivor.lastName or source and source.surname)
        nickname = nickname or clean(identity and (identity.nickname
            or identity.alias))
    end

    if fullName and (not firstName or not surname) then
        local parsedFirst, parsedSurname = splitName(fullName)
        firstName = firstName or parsedFirst
        surname = surname or parsedSurname
    end
    if not fullName and firstName and surname then
        fullName = firstName .. " " .. surname
    end

    local displayName = appendNickname(fullName, nickname)
        or nickname or firstName or surname or Identity.UnknownName
    local level = "unknown"
    if fullName then
        level = "full_name"
    elseif nickname then
        level = "nickname"
    elseif firstName or surname then
        level = "name_part"
    end
    return {
        displayName = displayName,
        fullName = fullName,
        firstName = firstName,
        surname = surname,
        lastName = surname,
        nickname = nickname,
        level = level,
    }
end

function Identity.GetIdentityLevel(npc)
    return Identity.GetIdentityParts(npc).level
end

function Identity.IsNameKnown(npc)
    return Identity.GetIdentityLevel(npc) ~= "unknown"
end

-- Presentation placeholders are transport values, not names the player learned.
-- The server's own projection uses the same literal (`PresentationFor` sets
-- `displayName = "Unknown survivor"` while the name is unknown), so every
-- consumer that decides whether to *display* a name must reject them.
local placeholderNames

local function buildPlaceholderNames()
    local values = {
        Identity.UnknownName,
        Identity.UnknownTransportName,
        Identity.UnknownArchetype,
        Identity.UnknownFaction,
        "STRANGER",
        "UNKNOWN",
    }
    local output = {}
    for index = 1, #values do
        local value = values[index]
        if type(value) == "string" and value ~= "" then
            output[string.upper(value)] = true
        end
    end
    return output
end

function Identity.IsPlaceholderName(value)
    if type(value) ~= "string" or value == "" then return false end
    placeholderNames = placeholderNames or buildPlaceholderNames()
    return placeholderNames[string.upper(value)] == true
end

function Identity.GetName(npc)
    return Identity.GetIdentityParts(npc).displayName
end

-- A descriptor can exist without a usable value (a snapshot whose truth failed
-- to resolve, or a value that did not survive transport). Callers that decide
-- whether to *display* a name must treat that as still-unknown: `GetName`
-- deliberately returns the placeholder, and rendering it as a learned name
-- produces a plate that reads "Unknown survivor" as if the player had been told.
function Identity.GetKnownName(npc)
    local parts = Identity.GetIdentityParts(npc)
    return parts.level ~= "unknown" and parts.displayName or nil
end

function Identity.GetFullName(npc)
    return Identity.GetIdentityParts(npc).fullName
end

function Identity.GetNickname(npc)
    return Identity.GetIdentityParts(npc).nickname
end

function Identity.GetArchetype(npc)
    local fact = Identity.GetFact(npc, "identity.archetype")
    if fact then return tostring(fact.value or Identity.UnknownArchetype) end
    if not clientState() and type(npc) == "table" then
        local source = sourceFor(npc)
        return tostring(source.archetypeLabel or Identity.UnknownArchetype)
    end
    return Identity.UnknownArchetype
end

function Identity.GetFaction(npc)
    local knowledge = Identity.GetKnowledge(npc)
    if knowledge and knowledge.knownFaction
        and (Identity.GetFact(npc, "faction.identity") ~= nil or not clientState())
    then
        return knowledge.knownFaction
    end
    if type(npc) == "table" then
        local source = sourceFor(npc)
        if type(source) == "table" then
            if source.knownFaction
                and (Identity.GetFact(npc, "faction.identity") ~= nil or not clientState())
            then
                return source.knownFaction
            end
            if source.organizationalFaction
                and (Identity.GetFact(npc, "faction.identity") ~= nil
                    or not clientState())
            then
                return source.organizationalFaction
            end
        end
    end
    return nil
end

function Identity.GetFactionName(npc)
    local faction = Identity.GetFaction(npc)
    return faction and tostring(faction.name or Identity.UnknownFaction)
        or Identity.UnknownFaction
end

function Identity.GetContextLabel(npc)
    return Identity.IsNameKnown(npc) and Identity.GetName(npc)
        or PNC.Translation.GetKey("UI_PNC_Character_TalkToStranger",
            "Talk to stranger")
end

-- Dialogue may explicitly reveal identity before the following knowledge
-- snapshot arrives. Keep that one intentional reveal behind this API too.
function Identity.GetDisclosureName(npc)
    return Identity.GetDebugName(npc, "a survivor")
end

function Identity.GetDisclosureFaction(npc)
    local source = sourceFor(npc)
    return type(source) == "table" and (
        source.organizationalFaction or source.knownFaction
    ) or nil
end

-- Explicitly opt into raw diagnostic data; ordinary UI must use GetName.
function Identity.GetDebugName(npc, fallback)
    local source = sourceFor(npc)
    if type(source) == "table" then
        return tostring(source.displayName or fallback or Identity.UnknownName)
    end
    local id = normalizeID(npc)
    local state = clientState()
    local snapshot = id and state and state.snapshots and state.snapshots[id] or nil
    return tostring(snapshot and snapshot.displayName or fallback or Identity.UnknownName)
end

return Identity
