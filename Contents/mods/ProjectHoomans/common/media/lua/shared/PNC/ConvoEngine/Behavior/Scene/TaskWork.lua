-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "scene",
        ["domainPath"] = "scene/task_work",
        ["id"] = "behavior.scene_task_work_assigned",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "scene_task_work_assigned",
            ["sourceId"] = "behavior.scene_task_work_assigned",
            ["sourcePath"] = "behavior/scene/task_work/scene_task_work_assigned.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Scene/TaskWork",
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
            ["act"] = "TASK_WORK_STATUS",
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
                    ["contentTemplateID"] = "interaction.scene.task_work_assigned",
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
        ["sourceShard"] = "behavior/scene/task_work/scene_task_work_assigned.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "TASK_WORK_ASSIGNED",
        },
    },
    {
        ["domain"] = "scene",
        ["domainPath"] = "scene/task_work",
        ["id"] = "behavior.scene_task_work_completed",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "scene_task_work_completed",
            ["sourceId"] = "behavior.scene_task_work_completed",
            ["sourcePath"] = "behavior/scene/task_work/scene_task_work_completed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Scene/TaskWork",
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
            ["act"] = "TASK_WORK_STATUS",
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
                    ["contentTemplateID"] = "interaction.scene.task_work_completed",
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
        ["sourceShard"] = "behavior/scene/task_work/scene_task_work_completed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "TASK_WORK_COMPLETED",
        },
    },
}
