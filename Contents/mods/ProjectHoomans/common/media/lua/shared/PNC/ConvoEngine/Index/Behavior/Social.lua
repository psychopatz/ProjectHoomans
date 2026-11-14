-- Generated Conversation discovery index; do not edit by hand.
return {
    ["behavior.acknowledge_memory"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.acknowledge_memory",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.memory.acknowledge",
            "interaction.memory.acknowledge_flavor",
        },
        ["source"] = "behavior/social/acknowledge_memory.json",
    },
    ["behavior.acknowledge_news"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.acknowledge_news",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.news.acknowledge",
        },
        ["source"] = "behavior/social/acknowledge_news.json",
    },
    ["behavior.acknowledge_repair"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.acknowledge_repair",
        ["kind"] = "behavior",
        ["related"] = {
            "social.apology.friendly",
        },
        ["source"] = "behavior/social/acknowledge_repair.json",
    },
    ["behavior.acknowledge_reply"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.acknowledge_reply",
        ["kind"] = "behavior",
        ["related"] = {
            "social.acknowledged",
        },
        ["source"] = "behavior/social/acknowledge_reply.json",
    },
    ["behavior.acknowledge_thanks"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.acknowledge_thanks",
        ["kind"] = "behavior",
        ["related"] = {
            "social.acknowledged",
        },
        ["source"] = "behavior/social/acknowledge_thanks.json",
    },
    ["behavior.ask_memory_followup"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.ask_memory_followup",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.memory.followup",
        },
        ["source"] = "behavior/social/ask_memory_followup.json",
    },
    ["behavior.challenge"] = {
        ["dependents"] = {
            "beat.suspicious_first_contact",
        },
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.challenge",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.first_contact.challenge",
        },
        ["source"] = "behavior/social/challenge.json",
    },
    ["behavior.clarify_context"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.clarify_context",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.context.clarify",
        },
        ["source"] = "behavior/social/clarify_context.json",
    },
    ["behavior.deescalate"] = {
        ["dependents"] = {
            "beat.argument_escalation",
            "beat.suspicious_first_contact",
        },
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.deescalate",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.argument.deescalate",
        },
        ["source"] = "behavior/social/deescalate.json",
    },
    ["behavior.end_conversation"] = {
        ["dependents"] = {
            "beat.argument_escalation",
            "beat.reconciliation",
        },
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.end_conversation",
        ["kind"] = "behavior",
        ["related"] = {
            "social.hostile_withdrawn",
        },
        ["source"] = "behavior/social/end_conversation.json",
    },
    ["behavior.reconcile"] = {
        ["dependents"] = {
            "beat.reconciliation",
        },
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.reconcile",
        ["kind"] = "behavior",
        ["related"] = {
            "social.apology.friendly",
        },
        ["source"] = "behavior/social/reconcile.json",
    },
    ["behavior.retaliate_verbally"] = {
        ["dependents"] = {
            "beat.argument_escalation",
        },
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.retaliate_verbally",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.argument.retaliate",
        },
        ["source"] = "behavior/social/retaliate_verbally.json",
    },
    ["behavior.scene_excursion_acknowledge"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.scene_excursion_acknowledge",
        ["kind"] = "behavior",
        ["related"] = {
            "social.acknowledged",
        },
        ["source"] = "behavior/social/scene_excursion_acknowledge.json",
    },
    ["behavior.scene_excursion_departing"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.scene_excursion_departing",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.scene.excursion_departing",
        },
        ["source"] = "behavior/social/scene_excursion_departing.json",
    },
    ["behavior.scene_excursion_failed"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.scene_excursion_failed",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.scene.excursion_failed",
        },
        ["source"] = "behavior/social/scene_excursion_failed.json",
    },
    ["behavior.scene_excursion_home"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.scene_excursion_home",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.scene.excursion_home",
        },
        ["source"] = "behavior/social/scene_excursion_home.json",
    },
    ["behavior.scene_excursion_preparing"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.scene_excursion_preparing",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.scene.excursion_preparing",
        },
        ["source"] = "behavior/social/scene_excursion_preparing.json",
    },
    ["behavior.scene_excursion_returning"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.scene_excursion_returning",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.scene.excursion_returning",
        },
        ["source"] = "behavior/social/scene_excursion_returning.json",
    },
    ["behavior.scene_grounded_news_share"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.scene_grounded_news_share",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.scene.grounded_news_share",
        },
        ["source"] = "behavior/social/scene_grounded_news_share.json",
    },
    ["behavior.scene_horde_prompt"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.scene_horde_prompt",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.scene.horde_prompt",
        },
        ["source"] = "behavior/social/scene_horde_prompt.json",
    },
    ["behavior.scene_horde_reply_brave"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.scene_horde_reply_brave",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.scene.horde_reply_brave",
        },
        ["source"] = "behavior/social/scene_horde_reply_brave.json",
    },
    ["behavior.scene_horde_reply_cautious"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.scene_horde_reply_cautious",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.scene.horde_reply_cautious",
        },
        ["source"] = "behavior/social/scene_horde_reply_cautious.json",
    },
    ["behavior.scene_horde_reply_steady"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.scene_horde_reply_steady",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.scene.horde_reply_steady",
        },
        ["source"] = "behavior/social/scene_horde_reply_steady.json",
    },
    ["behavior.scene_news_followup"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.scene_news_followup",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.memory.followup",
        },
        ["source"] = "behavior/social/scene_news_followup.json",
    },
    ["behavior.scene_news_followup_answer"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.scene_news_followup_answer",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.scene.grounded_news_answer",
        },
        ["source"] = "behavior/social/scene_news_followup_answer.json",
    },
    ["behavior.scene_post_combat_clear"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.scene_post_combat_clear",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.scene.post_combat_clear",
        },
        ["source"] = "behavior/social/scene_post_combat_clear.json",
    },
    ["behavior.scene_task_work_assigned"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.scene_task_work_assigned",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.scene.task_work_assigned",
        },
        ["source"] = "behavior/social/scene_task_work_assigned.json",
    },
    ["behavior.scene_task_work_completed"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.scene_task_work_completed",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.scene.task_work_completed",
        },
        ["source"] = "behavior/social/scene_task_work_completed.json",
    },
    ["behavior.warn"] = {
        ["dependents"] = {
            "beat.argument_escalation",
            "beat.reconciliation",
            "beat.suspicious_first_contact",
        },
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.warn",
        ["kind"] = "behavior",
        ["related"] = {
            "social.hostile_boundary",
        },
        ["source"] = "behavior/social/warn.json",
    },
    ["behavior.world_event_warn"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social",
        },
        ["id"] = "behavior.world_event_warn",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.world_event.warning",
            "interaction.world_event.warning_flavor",
        },
        ["source"] = "behavior/social/world_event_warn.json",
    },
}
