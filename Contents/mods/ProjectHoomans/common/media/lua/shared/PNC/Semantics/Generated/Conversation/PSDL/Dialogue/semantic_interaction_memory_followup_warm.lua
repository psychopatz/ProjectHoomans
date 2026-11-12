-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_memory",
        ["id"] = "semantic.interaction.memory.followup.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.memory.followup.warm",
            ["sourcePath"] = "psdl/dialogue/social_interaction_memory.json#records[9]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_memory_followup_warm",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.memory.followup",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/memory/followup.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "Really? Tell me more about that.",
                            },
                            ["TL"] = {
                                "Talaga? Kuwento mo pa sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "That sounds like quite a memory. How did it feel?",
                            },
                            ["TL"] = {
                                "Mukhang napakagandang alaala. Anong naramdaman mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'd love to hear the rest of that story if you want to share.",
                            },
                            ["TL"] = {
                                "Gusto kong marinig ang karugtong ng kuwento kung nais mong ibahagi.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "It must have taken real courage. How did you hold up?",
                            },
                            ["TL"] = {
                                "Kailangan ng tunay na tapang doon. Paano mo kinaya?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "You went through so much. I'm glad you're here to talk about it.",
                            },
                            ["TL"] = {
                                "Napakalaki ng pinagdaanan mo. Mabuti at narito ka para ikuwento.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Were you able to save anything from back then?",
                            },
                            ["TL"] = {
                                "May naisalba ka ba mula noong panahong iyon?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'm listening, friend. Take all the time you need.",
                            },
                            ["TL"] = {
                                "Nakikinig ako, kaibigan. Huwag kang magmadali.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "That sounds like someone who mattered deeply to you.",
                            },
                            ["TL"] = {
                                "Mukhang may taong napakahalaga sa 'yo sa kuwentong 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "What a journey. What kept you holding on?",
                            },
                            ["TL"] = {
                                "Napakalaking paglalakbay. Ano ang nagpatatag sa 'yo?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Thank you for trusting me with that memory. What happened next?",
                            },
                            ["TL"] = {
                                "Salamat sa pagtitiwala sa akin ng alaalang 'yan. Ano sumunod?",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_memory.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
