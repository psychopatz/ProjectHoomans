-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.default.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.whats_up.default.warm",
            ["sourcePath"] = "psdl/dialogue/conversation_whats_up.json#records[7]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_whats_up_default_warm",
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
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "Not much. I'm just trying to keep things together. Good to see you, though.",
                            },
                            ["TL"] = {
                                "Wala naman. Sinusubukan ko lang na panatilihing maayos ang lahat. Mabuti at nakita kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Just grateful to see another sunrise. It's lovely having you here.",
                            },
                            ["TL"] = {
                                "Nagpapasalamat lang sa panibagong bukang-liwayway. Masayang nandito ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Not much happening, but having good folks around brightens the day.",
                            },
                            ["TL"] = {
                                "Walang gaanong kaganapan, pero gumaganda ang araw kapag may mabubuting kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Just taking it easy for a moment. Really glad you stopped to talk.",
                            },
                            ["TL"] = {
                                "Nagpapahinga lang sandali. Masaya talaga akong huminto ka para makipag-usap.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Things are calm today, thank goodness. How has your day been going?",
                            },
                            ["TL"] = {
                                "Payapa ang araw ngayon, salamat sa Diyos. Kumusta naman ang araw mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Nothing out of the ordinary, but seeing you always lifts my spirits.",
                            },
                            ["TL"] = {
                                "Walang kakaiba, pero laging nakakapagpagaan ng loob ang makita ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Holding steady with a smile. Hope everything is smooth on your side.",
                            },
                            ["TL"] = {
                                "Matatag pa rin at nakangiti. Sana maayos ang lahat sa panig mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Just soaking in the peace while it lasts. Good to see you, friend.",
                            },
                            ["TL"] = {
                                "Nilalasap ang kapayapaan habang nariyan pa. Mabuti at nakita kita, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Counting my blessings out here. Having reliable people is number one.",
                            },
                            ["TL"] = {
                                "Nagbibilang ng mga biyaya. Ang magkaroon ng maaasahang kasama ang una roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Nothing major, just glad we're both standing. How's everything with you?",
                            },
                            ["TL"] = {
                                "Wala namang malaki, masaya lang akong pareho tayong nakatayo. Kumusta ka?",
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
