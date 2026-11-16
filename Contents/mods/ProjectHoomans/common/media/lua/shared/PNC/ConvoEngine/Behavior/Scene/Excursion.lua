-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "scene",
        ["domainPath"] = "scene/excursion",
        ["id"] = "behavior.scene_excursion_acknowledge",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "scene_excursion_acknowledge",
            ["sourceId"] = "behavior.scene_excursion_acknowledge",
            ["sourcePath"] = "behavior/scene/excursion/scene_excursion_acknowledge.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Scene/Excursion",
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
            ["act"] = "ACKNOWLEDGE",
            ["baseRelevance"] = 1,
            ["continuation"] = {
                ["inheritEventRefs"] = true,
                ["inheritFactRefs"] = true,
                ["mode"] = "terminate",
                ["target"] = "none",
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["emote"] = {
                    ["id"] = "emote.nod",
                },
                ["speech"] = {
                    ["contentTemplateID"] = "social.acknowledged",
                    ["dialogueAct"] = "ACKNOWLEDGE",
                },
            },
            ["requiredCapabilities"] = {
            },
            ["stimuli"] = {
                "NPC_SEMANTIC_ACT",
            },
            ["version"] = 1,
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/scene/excursion/scene_excursion_acknowledge.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "ACKNOWLEDGE_EXCURSION",
        },
    },
    {
        ["domain"] = "scene",
        ["domainPath"] = "scene/excursion",
        ["id"] = "behavior.scene_excursion_departing",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "scene_excursion_departing",
            ["sourceId"] = "behavior.scene_excursion_departing",
            ["sourcePath"] = "behavior/scene/excursion/scene_excursion_departing.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Scene/Excursion",
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
            ["act"] = "EXCURSION_STATUS_REPORT",
            ["baseRelevance"] = 1,
            ["continuation"] = {
                ["inheritEventRefs"] = true,
                ["inheritFactRefs"] = true,
                ["intent"] = "ACKNOWLEDGE_EXCURSION",
                ["mode"] = "emit",
                ["speechAct"] = "ACKNOWLEDGE",
                ["target"] = "other",
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.scene.excursion_departing",
                    ["dialogueAct"] = "INFORM",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
            },
            ["stimuli"] = {
                "TASK_EVENT",
            },
            ["version"] = 1,
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/scene/excursion/scene_excursion_departing.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "EXCURSION_DEPARTING",
        },
    },
    {
        ["domain"] = "scene",
        ["domainPath"] = "scene/excursion",
        ["id"] = "behavior.scene_excursion_failed",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "scene_excursion_failed",
            ["sourceId"] = "behavior.scene_excursion_failed",
            ["sourcePath"] = "behavior/scene/excursion/scene_excursion_failed.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Scene/Excursion",
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
            ["act"] = "EXCURSION_STATUS_REPORT",
            ["baseRelevance"] = 1,
            ["continuation"] = {
                ["inheritEventRefs"] = true,
                ["inheritFactRefs"] = true,
                ["intent"] = "ACKNOWLEDGE_EXCURSION",
                ["mode"] = "emit",
                ["speechAct"] = "ACKNOWLEDGE",
                ["target"] = "other",
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.scene.excursion_failed",
                    ["dialogueAct"] = "INFORM",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
            },
            ["stimuli"] = {
                "TASK_EVENT",
            },
            ["version"] = 1,
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/scene/excursion/scene_excursion_failed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "EXCURSION_FAILED",
        },
    },
    {
        ["domain"] = "scene",
        ["domainPath"] = "scene/excursion",
        ["id"] = "behavior.scene_excursion_home",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "scene_excursion_home",
            ["sourceId"] = "behavior.scene_excursion_home",
            ["sourcePath"] = "behavior/scene/excursion/scene_excursion_home.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Scene/Excursion",
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
            ["act"] = "EXCURSION_STATUS_REPORT",
            ["baseRelevance"] = 1,
            ["continuation"] = {
                ["inheritEventRefs"] = true,
                ["inheritFactRefs"] = true,
                ["intent"] = "ACKNOWLEDGE_EXCURSION",
                ["mode"] = "emit",
                ["speechAct"] = "ACKNOWLEDGE",
                ["target"] = "other",
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.scene.excursion_home",
                    ["dialogueAct"] = "INFORM",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
            },
            ["stimuli"] = {
                "TASK_EVENT",
            },
            ["version"] = 1,
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/scene/excursion/scene_excursion_home.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "EXCURSION_HOME",
        },
    },
    {
        ["domain"] = "scene",
        ["domainPath"] = "scene/excursion",
        ["id"] = "behavior.scene_excursion_preparing",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "scene_excursion_preparing",
            ["sourceId"] = "behavior.scene_excursion_preparing",
            ["sourcePath"] = "behavior/scene/excursion/scene_excursion_preparing.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Scene/Excursion",
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
            ["act"] = "EXCURSION_STATUS_REPORT",
            ["baseRelevance"] = 1,
            ["continuation"] = {
                ["inheritEventRefs"] = true,
                ["inheritFactRefs"] = true,
                ["intent"] = "ACKNOWLEDGE_EXCURSION",
                ["mode"] = "emit",
                ["speechAct"] = "ACKNOWLEDGE",
                ["target"] = "other",
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.scene.excursion_preparing",
                    ["dialogueAct"] = "INFORM",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
            },
            ["stimuli"] = {
                "TASK_EVENT",
            },
            ["version"] = 1,
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/scene/excursion/scene_excursion_preparing.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "EXCURSION_PREPARING",
        },
    },
    {
        ["domain"] = "scene",
        ["domainPath"] = "scene/excursion",
        ["id"] = "behavior.scene_excursion_returning",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "scene_excursion_returning",
            ["sourceId"] = "behavior.scene_excursion_returning",
            ["sourcePath"] = "behavior/scene/excursion/scene_excursion_returning.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Scene/Excursion",
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
            ["act"] = "EXCURSION_STATUS_REPORT",
            ["baseRelevance"] = 1,
            ["continuation"] = {
                ["inheritEventRefs"] = true,
                ["inheritFactRefs"] = true,
                ["intent"] = "ACKNOWLEDGE_EXCURSION",
                ["mode"] = "emit",
                ["speechAct"] = "ACKNOWLEDGE",
                ["target"] = "other",
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.scene.excursion_returning",
                    ["dialogueAct"] = "INFORM",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
            },
            ["stimuli"] = {
                "TASK_EVENT",
            },
            ["version"] = 1,
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/scene/excursion/scene_excursion_returning.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "EXCURSION_RETURNING",
        },
    },
}
