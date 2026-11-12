-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.default.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.whats_up.default.neutral",
            ["sourcePath"] = "psdl/dialogue/conversation_whats_up.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_whats_up_default_neutral",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
                ["responseTemplateID"] = "semantic.question.whats_up.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/conversation.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Not much. I'm just trying to keep things together.",
                            },
                            ["TL"] = {
                                "Wala naman. Sinusubukan ko lang na panatilihing maayos ang lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Just another day trying to stay alive and in one piece.",
                            },
                            ["TL"] = {
                                "Isa na namang araw sa pagsubok na manatiling buhay at buo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Taking things as they come. Anything interesting happening?",
                            },
                            ["TL"] = {
                                "Tinatanggap ang bawat araw. May bago ba o kawili-wili?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Not a whole lot. Keeping an eye on the surroundings.",
                            },
                            ["TL"] = {
                                "Wala masyado. Binabantayan lang ang kapaligiran.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Just waiting to see what the afternoon brings.",
                            },
                            ["TL"] = {
                                "Nagmamasid lang kung anong mangyayari ngayong hapon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Ordinary day out here, if you can call this ordinary.",
                            },
                            ["TL"] = {
                                "Karaniwang araw dito, kung matatawag mong karaniwan ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Just trying to make it to sundown without issues.",
                            },
                            ["TL"] = {
                                "Sinusubukang umabot sa takip-silim nang walang aberya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Holding down the fort. How are things with you?",
                            },
                            ["TL"] = {
                                "Binabantayan ang pwesto. Kumusta naman sa iyo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Quiet so far. That's usually a blessing.",
                            },
                            ["TL"] = {
                                "Tahimik sa ngayon. Biyaya na ang ganoon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Not much news. Just staying out of harm's way.",
                            },
                            ["TL"] = {
                                "Walang masyadong balita. Umiiwas lang sa kapahamakan.",
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
        ["sourceShard"] = "psdl/dialogue/conversation_whats_up.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
