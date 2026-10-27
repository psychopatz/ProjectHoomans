-- Render semantic responses into queue-ready presentation payloads.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input
local Internal = Input.Internal or {}
Input.Internal = Internal

require "PNC/Semantics/PNC_SemanticDialogueInput_Presentation_Responses_Translation"
local ResponsePlan = require
    "PNC/Semantics/PNC_SemanticDialogueResponsePlan"
local SpeechRealization = require
    "PNC/Semantics/PNC_SpeechRealization"
local ResponseAdapter = Internal.ResponseAdapter or {}
Internal.ResponseAdapter = ResponseAdapter

local function argumentValues(args)
    args = type(args) == "table" and args or {}
    local values = {}
    local order = {
        "playerName", "npcName", "familyAddress", "familyTerm",
        "target", "location", "content", "topic", "activity",
        "time", "month", "day", "year", "temperature", "gameDay",
        "object", "value",
    }
    for _, key in ipairs(order) do
        local value = args[key]
        if value ~= nil and type(value) ~= "table" then
            values[#values + 1] = value
            if #values >= 4 then break end
        end
    end
    return values
end

local function localizedSegment(templateID, fallback, args)
    local response = {
        templateID = templateID,
        fallback = fallback,
        args = args,
    }
    fallback = tostring(fallback or "")
    local key = Internal.SemanticTranslationKey(response)
    local translation = PNC.Translation
    if not key or not translation
        or type(translation.TrFormat) ~= "function"
    then
        return fallback, key
    end
    args = type(args) == "table" and args or {}
    local values = argumentValues(args)
    local ok, value = pcall(
        translation.TrFormat,
        key,
        fallback,
        values[1], values[2], values[3], values[4]
    )
    if ok and value ~= nil and tostring(value) ~= "" then
        return tostring(value), key
    end
    return fallback, key
end

local function fallbackSegment(templateID, fallback, args)
    local values = argumentValues(args)
    local text = tostring(fallback or "")
    text = string.gsub(text, "%%([1-9][0-9]*)", function(number)
        local value = values[tonumber(number)]
        return value ~= nil and tostring(value) or "%%" .. number
    end)
    local ok, formatted = pcall(
        string.format, text, values[1], values[2], values[3], values[4]
    )
    return ok and formatted or text, nil
end

local function payloadForPlanTurn(response, rendered, fallbackRendered)
    local firstSegment = rendered.segments[1] or {}
    -- Keep the rendered key for existing presentation consumers.  The
    -- canonical semantic segment identity travels separately so lifecycle
    -- and review diagnostics do not have to infer it from a phrase key.
    local semanticKey = firstSegment.semanticTemplateID
    if not semanticKey and type(response.plan) == "table"
        and type(response.plan.turns) == "table"
    then
        local canonicalTurn = response.plan.turns[rendered.index] or {}
        local canonicalSegment = canonicalTurn.segments
            and canonicalTurn.segments[1]
        semanticKey = type(canonicalSegment) == "table"
            and canonicalSegment.templateID or nil
    end
    local key = firstSegment.templateID
        or response.templateID
    local translationKey = rendered.translationKeys[1]
    return {
        key = key,
        semanticTemplateID = semanticKey,
        domain = "pnc.system.shared.categories",
        -- Keep the authored English fallback on every live payload. Text
        -- resolution still gives a registered translation precedence, but a
        -- missing/late registration cannot leak a template ID into the UI.
        text = rendered.text ~= "" and rendered.text or nil,
        fallback = fallbackRendered.text,
        args = firstSegment.args or response.args,
        translationKey = translationKey,
        translationKeys = rendered.translationKeys,
        plan = response.plan,
        planTurn = rendered.index,
        planTurnID = rendered.id,
        planContinuation = rendered.continuation,
        topic = response.topic,
        referenceTopic = response.referenceTopic,
        referenceSubject = response.referenceSubject,
        segments = rendered.segments,
        speechStyleContext = response.speechStyleContext,
        realization = response.realization,
        realizationFamily = response.realizationFamily,
        realizationVariant = response.realizationVariant,
        semanticVariantID = response.semanticVariantID,
        speechStyleVariant = response.speechStyleVariant,
        phraseFamilyID = firstSegment.phraseFamilyID or response.phraseFamilyID,
        phraseID = firstSegment.phraseID or response.phraseID,
        phrasePoolSize = firstSegment.phrasePoolSize or response.phrasePoolSize,
        phraseAntiRepeatReason = firstSegment.phraseAntiRepeatReason
            or response.phraseAntiRepeatReason,
        phraseSemanticTemplateID = firstSegment.phraseSemanticTemplateID
            or response.phraseSemanticTemplateID,
        phraseSelection = response.phraseSelection,
        realizationFallbackReason = response.realizationFallbackReason,
        renderTemplateID = response.renderTemplateID,
    }
end

local function payloadsForResponse(response)
    response = type(response) == "table" and response or {}
    local renderPlan = response.renderPlan or response.plan
    if type(renderPlan) == "table"
        and ResponsePlan
        and type(ResponsePlan.RenderDetailed) == "function"
        and type(ResponsePlan.Validate) == "function"
    then
        local valid = ResponsePlan.Validate(renderPlan)
        if valid then
            local payloads = {}
            local index
            for index = 1, #renderPlan.turns do
                local rendered = ResponsePlan.RenderDetailed(
                    renderPlan,
                    localizedSegment,
                    index
                )
                local fallbackRendered = ResponsePlan.RenderDetailed(
                    renderPlan,
                    fallbackSegment,
                    index
                )
                if rendered and fallbackRendered
                    and rendered.text ~= ""
                then
                    payloads[#payloads + 1] = payloadForPlanTurn(
                        response,
                        rendered,
                        fallbackRendered
                    )
                end
            end
            if #payloads > 0 then return payloads end
        end
    end

    local fallback = tostring(response.fallback or "")
    local renderTemplateID = response.renderTemplateID or response.templateID
    local fallbackText = fallbackSegment(
        renderTemplateID,
        fallback,
        response.args
    )
    local text, translationKey = localizedSegment(
        renderTemplateID,
        fallback,
        response.args
    )
    return {
        {
            key = response.templateID,
            semanticTemplateID = response.semanticVariantID
                or response.templateID,
            domain = "pnc.system.shared.categories",
            text = text ~= "" and text or nil,
        fallback = fallbackText,
            args = response.args,
            translationKey = translationKey,
            plan = response.plan,
            planTurn = 1,
            topic = response.topic,
            referenceTopic = response.referenceTopic,
            referenceSubject = response.referenceSubject,
            speechStyleContext = response.speechStyleContext,
            realization = response.realization,
            realizationFamily = response.realizationFamily,
            realizationVariant = response.realizationVariant,
            semanticVariantID = response.semanticVariantID,
            speechStyleVariant = response.speechStyleVariant,
            phraseFamilyID = response.phraseFamilyID,
            phraseID = response.phraseID,
            phrasePoolSize = response.phrasePoolSize,
            phraseAntiRepeatReason = response.phraseAntiRepeatReason,
            phraseSemanticTemplateID = response.phraseSemanticTemplateID,
            phraseSelection = response.phraseSelection,
            realizationFallbackReason = response.realizationFallbackReason,
            renderTemplateID = renderTemplateID,
        },
    }
end

function ResponseAdapter.Payloads(decision, context)
    local response = decision and decision.response or {}
    -- Realize only a presentation copy. The decision response and its plan
    -- remain the semantic/action authority for later policy and dispatch.
    response = SpeechRealization.Apply(response, context)
    return payloadsForResponse(response)
end

function ResponseAdapter.Payload(decision, context)
    return ResponseAdapter.Payloads(decision, context)[1]
end

-- Authoritative conversation receipts (knowledge disclosure, identity, and
-- similar server results) use the same typed translation-argument binding as
-- ordinary deterministic turns. Keep the adapter private by default while
-- exposing this narrow production hook to the existing conversation
-- lifecycle receiver.
Internal.ResponsePayload = ResponseAdapter.Payload

return ResponseAdapter
