-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "quest_content",
        ["id"] = "semantic.quest.clinic_supplies.accept.failed.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.quest.clinic_supplies.accept.failed.neutral",
            ["sourcePath"] = "psdl/dialogue/quest_content.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_quest_clinic_supplies_accept_failed_neutral",
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
                ["responseTemplateID"] = "semantic.quest.clinic_supplies.accept.failed",
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
                                "I couldn't accept that request.",
                            },
                            ["TL"] = {
                                "Hindi ko matanggap ang kahilingang iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Something went wrong. I couldn't take that on.",
                            },
                            ["TL"] = {
                                "May nagkaproblema. Hindi ko magawang tanggapin 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I wasn't able to accept the clinic supply run.",
                            },
                            ["TL"] = {
                                "Hindi ko nagawang tanggapin ang pagkuha ng suplay sa klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to commit to that medical task right now.",
                            },
                            ["TL"] = {
                                "Hindi makakapangako sa medikal na gawaing 'yan ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "The request failed to go through on my end.",
                            },
                            ["TL"] = {
                                "Hindi pumasok ang kahilingan sa panig ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I can't lock that clinic mission in.",
                            },
                            ["TL"] = {
                                "Hindi ko maitalaga ang misyong 'yan sa klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't confirm that request. Try again later.",
                            },
                            ["TL"] = {
                                "Hindi makumpirma ang kahilingang 'yan. Subukan ulit mamaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Accepting that task didn't work out.",
                            },
                            ["TL"] = {
                                "Hindi nagtagumpay ang pagtanggap sa gawaing 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't take on the supplies task right now.",
                            },
                            ["TL"] = {
                                "Hindi ko kayang balikatin ang gawain sa suplay ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "That request couldn't be accepted.",
                            },
                            ["TL"] = {
                                "Hindi natanggap ang kahilingang iyon.",
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
