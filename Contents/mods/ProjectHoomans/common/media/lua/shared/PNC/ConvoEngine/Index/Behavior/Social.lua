-- Generated Conversation discovery index; do not edit by hand.
return {
    ["behavior.acknowledge_memory"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social/Acknowledgement",
        },
        ["id"] = "behavior.acknowledge_memory",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.memory.acknowledge",
            "interaction.memory.acknowledge_flavor",
        },
        ["source"] = "behavior/social/acknowledgement/acknowledge_memory.json",
    },
    ["behavior.acknowledge_news"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social/Acknowledgement",
        },
        ["id"] = "behavior.acknowledge_news",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.news.acknowledge",
        },
        ["source"] = "behavior/social/acknowledgement/acknowledge_news.json",
    },
    ["behavior.acknowledge_repair"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social/Repair",
        },
        ["id"] = "behavior.acknowledge_repair",
        ["kind"] = "behavior",
        ["related"] = {
            "social.apology.friendly",
        },
        ["source"] = "behavior/social/repair/acknowledge_repair.json",
    },
    ["behavior.acknowledge_reply"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social/Acknowledgement",
        },
        ["id"] = "behavior.acknowledge_reply",
        ["kind"] = "behavior",
        ["related"] = {
            "social.acknowledged",
        },
        ["source"] = "behavior/social/acknowledgement/acknowledge_reply.json",
    },
    ["behavior.acknowledge_thanks"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social/Acknowledgement",
        },
        ["id"] = "behavior.acknowledge_thanks",
        ["kind"] = "behavior",
        ["related"] = {
            "social.acknowledged",
        },
        ["source"] = "behavior/social/acknowledgement/acknowledge_thanks.json",
    },
    ["behavior.ask_memory_followup"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social/Context",
        },
        ["id"] = "behavior.ask_memory_followup",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.memory.followup",
        },
        ["source"] = "behavior/social/context/ask_memory_followup.json",
    },
    ["behavior.challenge"] = {
        ["dependents"] = {
            "beat.suspicious_first_contact",
        },
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social/Conflict",
        },
        ["id"] = "behavior.challenge",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.first_contact.challenge",
        },
        ["source"] = "behavior/social/conflict/challenge.json",
    },
    ["behavior.clarify_context"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social/Context",
        },
        ["id"] = "behavior.clarify_context",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.context.clarify",
        },
        ["source"] = "behavior/social/context/clarify_context.json",
    },
    ["behavior.deescalate"] = {
        ["dependents"] = {
            "beat.argument_escalation",
            "beat.suspicious_first_contact",
        },
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social/Repair",
        },
        ["id"] = "behavior.deescalate",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.argument.deescalate",
        },
        ["source"] = "behavior/social/repair/deescalate.json",
    },
    ["behavior.end_conversation"] = {
        ["dependents"] = {
            "beat.argument_escalation",
            "beat.reconciliation",
        },
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social/Repair",
        },
        ["id"] = "behavior.end_conversation",
        ["kind"] = "behavior",
        ["related"] = {
            "social.hostile_withdrawn",
        },
        ["source"] = "behavior/social/repair/end_conversation.json",
    },
    ["behavior.reconcile"] = {
        ["dependents"] = {
            "beat.reconciliation",
        },
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social/Repair",
        },
        ["id"] = "behavior.reconcile",
        ["kind"] = "behavior",
        ["related"] = {
            "social.apology.friendly",
        },
        ["source"] = "behavior/social/repair/reconcile.json",
    },
    ["behavior.retaliate_verbally"] = {
        ["dependents"] = {
            "beat.argument_escalation",
        },
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social/Conflict",
        },
        ["id"] = "behavior.retaliate_verbally",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.argument.retaliate",
        },
        ["source"] = "behavior/social/conflict/retaliate_verbally.json",
    },
    ["behavior.warn"] = {
        ["dependents"] = {
            "beat.argument_escalation",
            "beat.reconciliation",
            "beat.suspicious_first_contact",
        },
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social/Conflict",
        },
        ["id"] = "behavior.warn",
        ["kind"] = "behavior",
        ["related"] = {
            "social.hostile_boundary",
        },
        ["source"] = "behavior/social/conflict/warn.json",
    },
    ["behavior.world_event_warn"] = {
        ["domain"] = "social",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Behavior/Social/WorldEvents",
        },
        ["id"] = "behavior.world_event_warn",
        ["kind"] = "behavior",
        ["related"] = {
            "interaction.world_event.warning",
            "interaction.world_event.warning_flavor",
        },
        ["source"] = "behavior/social/world_events/world_event_warn.json",
    },
}
