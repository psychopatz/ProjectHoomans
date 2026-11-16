-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "scene",
        ["domainPath"] = "scene/post_combat",
        ["id"] = "behavior.scene_post_combat_clear",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "scene_post_combat_clear",
            ["sourceId"] = "behavior.scene_post_combat_clear",
            ["sourcePath"] = "behavior/scene/post_combat/scene_post_combat_clear.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Scene/PostCombat",
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
            ["act"] = "POST_COMBAT_REACTION",
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
                    ["contentTemplateID"] = "interaction.scene.post_combat_clear",
                    ["dialogueAct"] = "INFORM",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
            },
            ["stimuli"] = {
                "DANGER_CHANGED",
            },
            ["version"] = 1,
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/scene/post_combat/scene_post_combat_clear.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "POST_COMBAT_CLEAR",
        },
    },
}
