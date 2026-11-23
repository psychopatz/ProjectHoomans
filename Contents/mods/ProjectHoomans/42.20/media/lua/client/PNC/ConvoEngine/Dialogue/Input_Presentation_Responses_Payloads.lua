-- Render semantic responses into queue-ready presentation payloads.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Input = PNC.ConvoEngine.DialogueInput or {}
PNC.ConvoEngine.DialogueInput = Input
local Internal = Input.Internal or {}
Input.Internal = Internal

require "PNC/ConvoEngine/Dialogue/Input_Presentation_Responses_Translation"
local ResponsePlan = require
    "PNC/ConvoEngine/Dialogue/ResponsePlan"
local SpeechRealization = require
    "PNC/ConvoEngine/SpeechRealization"
local TokenFormatter = PNC.ConvoEngine.TokenFormatter
    or require "PNC/ConvoEngine/TokenFormatter"
local ResponseAdapter = Internal.ResponseAdapter or {}
Internal.ResponseAdapter = ResponseAdapter

local function formatTemplateText(text, args)
    text = tostring(text or "")
    args = type(args) == "table" and args or {}
    if text ~= "" and string.find(text, "{", 1, true) then
        text = TokenFormatter.Format(text, args)
    end
    local firstArg = args.familyAddress or args.familyTerm or args.npcName
        or args.target or args.object or args.location or args.topic
        or args.content or args.value
    if type(firstArg) == "table" then firstArg = nil end
    if firstArg ~= nil and firstArg ~= "" then
        text = string.gsub(text, "%%1", function() return tostring(firstArg) end)
        text = string.gsub(text, "%%s", function() return tostring(firstArg) end)
    elseif string.find(text, "%s", 1, true) or string.find(text, "%1", 1, true) then
        text = string.gsub(text, "^%%[s1],%s*", "")
        text = string.gsub(text, ",%s*%%[s1]([%p%s]?)", "%1")
        text = string.gsub(text, "%%[s1]%s*", "")
        text = string.gsub(text, "^%s+", "")
        text = string.gsub(text, "%s%s+", " ")
        local first = string.sub(text, 1, 1)
        if first ~= "" then
            text = string.upper(first) .. string.sub(text, 2)
        end
    end
    return text
end

local function localizedSegment(templateID, fallback, args, segment)
    local response = {
        templateID = templateID,
        fallback = fallback,
        args = args,
    }
    fallback = tostring(fallback or "")
    local enFallback = tostring(
        (type(segment) == "table" and segment.enFallback) or fallback
    )
    args = type(args) == "table" and args or {}
    local firstArg = args.familyAddress or args.familyTerm or args.npcName
        or args.target or args.object or args.location or args.topic
        or args.content or args.value
    if type(firstArg) == "table" then firstArg = nil end
    local key = Internal.SemanticTranslationKey(response)
    local translation = PNC.Translation
    if not key or not translation
        or type(translation.TrFormat) ~= "function"
    then
        return formatTemplateText(fallback, args), key
    end
    local formattedFallback = formatTemplateText(enFallback, args)
    local ok, value = pcall(translation.TrFormat, key, formattedFallback, firstArg)
    if ok and value ~= nil and tostring(value) ~= "" then
        return formatTemplateText(tostring(value), args), key
    end
    return formatTemplateText(fallback, args), key
end

local function fallbackSegment(templateID, fallback, args, segment)
    local englishFallback = (type(segment) == "table" and segment.enFallback)
        or fallback
    return formatTemplateText(englishFallback, args), nil
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
        domain = "pnc.semantic.dialogue",
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
        utterancePlan = response.utterancePlan,
        utteranceRealization = response.utteranceRealization,
        utterancePlanFallbackReason =
            response.utterancePlanFallbackReason,
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
    local enFallback = tostring(response.enFallback or fallback)
    local renderTemplateID = response.renderTemplateID or response.templateID
    local text, translationKey = localizedSegment(
        renderTemplateID,
        fallback,
        response.args,
        response
    )
    return {
        {
            key = response.templateID,
            semanticTemplateID = response.semanticTemplateID
                or response.templateID,
            domain = "pnc.semantic.dialogue",
            text = text ~= "" and text or nil,
            fallback = formatTemplateText(enFallback, response.args),
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
            utterancePlan = response.utterancePlan,
            utteranceRealization = response.utteranceRealization,
            utterancePlanFallbackReason =
                response.utterancePlanFallbackReason,
            renderTemplateID = renderTemplateID,
        },
    }
end

local function enrichPresentationArgs(args, context)
    if type(context) ~= "table" then return args end
    args = type(args) == "table" and args or {}
    if args["addressee.name"] == nil then
        -- Name knowledge is an explicit capability.  A missing flag must not
        -- be treated as permission to expose the player's real name: older
        -- ambient/response payloads legitimately omit it.
        local known = context.playerNameKnown == true
        local raw
        if known then
            raw = context.addresseeName
                or context.playerFirstName
                or context.playerAddressName
                or context.playerName
        elseif context.playerNameKnown == false then
            -- Keep an already-resolved formal term, but never trust a raw
            -- addresseeName field when the NPC is explicitly name-blind.
            raw = context.playerAddressName or context.player
        end
        args["addressee.name"] = TokenFormatter.FirstTokenName(raw)
    end
    if args["speaker.name"] == nil then
        args["speaker.name"] = TokenFormatter.FirstTokenName(
            context.speakerName or context.npcFirstName or context.npcFullName or context.npcName
        )
    end
    if args["scene.location"] == nil then
        args["scene.location"] = TokenFormatter.CleanLocation(
            context.sceneLocation or context.locationLabel or context.locationName
            or context.zoneName or context.settlementName or context.roomName
        )
    end
    if args["slot.location"] == nil and args["scene.location"] ~= nil then
        args["slot.location"] = args["scene.location"]
    end
    if args["scene.clock"] == nil then
        local world = type(context.worldContext) == "table" and context.worldContext or nil
        local time = world and type(world.time) == "table" and world.time or nil
        args["scene.clock"] = TokenFormatter.CleanName(
            context.sceneClock or (time and time.band) or context.timeOfDay
        )
    end
    return args
end

function ResponseAdapter.Payloads(decision, context)
    local response = decision and decision.response or {}
    -- Realize only a presentation copy. The decision response and its plan
    -- remain the semantic/action authority for later policy and dispatch.
    response = SpeechRealization.Apply(response, context)
    if type(response) == "table" then
        response.args = enrichPresentationArgs(response.args, context)
        local renderPlan = response.renderPlan or response.plan
        if type(renderPlan) == "table" and type(renderPlan.turns) == "table" then
            for _, turn in ipairs(renderPlan.turns) do
                for _, seg in ipairs(turn.segments or {}) do
                    if type(seg) == "table" then
                        seg.args = enrichPresentationArgs(seg.args, context)
                    end
                end
            end
        end
    end
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
