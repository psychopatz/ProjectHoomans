-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "scene",
        ["domainPath"] = "scene/horde",
        ["id"] = "behavior.scene_horde_prompt",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "scene_horde_prompt",
            ["sourceId"] = "behavior.scene_horde_prompt",
            ["sourcePath"] = "behavior/scene/horde/scene_horde_prompt.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Scene/Horde",
        ["namespace"] = "behavior",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["act"] = "COMBAT_HORDE_PROMPT",
            ["baseRelevance"] = 1,
            ["continuation"] = {
                ["inheritEventRefs"] = true,
                ["inheritFactRefs"] = true,
                ["intent"] = "COMBAT_HORDE_REPLY",
                ["mode"] = "emit",
                ["speechAct"] = "REPLY",
                ["target"] = "other",
            },
            ["domains"] = {
                {
                    ["domain"] = "combat",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["events"] = {
                {
                    ["id"] = "horde_detected",
                    ["kind"] = "world_event",
                },
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["emote"] = {
                    ["id"] = "emote.alert",
                },
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.scene.horde_prompt",
                    ["dialogueAct"] = "WARN",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
            },
            ["stimuli"] = {
                "DANGER_CHANGED",
            },
            ["topics"] = {
                {
                    ["domain"] = "combat",
                    ["id"] = "horde_threat",
                },
            },
            ["version"] = 1,
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/scene/horde/scene_horde_prompt.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "COMBAT_HORDE_ALERT",
        },
    },
    {
        ["domain"] = "scene",
        ["domainPath"] = "scene/horde",
        ["id"] = "behavior.scene_horde_reply_brave",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "scene_horde_reply_brave",
            ["sourceId"] = "behavior.scene_horde_reply_brave",
            ["sourcePath"] = "behavior/scene/horde/scene_horde_reply_brave.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Scene/Horde",
        ["namespace"] = "behavior",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["act"] = "COMBAT_HORDE_REPLY",
            ["baseRelevance"] = 1,
            ["continuation"] = {
                ["inheritEventRefs"] = true,
                ["inheritFactRefs"] = true,
                ["mode"] = "terminate",
                ["target"] = "none",
            },
            ["domains"] = {
                {
                    ["domain"] = "combat",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["events"] = {
                {
                    ["id"] = "horde_detected",
                    ["kind"] = "world_event",
                },
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.scene.horde_reply_brave",
                    ["dialogueAct"] = "PROPOSE_ENGAGE",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
            },
            ["stimuli"] = {
                "NPC_SEMANTIC_ACT",
            },
            ["topics"] = {
                {
                    ["domain"] = "combat",
                    ["id"] = "horde_threat",
                },
            },
            ["version"] = 1,
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/scene/horde/scene_horde_reply_brave.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["all"] = {
                {
                    ["op"] = "eq",
                    ["path"] = "stimulus.semantic.intent",
                    ["value"] = "COMBAT_HORDE_REPLY",
                },
                {
                    ["op"] = "gte",
                    ["path"] = "actor.disposition.confidence",
                    ["value"] = 0.65,
                },
            },
        },
    },
    {
        ["domain"] = "scene",
        ["domainPath"] = "scene/horde",
        ["id"] = "behavior.scene_horde_reply_cautious",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "scene_horde_reply_cautious",
            ["sourceId"] = "behavior.scene_horde_reply_cautious",
            ["sourcePath"] = "behavior/scene/horde/scene_horde_reply_cautious.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Scene/Horde",
        ["namespace"] = "behavior",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["act"] = "COMBAT_HORDE_REPLY",
            ["baseRelevance"] = 1,
            ["continuation"] = {
                ["inheritEventRefs"] = true,
                ["inheritFactRefs"] = true,
                ["mode"] = "terminate",
                ["target"] = "none",
            },
            ["domains"] = {
                {
                    ["domain"] = "combat",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["events"] = {
                {
                    ["id"] = "horde_detected",
                    ["kind"] = "world_event",
                },
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.scene.horde_reply_cautious",
                    ["dialogueAct"] = "PROPOSE_AVOID",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
            },
            ["stimuli"] = {
                "NPC_SEMANTIC_ACT",
            },
            ["topics"] = {
                {
                    ["domain"] = "combat",
                    ["id"] = "horde_threat",
                },
            },
            ["version"] = 1,
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/scene/horde/scene_horde_reply_cautious.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["all"] = {
                {
                    ["op"] = "eq",
                    ["path"] = "stimulus.semantic.intent",
                    ["value"] = "COMBAT_HORDE_REPLY",
                },
                {
                    ["op"] = "lt",
                    ["path"] = "actor.disposition.confidence",
                    ["value"] = 0.35,
                },
            },
        },
    },
    {
        ["domain"] = "scene",
        ["domainPath"] = "scene/horde",
        ["id"] = "behavior.scene_horde_reply_steady",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "scene_horde_reply_steady",
            ["sourceId"] = "behavior.scene_horde_reply_steady",
            ["sourcePath"] = "behavior/scene/horde/scene_horde_reply_steady.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Scene/Horde",
        ["namespace"] = "behavior",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["act"] = "COMBAT_HORDE_REPLY",
            ["baseRelevance"] = 0.65,
            ["continuation"] = {
                ["inheritEventRefs"] = true,
                ["inheritFactRefs"] = true,
                ["mode"] = "terminate",
                ["target"] = "none",
            },
            ["domains"] = {
                {
                    ["domain"] = "combat",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["events"] = {
                {
                    ["id"] = "horde_detected",
                    ["kind"] = "world_event",
                },
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.scene.horde_reply_steady",
                    ["dialogueAct"] = "PROPOSE_HOLD",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
            },
            ["stimuli"] = {
                "NPC_SEMANTIC_ACT",
            },
            ["topics"] = {
                {
                    ["domain"] = "combat",
                    ["id"] = "horde_threat",
                },
            },
            ["version"] = 1,
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/scene/horde/scene_horde_reply_steady.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "COMBAT_HORDE_REPLY",
        },
    },
}
