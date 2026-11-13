-- Generated Conversation discovery index; do not edit by hand.
return {
    ["beat.argument_escalation"] = {
        ["domain"] = "social_director",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Beat/SocialDirector",
        },
        ["id"] = "beat.argument_escalation",
        ["kind"] = "beat",
        ["related"] = {
            "behavior.deescalate",
            "behavior.end_conversation",
            "behavior.retaliate_verbally",
            "behavior.warn",
        },
        ["source"] = "psdl/director/social.json",
    },
    ["beat.reconciliation"] = {
        ["domain"] = "social_director",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Beat/SocialDirector",
        },
        ["id"] = "beat.reconciliation",
        ["kind"] = "beat",
        ["related"] = {
            "behavior.end_conversation",
            "behavior.reconcile",
            "behavior.warn",
        },
        ["source"] = "psdl/director/social.json",
    },
    ["beat.suspicious_first_contact"] = {
        ["domain"] = "social_director",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Beat/SocialDirector",
        },
        ["id"] = "beat.suspicious_first_contact",
        ["kind"] = "beat",
        ["related"] = {
            "behavior.challenge",
            "behavior.deescalate",
            "behavior.warn",
        },
        ["source"] = "psdl/director/social.json",
    },
}
