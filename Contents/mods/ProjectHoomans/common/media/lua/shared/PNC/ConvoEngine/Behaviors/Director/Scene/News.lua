-- Generated; do not edit by hand.
return {
    {
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
        ["domain"] = "scene",
        ["domainPath"] = "scene/news",
        ["id"] = "behavior.scene_grounded_news_share",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "interaction.scene.grounded_news_share",
                ["dialogueAct"] = "DISCLOSE",
            },
        },
        ["owner"] = "ProjectHoomans",
        ["requiredCapabilities"] = {
            "speech",
        },
        ["stimuli"] = {
            "AMBIENT_SOCIAL_OPPORTUNITY",
        },
        ["version"] = 1,
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "SHARE_GROUNDED_NEWS",
        },
    },
    {
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
        ["domain"] = "scene",
        ["domainPath"] = "scene/news",
        ["id"] = "behavior.scene_news_followup",
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
            ["value"] = "SHARE_GROUNDED_NEWS",
        },
    },
    {
        ["act"] = "ANSWER_NEWS",
        ["baseRelevance"] = 1,
        ["continuation"] = {
            ["inheritEventRefs"] = true,
            ["inheritFactRefs"] = true,
            ["mode"] = "terminate",
            ["target"] = "none",
        },
        ["domain"] = "scene",
        ["domainPath"] = "scene/news",
        ["id"] = "behavior.scene_news_followup_answer",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "interaction.scene.grounded_news_answer",
                ["dialogueAct"] = "ANSWER",
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
            ["value"] = "ASK_NEWS_FOLLOWUP",
        },
    },
}
