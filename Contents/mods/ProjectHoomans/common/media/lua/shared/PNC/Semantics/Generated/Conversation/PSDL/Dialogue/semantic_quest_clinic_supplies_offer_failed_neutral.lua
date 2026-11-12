-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "quest_content",
        ["id"] = "semantic.quest.clinic_supplies.offer.failed.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.quest.clinic_supplies.offer.failed.neutral",
            ["sourcePath"] = "psdl/dialogue/quest_content.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_quest_clinic_supplies_offer_failed_neutral",
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
                ["responseTemplateID"] = "semantic.quest.clinic_supplies.offer.failed",
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
                                "I couldn't check that clinic-supplies request.",
                            },
                            ["TL"] = {
                                "Hindi ko masuri ang kahilingan para sa suplay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to look over the clinic supply offer.",
                            },
                            ["TL"] = {
                                "Hindi ko masilip ang alok sa suplay ng klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "The offer couldn't be processed.",
                            },
                            ["TL"] = {
                                "Hindi maproseso ang alok na 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Something went wrong while checking the medical offer.",
                            },
                            ["TL"] = {
                                "May nagkaproblema habang sinusuri ang medikal na alok.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't review the supplies request just now.",
                            },
                            ["TL"] = {
                                "Hindi masuri ang kahilingan sa suplay ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't verify that clinic offer.",
                            },
                            ["TL"] = {
                                "Hindi ko makumpirma ang alok na 'yon sa klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to inspect the clinic supplies details.",
                            },
                            ["TL"] = {
                                "Bigo sa pagsusuri ng detalye ng suplay sa klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I wasn't able to review that request.",
                            },
                            ["TL"] = {
                                "Hindi ko nasuri ang kahilingang iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Could not check the medical offer properly.",
                            },
                            ["TL"] = {
                                "Hindi maayos na nasuri ang medikal na alok.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Checking that offer didn't work out.",
                            },
                            ["TL"] = {
                                "Hindi gumana ang pagsusuri sa alok na 'yon.",
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
