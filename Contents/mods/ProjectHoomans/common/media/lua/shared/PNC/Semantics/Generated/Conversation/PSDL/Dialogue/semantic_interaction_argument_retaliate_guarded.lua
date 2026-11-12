-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_argument",
        ["id"] = "semantic.interaction.argument.retaliate.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.argument.retaliate.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_argument.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_argument_retaliate_guarded",
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
                ["responseTemplateID"] = "semantic.interaction.argument.retaliate",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/argument/retaliate.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Say that again and see how far it gets you.",
                            },
                            ["TL"] = {
                                "Sabihin mo ulit at tingnan natin kung saan ka aabot.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "You want to push this? I will push back harder.",
                            },
                            ["TL"] = {
                                "Gusto mong isagad ito? Mas malakas akong gaganti.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Don't make threats you can't survive.",
                            },
                            ["TL"] = {
                                "Huwag kang magbanta ng hindi mo kayang maligtasan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Try me. See what happens to you.",
                            },
                            ["TL"] = {
                                "Subukan mo ako. Tingnan mo kung anong mangyayari sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "You're digging your own grave with that talk.",
                            },
                            ["TL"] = {
                                "Hinuhukay mo ang sarili mong libingan sa salitang 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Keep running that mouth and find out.",
                            },
                            ["TL"] = {
                                "Sige, magpatuloy ka sa kadadaldal at nang malaman mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not the one to mess with out here.",
                            },
                            ["TL"] = {
                                "Hindi ako ang taong dapat mong ginagalit dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Push one more inch and we have bloodshed.",
                            },
                            ["TL"] = {
                                "Sumulong ka pa nang isang pulgada at magkakadugo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Say it one more time. I dare you.",
                            },
                            ["TL"] = {
                                "Ulitin mo pa nang isang beses. Hinahamon kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "You will regret crossing me.",
                            },
                            ["TL"] = {
                                "Pagsisisihan mo ang pagbangga sa akin.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_argument.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
