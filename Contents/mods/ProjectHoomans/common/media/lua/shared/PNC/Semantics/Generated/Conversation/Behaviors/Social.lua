-- Generated; do not edit by hand.
return {
    {
        ["act"] = "ACKNOWLEDGE_MEMORY",
        ["baseRelevance"] = 0.5,
        ["domain"] = "social",
        ["id"] = "behavior.acknowledge_memory",
        ["mode"] = "one_shot",
        ["modifiers"] = {
            {
                ["delta"] = 0.25,
                ["reason"] = "empathy_favors_acknowledgement",
                ["when"] = {
                    ["op"] = "gte",
                    ["path"] = "actor.disposition.empathy",
                    ["value"] = 0.6,
                },
            },
            {
                ["delta"] = 0.1,
                ["reason"] = "low_sociability_favors_acknowledgement",
                ["when"] = {
                    ["op"] = "lt",
                    ["path"] = "actor.disposition.sociability",
                    ["value"] = 0.4,
                },
            },
        },
        ["outputs"] = {
            ["emote"] = {
                ["id"] = "emote.nod",
            },
            ["flavor"] = {
                ["contentTemplateID"] = "semantic.interaction.memory.acknowledge_flavor",
                ["presentationAct"] = "AMBIENT_FLAVOR",
            },
            ["speech"] = {
                ["contentTemplateID"] = "semantic.interaction.memory.acknowledge",
                ["dialogueAct"] = "ACKNOWLEDGE",
            },
        },
        ["owner"] = "ProjectHoomans",
        ["requiredCapabilities"] = {
        },
        ["stimuli"] = {
            "NPC_SEMANTIC_ACT",
        },
        ["version"] = 1,
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "SHARE_MEMORY",
        },
    },
    {
        ["act"] = "ACKNOWLEDGE_NEWS",
        ["baseRelevance"] = 0.55,
        ["domain"] = "social",
        ["id"] = "behavior.acknowledge_news",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["emote"] = {
                ["id"] = "emote.nod",
            },
            ["speech"] = {
                ["contentTemplateID"] = "semantic.interaction.news.acknowledge",
                ["dialogueAct"] = "ACKNOWLEDGE",
            },
        },
        ["owner"] = "ProjectHoomans",
        ["requiredCapabilities"] = {
        },
        ["stimuli"] = {
            "NPC_SEMANTIC_ACT",
        },
        ["version"] = 1,
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "SHARE_NEWS",
        },
    },
    {
        ["act"] = "ACKNOWLEDGE_THANKS",
        ["baseRelevance"] = 0.55,
        ["domain"] = "social",
        ["id"] = "behavior.acknowledge_thanks",
        ["mode"] = "one_shot",
        ["modifiers"] = {
            {
                ["delta"] = 0.1,
                ["reason"] = "sociable_acknowledgement",
                ["when"] = {
                    ["op"] = "gte",
                    ["path"] = "actor.disposition.sociability",
                    ["value"] = 0.65,
                },
            },
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "semantic.social.acknowledged",
                ["dialogueAct"] = "ACKNOWLEDGE",
            },
        },
        ["owner"] = "ProjectHoomans",
        ["requiredCapabilities"] = {
            "speech",
        },
        ["stimuli"] = {
            "HUMAN_UTTERANCE",
            "NPC_SEMANTIC_ACT",
        },
        ["version"] = 1,
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "THANK",
        },
    },
    {
        ["act"] = "ASK_MEMORY_FOLLOWUP",
        ["baseRelevance"] = 0.45,
        ["domain"] = "social",
        ["id"] = "behavior.ask_memory_followup",
        ["mode"] = "one_shot",
        ["modifiers"] = {
            {
                ["delta"] = 0.25,
                ["reason"] = "sociability_favors_followup",
                ["when"] = {
                    ["op"] = "gte",
                    ["path"] = "actor.disposition.sociability",
                    ["value"] = 0.6,
                },
            },
            {
                ["delta"] = 0.1,
                ["reason"] = "familiarity_favors_followup",
                ["when"] = {
                    ["op"] = "gte",
                    ["path"] = "relationship.familiarity",
                    ["value"] = 2,
                },
            },
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "semantic.interaction.memory.followup",
                ["dialogueAct"] = "ASK_FOLLOWUP",
            },
        },
        ["owner"] = "ProjectHoomans",
        ["requiredCapabilities"] = {
            "speech",
        },
        ["stimuli"] = {
            "NPC_SEMANTIC_ACT",
        },
        ["version"] = 1,
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "SHARE_MEMORY",
        },
    },
    {
        ["act"] = "CHALLENGE",
        ["baseRelevance"] = 0.5,
        ["domain"] = "social",
        ["id"] = "behavior.challenge",
        ["mode"] = "beat",
        ["modifiers"] = {
            {
                ["delta"] = 0.12,
                ["reason"] = "confidence_supports_challenge",
                ["when"] = {
                    ["op"] = "gte",
                    ["path"] = "actor.disposition.confidence",
                    ["value"] = 0.55,
                },
            },
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "semantic.interaction.first_contact.challenge",
                ["dialogueAct"] = "CHALLENGE",
            },
        },
        ["owner"] = "ProjectHoomans",
        ["requiredCapabilities"] = {
            "speech",
        },
        ["stimuli"] = {
            "HUMAN_UTTERANCE",
            "NPC_SEMANTIC_ACT",
        },
        ["version"] = 1,
        ["when"] = {
            ["op"] = "in",
            ["path"] = "stimulus.semantic.intent",
            ["values"] = {
                "GREET",
                "GOSSIP",
            },
        },
    },
    {
        ["act"] = "DEESCALATE",
        ["baseRelevance"] = 0.35,
        ["domain"] = "social",
        ["id"] = "behavior.deescalate",
        ["mode"] = "beat",
        ["modifiers"] = {
            {
                ["delta"] = 0.4,
                ["reason"] = "fear_favors_deescalation",
                ["when"] = {
                    ["op"] = "gte",
                    ["path"] = "actor.condition.panic",
                    ["value"] = 0.6,
                },
            },
            {
                ["delta"] = 0.2,
                ["reason"] = "danger_favors_deescalation",
                ["when"] = {
                    ["op"] = "truthy",
                    ["path"] = "world.immediateDanger",
                },
            },
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "semantic.interaction.argument.deescalate",
                ["dialogueAct"] = "DEESCALATE",
            },
        },
        ["owner"] = "ProjectHoomans",
        ["requiredCapabilities"] = {
            "speech",
        },
        ["stimuli"] = {
            "HUMAN_UTTERANCE",
            "NPC_SEMANTIC_ACT",
        },
        ["version"] = 1,
        ["when"] = {
            ["any"] = {
                {
                    ["op"] = "in",
                    ["path"] = "stimulus.semantic.speechAct",
                    ["values"] = {
                        "INSULT",
                        "HOSTILE_REMARK",
                        "THREATEN",
                    },
                },
                {
                    ["op"] = "truthy",
                    ["path"] = "world.immediateDanger",
                },
            },
        },
    },
    {
        ["act"] = "END_INTERACTION",
        ["baseRelevance"] = 0.2,
        ["domain"] = "social",
        ["id"] = "behavior.end_conversation",
        ["mode"] = "beat",
        ["modifiers"] = {
            {
                ["delta"] = 0.3,
                ["reason"] = "danger_favors_exit",
                ["when"] = {
                    ["op"] = "truthy",
                    ["path"] = "world.immediateDanger",
                },
            },
            {
                ["delta"] = 0.45,
                ["reason"] = "low_forgiveness_favors_exit",
                ["when"] = {
                    ["op"] = "lt",
                    ["path"] = "actor.disposition.forgiveness",
                    ["value"] = 0.25,
                },
            },
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "semantic.social.hostile_withdrawn",
                ["dialogueAct"] = "END_CONVERSATION",
            },
        },
        ["owner"] = "ProjectHoomans",
        ["requiredCapabilities"] = {
            "speech",
        },
        ["stimuli"] = {
            "HUMAN_UTTERANCE",
            "NPC_SEMANTIC_ACT",
        },
        ["version"] = 1,
        ["when"] = {
            ["any"] = {
                {
                    ["op"] = "in",
                    ["path"] = "stimulus.semantic.speechAct",
                    ["values"] = {
                        "INSULT",
                        "HOSTILE_REMARK",
                        "THREATEN",
                    },
                },
                {
                    ["op"] = "eq",
                    ["path"] = "stimulus.semantic.intent",
                    ["value"] = "APOLOGIZE",
                },
                {
                    ["op"] = "truthy",
                    ["path"] = "world.immediateDanger",
                },
            },
        },
    },
    {
        ["act"] = "RECONCILE",
        ["baseRelevance"] = 0.6,
        ["domain"] = "social",
        ["id"] = "behavior.reconcile",
        ["mode"] = "beat",
        ["modifiers"] = {
            {
                ["delta"] = 0.15,
                ["reason"] = "relationship_recoverable",
                ["when"] = {
                    ["op"] = "gte",
                    ["path"] = "relationship.approval",
                    ["value"] = -20,
                },
            },
            {
                ["delta"] = -0.2,
                ["reason"] = "low_forgiveness",
                ["when"] = {
                    ["op"] = "lt",
                    ["path"] = "actor.disposition.forgiveness",
                    ["value"] = 0.35,
                },
            },
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "semantic.social.apology.friendly",
                ["dialogueAct"] = "RECONCILE",
            },
        },
        ["owner"] = "ProjectHoomans",
        ["requiredCapabilities"] = {
            "speech",
        },
        ["stimuli"] = {
            "HUMAN_UTTERANCE",
            "NPC_SEMANTIC_ACT",
        },
        ["version"] = 1,
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "APOLOGIZE",
        },
    },
    {
        ["act"] = "RETALIATE_VERBALLY",
        ["baseRelevance"] = 0.55,
        ["domain"] = "social",
        ["id"] = "behavior.retaliate_verbally",
        ["mode"] = "beat",
        ["modifiers"] = {
            {
                ["delta"] = 0.2,
                ["reason"] = "aggressive_personality",
                ["when"] = {
                    ["op"] = "gte",
                    ["path"] = "actor.disposition.aggression",
                    ["value"] = 0.65,
                },
            },
            {
                ["delta"] = -0.3,
                ["reason"] = "fear_suppresses_retaliation",
                ["when"] = {
                    ["op"] = "gte",
                    ["path"] = "actor.condition.panic",
                    ["value"] = 0.6,
                },
            },
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "semantic.interaction.argument.retaliate",
                ["dialogueAct"] = "RETALIATE_VERBALLY",
            },
        },
        ["owner"] = "ProjectHoomans",
        ["requiredCapabilities"] = {
            "speech",
        },
        ["stimuli"] = {
            "HUMAN_UTTERANCE",
            "NPC_SEMANTIC_ACT",
        },
        ["version"] = 1,
        ["when"] = {
            ["op"] = "in",
            ["path"] = "stimulus.semantic.speechAct",
            ["values"] = {
                "INSULT",
                "HOSTILE_REMARK",
                "THREATEN",
            },
        },
    },
    {
        ["act"] = "WARN",
        ["baseRelevance"] = 0.65,
        ["domain"] = "social",
        ["id"] = "behavior.warn",
        ["mode"] = "beat",
        ["modifiers"] = {
            {
                ["delta"] = 0.12,
                ["reason"] = "low_approval",
                ["when"] = {
                    ["op"] = "lt",
                    ["path"] = "relationship.approval",
                    ["value"] = 0,
                },
            },
            {
                ["delta"] = 0.08,
                ["reason"] = "confident",
                ["when"] = {
                    ["op"] = "gte",
                    ["path"] = "actor.disposition.confidence",
                    ["value"] = 0.6,
                },
            },
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "semantic.social.hostile_boundary",
                ["dialogueAct"] = "BOUNDARY_WARNING",
            },
        },
        ["owner"] = "ProjectHoomans",
        ["requiredCapabilities"] = {
            "speech",
        },
        ["stimuli"] = {
            "HUMAN_UTTERANCE",
            "NPC_SEMANTIC_ACT",
        },
        ["version"] = 1,
        ["when"] = {
            ["op"] = "in",
            ["path"] = "stimulus.semantic.speechAct",
            ["values"] = {
                "INSULT",
                "HOSTILE_REMARK",
                "THREATEN",
            },
        },
    },
    {
        ["act"] = "WARN_GROUP",
        ["baseRelevance"] = 0.8,
        ["domain"] = "social",
        ["id"] = "behavior.world_event_warn",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["emote"] = {
                ["id"] = "emote.alert",
            },
            ["flavor"] = {
                ["contentTemplateID"] = "semantic.interaction.world_event.warning_flavor",
                ["presentationAct"] = "AMBIENT_FLAVOR",
            },
            ["speech"] = {
                ["contentTemplateID"] = "semantic.interaction.world_event.warning",
                ["dialogueAct"] = "WORLD_WARNING",
            },
        },
        ["owner"] = "ProjectHoomans",
        ["requiredCapabilities"] = {
        },
        ["stimuli"] = {
            "WORLD_EVENT",
            "DANGER_CHANGED",
        },
        ["version"] = 1,
        ["when"] = {
            ["op"] = "truthy",
            ["path"] = "world.immediateDanger",
        },
    },
}
