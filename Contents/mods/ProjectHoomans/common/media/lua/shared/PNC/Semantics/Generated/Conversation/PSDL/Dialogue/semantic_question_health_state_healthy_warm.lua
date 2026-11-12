-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.health_state.healthy.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.health_state.healthy.warm",
            ["sourcePath"] = "psdl/dialogue/health_content.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_health_state_healthy_warm",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseTemplateID"] = "semantic.question.health_state.healthy",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/health_state.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm doing okay. Thanks for checking in.",
                            },
                            ["TL"] = {
                                "Ayos lang ako. Salamat sa pagsuri.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Healthy and feeling good today. Truly appreciate you asking.",
                            },
                            ["TL"] = {
                                "Malusog at maganda ang pakiramdam ko ngayon. Salamat sa pagtatanong.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Not a scratch on me. Glad you're keeping an eye out.",
                            },
                            ["TL"] = {
                                "Kahit gasgas wala ako. Salamat sa pagbabantay.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Feeling strong and healthy, friend. Hope you are too.",
                            },
                            ["TL"] = {
                                "Malakas at malusog ang pakiramdam ko, kaibigan. Sana ikaw rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "All intact on my side. Thank you for looking after me.",
                            },
                            ["TL"] = {
                                "Buo ang lahat sa akin. Salamat sa pag-aalaga mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Doing wonderfully, thank you. It's comforting that you asked.",
                            },
                            ["TL"] = {
                                "Napakaganda ng kalagayan ko, salamat. Nakakapanatag na nagtanong ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "In great health today. Ready to face whatever comes our way.",
                            },
                            ["TL"] = {
                                "Napakalusog ko ngayon. Handa harapin ang anumang dumating.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Feeling well rested and sound. Appreciate the kind check-in.",
                            },
                            ["TL"] = {
                                "Mabuti ang pahinga at kalagayan ko. Salamat sa magandang pangangamusta.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "No bumps or scrapes today. Thank you for caring.",
                            },
                            ["TL"] = {
                                "Walang pasa o gasgas ngayon. Salamat sa pagmamalasakit.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "I'm doing great, honestly. Let's make sure we both stay that way.",
                            },
                            ["TL"] = {
                                "Maayos talaga ako. Siguraduhin nating manatili tayong parehong ganito.",
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
        ["sourceShard"] = "psdl/dialogue/health_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
