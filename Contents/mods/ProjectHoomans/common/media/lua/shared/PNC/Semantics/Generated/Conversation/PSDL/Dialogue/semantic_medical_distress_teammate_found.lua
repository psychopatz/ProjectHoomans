-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_teammate",
        ["id"] = "semantic.medical.distress.teammate.found",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.teammate.found",
            ["sourcePath"] = "psdl/dialogue/medical_event_teammate.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_medical_distress_teammate_found",
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
                ["category"] = "projecthoomans:medical_event",
                ["responseTemplateID"] = "semantic.medical.distress.teammate.found",
                ["sourceSurface"] = "content/event/medical/teammate.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.found.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I found a bandage for them. Hold still while I patch them up.",
                            },
                            ["TL"] = {
                                "Nakahanap ako ng benda para sa kanila. Huwag kang gagalaw habang ginagamot ko sila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.found.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Got a dressing right here. Wrapping the wound now.",
                            },
                            ["TL"] = {
                                "May pambenda ako rito. Binabalot ko na ang sugat ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.found.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Found medical supplies! Hold on, I'm dressing the injury.",
                            },
                            ["TL"] = {
                                "Nakahanap ako ng gamot! Kapit lang, ginagamot ko na ang pinsala.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.found.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I've got clean cloth. Hold steady while I bind it.",
                            },
                            ["TL"] = {
                                "May malinis akong tela. Manatiling nakapirmi habang itinatali ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.found.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Located a bandage. Applying pressure to their cut now.",
                            },
                            ["TL"] = {
                                "May nahanap na benda. Dinidiinan ko na ang hiwa nila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.found.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I've got medical wrap. Don't squirm, I'm securing it.",
                            },
                            ["TL"] = {
                                "May medical wrap ako. Huwag kang pumalag, inaayos ko na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.found.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Found supplies for them. Wrapping it up tightly now.",
                            },
                            ["TL"] = {
                                "May nahanap na gamit para sa kanila. Binabalot ko na nang mahigpit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.found.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Got the bandage ready. Applying it to the laceration.",
                            },
                            ["TL"] = {
                                "Handa na ang benda. Nilalapat ko na sa sugat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.found.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I have aid gear. Hold still, you'll be stable in a minute.",
                            },
                            ["TL"] = {
                                "May gamit ako rito. Huwag gagalaw, magiging maayos ka rin agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.found.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Bandage in hand! Dressing their wounds right now.",
                            },
                            ["TL"] = {
                                "Hawak ko na ang benda! Ginagamot ko na ang mga sugat nila.",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_teammate.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
