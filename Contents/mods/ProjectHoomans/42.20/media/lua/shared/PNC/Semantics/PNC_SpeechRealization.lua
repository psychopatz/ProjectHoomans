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

local COVERAGE = {
    { family = "greeting", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "wellbeing", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "needs", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "medical", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "identity", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "knowledge", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "acknowledgement", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "apology", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "offer_help", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "dispute_refusal", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "threat_hostility", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "gossip_event", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "companion_action", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "trading_entry", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "quest_commitment", supported = { "neutral", "warm", "terse", "guarded" } },
}

local function phraseFamily(prefix, neutral, warm, terse, guarded)
    local base = "UI_PNC_Conversation_Semantic_Realization"
        .. tostring(prefix)
    return {
        neutral = { key = base .. "Neutral", fallback = neutral },
        warm = { key = base .. "Warm", fallback = warm },
        terse = { key = base .. "Terse", fallback = terse },
        guarded = { key = base .. "Guarded", fallback = guarded },
    }
end

local function bondPhraseFamily(prefix, neutral, warm, terse, guarded)
    local family = phraseFamily(prefix, neutral, warm, terse, guarded)
    local base = "UI_PNC_Conversation_Semantic_Realization"
        .. tostring(prefix) .. "Bond"
    family.bond = {
        any = {
            neutral = { key = base .. "Neutral", fallback = neutral,
                argument = "familyAddress", forceKey = true },
            warm = { key = base .. "Warm", fallback = warm,
                argument = "familyAddress", forceKey = true },
            terse = { key = base .. "Terse", fallback = terse,
                argument = "familyAddress", forceKey = true },
            guarded = { key = base .. "Guarded", fallback = guarded,
                argument = "familyAddress", forceKey = true },
        },
    }
    return family
end

-- These are presentation families over existing semantic template IDs. The
-- semantic response and grounded facts remain the authority; only complete
-- localized phrases are selected here.
FAMILIES["semantic.question.wellbeing.default"] = phraseFamily(
    "Wellbeing", "I'm okay. How about you?", "I'm doing okay. Thanks for asking.",
    "I'm okay.", "I'm managing. Don't press me."
)
FAMILIES["semantic.question.wellbeing.injured"] = phraseFamily(
    "WellbeingInjured", "A little banged up, but I'll manage.",
    "I took a hit, but I'm steady enough to keep going.",
    "I'm hurt. I can manage.", "I'm hurt. That's all I can say."
)
FAMILIES["semantic.question.wellbeing.dataset.getting_by"] = phraseFamily(
    "WellbeingGettingBy", "I'm getting by, one day at a time. How about you?",
    "I'm getting by. Thanks for asking.", "Getting by.",
    "I'm getting by. Leave it there."
)
FAMILIES["semantic.question.needs.offer.hunger"] = phraseFamily(
    "NeedsHunger", "Food would help, but I don't know the exact amount.",
    "Food would help, if you can spare it.", "I need food.",
    "I need food. Keep your distance."
)
FAMILIES["semantic.question.medical_bite.positive"] = phraseFamily(
    "MedicalBitePositive", "Yes, I've been bitten.",
    "Yes. I've been bitten, and I appreciate you checking.",
    "Yes. I've been bitten.", "Yes. I've been bitten. That's all."
)
FAMILIES["semantic.question.medical_bite.negative"] = phraseFamily(
    "MedicalBiteNegative", "No, I don't have a recorded bite.",
    "No, I don't have a recorded bite. Thanks for checking.",
    "No bite.", "No bite. Leave it there."
)
FAMILIES["semantic.question.medical_bite.unknown"] = phraseFamily(
    "MedicalBiteUnknown", "I can't confirm whether I've been bitten.",
    "I can't confirm it, but thanks for checking.", "Can't confirm.",
    "I can't confirm that. Don't press me."
)
FAMILIES["semantic.question.health_state.injured"] = phraseFamily(
    "HealthStateInjured", "I'm hurt, but I'm managing.",
    "I'm hurt, but I'm managing. Thanks for asking.", "I'm hurt.",
    "I'm hurt. Give me space."
)
FAMILIES["semantic.question.health_state.healthy"] = phraseFamily(
    "HealthStateHealthy", "I'm doing okay.",
    "I'm doing okay. Thanks for checking in.", "I'm okay.",
    "I'm fine. Don't make a thing of it."
)
FAMILIES["semantic.question.health_state.unknown"] = phraseFamily(
    "HealthStateUnknown", "I can't confirm my health status right now.",
    "I can't confirm it right now, but thanks for asking.",
    "Can't confirm.", "I can't confirm that."
)
FAMILIES["semantic.question.identity"] = phraseFamily(
    "Identity", "I'll tell you my name once we've established some trust. What's yours?",
    "I'll tell you my name once we know each other. What should I call you?",
    "Not yet. Your name?", "I don't share my name yet. What's yours?"
)
FAMILIES["semantic.question.knowledge.unknown"] = phraseFamily(
    "KnowledgeUnknown", "I don't have reliable information about that.",
    "I don't know enough about that to help.", "I don't know.",
    "I don't know that. Don't guess."
)
FAMILIES["semantic.question.knowledge.known"] = phraseFamily(
    "KnowledgeKnown", "I know about that.",
    "I know about that. I can share what I remember.", "I know it.",
    "I know enough."
)
FAMILIES["semantic.social.acknowledged"] = bondPhraseFamily(
    "Acknowledged", "All right.", "All right. I hear you.", "All right.",
    "Understood. We'll leave it there."
)
FAMILIES["semantic.social.apology.default"] = phraseFamily(
    "Apology", "Noted. Let's move on.", "I appreciate the apology. Let's move on.",
    "Noted.", "Apology heard. Leave it there."
)
FAMILIES["semantic.social.apology.friendly"] = phraseFamily(
    "ApologyFriendly", "It's okay. We can put that behind us.",
    "It's okay. I appreciate you saying that.", "It's okay.",
    "I heard you. Leave it there."
)
FAMILIES["semantic.social.apology.withdrawn"] = phraseFamily(
    "ApologyWithdrawn", "All right. Let's leave it there.",
    "All right. Let's leave it there for now.", "Leave it.",
    "All right. Leave it there."
)
FAMILIES["semantic.social.apology.stressed"] = phraseFamily(
    "ApologyStressed", "I know things are tense. Let's keep it calm.",
    "I know things are tense. Thanks for saying that.", "Keep it calm.",
    "Things are tense. Leave it there."
)
FAMILIES["semantic.social.offer_friendly"] = bondPhraseFamily(
    "OfferHelp", "That's kind of you. I'll keep it in mind.",
    "Thank you. I'll keep it in mind.", "Thanks.",
    "No, thanks. I'll handle it."
)
FAMILIES["semantic.social.dispute_friendly"] = phraseFamily(
    "Dispute", "I see it differently, but we're okay.",
    "I see it differently, but we're still okay.", "I disagree.",
    "I disagree. Leave it there."
)
FAMILIES["semantic.social.dispute_stressed"] = phraseFamily(
    "DisputeStressed", "I hear you, but I need a moment.",
    "I hear you, but I need a moment before we continue.",
    "Need a moment.", "I hear you. Not now."
)
FAMILIES["semantic.social.dispute_trusted"] = phraseFamily(
    "DisputeTrusted", "I respect that. I still don't agree.",
    "I respect that. I still don't agree, but we can talk it through.",
    "I still disagree.", "I still don't agree. Leave it there."
)
FAMILIES["semantic.social.dispute_withdrawn"] = phraseFamily(
    "DisputeWithdrawn", "Let's leave it there.",
    "Let's leave it there for now.", "Leave it.",
    "Let's leave it there."
)
FAMILIES["semantic.social.threat_boundary"] = phraseFamily(
    "Threat", "Back off.", "Step back, please.", "Back off.",
    "Back away. Now."
)
FAMILIES["semantic.social.hostile_short"] = phraseFamily(
    "HostileShort", "Watch your mouth.", "Watch your mouth, please.",
    "Watch it.", "Watch your mouth. Now."
)
FAMILIES["semantic.social.hostile_withdrawn"] = phraseFamily(
    "HostileWithdrawn", "Then leave me alone.",
    "Please leave me alone for now.", "Leave me alone.",
    "Leave me alone. Now."
)
FAMILIES["semantic.social.hostile_stressed"] = phraseFamily(
    "HostileStressed", "That's enough. Keep it up and we're done.",
    "That's enough. Step back and we'll keep this calm.",
    "Enough. Back off.", "That's enough. Back away."
)
FAMILIES["semantic.social.hostile_boundary"] = phraseFamily(
    "HostileBoundary", "Don't talk to me like that.",
    "Please don't talk to me like that.", "Don't.",
    "Don't talk to me like that."
)
FAMILIES["semantic.gossip.unknown"] = bondPhraseFamily(
    "GossipUnknown", "I haven't heard any news lately.",
    "I haven't heard any news, sorry.", "No news.",
    "I don't have anything to share."
)
FAMILIES["semantic.conversation.acknowledged.default"] = phraseFamily(
    "ConversationAcknowledged", "All right. Ask if you want to talk more.",
    "All right. I'm here if you want to talk more.", "All right.",
    "Understood. We'll leave it there."
)
FAMILIES["semantic.question.activity.fishing"] = phraseFamily(
    "ActivityFishing", "I'm trying to catch something.",
    "I'm trying to catch something. Give me a moment.", "Fishing.",
    "I'm fishing. Don't distract me."
)
FAMILIES["semantic.question.activity.dataset.keep_moving"] = phraseFamily(
    "ActivityKeepMoving", "I'm doing what I can to keep things moving.",
    "I'm doing what I can to keep things moving. Thanks for asking.",
    "Keeping busy.", "I'm keeping busy. Don't distract me."
)
FAMILIES["UI_PNC_Conversation_Semantic_GeneratedFollowQueued"] = phraseFamily(
    "CompanionFollow", "Of course, I'll follow.", "Of course, I'll follow you.",
    "I'll follow.", "I'll follow. Stay close."
)
FAMILIES["UI_PNC_Conversation_Semantic_GeneratedFollowQueuedFriendly"] = phraseFamily(
    "CompanionFollow", "Of course, I'll follow.", "Of course, I'll follow you.",
    "I'll follow.", "I'll follow. Stay close."
)
FAMILIES["UI_PNC_Conversation_Semantic_GeneratedFollowQueuedWithdrawn"] = phraseFamily(
    "CompanionFollow", "Of course, I'll follow.", "Of course, I'll follow you.",
    "I'll follow.", "I'll follow. Stay close."
)

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

function Realization.Coverage()
    return copy(COVERAGE)
end

local function relationshipArgument(style, argument)
    if argument ~= "familyAddress" then return nil end
    local bond = type(style) == "table" and style.bond or nil
    local term = type(bond) == "table" and bond.term or nil
    local translation = PNC.Translation
    if type(term) == "table" and term.addressKey
        and translation and type(translation.GetKey) == "function"
    then
        local value = translation.GetKey(
            term.addressKey, tostring(bond.kind or "family")
        )
        if value ~= nil and tostring(value) ~= "" then return tostring(value) end
    end
    return term and tostring(bond.kind or "") or nil
end

function Realization.Resolve(templateID, style, semanticFallback)
    local family = FAMILIES[tostring(templateID or "")]
    if not family then return nil, "realization_family_unavailable" end
    style = type(style) == "table" and style or {}
    local selectedFamily = family
    local bond = type(style.bond) == "table" and style.bond or nil
    local bondFamily = bond and family.bond and family.bond.any or nil
    if type(bondFamily) == "table" and tostring(bond.class or "") ~= "" then
        selectedFamily = bondFamily
    end
    local selected = tostring(style.variant or "neutral")
    local value = selectedFamily[selected]
    local reason
    if type(value) ~= "table" then
        value = selectedFamily.neutral or family.neutral
        reason = "neutral_fallback"
    end
    if type(value) ~= "table" then
        return nil, "realization_neutral_unavailable"
    end
    -- The neutral/base family is the existing semantic catalog entry. Keep
    -- that canonical translation identity intact so adding presentation
    -- realization remains behavior-preserving for already-neutral turns.
    if selected == "neutral" and not value.forceKey then
        return {
            templateID = tostring(templateID),
            fallback = tostring(semanticFallback or value.fallback or ""),
            family = tostring(templateID),
            variant = "neutral",
            fallbackReason = nil,
        }
    end
    return {
        templateID = tostring(value.key or templateID),
        fallback = tostring(value.fallback or ""),
        family = tostring(templateID),
        variant = type(selectedFamily[selected]) == "table"
            and selected or "neutral",
        fallbackReason = reason,
        argument = value.argument,
    }
end

local function applySegment(segment, style, blocked)
    if type(segment) ~= "table" or segment.kind ~= "translation" then
        return segment, nil
    end
    if type(blocked) == "table" and blocked[segment.templateID] then
        return segment, nil
    end
    local resolved = Realization.Resolve(
        segment.templateID, style, segment.fallback
    )
    if not resolved then return segment, nil end
    local output = copy(segment)
    output.args = copy(segment.args or {})
    output.semanticTemplateID = segment.templateID
    output.templateID = resolved.templateID
    output.fallback = resolved.fallback
    output.realizationFamily = resolved.family
    output.realizationVariant = resolved.variant
    output.realizationFallbackReason = resolved.fallbackReason
    if resolved.argument then
        output.args[resolved.argument] = relationshipArgument(style, resolved.argument)
    end
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
    local blocked = {}

    -- The refusal catalog intentionally reuses the acknowledged semantic
    -- template for its default "No." branch. Do not replace that authoritative
    -- refusal with a friendly acknowledgement realization.
    if response.selectionID == "semantic.refuse.default" then
        blocked["semantic.social.acknowledged"] = true
    end

    output.speechStyleContext = Style.PublicView(style)
    if type(output.plan) == "table" and type(output.plan.turns) == "table" then
        for index = 1, math.min(#output.plan.turns, 4) do
            turn = output.plan.turns[index]
            for segmentIndex = 1, math.min(#(turn.segments or {}), 6) do
                segment, resolved = applySegment(
                    turn.segments[segmentIndex], style, blocked
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
    }, style, blocked)
    if resolved then
        output.args = segment.args
        output.semanticTemplateID = output.templateID
        output.renderTemplateID = resolved.templateID
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
