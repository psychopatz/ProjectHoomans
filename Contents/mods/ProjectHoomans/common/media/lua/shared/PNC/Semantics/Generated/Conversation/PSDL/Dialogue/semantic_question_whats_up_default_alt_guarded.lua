-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.default_alt.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.whats_up.default_alt.guarded",
            ["sourcePath"] = "psdl/dialogue/conversation_whats_up.json#records[8]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_whats_up_default_alt_guarded",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Staying alive. Keep your eyes open.",
                            },
                            ["TL"] = {
                                "Basta buhay. Maging mapagmatyag.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Watching the road. Don't stand in my line of sight.",
                            },
                            ["TL"] = {
                                "Binabantayan ang daan. Huwag kang humarang sa tingin ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Alive, but cautious. You should be too.",
                            },
                            ["TL"] = {
                                "Buhay, pero maingat. Dapat ganoon ka rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Just staying on high alert. Danger doesn't take days off.",
                            },
                            ["TL"] = {
                                "Laging alerto. Walang bakasyon ang panganib.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Focusing on staying off the radar. Step aside.",
                            },
                            ["TL"] = {
                                "Nakatutok sa pananatiling tago. Tabi muna.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Watching the fence lines. Nothing for you here.",
                            },
                            ["TL"] = {
                                "Binabantayan ang bakod. Walang kailangan dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Alive, and keeping it that way by not gossiping.",
                            },
                            ["TL"] = {
                                "Buhay, at mananatiling ganito kung hindi makikipagtsismisan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Eyes on the horizon. Don't make unnecessary noise.",
                            },
                            ["TL"] = {
                                "Nakatitig sa abot-tanaw. Huwag gumawa ng ingay.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Surviving. That requires vigilance, not conversation.",
                            },
                            ["TL"] = {
                                "Buhay pa. Kailangan 'yan ng pag-iingat, hindi ng daldalan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Just keeping myself safe. You do the same.",
                            },
                            ["TL"] = {
                                "Pinoprotektahan lang ang sarili ko. Gawin mo rin 'yan.",
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
