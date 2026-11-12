-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.traveling.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.whats_up.traveling.guarded",
            ["sourcePath"] = "psdl/dialogue/conversation_whats_up.json#records[12]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_whats_up_traveling_guarded",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Keeping moving. Don't slow me down.",
                            },
                            ["TL"] = {
                                "Patuloy lang sa paggalaw. Huwag mo akong pabagalin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "On the move. Don't block my path.",
                            },
                            ["TL"] = {
                                "Naglalakbay ako. Huwag kang humarang sa daan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Travel's dangerous right now. Step aside.",
                            },
                            ["TL"] = {
                                "Mapanganib ang daan ngayon. Tabi muna.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Covering ground. I don't stay in one spot too long.",
                            },
                            ["TL"] = {
                                "Tuloy-tuloy ang lakad ko. Hindi ako tumatambay nang matagal.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Moving fast, staying light. No time to chat.",
                            },
                            ["TL"] = {
                                "Mabilis ang lakad, magaan ang dala. Walang oras makipag-usap.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Don't follow too closely. I walk alone.",
                            },
                            ["TL"] = {
                                "Huwag kang masyadong lumapit. Nag-iisa akong naglalakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Just passing through. Mind your own road.",
                            },
                            ["TL"] = {
                                "Dumadaan lang. Asikasuhin mo ang sarili mong daan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Got places to be before dark. Move along.",
                            },
                            ["TL"] = {
                                "May pupuntahan ako bago magdilim. Lumakad ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Traveling light and watching behind me. Stand clear.",
                            },
                            ["TL"] = {
                                "Magaan ang dala at laging tumitingin sa likod. Tabi ka riyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Moving between points. Don't compromise my route.",
                            },
                            ["TL"] = {
                                "Lumilipat ng pwesto. Huwag mong sirain ang ruta ko.",
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
