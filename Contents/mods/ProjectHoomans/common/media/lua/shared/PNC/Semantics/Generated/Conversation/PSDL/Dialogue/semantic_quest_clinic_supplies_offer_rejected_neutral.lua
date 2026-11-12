-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "quest_content",
        ["id"] = "semantic.quest.clinic_supplies.offer.rejected.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.quest.clinic_supplies.offer.rejected.neutral",
            ["sourcePath"] = "psdl/dialogue/quest_content.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_quest_clinic_supplies_offer_rejected_neutral",
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
                ["responseTemplateID"] = "semantic.quest.clinic_supplies.offer.rejected",
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
                                "I can't take that clinic-supplies request right now.",
                            },
                            ["TL"] = {
                                "Hindi ko matatanggap ang kahilingan para sa suplay ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I have to turn down the clinic offer for now.",
                            },
                            ["TL"] = {
                                "Kailangan kong tanggihan ang alok sa klinika sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Not able to help with medical supplies today.",
                            },
                            ["TL"] = {
                                "Hindi makakatulong sa mga medikal na suplay ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I can't sign up for that clinic mission.",
                            },
                            ["TL"] = {
                                "Hindi ako makakasali sa misyong 'yan sa klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Must decline the clinic supplies offer.",
                            },
                            ["TL"] = {
                                "Kailangang tanggihan ang alok na suplay sa klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I can't accept the offer at this time.",
                            },
                            ["TL"] = {
                                "Hindi ko matatanggap ang alok sa panahong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Medical supply run isn't something I can do now.",
                            },
                            ["TL"] = {
                                "Hindi ko kayang gawin ang pagkuha ng medikal na suplay ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'll have to pass on this clinic offer.",
                            },
                            ["TL"] = {
                                "Lalagpasan ko muna ang alok na 'to para sa klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Can't take on the medical task right now.",
                            },
                            ["TL"] = {
                                "Hindi maaring hawakan ang medikal na gawain ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I must reject that offer for the moment.",
                            },
                            ["TL"] = {
                                "Kailangan kong tanggihan ang alok na 'yan sa sandaling ito.",
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
