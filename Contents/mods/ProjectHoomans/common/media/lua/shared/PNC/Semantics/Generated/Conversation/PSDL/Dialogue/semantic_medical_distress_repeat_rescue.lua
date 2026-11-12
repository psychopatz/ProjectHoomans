-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_repeat",
        ["id"] = "semantic.medical.distress.repeat.rescue",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.repeat.rescue",
            ["sourcePath"] = "psdl/dialogue/medical_event_repeat.json#records[6]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_medical_distress_repeat_rescue",
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
                ["responseTemplateID"] = "semantic.medical.distress.repeat.rescue",
                ["sourceSurface"] = "content/event/medical/repeat.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.rescue.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I am still down here! Do not leave me!",
                            },
                            ["TL"] = {
                                "Nandito pa rin ako sa sahig! Huwag niyo akong iwan!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.rescue.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't abandon me! Come back and pull me out!",
                            },
                            ["TL"] = {
                                "Huwag niyo akong iwanan! Bumalik kayo at hilahin ako palabas!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.rescue.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still trapped in this spot! Need someone here!",
                            },
                            ["TL"] = {
                                "Naipit pa rin sa pwestong 'to! Kailangan ko ng tao rito!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.rescue.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Where are you going?! I can't walk!",
                            },
                            ["TL"] = {
                                "Saan ka pupunta?! Hindi ako makalakad!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.rescue.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Please come back! I'm completely stranded!",
                            },
                            ["TL"] = {
                                "Pakiusap bumalik ka! Nastranded ako nang buo!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.rescue.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't walk away from my cries! Help me!",
                            },
                            ["TL"] = {
                                "Huwag mong talikuran ang tawag ko! Tulungan mo ako!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.rescue.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still stuck under this weight! Lift it off!",
                            },
                            ["TL"] = {
                                "Naipit pa rin sa bigat na 'to! Buhatin mo 'to!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.rescue.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm still here! Get me out before they find me!",
                            },
                            ["TL"] = {
                                "Nandito pa rin ako! Ilabas mo ako bago nila ako makita!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.rescue.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Rescue me, damn it! I can't drag myself!",
                            },
                            ["TL"] = {
                                "Saklolohan mo ako! Hindi ko kayang kaladkarin ang sarili ko!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.rescue.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't leave me behind to rot! Come back!",
                            },
                            ["TL"] = {
                                "Huwag mo akong iwang mabulok dito! Bumalik ka!",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_repeat.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
