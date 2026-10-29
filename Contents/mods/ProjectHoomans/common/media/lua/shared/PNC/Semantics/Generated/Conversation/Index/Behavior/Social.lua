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
    ["behavior.acknowledge_repair"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Behaviors/Social/AcknowledgeRepair",
        },
        ["id"] = "behavior.acknowledge_repair",
        ["kind"] = "behavior",
        ["source"] = "behaviors/social/acknowledge_repair.json",
    },
    ["behavior.acknowledge_reply"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Behaviors/Social/AcknowledgeReply",
        },
        ["id"] = "behavior.acknowledge_reply",
        ["kind"] = "behavior",
        ["source"] = "behaviors/social/acknowledge_reply.json",
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
    ["behavior.clarify_context"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Behaviors/Social/ClarifyContext",
        },
        ["id"] = "behavior.clarify_context",
        ["kind"] = "behavior",
        ["source"] = "behaviors/social/clarify_context.json",
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
    ["behavior.scene_excursion_acknowledge"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Behaviors/Social/SceneRuntimeAdopters",
        },
        ["id"] = "behavior.scene_excursion_acknowledge",
        ["kind"] = "behavior",
        ["source"] = "behaviors/social/scene_runtime_adopters.json",
    },
    ["behavior.scene_excursion_departing"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Behaviors/Social/SceneRuntimeAdopters",
        },
        ["id"] = "behavior.scene_excursion_departing",
        ["kind"] = "behavior",
        ["source"] = "behaviors/social/scene_runtime_adopters.json",
    },
    ["behavior.scene_excursion_failed"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Behaviors/Social/SceneRuntimeAdopters",
        },
        ["id"] = "behavior.scene_excursion_failed",
        ["kind"] = "behavior",
        ["source"] = "behaviors/social/scene_runtime_adopters.json",
    },
    ["behavior.scene_excursion_home"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Behaviors/Social/SceneRuntimeAdopters",
        },
        ["id"] = "behavior.scene_excursion_home",
        ["kind"] = "behavior",
        ["source"] = "behaviors/social/scene_runtime_adopters.json",
    },
    ["behavior.scene_excursion_preparing"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Behaviors/Social/SceneRuntimeAdopters",
        },
        ["id"] = "behavior.scene_excursion_preparing",
        ["kind"] = "behavior",
        ["source"] = "behaviors/social/scene_runtime_adopters.json",
    },
    ["behavior.scene_excursion_returning"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Behaviors/Social/SceneRuntimeAdopters",
        },
        ["id"] = "behavior.scene_excursion_returning",
        ["kind"] = "behavior",
        ["source"] = "behaviors/social/scene_runtime_adopters.json",
    },
    ["behavior.scene_grounded_news_share"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Behaviors/Social/SceneRuntimeAdopters",
        },
        ["id"] = "behavior.scene_grounded_news_share",
        ["kind"] = "behavior",
        ["source"] = "behaviors/social/scene_runtime_adopters.json",
    },
    ["behavior.scene_horde_prompt"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Behaviors/Social/SceneRuntimeAdopters",
        },
        ["id"] = "behavior.scene_horde_prompt",
        ["kind"] = "behavior",
        ["source"] = "behaviors/social/scene_runtime_adopters.json",
    },
    ["behavior.scene_horde_reply_brave"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Behaviors/Social/SceneRuntimeAdopters",
        },
        ["id"] = "behavior.scene_horde_reply_brave",
        ["kind"] = "behavior",
        ["source"] = "behaviors/social/scene_runtime_adopters.json",
    },
    ["behavior.scene_horde_reply_cautious"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Behaviors/Social/SceneRuntimeAdopters",
        },
        ["id"] = "behavior.scene_horde_reply_cautious",
        ["kind"] = "behavior",
        ["source"] = "behaviors/social/scene_runtime_adopters.json",
    },
    ["behavior.scene_horde_reply_steady"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Behaviors/Social/SceneRuntimeAdopters",
        },
        ["id"] = "behavior.scene_horde_reply_steady",
        ["kind"] = "behavior",
        ["source"] = "behaviors/social/scene_runtime_adopters.json",
    },
    ["behavior.scene_news_followup"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Behaviors/Social/SceneRuntimeAdopters",
        },
        ["id"] = "behavior.scene_news_followup",
        ["kind"] = "behavior",
        ["source"] = "behaviors/social/scene_runtime_adopters.json",
    },
    ["behavior.scene_news_followup_answer"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Behaviors/Social/SceneRuntimeAdopters",
        },
        ["id"] = "behavior.scene_news_followup_answer",
        ["kind"] = "behavior",
        ["source"] = "behaviors/social/scene_runtime_adopters.json",
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
