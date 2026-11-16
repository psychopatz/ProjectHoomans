-- Generated; do not edit by hand.
return {
    {
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
        ["domain"] = "scene",
        ["domainPath"] = "scene/horde",
        ["id"] = "behavior.scene_horde_prompt",
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
        ["owner"] = "ProjectHoomans",
        ["requiredCapabilities"] = {
            "speech",
        },
        ["stimuli"] = {
            "DANGER_CHANGED",
        },
        ["version"] = 1,
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "COMBAT_HORDE_ALERT",
        },
    },
    {
        ["act"] = "COMBAT_HORDE_REPLY",
        ["baseRelevance"] = 1,
        ["continuation"] = {
            ["inheritEventRefs"] = true,
            ["inheritFactRefs"] = true,
            ["mode"] = "terminate",
            ["target"] = "none",
        },
        ["domain"] = "scene",
        ["domainPath"] = "scene/horde",
        ["id"] = "behavior.scene_horde_reply_brave",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "interaction.scene.horde_reply_brave",
                ["dialogueAct"] = "PROPOSE_ENGAGE",
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
        ["act"] = "COMBAT_HORDE_REPLY",
        ["baseRelevance"] = 1,
        ["continuation"] = {
            ["inheritEventRefs"] = true,
            ["inheritFactRefs"] = true,
            ["mode"] = "terminate",
            ["target"] = "none",
        },
        ["domain"] = "scene",
        ["domainPath"] = "scene/horde",
        ["id"] = "behavior.scene_horde_reply_cautious",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "interaction.scene.horde_reply_cautious",
                ["dialogueAct"] = "PROPOSE_AVOID",
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
        ["act"] = "COMBAT_HORDE_REPLY",
        ["baseRelevance"] = 0.65,
        ["continuation"] = {
            ["inheritEventRefs"] = true,
            ["inheritFactRefs"] = true,
            ["mode"] = "terminate",
            ["target"] = "none",
        },
        ["domain"] = "scene",
        ["domainPath"] = "scene/horde",
        ["id"] = "behavior.scene_horde_reply_steady",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "interaction.scene.horde_reply_steady",
                ["dialogueAct"] = "PROPOSE_HOLD",
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
            ["value"] = "COMBAT_HORDE_REPLY",
        },
    },
}
