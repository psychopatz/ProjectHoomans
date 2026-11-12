-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_argument",
        ["id"] = "semantic.interaction.argument.deescalate.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.argument.deescalate.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_argument.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_argument_deescalate_guarded",
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
                ["responseTemplateID"] = "semantic.interaction.argument.deescalate",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/argument/deescalate.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Fine. Just lower your voice.",
                            },
                            ["TL"] = {
                                "Sige. Hinaan mo lang ang boses mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Lower your tone before you draw attention.",
                            },
                            ["TL"] = {
                                "Hinaan mo ang tono mo bago ka makahatak ng pansin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Stop yelling. You want every dead head hearing this?",
                            },
                            ["TL"] = {
                                "Huwag kang sumigaw. Gusto mo bang marinig tayo ng mga patay?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "All right. Keep it down and back off.",
                            },
                            ["TL"] = {
                                "Sige. Hinaan ang boses at umatras.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Enough. Lower the volume right now.",
                            },
                            ["TL"] = {
                                "Sapat na. Hinaan mo ang boses mo ngayon din.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "I heard you. Now drop the shouting.",
                            },
                            ["TL"] = {
                                "Narinig kita. Ngayon tigilan mo ang pagsigaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Shh! Keep your voice down.",
                            },
                            ["TL"] = {
                                "Shh! Hinaan mo ang boses mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Keep it civil and quiet. We're in danger.",
                            },
                            ["TL"] = {
                                "Maging maayos at tahimik. Nasa panganib tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Lower your voice. I'm not deaf.",
                            },
                            ["TL"] = {
                                "Hinaan mo ang boses. Hindi ako bingi.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Fine. Just tone it down.",
                            },
                            ["TL"] = {
                                "Sige. Hinaan mo lang.",
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
