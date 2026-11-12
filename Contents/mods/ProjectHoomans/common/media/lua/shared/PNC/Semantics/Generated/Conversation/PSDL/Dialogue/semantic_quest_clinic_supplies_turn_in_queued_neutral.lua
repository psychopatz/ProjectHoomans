-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "quest_content",
        ["id"] = "semantic.quest.clinic_supplies.turn_in.queued.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.quest.clinic_supplies.turn_in.queued.neutral",
            ["sourcePath"] = "psdl/dialogue/quest_content.json#records[10]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_quest_clinic_supplies_turn_in_queued_neutral",
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
                ["responseTemplateID"] = "semantic.quest.clinic_supplies.turn_in.queued",
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
                                "I'll turn in the clinic supplies.",
                            },
                            ["TL"] = {
                                "Ipapasa ko ang mga suplay ng klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I'm heading over to drop off the medical items.",
                            },
                            ["TL"] = {
                                "Pupunta na ako para iabot ang mga medikal na gamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'll deliver the clinic supplies right away.",
                            },
                            ["TL"] = {
                                "Ihahatid ko agad ang mga suplay ng klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Queued to hand over the medical gear.",
                            },
                            ["TL"] = {
                                "Nakatakdang iabot ang mga medikal na gamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I will submit the clinic supplies now.",
                            },
                            ["TL"] = {
                                "Ipapasa ko na ang mga suplay sa klinika ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Taking these supplies over to the clinic station.",
                            },
                            ["TL"] = {
                                "Dadalhin ko na ang mga suplay na 'to sa klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'll deposit the medical items as requested.",
                            },
                            ["TL"] = {
                                "Ilalagak ko ang mga medikal na gamit tulad ng hiniling.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Handing in the clinic goods now.",
                            },
                            ["TL"] = {
                                "Iniaabot ko na ang mga gamit sa klinika ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'll complete the delivery of the clinic supplies.",
                            },
                            ["TL"] = {
                                "Tatapusin ko ang paghahatid ng suplay sa klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Off to turn in our gathered clinic supplies.",
                            },
                            ["TL"] = {
                                "Aalis na para ipasa ang naipon nating suplay sa klinika.",
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
