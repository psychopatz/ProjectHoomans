-- Generated Conversation discovery index; do not edit by hand.
return {
    ["beat.argument_escalation"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Beat/Social",
        },
        ["id"] = "beat.argument_escalation",
        ["kind"] = "beat",
        ["related"] = {
            "behavior.deescalate",
            "behavior.end_conversation",
            "behavior.retaliate_verbally",
            "behavior.warn",
        },
        ["source"] = "beat/social/argument_escalation.json",
    },
    ["beat.reconciliation"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Beat/Social",
        },
        ["id"] = "beat.reconciliation",
        ["kind"] = "beat",
        ["related"] = {
            "behavior.end_conversation",
            "behavior.reconcile",
            "behavior.warn",
        },
        ["source"] = "beat/social/reconciliation.json",
    },
    ["beat.suspicious_first_contact"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Beat/Social",
        },
        ["id"] = "beat.suspicious_first_contact",
        ["kind"] = "beat",
        ["related"] = {
            "behavior.challenge",
            "behavior.deescalate",
            "behavior.warn",
        },
        ["source"] = "beat/social/suspicious_first_contact.json",
    },
}
