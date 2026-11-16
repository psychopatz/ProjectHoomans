-- Generated; do not edit by hand.
return {
    {
        ["act"] = "TASK_WORK_STATUS",
        ["baseRelevance"] = 1,
        ["continuation"] = {
            ["inheritEventRefs"] = true,
            ["inheritFactRefs"] = true,
            ["mode"] = "terminate",
            ["target"] = "none",
        },
        ["domain"] = "scene",
        ["domainPath"] = "scene/task_work",
        ["id"] = "behavior.scene_task_work_assigned",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "interaction.scene.task_work_assigned",
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
            ["value"] = "TASK_WORK_ASSIGNED",
        },
    },
    {
        ["act"] = "TASK_WORK_STATUS",
        ["baseRelevance"] = 1,
        ["continuation"] = {
            ["inheritEventRefs"] = true,
            ["inheritFactRefs"] = true,
            ["mode"] = "terminate",
            ["target"] = "none",
        },
        ["domain"] = "scene",
        ["domainPath"] = "scene/task_work",
        ["id"] = "behavior.scene_task_work_completed",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "interaction.scene.task_work_completed",
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
            ["value"] = "TASK_WORK_COMPLETED",
        },
    },
}
