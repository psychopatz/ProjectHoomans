-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_memory",
        ["id"] = "semantic.interaction.memory.acknowledge.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.memory.acknowledge.warm",
            ["sourcePath"] = "psdl/dialogue/social_interaction_memory.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_memory_acknowledge_warm",
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
                ["responseTemplateID"] = "semantic.interaction.memory.acknowledge",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/memory/acknowledge.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "Yeah. I can see why that stayed with you.",
                            },
                            ["TL"] = {
                                "Oo. Naiintindihan ko kung bakit hindi mo iyon makalimutan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "I remember that too. It meant a lot to me.",
                            },
                            ["TL"] = {
                                "Naaalala ko rin 'yon. Malaking bagay 'yon para sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "That was a special moment between us. Glad you remember.",
                            },
                            ["TL"] = {
                                "Espesyal na sandali 'yon sa atin. Mabuti at naaalala mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "It stayed in my heart as well, friend.",
                            },
                            ["TL"] = {
                                "Nanatili rin 'yon sa puso ko, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks for reminding me of that. Good times.",
                            },
                            ["TL"] = {
                                "Salamat sa pagpapaalala niyan. Magandang alaala.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Those memories keep us human out here.",
                            },
                            ["TL"] = {
                                "Ang mga alaalang 'yan ang nagpapanatiling tao sa atin dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "I smile every time I think back on that day.",
                            },
                            ["TL"] = {
                                "Napapangiti ako tuwing naaalala ko ang araw na 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "We made it through that together. I won't forget it.",
                            },
                            ["TL"] = {
                                "Nalusutan natin 'yon nang magkasama. Di ko 'yon malilimutan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'm glad we share that memory.",
                            },
                            ["TL"] = {
                                "Masaya ako at pinagsaluhan natin ang alaalang 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "That really stuck with both of us, didn't it?",
                            },
                            ["TL"] = {
                                "Talagang tumatak sa ating dalawa 'yon, 'di ba?",
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
