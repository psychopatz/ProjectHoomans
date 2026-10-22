-- Whole-phrase, localization-safe realization families.
--
-- Families are keyed by existing presentation template IDs. They do not
-- define new semantic intents, frames, actions, or response-plan branches.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Realization = PNC.Semantics.SpeechRealization or {}
PNC.Semantics.SpeechRealization = Realization

Realization.VERSION = 1
Realization.MAX_FAMILY_APPLICATIONS = 8

local Style = PNC.Semantics.SpeechStyleContext
    or require "PNC/Semantics/PNC_SpeechStyleContext"

local FAMILIES = {
    ["semantic.flow.greeting.opening.default"] = {
        neutral = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingNeutral",
            fallback = "Hello. Good to see you.",
        },
        warm = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingWarm",
            fallback = "Hey! It is good to see you.",
        },
        terse = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingTerse",
            fallback = "Hello.",
        },
        guarded = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingGuarded",
            fallback = "Hello. What is it?",
        },
    },
    ["semantic.flow.greeting.opening.friendly"] = {
        neutral = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingNeutral",
            fallback = "Hello. Good to see you.",
        },
        warm = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingWarm",
            fallback = "Hey! It is good to see you.",
        },
        terse = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingTerse",
            fallback = "Hello.",
        },
        guarded = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingGuarded",
            fallback = "Hello. What is it?",
        },
    },
    ["semantic.flow.greeting.opening.question.default"] = {
        neutral = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingQuestionNeutral",
            fallback = "How have you been?",
        },
        warm = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingQuestionWarm",
            fallback = "How have you been holding up?",
        },
        terse = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingQuestionTerse",
            fallback = "You okay?",
        },
        guarded = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingQuestionGuarded",
            fallback = "How are things?",
        },
    },
    ["semantic.flow.greeting.opening.question.friendly"] = {
        neutral = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingQuestionNeutral",
            fallback = "How have you been?",
        },
        warm = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingQuestionWarm",
            fallback = "How have you been holding up?",
        },
        terse = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingQuestionTerse",
            fallback = "You okay?",
        },
        guarded = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingQuestionGuarded",
            fallback = "How are things?",
        },
    },
}

local function copy(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    -- Preserve the complete bounded response plan while still preventing a
    -- provider from expanding an unbounded presentation payload.
    if depth >= 12 then return nil end
    local output = {}
    local count = 0
    for key, item in pairs(value) do
        if count >= 128 then break end
        if type(key) == "string" or type(key) == "number" then
            output[key] = copy(item, depth + 1)
            count = count + 1
        end
    end
    return output
end

function Realization.Register(templateID, family)
    templateID = tostring(templateID or "")
    if templateID == "" or type(family) ~= "table" then
        return false, "realization_family_invalid"
    end
    FAMILIES[templateID] = copy(family)
    return true, templateID
end

function Realization.Families()
    return copy(FAMILIES)
end

function Realization.Resolve(templateID, style)
    local family = FAMILIES[tostring(templateID or "")]
    if not family then return nil, "realization_family_unavailable" end
    style = type(style) == "table" and style or {}
    local selected = tostring(style.variant or "neutral")
    local value = family[selected]
    local reason
    if type(value) ~= "table" then
        value = family.neutral
        reason = "neutral_fallback"
    end
    if type(value) ~= "table" then
        return nil, "realization_neutral_unavailable"
    end
    return {
        templateID = tostring(value.key or templateID),
        fallback = tostring(value.fallback or ""),
        family = tostring(templateID),
        variant = type(family[selected]) == "table" and selected or "neutral",
        fallbackReason = reason,
    }
end

local function applySegment(segment, style)
    if type(segment) ~= "table" or segment.kind ~= "translation" then
        return segment, nil
    end
    local resolved = Realization.Resolve(segment.templateID, style)
    if not resolved then return segment, nil end
    local output = copy(segment)
    output.semanticTemplateID = segment.templateID
    output.templateID = resolved.templateID
    output.fallback = resolved.fallback
    output.realizationFamily = resolved.family
    output.realizationVariant = resolved.variant
    output.realizationFallbackReason = resolved.fallbackReason
    return output, resolved
end

function Realization.Apply(response, context)
    if type(response) ~= "table" then return response end
    local style = Style.Resolve(context)
    local output = copy(response)
    local applications = 0
    local fallbackCount = 0
    local first
    local resolved
    local segment
    local turn
    local index
    local segmentIndex

    output.speechStyleContext = Style.PublicView(style)
    if type(output.plan) == "table" and type(output.plan.turns) == "table" then
        for index = 1, math.min(#output.plan.turns, 4) do
            turn = output.plan.turns[index]
            for segmentIndex = 1, math.min(#(turn.segments or {}), 6) do
                segment, resolved = applySegment(
                    turn.segments[segmentIndex], style
                )
                turn.segments[segmentIndex] = segment
                if resolved then
                    applications = applications + 1
                    first = first or resolved
                    if resolved.fallbackReason then fallbackCount = fallbackCount + 1 end
                end
            end
        end
    end
    segment, resolved = applySegment({
        kind = "translation",
        templateID = output.templateID,
        fallback = output.fallback,
        args = output.args,
    }, style)
    if resolved then
        output.semanticTemplateID = output.templateID
        output.templateID = resolved.templateID
        output.fallback = resolved.fallback
        output.realizationFamily = resolved.family
        output.realizationVariant = resolved.variant
        output.realizationFallbackReason = resolved.fallbackReason
        applications = applications + 1
        first = first or resolved
        if resolved.fallbackReason then fallbackCount = fallbackCount + 1 end
    end
    output.realization = {
        family = first and first.family or nil,
        variant = first and first.variant or style.variant,
        applied = applications > 0,
        applicationCount = applications,
        neutralFallbackCount = fallbackCount,
        maxApplications = Realization.MAX_FAMILY_APPLICATIONS,
    }
    return output
end

return Realization
