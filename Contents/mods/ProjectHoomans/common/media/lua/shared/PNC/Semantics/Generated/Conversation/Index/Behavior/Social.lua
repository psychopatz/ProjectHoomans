-- Generated Conversation discovery index; do not edit by hand.
return {
    ["behavior.acknowledge_memory"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Behaviors/Social/AcknowledgeMemory",
        },
        ["id"] = "behavior.acknowledge_memory",
        ["kind"] = "behavior",
        ["source"] = "behaviors/social/acknowledge_memory.json",
    },
    ["behavior.acknowledge_news"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Behaviors/Social/AcknowledgeNews",
        },
        ["id"] = "behavior.acknowledge_news",
        ["kind"] = "behavior",
        ["source"] = "behaviors/social/acknowledge_news.json",
    },
    ["behavior.acknowledge_thanks"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Behaviors/Social/AcknowledgeThanks",
        },
        ["id"] = "behavior.acknowledge_thanks",
        ["kind"] = "behavior",
        ["source"] = "behaviors/social/acknowledge_thanks.json",
    },
    ["behavior.ask_memory_followup"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Behaviors/Social/AskMemoryFollowup",
        },
        ["id"] = "behavior.ask_memory_followup",
        ["kind"] = "behavior",
        ["source"] = "behaviors/social/ask_memory_followup.json",
    },
    ["behavior.challenge"] = {
        ["dependents"] = {
            "beat.suspicious_first_contact",
        },
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Behaviors/Social/Challenge",
        },
        ["id"] = "behavior.challenge",
        ["kind"] = "behavior",
        ["source"] = "behaviors/social/challenge.json",
    },
    ["behavior.deescalate"] = {
        ["dependents"] = {
            "beat.argument_escalation",
            "beat.suspicious_first_contact",
        },
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Behaviors/Social/Deescalate",
        },
        ["id"] = "behavior.deescalate",
        ["kind"] = "behavior",
        ["source"] = "behaviors/social/deescalate.json",
    },
    ["behavior.end_conversation"] = {
        ["dependents"] = {
            "beat.argument_escalation",
            "beat.reconciliation",
        },
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Behaviors/Social/EndConversation",
        },
        ["id"] = "behavior.end_conversation",
        ["kind"] = "behavior",
        ["source"] = "behaviors/social/end_conversation.json",
    },
    ["behavior.reconcile"] = {
        ["dependents"] = {
            "beat.reconciliation",
        },
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Behaviors/Social/Reconcile",
        },
        ["id"] = "behavior.reconcile",
        ["kind"] = "behavior",
        ["source"] = "behaviors/social/reconcile.json",
    },
    ["behavior.retaliate_verbally"] = {
        ["dependents"] = {
            "beat.argument_escalation",
        },
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Behaviors/Social/RetaliateVerbally",
        },
        ["id"] = "behavior.retaliate_verbally",
        ["kind"] = "behavior",
        ["source"] = "behaviors/social/retaliate_verbally.json",
    },
    ["behavior.warn"] = {
        ["dependents"] = {
            "beat.argument_escalation",
            "beat.reconciliation",
            "beat.suspicious_first_contact",
        },
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Behaviors/Social/Warn",
        },
        ["id"] = "behavior.warn",
        ["kind"] = "behavior",
        ["source"] = "behaviors/social/warn.json",
    },
    ["behavior.world_event_warn"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Behaviors/Social/WorldEventWarn",
        },
        ["id"] = "behavior.world_event_warn",
        ["kind"] = "behavior",
        ["source"] = "behaviors/social/world_event_warn.json",
    },
}
