-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.health_state.healthy.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.health_state.healthy.guarded",
            ["sourcePath"] = "psdl/dialogue/health_content.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_health_state_healthy_guarded",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseTemplateID"] = "semantic.question.health_state.healthy",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/health_state.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm fine. Don't make a thing of it.",
                            },
                            ["TL"] = {
                                "Mabuti ako. Huwag mo nang palakihin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Nothing wrong with me. Keep your eyes on the road.",
                            },
                            ["TL"] = {
                                "Walang mali sa akin. Tumutok ka sa daan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "No injuries to report. Step back.",
                            },
                            ["TL"] = {
                                "Walang sugat na dapat sabihin. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'm in fighting shape. Don't worry about me.",
                            },
                            ["TL"] = {
                                "Kaya ko pang lumaban. Huwag mo akong alalahanin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Not a scratch on me. That's all you get.",
                            },
                            ["TL"] = {
                                "Kahit gasgas wala ako. Iyon lang ang masasabi ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'm completely healthy. Leave it alone.",
                            },
                            ["TL"] = {
                                "Malusog ako. Huwag mo nang usisain.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Body's holding up just fine. Mind your own health.",
                            },
                            ["TL"] = {
                                "Maayos ang katawan ko. Asikasuhin mo ang sarili mong kalusugan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Clean bill of health. You don't need to inspect me.",
                            },
                            ["TL"] = {
                                "Ligtas ako sa anumang sakit. Hindi mo kailangang siyasatin ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'm intact and able-bodied. Let's move on.",
                            },
                            ["TL"] = {
                                "Buo ako at maayos ang katawan. Magpatuloy na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "No wounds, no sickness. Keep your distance.",
                            },
                            ["TL"] = {
                                "Walang sugat, walang sakit. Lumayo ka.",
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
        ["sourceShard"] = "psdl/dialogue/health_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
