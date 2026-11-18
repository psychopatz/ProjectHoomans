-- Generated Conversation discovery index; do not edit by hand.
return {
    ["flow.needs.exchange"] = {
        ["domain"] = "conversation_needs",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/ConversationNeeds",
        },
        ["id"] = "flow.needs.exchange",
        ["kind"] = "dialogue",
        ["related"] = {
            "offer",
        },
        ["source"] = "dialogue/conversation_needs/flow_needs_exchange.json",
    },
    ["question.needs.offer"] = {
        ["domain"] = "conversation_needs",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/ConversationNeeds",
        },
        ["id"] = "question.needs.offer",
        ["kind"] = "dialogue",
        ["related"] = {
            "offer",
            "question.needs",
        },
        ["source"] = "dialogue/conversation_needs/question_needs_offer.json",
    },
    ["question.needs.proposal"] = {
        ["domain"] = "conversation_needs",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/ConversationNeeds",
        },
        ["id"] = "question.needs.proposal",
        ["kind"] = "dialogue",
        ["related"] = {
            "question.needs",
        },
        ["source"] = "dialogue/conversation_needs/question_needs_proposal.json",
    },
    ["question.needs.quantity"] = {
        ["domain"] = "conversation_needs",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/ConversationNeeds",
        },
        ["id"] = "question.needs.quantity",
        ["kind"] = "dialogue",
        ["related"] = {
            "question.needs",
        },
        ["source"] = "dialogue/conversation_needs/question_needs_quantity.json",
    },
}
