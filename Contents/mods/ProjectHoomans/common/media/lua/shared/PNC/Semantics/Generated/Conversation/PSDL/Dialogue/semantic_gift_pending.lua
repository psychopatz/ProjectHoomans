-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.gift.pending",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.gift.pending",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[22]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_gift_pending",
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
                ["responseTemplateID"] = "semantic.gift.pending",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/gift.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'll take a look at that gift.",
                            },
                            ["TL"] = {
                                "Titingnan ko ang regalong iyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Let's see what you brought.",
                            },
                            ["TL"] = {
                                "Tingnan natin kung ano ang dala mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Considering the gift now.",
                            },
                            ["TL"] = {
                                "Tinitingnan ang regalo ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Inspecting what you have for me.",
                            },
                            ["TL"] = {
                                "Sinusuri ang handog mo para sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Hold on, looking at the offering.",
                            },
                            ["TL"] = {
                                "Teka, tinitingnan ang iniaalok.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'll review the item you offered.",
                            },
                            ["TL"] = {
                                "Susuriin ko ang bagay na inialok mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Checking out the gift.",
                            },
                            ["TL"] = {
                                "Tinitingnan ang regalo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Let me examine what this is.",
                            },
                            ["TL"] = {
                                "Hayaan mong tingnan ko kung ano ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Looking over your gift.",
                            },
                            ["TL"] = {
                                "Sinusuri ang regalo mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Give me a second to check this item.",
                            },
                            ["TL"] = {
                                "Bigyan mo ako ng sandali para tingnan ang gamit na ito.",
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
