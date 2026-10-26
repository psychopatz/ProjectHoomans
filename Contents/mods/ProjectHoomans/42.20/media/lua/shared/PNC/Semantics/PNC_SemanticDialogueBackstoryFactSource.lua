-- Authoritative offline fact provider for immutable NPC backstory.
--
-- This source is loaded by the server composition after Conversation Memory
-- exists. It reads the existing identity-seeded definitions and returns one
-- bounded fact at a time; it never exposes a complete profile or mutable
-- gameplay state.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Facts = PNC.Semantics.DialogueFacts
if type(Facts) ~= "table" then
    Facts = require "PNC/Semantics/PNC_SemanticDialogueFacts"
end

local Memory = require
    "PNC/Semantics/PNC_SemanticConversationMemoryProvider"

local function topicValue(value)
    if type(value) == "table" then
        value = value.kind or value.id or value.key
            or value.value or value.text
    end
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "[^%w]+", "_")
    value = string.gsub(value, "^_+", "")
    value = string.gsub(value, "_+$", "")
    return value ~= "" and value or nil
end

local KIND_ALIASES = {
    job = "former_job",
    jobs = "former_job",
    occupation = "former_job",
    profession = "former_job",
    hometown = "hometown",
    home_town = "hometown",
    education = "education",
    hobby = "hobby",
    hobbies = "hobby",
    family = "family_background",
    family_background = "family_background",
    value = "value",
    values = "value",
    fear = "fear",
    fears = "fear",
    tragedy = "tragedy",
    event = "tragedy",
    personal_event = "tragedy",
    survival = "survival_origin",
    survival_origin = "survival_origin",
    birthday = "date_of_birth",
    date_of_birth = "date_of_birth",
}

local function requestedKind(ir)
    local slots = ir and ir.slots or nil
    local value = slots and (
        slots.backstoryKind or slots.backstory_kind or slots.kind
            or slots.topic
    ) or nil
    if value == nil and ir then
        value = ir.backstoryKind or ir.backstory_kind
    end
    value = topicValue(value)
    return value and (KIND_ALIASES[value] or value) or nil
end

local function languageOf(context)
    local value = context and (
        context.language or context.translationLanguage
            or context.locale
    ) or nil
    value = string.upper(tostring(value or "EN"))
    return value == "TL" and "TL" or "EN"
end

local function renderFact(fact, language)
    local content
    local birth
    if fact.kind == "date_of_birth" then
        birth = string.format(
            "%04d-%02d-%02d",
            tonumber(fact.year) or 0,
            tonumber(fact.month) or 0,
            tonumber(fact.day) or 0
        )
        return birth
    end
    if type(Memory.GetBackstoryText) == "function" then
        content = Memory.GetBackstoryText(fact, language)
    end
    if content == nil then
        content = fact.value
    end
    if type(Memory.RenderText) == "function" then
        content = Memory.RenderText(content, fact)
    end
    return type(content) == "string" and content ~= "" and content or nil
end

local function authorizedDescriptor(snapshot, kind)
    local categories = snapshot and snapshot.categories
    local descriptorID = "history.backstory." .. tostring(kind or "")
    if type(categories) ~= "table" then return nil end
    for _, category in ipairs(categories) do
        for _, descriptor in ipairs(category.descriptors or {}) do
            local presentation = descriptor.presentation or {}
            if presentation.backstoryKind == kind
                or descriptor.descriptorID == descriptorID
            then
                return descriptor
            end
        end
    end
    return nil
end

local function authorizedRecord(context)
    local record = context and context.npcRecord or nil
    if type(record) == "table" then return record end
    -- The live registry is the existing authoritative record boundary.  A
    -- record is consulted only after the player-scoped snapshot has already
    -- passed the known/confirmed gate below; it is never used to enumerate
    -- undisclosed generated backstory.
    local registry = PNC.Registry
    local npcID = context and context.npcID or nil
    if type(registry) == "table" and type(registry.Get) == "function"
        and npcID ~= nil
    then
        local resolved = registry.Get(npcID)
        if type(resolved) == "table" then return resolved end
    end
    return nil
end

local function disclosureAllowed(context, kind)
    local knowledge = PNC.NPCKnowledge
    local record = context and context.npcRecord or nil
    local npcID = context and context.npcID or record and record.id
    local characterUUID = context and context.characterUUID
    if type(knowledge) ~= "table"
        or type(knowledge.CanDisclose) ~= "function"
        or characterUUID == nil or npcID == nil
    then
        return true, nil
    end
    return knowledge.CanDisclose(
        characterUUID,
        npcID,
        "history.backstory." .. tostring(kind or ""),
        {
            topicID = "backstory." .. tostring(kind or ""),
            sourceType = "direct_disclosure",
        }
    )
end

local function projectedFact(ir, context, kind)
    local snapshot = context and (
        context.npcKnowledge or context.knowledgeSnapshot
    ) or nil
    local descriptor = authorizedDescriptor(snapshot, kind)
    local status = descriptor and tostring(descriptor.status or "") or ""
    if not descriptor or (status ~= "known" and status ~= "confirmed"
        and status ~= "suspected")
    then
        return nil
    end
    local content = descriptor.content
    -- A suspected descriptor is the player's observation, not permission to
    -- replace it with canonical NPC truth. Canonical rendering is allowed
    -- only after the authoritative Knowledge service has confirmed the fact.
    local record = authorizedRecord(context)
    local fact = status ~= "suspected" and record and Memory.GetBackstory
        and Memory.GetBackstory(record, kind) or nil
    if fact then content = renderFact(fact, languageOf(context)) end
    content = content or descriptor.value
    if type(content) ~= "string" or content == "" then return nil end
    return {
        status = status == "suspected" and "suspected" or "known",
        kind = kind,
        factID = descriptor.descriptorID,
        value = descriptor.value,
        content = content,
        immutable = true,
        provenance = "PNC.NPCKnowledge.player_snapshot",
        confidence = descriptor.confidence,
    }
end

Facts.RegisterProvider("npc_backstory", {
    priority = 220,
    subjects = { NPC_BACKSTORY = true },
    Resolve = function(ir, state, context)
        local record = context and context.npcRecord
        local kind = requestedKind(ir)
        local fact
        local content
        if not kind then
            return {
                status = "ambiguous",
                reason = "backstory_kind_required",
            }
        end
        fact = projectedFact(ir, context, kind)
        if fact then return fact end
        -- Only the server-authoritative harness and the server disclosure
        -- boundary may ask for raw generated truth. Normal dialogue and
        -- optional PBrainZ contexts must use the player-specific snapshot.
        if not (context and context.authoritativeBackstoryAccess == true) then
            return {
                status = "unknown",
                kind = kind,
                topicID = "backstory." .. kind,
                reason = "backstory_not_disclosed",
            }
        end
        local disclosureOK, disclosureReason = disclosureAllowed(context, kind)
        if disclosureOK ~= true then
            return {
                status = "unknown",
                kind = kind,
                topicID = "backstory." .. kind,
                reason = disclosureReason or "backstory_disclosure_denied",
            }
        end
        if type(record) ~= "table" then
            return {
                status = "unknown",
                kind = kind,
                reason = "authoritative_npc_record_unavailable",
            }
        end
        if type(Memory.GetBackstory) ~= "function" then
            return {
                status = "unknown",
                reason = "backstory_memory_unavailable",
            }
        end
        fact = Memory.GetBackstory(record, kind)
        if not fact then
            return {
                status = "unknown",
                kind = kind,
                reason = "backstory_fact_unavailable",
            }
        end
        content = renderFact(fact, languageOf(context))
        if not content then
            return {
                status = "unknown",
                kind = kind,
                factID = fact.id,
                reason = "backstory_text_unavailable",
            }
        end
        return {
            status = "known",
            kind = kind,
            factID = fact.id,
            value = fact.value,
            content = content,
            immutable = true,
            provenance = "PNC.Conversation.Memory.BackstoryDefinitions",
            confidence = 0.95,
        }
    end,
})

return Facts
