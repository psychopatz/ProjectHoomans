-- Semantic response pools for first-party tool outcomes.
--
-- Tool execution remains authoritative in the gameplay/tool handlers. This
-- provider only maps bounded result facts to one semantic realization; it
-- deliberately does not read the former ToolReply wording table.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

local CONTENT_OWNER = "projecthoomans.dialogue_content.tool_replies"

local function hash(value)
    local output = 0
    value = tostring(value or "")
    for index = 1, #value do
        output = (output * 31 + string.byte(value, index)) % 2147483647
    end
    return output
end

local function line(fallback, id)
    return {
        id = id,
        templateID = "UI_PNC_Conversation_ToolReply_Line_" .. hash(fallback),
        fallback = fallback,
        contentOwner = CONTENT_OWNER,
    }
end

local function namedLine(templateID, fallback, id)
    return {
        id = id,
        templateID = templateID,
        fallback = fallback,
        contentOwner = CONTENT_OWNER,
    }
end

local function register(id, variants)
    return Catalog.Register(id, { variants = variants })
end

-- Accepted social reactions.
register("semantic.tool_reply.social.accepted.compliment", {
    line("That is kind of you to say.", "semantic.tool_reply.compliment.1"),
    line("I appreciate the compliment.", "semantic.tool_reply.compliment.2"),
    line("You noticed. Thank you.", "semantic.tool_reply.compliment.3"),
})
register("semantic.tool_reply.social.accepted.romantic_interest", {
    line("Careful. You are making me smile.", "semantic.tool_reply.romantic.1"),
    line("You always know how to get my attention.", "semantic.tool_reply.romantic.2"),
    line("That is a dangerous thing to say to me.", "semantic.tool_reply.romantic.3"),
})
register("semantic.tool_reply.social.accepted.sexual_advance", {
    line("You are bold. I cannot say I dislike that.", "semantic.tool_reply.sexual.1"),
    line("That is a very direct proposition.", "semantic.tool_reply.sexual.2"),
    line("You are moving fast, but I heard you.", "semantic.tool_reply.sexual.3"),
})
register("semantic.tool_reply.social.accepted.hostile_abuse", {
    line("Watch your mouth.", "semantic.tool_reply.hostile.1"),
    line("Try that again and see what happens.", "semantic.tool_reply.hostile.2"),
    line("I have heard worse, but do not make a habit of it.", "semantic.tool_reply.hostile.3"),
})
register("semantic.tool_reply.social.accepted.admire", {
    line("I appreciate that more than you know.", "semantic.tool_reply.admire.1"),
    line("That is kind of you to say.", "semantic.tool_reply.admire.2"),
    line("You see more in me than most people do.", "semantic.tool_reply.admire.3"),
})
register("semantic.tool_reply.social.accepted.praise", {
    line("I appreciate that.", "semantic.tool_reply.praise.1"),
    line("Good. I was hoping you noticed.", "semantic.tool_reply.praise.2"),
    line("That is nice to hear from you.", "semantic.tool_reply.praise.3"),
})
register("semantic.tool_reply.social.accepted.comfort", {
    line("Thanks. I needed that.", "semantic.tool_reply.comfort.1"),
    line("I appreciate you being here.", "semantic.tool_reply.comfort.2"),
    line("That helps more than I expected.", "semantic.tool_reply.comfort.3"),
})
register("semantic.tool_reply.social.accepted.apologize", {
    line("All right. Let us move on.", "semantic.tool_reply.apology.1"),
    line("I accept the apology.", "semantic.tool_reply.apology.2"),
    line("Fine. We can put it behind us.", "semantic.tool_reply.apology.3"),
})
register("semantic.tool_reply.social.accepted.flirt", {
    line("Careful. You are making me smile.", "semantic.tool_reply.flirt.1"),
    line("You always know how to get my attention.", "semantic.tool_reply.flirt.2"),
    line("That is a dangerous thing to say to me.", "semantic.tool_reply.flirt.3"),
})
register("semantic.tool_reply.social.accepted.insult", {
    line("Watch your mouth.", "semantic.tool_reply.insult.1"),
    line("Try that again and see what happens.", "semantic.tool_reply.insult.2"),
    line("I have heard worse, but do not make a habit of it.", "semantic.tool_reply.insult.3"),
})
register("semantic.tool_reply.social.accepted.generic", {
    line("I hear you.", "semantic.tool_reply.accepted_generic.1"),
    line("I will keep that in mind.", "semantic.tool_reply.accepted_generic.2"),
})

-- Network-queued reactions remain explicitly non-committal.
register("semantic.tool_reply.social.queued.compliment", {
    line("I heard the compliment.", "semantic.tool_reply.queued_compliment.1"),
    line("That is kind of you to say.", "semantic.tool_reply.queued_compliment.2"),
})
register("semantic.tool_reply.social.queued.romantic_interest", {
    line("I heard you. You are bold, I will give you that.", "semantic.tool_reply.queued_romantic.1"),
    line("You certainly know how to get my attention.", "semantic.tool_reply.queued_romantic.2"),
})
register("semantic.tool_reply.social.queued.sexual_advance", {
    line("I heard you. Give me a second.", "semantic.tool_reply.queued_sexual.1"),
    line("That is a bold thing to say.", "semantic.tool_reply.queued_sexual.2"),
})
register("semantic.tool_reply.social.queued.hostile_abuse", {
    line("I heard you. Watch yourself.", "semantic.tool_reply.queued_hostile.1"),
    line("Noted. Choose your next words carefully.", "semantic.tool_reply.queued_hostile.2"),
})
register("semantic.tool_reply.social.queued.admire", {
    line("I hear you.", "semantic.tool_reply.queued_admire.1"),
    line("That got through.", "semantic.tool_reply.queued_admire.2"),
})
register("semantic.tool_reply.social.queued.praise", {
    line("I hear you.", "semantic.tool_reply.queued_praise.1"),
    line("I will remember that.", "semantic.tool_reply.queued_praise.2"),
})
register("semantic.tool_reply.social.queued.comfort", {
    line("I hear you.", "semantic.tool_reply.queued_comfort.1"),
    line("Thanks for saying that.", "semantic.tool_reply.queued_comfort.2"),
})
register("semantic.tool_reply.social.queued.apologize", {
    line("I hear you.", "semantic.tool_reply.queued_apology.1"),
    line("We will talk about it.", "semantic.tool_reply.queued_apology.2"),
})
register("semantic.tool_reply.social.queued.flirt", {
    line("I heard you.", "semantic.tool_reply.queued_flirt.1"),
    line("You are bold, I will give you that.", "semantic.tool_reply.queued_flirt.2"),
})
register("semantic.tool_reply.social.queued.insult", {
    line("I heard you.", "semantic.tool_reply.queued_insult.1"),
    line("Noted.", "semantic.tool_reply.queued_insult.2"),
})
register("semantic.tool_reply.social.queued.generic", {
    line("I hear you.", "semantic.tool_reply.queued_generic.1"),
    line("Give me a moment.", "semantic.tool_reply.queued_generic.2"),
})

-- Rejections preserve the result reason/boundary chosen by the tool handler.
register("semantic.tool_reply.social.rejected.positive_cooldown_active", {
    line("You have had your turn with the compliments today.", "semantic.tool_reply.cooldown.1"),
    line("Save the sweet talk for tomorrow.", "semantic.tool_reply.cooldown.2"),
})
register("semantic.tool_reply.social.rejected.relationship_gate", {
    line("We are not there yet.", "semantic.tool_reply.relationship.1"),
    line("That is a little too familiar for us.", "semantic.tool_reply.relationship.2"),
})
register("semantic.tool_reply.social.rejected.personality_gate", {
    line("That kind of attention is not welcome from me.", "semantic.tool_reply.personality.1"),
    line("You are reading me wrong.", "semantic.tool_reply.personality.2"),
})
register("semantic.tool_reply.social.rejected.orientation_gate", {
    line("That is not the kind of interest I have in you.", "semantic.tool_reply.orientation.1"),
    line("Do not mistake my kindness for an invitation.", "semantic.tool_reply.orientation.2"),
})
register("semantic.tool_reply.social.rejected.rejected_by_game", {
    line("Not now.", "semantic.tool_reply.rejected_game.1"),
    line("That did not land well.", "semantic.tool_reply.rejected_game.2"),
})
register("semantic.tool_reply.social.rejected.sexual_advance", {
    line("That is not happening.", "semantic.tool_reply.rejected_sexual.1"),
    line("Do not talk to me like that.", "semantic.tool_reply.rejected_sexual.2"),
    line("You are moving far too fast.", "semantic.tool_reply.rejected_sexual.3"),
})
register("semantic.tool_reply.social.rejected.hostile_abuse", {
    line("Back off.", "semantic.tool_reply.rejected_hostile.1"),
    line("You do not get to speak to me that way.", "semantic.tool_reply.rejected_hostile.2"),
})
register("semantic.tool_reply.social.rejected.generic", {
    line("That did not land well.", "semantic.tool_reply.rejected_generic.1"),
    line("I am not taking that from you right now.", "semantic.tool_reply.rejected_generic.2"),
})

register("semantic.tool_reply.ask_name.prompt", {
    namedLine(
        "UI_PNC_Conversation_Semantic_QuestionIdentity",
        "I'll tell you my name once we've established some trust. What's your name?",
        "semantic.tool_reply.ask_name.prompt"
    ),
})
register("semantic.tool_reply.ask_name.named", {
    namedLine(
        "UI_PNC_Conversation_ToolReply_AskNameNamed_1",
        "I am %s.",
        "semantic.tool_reply.ask_name.named.1"
    ),
    namedLine(
        "UI_PNC_Conversation_ToolReply_AskNameNamed_2",
        "The name is %s.",
        "semantic.tool_reply.ask_name.named.2"
    ),
    namedLine(
        "UI_PNC_Conversation_ToolReply_AskNameNamed_3",
        "You can call me %s.",
        "semantic.tool_reply.ask_name.named.3"
    ),
})
register("semantic.tool_reply.ask_name.unnamed", {
    namedLine(
        "UI_PNC_Conversation_ToolReply_AskNameUnnamed_1",
        "You want to know my name? Give me a second.",
        "semantic.tool_reply.ask_name.unnamed.1"
    ),
    namedLine(
        "UI_PNC_Conversation_ToolReply_AskNameUnnamed_2",
        "My name is a longer story than you might expect.",
        "semantic.tool_reply.ask_name.unnamed.2"
    ),
})
register("semantic.tool_reply.ask_name.rejected", {
    namedLine(
        "UI_PNC_Conversation_ToolReply_AskNameRejected_1",
        "I am not ready to share that yet.",
        "semantic.tool_reply.ask_name.rejected.1"
    ),
    namedLine(
        "UI_PNC_Conversation_ToolReply_AskNameRejected_2",
        "Ask me again when we know each other better.",
        "semantic.tool_reply.ask_name.rejected.2"
    ),
})

register("semantic.tool_reply.order.follow", {
    line("All right. I am with you.", "semantic.tool_reply.order_follow.1"),
    line("Lead the way.", "semantic.tool_reply.order_follow.2"),
    line("I will stay close.", "semantic.tool_reply.order_follow.3"),
})
register("semantic.tool_reply.order.stay", {
    line("All right. I will hold here.", "semantic.tool_reply.order_stay.1"),
    line("I will stay put.", "semantic.tool_reply.order_stay.2"),
})
register("semantic.tool_reply.order.camp", {
    line("All right. We will make camp here.", "semantic.tool_reply.order_camp.1"),
    line("I will settle in here for now.", "semantic.tool_reply.order_camp.2"),
    line("Understood. I will stay here and take care of my needs.", "semantic.tool_reply.order_camp.3"),
})
register("semantic.tool_reply.order.accepted.generic", {
    line("All right.", "semantic.tool_reply.order_generic.1"),
    line("Understood.", "semantic.tool_reply.order_generic.2"),
    line("I will handle it.", "semantic.tool_reply.order_generic.3"),
})
register("semantic.tool_reply.order.rejected", {
    line("I cannot do that right now.", "semantic.tool_reply.order_rejected.1"),
    line("That order is not going to work.", "semantic.tool_reply.order_rejected.2"),
})

return true
