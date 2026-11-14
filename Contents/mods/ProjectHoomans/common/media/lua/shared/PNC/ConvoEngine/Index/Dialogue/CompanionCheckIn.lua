-- Generated Conversation discovery index; do not edit by hand.
return {
    ["question.gossip"] = {
        ["domain"] = "companion_check_in",
        ["generated"] = {
            "PNC/ConvoEngine/UI/Dialogue/CompanionCheckIn",
        },
        ["id"] = "question.gossip",
        ["kind"] = "dialogue",
        ["source"] = "adopters/hoomans/dialogue/companion_check_in/question_gossip.json",
    },
    ["question.health"] = {
        ["domain"] = "companion_check_in",
        ["generated"] = {
            "PNC/ConvoEngine/UI/Dialogue/CompanionCheckIn",
        },
        ["id"] = "question.health",
        ["kind"] = "dialogue",
        ["source"] = "adopters/hoomans/dialogue/companion_check_in/question_health.json",
    },
    ["question.needs"] = {
        ["dependents"] = {
            "question.needs.proposal",
            "question.needs.quantity",
        },
        ["domain"] = "companion_check_in",
        ["generated"] = {
            "PNC/ConvoEngine/UI/Dialogue/CompanionCheckIn",
        },
        ["id"] = "question.needs",
        ["kind"] = "dialogue",
        ["source"] = "adopters/hoomans/dialogue/companion_check_in/question_needs.json",
    },
}
