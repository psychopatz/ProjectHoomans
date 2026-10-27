PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Semantic = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local IR = Semantic.IR
local CandidateEligibility = require
    "PNC/Semantics/PNC_SemanticDialogueCandidateEligibility"
local FlowKernel = require
    "PNC/Semantics/PNC_SemanticDialogueFlowKernel"
local SemanticOffer = PNC.Gifts
    and PNC.Gifts.Foundation
    and PNC.Gifts.Foundation.SemanticOffer or nil
if type(SemanticOffer) ~= "table" then
    local loaded = require "PNC/Gifts/PNC_GiftSemanticOffer"
    SemanticOffer = type(loaded) == "table" and loaded or nil
end
local Policy = PNC.Semantics.DialoguePolicy or {}
PNC.Semantics.DialoguePolicy = Policy
local LocalResponse = PNC.Semantics.LocalResponse
if type(LocalResponse) ~= "table" then
    local loaded = require "PNC/Semantics/PNC_SemanticDialogueLocalResponse"
    LocalResponse = type(loaded) == "table" and loaded or nil
end

Policy.VERSION = 1
Policy.DEFAULT_HIGH_THRESHOLD = 0.85
Policy.DEFAULT_MEDIUM_THRESHOLD = 0.60

local COMMAND_ACTIONS = {
    FOLLOW = true,
    STOP = true,
    STAY = true,
    GO = true,
    HELP = true,
    FETCH = true,
    GIVE = true,
    TAKE = true,
    WAIT_AT = true,
    CAMP = true,
    EAT = true,
    DRINK = true,
    REFILL = true,
    CONSUME = true,
    QUEST_ACCEPT = true,
    QUEST_STATUS = true,
    QUEST_TURN_IN = true,
    RECRUIT = true,
    RELATIONSHIP_PROPOSAL = true,
}

function Policy.GetCommandActions()
    local actions = {}
    for action in pairs(COMMAND_ACTIONS) do
        actions[#actions + 1] = action
    end
    table.sort(actions)
    return actions
end

-- Fuzzy recognition is useful for low-risk conversational movement commands,
-- but a typo must not silently turn into an inventory or task side effect.
local FUZZY_SAFE_ACTIONS = {
    FOLLOW = true,
    STOP = true,
    STAY = true,
}

-- A literal item name is intentionally allowed to remain unresolved here.
-- The authoritative item selector must still classify it and find an actual
-- inventory entry before any gameplay effect can occur.
local ITEM_REQUEST_ACTIONS = {
    FETCH = true,
    GIVE = true,
    EAT = true,
    DRINK = true,
    REFILL = true,
    CONSUME = true,
}

local RESPONSE_TEMPLATES = {
    COMMAND_ACCEPTED = {
        templateID = "semantic.command.accepted",
    },
    REQUEST_ACKNOWLEDGED = {
        templateID = "semantic.request.acknowledged",
    },
    QUESTION_RECEIVED = {
        templateID = "semantic.question.received",
    },
    INVENTORY_QUERY_RECEIVED = {
        templateID = "semantic.inventory.query.pending",
    },
    SOCIAL_ACKNOWLEDGED = {
        templateID = "semantic.social.acknowledged",
    },
    GREET_ACKNOWLEDGED = {
        templateID = "semantic.greet.acknowledged",
    },
    OFFER_RECEIVED = {
        templateID = "semantic.offer.received",
    },
    GIFT_SELECTION_REQUIRED = {
        templateID = "semantic.gift.selection_required",
    },
    GIFT_OFFER_DISPATCHED = {
        templateID = "semantic.gift.pending",
    },
    GIFT_CONSENT_DECLINED = {
        templateID = "semantic.gift.consent.declined",
    },
    GIFT_CONSENT_AMBIGUOUS = {
        templateID = "semantic.gift.consent.ambiguous",
    },
    CONVERSATION_RECRUITMENT_REQUESTED = {
        templateID = "semantic.conversation.recruitment.requested",
    },
    GOSSIP_RECEIVED = {
        templateID = "semantic.gossip.unknown",
    },
    HOSTILE_REMARK_RECEIVED = {
        templateID = "semantic.social.hostile_remark",
    },
    SELF_REFLECTION_RECEIVED = {
        templateID = "semantic.social.self_reflection",
    },
    IDENTITY_CLAIM_RECEIVED = {
        templateID = "semantic.identity.exchange",
    },
    IDENTITY_NAME_EVASION = {
        templateID = "semantic.identity.evasion",
    },
    THREAT_RECEIVED = {
        templateID = "semantic.social.threat",
    },
    ASK_CLARIFICATION = {
        templateID = "semantic.ask_clarification",
    },
    ACTION_UNAVAILABLE = {
        templateID = "semantic.action.unavailable",
    },
    CAMP_REQUESTED = {
        templateID = "semantic.camp.requested",
    },
    UNKNOWN = {
        templateID = "semantic.unknown",
    },
}
Policy.ResponseTemplates = Policy.ResponseTemplates or {}
for branch, definition in pairs(RESPONSE_TEMPLATES) do
    local stored = Policy.ResponseTemplates[branch]
    if not stored then
        stored = {}
    end
    stored.templateID = definition.templateID
    -- A hot-reloaded process may still hold the pre-P11 fallback field. Clear
    -- it so wording cannot survive outside Dialogue Content.
    stored.fallback = nil
    Policy.ResponseTemplates[branch] = stored
end


Policy.Internal = Policy.Internal or {}
local Internal = Policy.Internal
Internal.IR = IR
Internal.SemanticOffer = SemanticOffer
Internal.LocalResponse = LocalResponse
Internal.CommandActions = COMMAND_ACTIONS
Internal.FuzzySafeActions = FUZZY_SAFE_ACTIONS
Internal.ItemRequestActions = ITEM_REQUEST_ACTIONS
Internal.CandidateEligibility = CandidateEligibility
Internal.FlowKernel = FlowKernel

function Policy.SelectCandidate(bundle, state, context, options, contextResolver)
    return CandidateEligibility.Select(
        bundle, state, context, options, contextResolver
    )
end

function Policy.CommitFlow(decisionResult, ir, state, context, options)
    local preview = decisionResult and decisionResult.flow or nil
    if not preview then return nil, "no_flow_preview" end
    return FlowKernel.Commit(preview, ir, state, context, options)
end

return Policy
