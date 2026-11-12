-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.fetch.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.task.fetch.failed",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[18]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_task_fetch_failed",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.fetch.failed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/fetch.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't fetch that.",
                            },
                            ["TL"] = {
                                "Hindi ko nakuha iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to retrieve the item.",
                            },
                            ["TL"] = {
                                "Bigo sa pagkuha ng gamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "The item wasn't there or was destroyed.",
                            },
                            ["TL"] = {
                                "Wala roon ang gamit o kaya'y nasira na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Way was blocked. Couldn't reach it.",
                            },
                            ["TL"] = {
                                "May harang sa daan. Di ko naabot.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Hostiles prevented me from grabbing it.",
                            },
                            ["TL"] = {
                                "Pumigil ang mga kalaban sa pagkuha ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to fetch that from that container.",
                            },
                            ["TL"] = {
                                "Di makuha 'yon mula sa lalagyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Lost access to the item. Fetch failed.",
                            },
                            ["TL"] = {
                                "Nawalan ng daan sa gamit. Bigo ang pagkuha.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't find what you were pointing to.",
                            },
                            ["TL"] = {
                                "Di ko nahanap ang itinuturo mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Inventory full or path obstructed. Failed.",
                            },
                            ["TL"] = {
                                "Puno ang bag o may harang sa daan. Bigo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't get to the target item.",
                            },
                            ["TL"] = {
                                "Di makarating sa puntiryang gamit.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
