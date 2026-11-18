-- Generated; do not edit by hand.
return {
    {
        ["act"] = "POST_COMBAT_REACTION",
        ["baseRelevance"] = 1,
        ["continuation"] = {
            ["inheritEventRefs"] = true,
            ["inheritFactRefs"] = true,
            ["mode"] = "terminate",
            ["target"] = "none",
        },
        ["domain"] = "scene",
        ["domainPath"] = "scene/post_combat",
        ["domains"] = {
            {
                ["domain"] = "combat",
                ["owner"] = "ProjectHoomans",
            },
        },
        ["events"] = {
            {
                ["id"] = "combat_event",
                ["kind"] = "combat_event",
            },
        },
        ["id"] = "behavior.scene_post_combat_clear",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "interaction.scene.post_combat_clear",
                ["dialogueAct"] = "INFORM",
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
            ["value"] = "POST_COMBAT_CLEAR",
        },
    },
}
