-- Generated Conversation discovery index; do not edit by hand.
return {
    ["conversation.landing.whats_up"] = {
        ["domain"] = "conversation_greeting",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/ConversationGreeting",
        },
        ["id"] = "conversation.landing.whats_up",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/conversation_greeting/conversation_landing_whats_up.json",
    },
    ["flow.greeting.exchange"] = {
        ["domain"] = "conversation_greeting",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/ConversationGreeting",
        },
        ["id"] = "flow.greeting.exchange",
        ["kind"] = "dialogue",
        ["related"] = {
            "greeting",
        },
        ["source"] = "dialogue/conversation_greeting/flow_greeting_exchange.json",
    },
    ["flow.greeting.followup"] = {
        ["domain"] = "conversation_greeting",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/ConversationGreeting",
        },
        ["id"] = "flow.greeting.followup",
        ["kind"] = "dialogue",
        ["related"] = {
            "greeting",
        },
        ["source"] = "dialogue/conversation_greeting/flow_greeting_followup.json",
    },
    ["flow.greeting.opening"] = {
        ["dependents"] = {
            "flow.greeting.opening.rain",
        },
        ["domain"] = "conversation_greeting",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/ConversationGreeting",
        },
        ["id"] = "flow.greeting.opening",
        ["kind"] = "dialogue",
        ["related"] = {
            "greeting",
        },
        ["source"] = "dialogue/conversation_greeting/flow_greeting_opening.json",
    },
    ["flow.greeting.opening.rain"] = {
        ["domain"] = "conversation_greeting",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/ConversationGreeting",
        },
        ["id"] = "flow.greeting.opening.rain",
        ["kind"] = "dialogue",
        ["related"] = {
            "flow.greeting.opening",
            "greeting",
        },
        ["source"] = "dialogue/conversation_greeting/flow_greeting_opening_rain.json",
    },
    ["flow.greeting.responses"] = {
        ["domain"] = "conversation_greeting",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/ConversationGreeting",
        },
        ["id"] = "flow.greeting.responses",
        ["kind"] = "dialogue",
        ["related"] = {
            "greeting",
        },
        ["source"] = "dialogue/conversation_greeting/flow_greeting_responses.json",
    },
}
