-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.default.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.whats_up.default.guarded",
            ["sourcePath"] = "psdl/dialogue/conversation_whats_up.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_whats_up_default_guarded",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Nothing worth discussing. Stay alert.",
                            },
                            ["TL"] = {
                                "Walang mahalagang pag-usapan. Manatiling alerto.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Same old story. Don't let your guard down.",
                            },
                            ["TL"] = {
                                "Ganoon pa rin. Huwag kang magpapabaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Just watching the perimeter. You should do the same.",
                            },
                            ["TL"] = {
                                "Binabantayan lang ang paligid. Dapat ganoon ka rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Nothing new, and quiet usually means trouble is brewing.",
                            },
                            ["TL"] = {
                                "Walang bago, at ang katahimikan ay kadalasang may dalang gulo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Nothing to share. Keep moving along.",
                            },
                            ["TL"] = {
                                "Walang dapat ibahagi. Magpatuloy ka lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Surviving another day. That's about it.",
                            },
                            ["TL"] = {
                                "Nabubuhay pa ng isa pang araw. Iyon lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "I keep my thoughts to myself out here.",
                            },
                            ["TL"] = {
                                "Itinatago ko ang iniisip ko sa sarili ko rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "All quiet on my watch. Keep your distance.",
                            },
                            ["TL"] = {
                                "Tahimik sa bantay ko. Lumayo ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Not much, and I'd like to keep it that way.",
                            },
                            ["TL"] = {
                                "Wala naman, at gusto kong manatiling ganoon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Nothing you need to concern yourself with.",
                            },
                            ["TL"] = {
                                "Walang dapat mong alalahanin.",
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
