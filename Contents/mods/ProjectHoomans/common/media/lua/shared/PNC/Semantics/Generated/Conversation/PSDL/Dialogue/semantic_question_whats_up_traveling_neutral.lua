-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.traveling.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.whats_up.traveling.neutral",
            ["sourcePath"] = "psdl/dialogue/conversation_whats_up.json#records[13]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_whats_up_traveling_neutral",
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
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm keeping moving and watching what is ahead.",
                            },
                            ["TL"] = {
                                "Patuloy akong gumagalaw at binabantayan ang nasa unahan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Just trekking from point to point. Road's fairly calm.",
                            },
                            ["TL"] = {
                                "Naglalakad lang mula pwesto hanggang pwesto. Medyo kalmado ang kalsada.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Making headway before the sun starts dropping.",
                            },
                            ["TL"] = {
                                "Bumabaybay habang mataas pa ang araw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Covering some ground today. How's the path behind you?",
                            },
                            ["TL"] = {
                                "Marami-rami na ring nalakad ngayon. Kumusta ang daan sa pinanggalingan mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "On the road again. Gotta keep moving to find supplies.",
                            },
                            ["TL"] = {
                                "Nasa kalsada na naman. Kailangang gumalaw para maghanap ng gamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Heading out on a scouting loop. Everything looks quiet.",
                            },
                            ["TL"] = {
                                "Nag-iikot para magmanman. Mukhang tahimik naman ang lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Putting miles under my boots. Helps clear my head.",
                            },
                            ["TL"] = {
                                "Tuloy lang sa paghakbang. Nakakatulong magpalinaw ng isip.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Just moving between shelters. Don't want to linger anywhere too long.",
                            },
                            ["TL"] = {
                                "Lumilipat lang ng silungan. Ayokong tumambay nang matagal sa iisang lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Traveling down the lane. Hoping to avoid any hordes.",
                            },
                            ["TL"] = {
                                "Naglalakad sa kalsada. Sana walang makasalubong na kumpol ng patay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "On my way across the sector. How are things looking your way?",
                            },
                            ["TL"] = {
                                "Patawid ako sa kabilang bahagi. Kumusta ang kalagayan sa direksyon mo?",
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
