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

local Memory = PNC.Conversation
    and PNC.Conversation.Memory or nil
if type(Memory) ~= "table" then
    Memory = require "PNC/Conversation/Memory/PNC_ConversationMemory"
end

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

Facts.RegisterProvider("npc_backstory", {
    priority = 220,
    subjects = { NPC_BACKSTORY = true },
    Resolve = function(ir, state, context)
        local record = context and context.npcRecord
        local kind = requestedKind(ir)
        local fact
        local content
        if type(record) ~= "table" then
            return {
                status = "unknown",
                reason = "authoritative_npc_record_unavailable",
            }
        end
        if not kind then
            return {
                status = "ambiguous",
                reason = "backstory_kind_required",
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
