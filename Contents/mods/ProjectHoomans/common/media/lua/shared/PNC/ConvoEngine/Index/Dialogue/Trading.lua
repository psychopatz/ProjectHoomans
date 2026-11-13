-- Generated Conversation discovery index; do not edit by hand.
return {
    ["trade.conversation.opening"] = {
        ["domain"] = "trading",
        ["generated"] = {
            "DTCommon/ConvoEngine/Dialogue/Trading",
        },
        ["id"] = "trade.conversation.opening",
        ["kind"] = "dialogue",
        ["source"] = "adopters/dt/dialogue/trading/trade_conversation_opening.json",
    },
    ["trade.conversation.referral"] = {
        ["domain"] = "trading",
        ["generated"] = {
            "DTCommon/ConvoEngine/Dialogue/Trading",
        },
        ["id"] = "trade.conversation.referral",
        ["kind"] = "dialogue",
        ["source"] = "adopters/dt/dialogue/trading/trade_conversation_referral.json",
    },
    ["trade.conversation.suggestions"] = {
        ["domain"] = "trading",
        ["generated"] = {
            "DTCommon/ConvoEngine/Dialogue/Trading",
        },
        ["id"] = "trade.conversation.suggestions",
        ["kind"] = "dialogue",
        ["related"] = {
            "action.trade",
            "pack.DT.trader_story",
            "question.destination",
            "question.origin",
            "question.rumors",
            "question.settlement",
            "question.story",
            "question.trader",
        },
        ["source"] = "adopters/dt/dialogue/trading/trade_conversation_suggestions.json",
    },
}
