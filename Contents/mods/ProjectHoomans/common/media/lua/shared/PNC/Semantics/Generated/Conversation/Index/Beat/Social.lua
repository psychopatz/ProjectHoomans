-- Generated Conversation discovery index; do not edit by hand.
return {
    ["beat.argument_escalation"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Beats/Social/ArgumentEscalation",
        },
        ["id"] = "beat.argument_escalation",
        ["kind"] = "beat",
        ["related"] = {
            "behavior.deescalate",
            "behavior.end_conversation",
            "behavior.retaliate_verbally",
            "behavior.warn",
        },
        ["source"] = "beats/social/argument_escalation.json",
    },
    ["beat.reconciliation"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Beats/Social/Reconciliation",
        },
        ["id"] = "beat.reconciliation",
        ["kind"] = "beat",
        ["related"] = {
            "behavior.end_conversation",
            "behavior.reconcile",
            "behavior.warn",
        },
        ["source"] = "beats/social/reconciliation.json",
    },
    ["beat.suspicious_first_contact"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Beats/Social/SuspiciousFirstContact",
        },
        ["id"] = "beat.suspicious_first_contact",
        ["kind"] = "beat",
        ["related"] = {
            "behavior.challenge",
            "behavior.deescalate",
            "behavior.warn",
        },
        ["source"] = "beats/social/suspicious_first_contact.json",
    },
}
