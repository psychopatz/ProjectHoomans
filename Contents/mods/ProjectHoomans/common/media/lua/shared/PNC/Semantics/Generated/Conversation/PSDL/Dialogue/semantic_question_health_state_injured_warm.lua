-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.health_state.injured.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.health_state.injured.warm",
            ["sourcePath"] = "psdl/dialogue/health_content.json#records[7]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_health_state_injured_warm",
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
                ["responseTemplateID"] = "semantic.question.health_state.injured",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/health_state.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm hurt, but I'm managing. Thanks for asking.",
                            },
                            ["TL"] = {
                                "Nasaktan ako, pero kinakaya ko. Salamat sa pagtatanong.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Took a hit out there, but knowing you're here helps a lot.",
                            },
                            ["TL"] = {
                                "Tinamaan ako sa labas, pero malaking tulong na nandito ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "It hurts, friend, but I promise I'm holding together.",
                            },
                            ["TL"] = {
                                "Masakit, kaibigan, pero nangangako akong kakayanin ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Got banged up a little. Thank you for your care and concern.",
                            },
                            ["TL"] = {
                                "Medyo napuruhan ako. Salamat sa malasakit mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Nursing a wound, but seeing you safe gives me strength.",
                            },
                            ["TL"] = {
                                "May sugat ako, pero nagbibigay ng lakas na ligtas ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'll pull through with some rest. Thanks for checking on me.",
                            },
                            ["TL"] = {
                                "Makakaraos din ako kapag nakapagpahinga. Salamat sa pangangamusta.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "It's painful, but we'll patch it up together, right?",
                            },
                            ["TL"] = {
                                "Masakit, pero gagamutin natin ito nang magkasama, di ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Appreciate the check-in. Don't worry too much about me.",
                            },
                            ["TL"] = {
                                "Salamat sa pagsuri. Huwag kang masyadong mag-alala sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Got scratched up bad, but I'm glad you're by my side.",
                            },
                            ["TL"] = {
                                "Malala ang gasgas ko, pero masaya akong nasa tabi kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Hurts like hell, but having good folks around keeps me going.",
                            },
                            ["TL"] = {
                                "Napakasakit, pero ang mabubuting kasama ang nagpapatuloy sa akin.",
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
