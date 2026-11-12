-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.medical_bite.positive.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.medical_bite.positive.warm",
            ["sourcePath"] = "psdl/dialogue/health_content.json#records[19]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_medical_bite_positive_warm",
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
                ["responseTemplateID"] = "semantic.question.medical_bite.positive",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/medical_bite.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "Yes. I've been bitten, and I appreciate you checking.",
                            },
                            ["TL"] = {
                                "Oo. Nakagat ako, at salamat sa pagsuri.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "They got me, friend. I'm sorry to bring you this news.",
                            },
                            ["TL"] = {
                                "Nakuha nila ako, kaibigan. Pasensya na sa masamang balita.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "I was bitten. Thank you for caring enough to ask me directly.",
                            },
                            ["TL"] = {
                                "Nakagat ako. Salamat sa pagtatanong nang diretso sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "It happened. I'm just glad I got to know you before the end.",
                            },
                            ["TL"] = {
                                "Nangyari na. Masaya akong nakilala kita bago ang lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "I've been bitten. Please, keep yourself safe when the time comes.",
                            },
                            ["TL"] = {
                                "Nakagat ako. Pakiusap, protektahan mo ang sarili mo pagdating ng oras.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Yes, they got their teeth in me. Thank you for standing by me.",
                            },
                            ["TL"] = {
                                "Oo, kinagat nila ako. Salamat sa pananatili sa tabi ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "I won't hide it from you. I was bitten. Take care of yourself.",
                            },
                            ["TL"] = {
                                "Hindi ko itatago sa 'yo. Nakagat ako. Alagaan mo ang sarili mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "It's a bite, friend. I appreciate all the times we shared.",
                            },
                            ["TL"] = {
                                "Kagat nga, kaibigan. Salamat sa lahat ng pinagsamahan natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'm infected. Thank you for treating me like a human being.",
                            },
                            ["TL"] = {
                                "Nahawaan na ako. Salamat sa pagtrato sa akin bilang kapwa tao.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "They bit me. Don't be sad; we fought as hard as we could.",
                            },
                            ["TL"] = {
                                "Kinagat nila ako. Huwag kang malungkot; lumaban tayo nang buong husay.",
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
