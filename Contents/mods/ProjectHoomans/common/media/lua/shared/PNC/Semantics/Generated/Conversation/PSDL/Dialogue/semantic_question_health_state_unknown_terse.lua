-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.health_state.unknown.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.health_state.unknown.terse",
            ["sourcePath"] = "psdl/dialogue/health_content.json#records[10]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_health_state_unknown_terse",
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
                ["responseTemplateID"] = "semantic.question.health_state.unknown",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/health_state.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Can't confirm.",
                            },
                            ["TL"] = {
                                "Hindi makumpirma.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Unsure.",
                            },
                            ["TL"] = {
                                "Hindi sigurado.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Not sure yet.",
                            },
                            ["TL"] = {
                                "Hindi pa tiyak.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Need to check.",
                            },
                            ["TL"] = {
                                "Kailangang suriin.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Unknown.",
                            },
                            ["TL"] = {
                                "Hindi alam.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Hard to say.",
                            },
                            ["TL"] = {
                                "Mahirap sabihin.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Can't tell.",
                            },
                            ["TL"] = {
                                "Hindi masabi.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Need a look.",
                            },
                            ["TL"] = {
                                "Kailangang tingnan.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Unchecked.",
                            },
                            ["TL"] = {
                                "Hindi pa nasusuri.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Too early to tell.",
                            },
                            ["TL"] = {
                                "Masyadong maaga pa.",
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
