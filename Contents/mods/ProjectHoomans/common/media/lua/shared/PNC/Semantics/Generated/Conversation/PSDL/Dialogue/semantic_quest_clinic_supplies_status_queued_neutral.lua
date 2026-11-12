-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "quest_content",
        ["id"] = "semantic.quest.clinic_supplies.status.queued.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.quest.clinic_supplies.status.queued.neutral",
            ["sourcePath"] = "psdl/dialogue/quest_content.json#records[7]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_quest_clinic_supplies_status_queued_neutral",
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
                ["responseTemplateID"] = "semantic.quest.clinic_supplies.status.queued",
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
                                "I'll check the clinic-supplies request.",
                            },
                            ["TL"] = {
                                "Susuriin ko ang kahilingan para sa suplay ng klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I'll see how we're doing on those medical supplies.",
                            },
                            ["TL"] = {
                                "Titingnan ko kung kamusta na ang mga medikal na suplay natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Checking our progress on the clinic gear now.",
                            },
                            ["TL"] = {
                                "Sinusuri na ang progreso natin sa gamot para sa klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'll look into the status of the clinic task.",
                            },
                            ["TL"] = {
                                "Sisiyasatin ko ang katayuan ng gawain sa klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Reviewing where we stand with the clinic supplies.",
                            },
                            ["TL"] = {
                                "Sinusuri kung nasaan na tayo sa mga suplay ng klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'll pull up the clinic supply checklist.",
                            },
                            ["TL"] = {
                                "Kukunin ko ang listahan ng suplay para sa klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Let me verify our clinic supplies count.",
                            },
                            ["TL"] = {
                                "Hayaan mong kumpirmahin ko ang bilang ng suplay sa klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'm checking the medical supplies progress.",
                            },
                            ["TL"] = {
                                "Sinusuri ko ang progreso ng mga medikal na suplay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'll inspect the clinic supplies status for you.",
                            },
                            ["TL"] = {
                                "Titingnan ko ang katayuan ng suplay sa klinika para sa'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Looking into the clinic request right now.",
                            },
                            ["TL"] = {
                                "Sinisiyasat ko na ang kahilingan ng klinika ngayon.",
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
