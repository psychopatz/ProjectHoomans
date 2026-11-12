-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "quest_content",
        ["id"] = "semantic.quest.clinic_supplies.accept.queued.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.quest.clinic_supplies.accept.queued.neutral",
            ["sourcePath"] = "psdl/dialogue/quest_content.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_quest_clinic_supplies_accept_queued_neutral",
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
                ["category"] = "projecthoomans:quest_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.quest",
                ["responseTemplateID"] = "semantic.quest.clinic_supplies.accept.queued",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/quest.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'll bring the clinic supplies.",
                            },
                            ["TL"] = {
                                "Dadalahin ko ang mga suplay ng klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I've got the clinic supply run on my list.",
                            },
                            ["TL"] = {
                                "Nasa listahan ko na ang pagkuha ng suplay para sa klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'll gather the medical gear as soon as I can.",
                            },
                            ["TL"] = {
                                "Kukunin ko ang mga gamot sa lalong madaling panahon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Count on me for the clinic supplies.",
                            },
                            ["TL"] = {
                                "Asahan mo ako sa mga suplay ng klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I'll track down those medical items for you.",
                            },
                            ["TL"] = {
                                "Hahanapin ko ang mga gamot na 'yon para sa'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Queued up. I'll secure those clinic supplies.",
                            },
                            ["TL"] = {
                                "Nakalista na. Kukunin ko ang mga suplay sa klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'm on it. I'll deliver the clinic supplies.",
                            },
                            ["TL"] = {
                                "Ako na bahala. Ihahatid ko ang mga suplay ng klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Medical supplies are queued. I'll get them.",
                            },
                            ["TL"] = {
                                "Nakatala na ang mga medikal na suplay. Kukunin ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'll fetch what the clinic needs.",
                            },
                            ["TL"] = {
                                "Kukunin ko kung ano ang kailangan ng klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Accepted. I'll bring back those clinic supplies.",
                            },
                            ["TL"] = {
                                "Tinanggap ko na. Dadalhin ko pabalik ang mga suplay sa klinika.",
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
        ["sourceShard"] = "psdl/dialogue/quest_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
