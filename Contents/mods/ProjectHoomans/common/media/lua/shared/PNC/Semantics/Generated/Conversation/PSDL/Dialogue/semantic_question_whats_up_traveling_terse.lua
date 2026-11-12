-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.traveling.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.whats_up.traveling.terse",
            ["sourcePath"] = "psdl/dialogue/conversation_whats_up.json#records[14]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_whats_up_traveling_terse",
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
                ["responseTemplateID"] = "semantic.question.whats_up.traveling",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/conversation.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Keeping moving.",
                            },
                            ["TL"] = {
                                "Patuloy lang sa paggalaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "On the road.",
                            },
                            ["TL"] = {
                                "Nasa daan.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Traveling.",
                            },
                            ["TL"] = {
                                "Naglalakbay.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Moving out.",
                            },
                            ["TL"] = {
                                "Umaalis.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Passing through.",
                            },
                            ["TL"] = {
                                "Dumadaan lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Covering ground.",
                            },
                            ["TL"] = {
                                "Naglalakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "On the move.",
                            },
                            ["TL"] = {
                                "Kumikilos.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Headed out.",
                            },
                            ["TL"] = {
                                "Papunta na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "In transit.",
                            },
                            ["TL"] = {
                                "Bumabyahe.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Pushing ahead.",
                            },
                            ["TL"] = {
                                "Pasulong.",
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
