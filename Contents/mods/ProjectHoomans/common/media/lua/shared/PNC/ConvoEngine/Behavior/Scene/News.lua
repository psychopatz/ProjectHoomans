-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "scene",
        ["domainPath"] = "scene/news",
        ["id"] = "behavior.scene_grounded_news_share",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "scene_grounded_news_share",
            ["sourceId"] = "behavior.scene_grounded_news_share",
            ["sourcePath"] = "behavior/scene/news/scene_grounded_news_share.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Scene/News",
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
            ["act"] = "SHARE_NEWS",
            ["baseRelevance"] = 1,
            ["continuation"] = {
                ["inheritEventRefs"] = true,
                ["inheritFactRefs"] = true,
                ["intent"] = "SHARE_GROUNDED_NEWS",
                ["mode"] = "emit",
                ["speechAct"] = "INFORM",
                ["target"] = "other",
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.scene.grounded_news_share",
                    ["dialogueAct"] = "DISCLOSE",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
            },
            ["stimuli"] = {
                "AMBIENT_SOCIAL_OPPORTUNITY",
            },
            ["version"] = 1,
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/scene/news/scene_grounded_news_share.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "SHARE_GROUNDED_NEWS",
        },
    },
    {
        ["domain"] = "scene",
        ["domainPath"] = "scene/news",
        ["id"] = "behavior.scene_news_followup",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "scene_news_followup",
            ["sourceId"] = "behavior.scene_news_followup",
            ["sourcePath"] = "behavior/scene/news/scene_news_followup.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Scene/News",
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
            ["act"] = "ASK_NEWS_FOLLOWUP",
            ["baseRelevance"] = 0.45,
            ["continuation"] = {
                ["inheritEventRefs"] = true,
                ["inheritFactRefs"] = true,
                ["intent"] = "ASK_NEWS_FOLLOWUP",
                ["mode"] = "emit",
                ["speechAct"] = "ASK_FOLLOWUP",
                ["target"] = "source",
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
                {
                    ["delta"] = 0.25,
                    ["reason"] = "sociability_favors_news_followup",
                    ["when"] = {
                        ["op"] = "gte",
                        ["path"] = "actor.disposition.sociability",
                        ["value"] = 0.6,
                    },
                },
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.memory.followup",
                    ["dialogueAct"] = "ASK_FOLLOWUP",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
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
        ["sourceShard"] = "behavior/scene/news/scene_news_followup.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "SHARE_GROUNDED_NEWS",
        },
    },
    {
        ["domain"] = "scene",
        ["domainPath"] = "scene/news",
        ["id"] = "behavior.scene_news_followup_answer",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "scene_news_followup_answer",
            ["sourceId"] = "behavior.scene_news_followup_answer",
            ["sourcePath"] = "behavior/scene/news/scene_news_followup_answer.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Scene/News",
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
            ["act"] = "ANSWER_NEWS",
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
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.scene.grounded_news_answer",
                    ["dialogueAct"] = "ANSWER",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
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
        ["sourceShard"] = "behavior/scene/news/scene_news_followup_answer.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "ASK_NEWS_FOLLOWUP",
        },
    },
}
