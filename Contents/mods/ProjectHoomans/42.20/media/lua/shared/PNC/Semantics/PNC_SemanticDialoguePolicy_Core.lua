PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Semantic = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local IR = Semantic.IR
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
        fallback = "Okay.",
    },
    REQUEST_ACKNOWLEDGED = {
        templateID = "semantic.request.acknowledged",
        fallback = "I'll see what I can do.",
    },
    QUESTION_RECEIVED = {
        templateID = "semantic.question.received",
        fallback = "Let me think about that.",
    },
    INVENTORY_QUERY_RECEIVED = {
        templateID = "semantic.inventory.query.pending",
        fallback = "Let me check what I have.",
    },
    SOCIAL_ACKNOWLEDGED = {
        templateID = "semantic.social.acknowledged",
        fallback = "Understood.",
    },
    GREET_ACKNOWLEDGED = {
        templateID = "semantic.greet.acknowledged",
        fallback = "Hey there.",
    },
    OFFER_RECEIVED = {
        templateID = "semantic.offer.received",
        fallback = "I'd really like one. Could I have it?",
    },
    GIFT_SELECTION_REQUIRED = {
        templateID = "semantic.gift.selection_required",
        fallback = "Oh? What did you bring me?",
    },
    GIFT_OFFER_DISPATCHED = {
        templateID = "semantic.gift.pending",
        fallback = "",
    },
    GIFT_CONSENT_DECLINED = {
        templateID = "semantic.gift.consent.declined",
        fallback = "No problem. I'll leave it with you.",
    },
    GIFT_CONSENT_AMBIGUOUS = {
        templateID = "semantic.gift.consent.ambiguous",
        fallback = "More than one of us wants it. Please offer it to one person directly.",
    },
    GOSSIP_RECEIVED = {
        templateID = "semantic.gossip.unknown",
        fallback = "I haven't heard anything about that yet.",
    },
    HOSTILE_REMARK_RECEIVED = {
        templateID = "semantic.social.hostile_remark",
        fallback = "Don't talk to me like that.",
    },
    SELF_REFLECTION_RECEIVED = {
        templateID = "semantic.social.self_reflection",
        fallback = "Don't talk about yourself like that.",
    },
    IDENTITY_CLAIM_RECEIVED = {
        templateID = "semantic.identity.exchange",
        fallback = "Nice to meet you.",
    },
    IDENTITY_NAME_EVASION = {
        templateID = "semantic.identity.evasion",
        fallback = "I asked you your name. Don't just change the subject.",
    },
    THREAT_RECEIVED = {
        templateID = "semantic.social.threat",
        fallback = "Back off.",
    },
    ASK_CLARIFICATION = {
        templateID = "semantic.ask_clarification",
        fallback = "I'm not sure what you mean.",
    },
    ACTION_UNAVAILABLE = {
        templateID = "semantic.action.unavailable",
        fallback = "I can't do that yet.",
    },
    CAMP_REQUESTED = {
        templateID = "semantic.camp.requested",
        fallback = "I'll find us a safe place to camp.",
    },
    UNKNOWN = {
        templateID = "semantic.unknown",
        fallback = "I don't understand.",
    },
}
Policy.ResponseTemplates = Policy.ResponseTemplates or {}
local function registerTextFallback(definition)
    local text = PsychopatzCore
        and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.Text
    if text and type(text.RegisterFallback) == "function"
        and type(definition) == "table"
    then
        text.RegisterFallback(definition.templateID, definition.fallback)
    end
end

for branch, definition in pairs(RESPONSE_TEMPLATES) do
    local stored = Policy.ResponseTemplates[branch]
    if not stored then
        stored = definition
    elseif stored.templateID == definition.templateID
        and (stored.fallback == nil
            or stored.fallback == ""
            or stored.fallback == stored.templateID)
    then
        -- Repair response tables left in memory by an older hot-reloaded
        -- build that accidentally used the template ID as its fallback.
        stored.fallback = definition.fallback
    end
    Policy.ResponseTemplates[branch] = stored
    registerTextFallback(stored)
end

function Policy.RegisterTextFallbacks()
    local count = 0
    for _, definition in pairs(Policy.ResponseTemplates) do
        registerTextFallback(definition)
        count = count + 1
    end
    return count
end


Policy.Internal = Policy.Internal or {}
local Internal = Policy.Internal
Internal.IR = IR
Internal.SemanticOffer = SemanticOffer
Internal.LocalResponse = LocalResponse
Internal.CommandActions = COMMAND_ACTIONS
Internal.FuzzySafeActions = FUZZY_SAFE_ACTIONS
Internal.ItemRequestActions = ITEM_REQUEST_ACTIONS
Internal.RegisterTextFallback = registerTextFallback

return Policy
