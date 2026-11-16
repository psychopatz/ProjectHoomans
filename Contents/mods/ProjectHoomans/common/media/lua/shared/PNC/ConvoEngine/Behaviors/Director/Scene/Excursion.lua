-- Generated; do not edit by hand.
return {
    {
        ["act"] = "ACKNOWLEDGE",
        ["baseRelevance"] = 1,
        ["continuation"] = {
            ["inheritEventRefs"] = true,
            ["inheritFactRefs"] = true,
            ["mode"] = "terminate",
            ["target"] = "none",
        },
        ["domain"] = "scene",
        ["domainPath"] = "scene/excursion",
        ["id"] = "behavior.scene_excursion_acknowledge",
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
            ["value"] = "ACKNOWLEDGE_EXCURSION",
        },
    },
    {
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
        ["domain"] = "scene",
        ["domainPath"] = "scene/excursion",
        ["id"] = "behavior.scene_excursion_departing",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "interaction.scene.excursion_departing",
                ["dialogueAct"] = "INFORM",
            },
        },
        ["owner"] = "ProjectHoomans",
        ["requiredCapabilities"] = {
            "speech",
        },
        ["stimuli"] = {
            "TASK_EVENT",
        },
        ["version"] = 1,
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "EXCURSION_DEPARTING",
        },
    },
    {
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
        ["domain"] = "scene",
        ["domainPath"] = "scene/excursion",
        ["id"] = "behavior.scene_excursion_failed",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "interaction.scene.excursion_failed",
                ["dialogueAct"] = "INFORM",
            },
        },
        ["owner"] = "ProjectHoomans",
        ["requiredCapabilities"] = {
            "speech",
        },
        ["stimuli"] = {
            "TASK_EVENT",
        },
        ["version"] = 1,
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "EXCURSION_FAILED",
        },
    },
    {
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
        ["domain"] = "scene",
        ["domainPath"] = "scene/excursion",
        ["id"] = "behavior.scene_excursion_home",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "interaction.scene.excursion_home",
                ["dialogueAct"] = "INFORM",
            },
        },
        ["owner"] = "ProjectHoomans",
        ["requiredCapabilities"] = {
            "speech",
        },
        ["stimuli"] = {
            "TASK_EVENT",
        },
        ["version"] = 1,
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "EXCURSION_HOME",
        },
    },
    {
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
        ["domain"] = "scene",
        ["domainPath"] = "scene/excursion",
        ["id"] = "behavior.scene_excursion_preparing",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "interaction.scene.excursion_preparing",
                ["dialogueAct"] = "INFORM",
            },
        },
        ["owner"] = "ProjectHoomans",
        ["requiredCapabilities"] = {
            "speech",
        },
        ["stimuli"] = {
            "TASK_EVENT",
        },
        ["version"] = 1,
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "EXCURSION_PREPARING",
        },
    },
    {
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
        ["domain"] = "scene",
        ["domainPath"] = "scene/excursion",
        ["id"] = "behavior.scene_excursion_returning",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "interaction.scene.excursion_returning",
                ["dialogueAct"] = "INFORM",
            },
        },
        ["owner"] = "ProjectHoomans",
        ["requiredCapabilities"] = {
            "speech",
        },
        ["stimuli"] = {
            "TASK_EVENT",
        },
        ["version"] = 1,
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "EXCURSION_RETURNING",
        },
    },
}
