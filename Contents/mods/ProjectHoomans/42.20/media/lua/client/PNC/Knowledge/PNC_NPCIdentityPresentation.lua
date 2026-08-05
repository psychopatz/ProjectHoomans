-- The only client-side presentation gateway for NPC identity. Gameplay UI
-- must never read snapshot.name/displayName directly: those fields exist for
-- transport and diagnostics, while this module enforces what the player has
-- actually learned.

PNC = PNC or {}
PNC.NPCIdentityPresentation = PNC.NPCIdentityPresentation or {}

local Identity = PNC.NPCIdentityPresentation
local function clientState()
    return PNC.Network and PNC.Network.ClientState or nil
end

Identity.UnknownName = "Unknown survivor"
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
    if type(npc) ~= "table" then return npc end
    return npc.snapshot or npc.record or npc.source or npc
end

local function isPlayerCompanion(npc)
    local source = sourceFor(npc)
    return type(source) == "table" and (
        source.recruited == true
        or source.colonist == true
        or source.characterWindow and source.characterWindow.ownerUsername ~= nil
    )
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

function Identity.IsNameKnown(npc)
    if not clientState() then return true end
    return isPlayerCompanion(npc)
        or Identity.GetFact(npc, "identity.name") ~= nil
end

function Identity.GetName(npc)
    local fact = Identity.GetFact(npc, "identity.name")
    if fact then return tostring(fact.value or Identity.UnknownName) end
    if Identity.IsNameKnown(npc) then return Identity.GetDebugName(npc) end
    return not clientState() and Identity.GetDebugName(npc) or Identity.UnknownName
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
    if knowledge and knowledge.knownFaction then return knowledge.knownFaction end
    if type(npc) == "table" then
        local source = sourceFor(npc)
        if type(source) == "table" then
            if source.knownFaction then return source.knownFaction end
            if source.organizationalFaction and (Identity.IsNameKnown(npc) or not clientState()) then
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
        or "Talk to stranger"
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
        return tostring(source.displayName or source.name
            or fallback or Identity.UnknownName)
    end
    local id = normalizeID(npc)
    local state = clientState()
    local snapshot = id and state and state.snapshots and state.snapshots[id] or nil
    return tostring(snapshot and (snapshot.displayName or snapshot.name) or fallback or Identity.UnknownName)
end

return Identity
