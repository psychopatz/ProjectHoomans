-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_call",
        ["id"] = "semantic.medical.distress.call.dehydration",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.call.dehydration",
            ["sourcePath"] = "psdl/dialogue/medical_event_call.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_medical_distress_call_dehydration",
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
                ["responseTemplateID"] = "semantic.medical.distress.call.dehydration",
                ["sourceSurface"] = "content/event/medical/call.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.dehydration.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "So thirsty... I need water before I pass out.",
                            },
                            ["TL"] = {
                                "Uhaw na uhaw na ako... kailangan ko ng tubig bago ako mahimatay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.dehydration.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Throat is completely parched... please, any water?",
                            },
                            ["TL"] = {
                                "Tuyong-tuyo na ang lalamunan ko... pakiusap, may tubig ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.dehydration.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Drying out... can barely swallow. Water, please.",
                            },
                            ["TL"] = {
                                "Nanghihina sa uhaw... halos hindi makalunok. Tubig, pakiusap.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.dehydration.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm too dehydrated to move my legs. Water...",
                            },
                            ["TL"] = {
                                "Masyado akong dehydrated para maigalaw ang binti ko. Tubig...",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.dehydration.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Give me a sip of water... dying of thirst.",
                            },
                            ["TL"] = {
                                "Pahingi ng kahit kaunting tubig... mamamatay na ako sa uhaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.dehydration.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Lips are cracked and bleeding... need clean water.",
                            },
                            ["TL"] = {
                                "Nangangapal at nagdurugo ang labi ko... kailangan ng malinis na tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.dehydration.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't walk anymore... please bring a water bottle.",
                            },
                            ["TL"] = {
                                "Hindi na makalakad... pakiusap dalhan mo ako ng tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.dehydration.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Head is pounding from dehydration... need a drink.",
                            },
                            ["TL"] = {
                                "Pumipintig ang ulo ko sa uhaw... kailangang uminom.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.dehydration.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm collapsing... just a few drops of water.",
                            },
                            ["TL"] = {
                                "Bumabagsak na ako... kahit ilang patak lang ng tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.dehydration.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Water... please, someone hand me water.",
                            },
                            ["TL"] = {
                                "Tubig... pakiusap, bigyan niyo ako ng tubig.",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_call.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
