-- Knowledge-disclosure response realization and receipt handling.

local Conversation = PNC.Conversation
local Internal = Conversation.DefinitionLifecycleInternal
local GIFT_PREFERENCE_RESPONSES = {
    like = {
        key = "semantic.gift.preference.like",
        text = "I like that.",
    },
    dislike = {
        key = "semantic.gift.preference.dislike",
        text = "I don't like that.",
    },
    neutral = {
        key = "semantic.gift.preference.neutral",
        text = "I don't have a strong preference.",
    },
    unknown = {
        key = "semantic.gift.preference.unknown",
        text = "I'm not sure which item you mean.",
    },
}

local function localizedBackstoryContent(result, kind)
    local registry = PNC.Registry
    local memory = PNC.Conversation and PNC.Conversation.Memory or nil
    local record = registry and type(registry.Get) == "function"
        and registry.Get(result.npcID) or nil
    if type(record) ~= "table" or type(memory) ~= "table"
        or type(memory.GetBackstory) ~= "function"
        or type(memory.GetBackstoryText) ~= "function"
    then
        return nil
    end
    local fact = memory.GetBackstory(record, kind)
    if type(fact) ~= "table" then return nil end
    local language = "EN"
    if Translator and type(Translator.getLanguage) == "function" then
        local languageValue = Translator.getLanguage()
        if languageValue and type(languageValue.toString) == "function" then
            language = tostring(languageValue:toString())
        end
    end
    local content = memory.GetBackstoryText(fact, language) or fact.value
    if type(memory.RenderText) == "function" then
        content = memory.RenderText(content, fact)
    end
    return type(content) == "string" and content ~= "" and content or nil
end

local function disclosureResponsePayload(result)
    local topicID = tostring(result and result.topicID or "")
    if string.sub(topicID, 1, 10) ~= "backstory." then return nil end
    local input = PNC.Semantics and PNC.Semantics.DialogueInput
    local inputInternal = input and input.Internal or nil
    local responsePayload = inputInternal
        and inputInternal.ResponsePayload or nil
    local catalog = PNC.Semantics and PNC.Semantics.ResponseCatalog or nil
    if type(responsePayload) ~= "function"
        or type(catalog) ~= "table"
        or type(catalog.Select) ~= "function"
    then
        return nil
    end
    local kind = string.sub(topicID, 11)
    local poolID
    if result.success == true then
        if type(result.responsePoolID) == "string"
            and result.responsePoolID ~= ""
        then
            poolID = result.responsePoolID
        else
            poolID = "semantic.question.backstory.known." .. kind
        end
    else
        poolID = "semantic.question.backstory.refusal"
    end
    local variant = catalog.Select(poolID, {
        npcID = result.npcID,
        topic = "NPC_BACKSTORY",
        subject = "NPC_BACKSTORY",
    }, result.requestID)
    if type(variant) ~= "table"
        and result.success == true
        and poolID ~= "semantic.question.backstory.known." .. kind
    then
        poolID = "semantic.question.backstory.known." .. kind
        variant = catalog.Select(poolID, {
            npcID = result.npcID,
            topic = "NPC_BACKSTORY",
            subject = "NPC_BACKSTORY",
        }, result.requestID)
    end
    if type(variant) ~= "table" then return nil end
    local content = result.success == true
        and localizedBackstoryContent(result, kind) or result.responseText
    local response = {
        templateID = variant.templateID,
        fallback = variant.fallback,
        args = result.success == true and {
            kind = kind,
            content = content,
        } or {},
        dialogueAct = variant.dialogueAct or "FACT_ANSWER",
        topic = "NPC_BACKSTORY",
        uncertainty = result.success == true and "known" or "refused",
        tone = result.success == true and "direct" or "guarded",
        groundedFactRefs = { "backstory." .. kind },
    }
    return responsePayload({ response = response })
end

function Conversation.ReceiveDisclosureResult(result)
    local view = PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.instance or nil
    local preference = result and result.giftPreference or nil
    local reaction = preference and GIFT_PREFERENCE_RESPONSES[
        tostring(preference.disposition or "")
    ] or nil
    local function recordBackstoryResponse(text)
        local topicID = tostring(result and result.topicID or "")
        local session = view and view.session or nil
        local context = session and session.semanticDialogueContext or nil
        if string.sub(topicID, 1, 10) ~= "backstory."
            or type(text) ~= "string" or text == ""
            or not context or type(context.RecordNPCResponse) ~= "function"
        then return end
        context:RecordNPCResponse({
            intent = "RESPONSE",
            speechAct = "ANSWER",
            subject = "NPC_BACKSTORY",
            rawText = text,
            extensions = { topic = topicID },
        }, {
            speaker = "npc",
            source = "knowledge_disclosure",
            branch = "QUESTION_RECEIVED",
            topic = topicID,
        })
    end
    if not view or not result
        or tostring(result.npcID) ~= tostring(view.spec and view.spec.npcID)
    then return false end
    local translatedPayload = disclosureResponsePayload(result)
    if translatedPayload
        and view.session and view.session.append
    then
        local responseText = translatedPayload.text
            or translatedPayload.fallback
            or result.responseText
        view.session:append("npc", translatedPayload)
        recordBackstoryResponse(responseText)
    elseif result.responseText
        and view.session and view.session.append
    then
        local responseText = tostring(result.responseText)
        view.session:append("npc", { fallback = responseText })
        recordBackstoryResponse(responseText)
    elseif result.success == true and reaction
        and view.session and view.session.append
    then
        view.session:append("npc", {
            key = reaction.key,
            domain = "pnc.system.shared.categories",
            text = reaction.text,
            fallback = reaction.text,
        })
    elseif result.success ~= true
        and tostring(result.topicID or "") == "gift_preferences"
        and (result.reason == "preference_item_required"
            or result.reason == "invalid_gift_item_type"
            or result.reason == "gift_preference_unavailable"
            or result.reason == "marketsense_unavailable")
        and view.session and view.session.append
    then
        local unknown = GIFT_PREFERENCE_RESPONSES.unknown
        view.session:append("npc", {
            key = unknown.key,
            domain = "pnc.system.shared.categories",
            text = unknown.text,
            fallback = unknown.text,
        })
    end
    return Internal.RefreshForNPC(result.npcID)
end
