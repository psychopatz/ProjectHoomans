-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "quest_content",
        ["id"] = "semantic.quest.clinic_supplies.turn_in.failed.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.quest.clinic_supplies.turn_in.failed.neutral",
            ["sourcePath"] = "psdl/dialogue/quest_content.json#records[9]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_quest_clinic_supplies_turn_in_failed_neutral",
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
                ["responseTemplateID"] = "semantic.quest.clinic_supplies.turn_in.failed",
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
                                "I couldn't turn in the clinic supplies.",
                            },
                            ["TL"] = {
                                "Hindi ko maipasa ang mga suplay ng klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Something went wrong handing over the medical gear.",
                            },
                            ["TL"] = {
                                "May nagkaproblema sa pag-abot ng mga medikal na gamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Turn-in failed. Check if we have every item.",
                            },
                            ["TL"] = {
                                "Bigo ang pagpasa. Tignan kung kumpleto ang bawat gamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to complete the clinic supply delivery.",
                            },
                            ["TL"] = {
                                "Hindi makumpleto ang paghahatid ng suplay sa klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I wasn't able to drop off the clinic supplies.",
                            },
                            ["TL"] = {
                                "Hindi ko naibigay ang mga suplay para sa klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to hand in the requested medical items.",
                            },
                            ["TL"] = {
                                "Bigo sa pagpasa ng hinihiling na medikal na kagamitan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't finalize the clinic supplies handover.",
                            },
                            ["TL"] = {
                                "Hindi matapos ang paglilipat ng suplay sa klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Delivery of clinic goods couldn't be registered.",
                            },
                            ["TL"] = {
                                "Hindi naitala ang paghahatid ng gamit sa klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Could not complete the turn-in for the clinic.",
                            },
                            ["TL"] = {
                                "Hindi makumpleto ang pagpasa para sa klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Turn-in was unsuccessful. Try again.",
                            },
                            ["TL"] = {
                                "Hindi nagtagumpay ang pagpasa. Subukan ulit.",
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
