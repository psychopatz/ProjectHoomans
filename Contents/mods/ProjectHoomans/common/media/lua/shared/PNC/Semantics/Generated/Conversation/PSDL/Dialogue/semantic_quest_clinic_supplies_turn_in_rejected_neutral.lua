-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "quest_content",
        ["id"] = "semantic.quest.clinic_supplies.turn_in.rejected.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.quest.clinic_supplies.turn_in.rejected.neutral",
            ["sourcePath"] = "psdl/dialogue/quest_content.json#records[11]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_quest_clinic_supplies_turn_in_rejected_neutral",
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
                ["responseTemplateID"] = "semantic.quest.clinic_supplies.turn_in.rejected",
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
                                "I can't turn that in yet.",
                            },
                            ["TL"] = {
                                "Hindi ko pa maipapasa iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "We don't have everything needed for the clinic yet.",
                            },
                            ["TL"] = {
                                "Wala pa sa atin ang lahat ng kailangan para sa klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Supplies aren't complete. Can't hand them over.",
                            },
                            ["TL"] = {
                                "Kulang pa ang mga suplay. Hindi pa pwedeng iabot.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I have to decline turning this in right now.",
                            },
                            ["TL"] = {
                                "Kailangan kong tanggihan ang pagpasa nito ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Not ready for turn-in. Missing items.",
                            },
                            ["TL"] = {
                                "Hindi pa handa sa pagpasa. May kulang na gamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Can't drop these off yet. Double-check our pack.",
                            },
                            ["TL"] = {
                                "Hindi pa maibibigay 'to. Tignan ulit ang bag natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I won't turn in an incomplete medical bundle.",
                            },
                            ["TL"] = {
                                "Hindi ako magpapasa ng kulang na medikal na gamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Hold on, we can't submit these clinic supplies yet.",
                            },
                            ["TL"] = {
                                "Sandali, hindi pa natin maipapasa ang mga suplay sa klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Delivery cannot be accepted until all items are present.",
                            },
                            ["TL"] = {
                                "Hindi matatanggap ang hatid hangga't kulang ang mga gamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Can't finalize the clinic hand-in at this stage.",
                            },
                            ["TL"] = {
                                "Hindi matatapos ang pagpasa sa klinika sa yugtong ito.",
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
