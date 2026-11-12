-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.default_alt.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.whats_up.default_alt.neutral",
            ["sourcePath"] = "psdl/dialogue/conversation_whats_up.json#records[9]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_whats_up_default_alt_neutral",
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
                ["responseTemplateID"] = "semantic.question.whats_up.default_alt",
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
                                "Same as ever. Staying alive and watching the road.",
                            },
                            ["TL"] = {
                                "Gaya ng dati. Nanatiling buhay at binabantayan ang daan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Doing what needs to be done to see tomorrow.",
                            },
                            ["TL"] = {
                                "Ginagawa kung anong kailangan para makita ang bukas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "One foot in front of the other. Road's quiet so far.",
                            },
                            ["TL"] = {
                                "Dahan-dahang naglalakad. Tahimik naman ang kalsada.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Keeping a low profile and taking care of business.",
                            },
                            ["TL"] = {
                                "Umiiwas sa gulo at inaasikaso ang mga kailangan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Just staying alert out here. How have you been?",
                            },
                            ["TL"] = {
                                "Laging nagmamasid dito sa labas. Kumusta ka na?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Watching the tree lines. Routine stuff.",
                            },
                            ["TL"] = {
                                "Binabantayan ang kakahuyan. Karaniwang gawain lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Still on the right side of the dirt. That's plenty.",
                            },
                            ["TL"] = {
                                "Nasa ibabaw pa rin ng lupa. Sapat na 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Taking each hour as it comes. How about yourself?",
                            },
                            ["TL"] = {
                                "Bawat oras kinakaya. Ikaw, kumusta ka?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Alive and alert. Hoping the peace lasts.",
                            },
                            ["TL"] = {
                                "Buhay at gising. Sana magtagal ang katahimikan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Watching the perimeter, making sure we're unbothered.",
                            },
                            ["TL"] = {
                                "Binabantayan ang paligid para masigurong ligtas tayo.",
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
