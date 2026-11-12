-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.health_state.unknown.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.health_state.unknown.guarded",
            ["sourcePath"] = "psdl/dialogue/health_content.json#records[8]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_health_state_unknown_guarded",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't confirm that.",
                            },
                            ["TL"] = {
                                "Hindi ko makumpirma iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Haven't checked properly yet. Mind your own business.",
                            },
                            ["TL"] = {
                                "Hindi ko pa nasusuri nang maayos. Asikasuhin mo ang sarili mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Can't tell right now, and I'm not stripping down to check.",
                            },
                            ["TL"] = {
                                "Hindi ko masabi ngayon, at hindi ako maghuhubad para magpakita.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Unsure. I'll evaluate my own condition later.",
                            },
                            ["TL"] = {
                                "Hindi sigurado. Susuriin ko ang sarili ko mamaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "No idea. Too chaotic out here to be certain.",
                            },
                            ["TL"] = {
                                "Walang ideya. Masyadong magulo rito para makasiguro.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "I don't have that information right now. Stand back.",
                            },
                            ["TL"] = {
                                "Wala akong impormasyon diyan ngayon. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Hard to tell through the layers. Let it go.",
                            },
                            ["TL"] = {
                                "Mahirap malaman dahil sa kapal ng damit. Hayaan mo na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Can't be certain. Focus on your own status.",
                            },
                            ["TL"] = {
                                "Hindi makasiguro. Ituon ang pansin sa sarili mong kalagayan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Not clear yet. Don't crowd me.",
                            },
                            ["TL"] = {
                                "Hindi pa malinaw. Huwag mo akong pagkumpulan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Status unknown. I'll deal with it when I'm safe.",
                            },
                            ["TL"] = {
                                "Hindi tiyak ang kalagayan. Aayusin ko 'to kapag ligtas na.",
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
