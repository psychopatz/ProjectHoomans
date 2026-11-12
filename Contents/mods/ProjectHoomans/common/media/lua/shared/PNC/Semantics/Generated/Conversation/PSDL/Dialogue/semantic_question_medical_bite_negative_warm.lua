-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.medical_bite.negative.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.medical_bite.negative.warm",
            ["sourcePath"] = "psdl/dialogue/health_content.json#records[15]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_medical_bite_negative_warm",
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
                ["responseTemplateID"] = "semantic.question.medical_bite.negative",
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
                                "No, I don't have a recorded bite. Thanks for checking.",
                            },
                            ["TL"] = {
                                "Hindi, wala akong naitalang kagat. Salamat sa pagsuri.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "I'm clean, friend. None of them got through my guard.",
                            },
                            ["TL"] = {
                                "Malinis ako, kaibigan. Walang nakalusot sa depensa ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "No bite marks on me. Good to know you're looking out for camp.",
                            },
                            ["TL"] = {
                                "Walang kagat sa akin. Mabuti at nagbabantay ka para sa kampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Completely free of bites, thank God. Appreciate the check.",
                            },
                            ["TL"] = {
                                "Ligtas sa anumang kagat, salamat sa Diyos. Salamat sa pagsuri.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "I checked thoroughly, nothing to fear. We're safe.",
                            },
                            ["TL"] = {
                                "Sinuri ko nang maayos, walang dapat ikatakot. Ligtas tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "No bites! Relieved to tell you I'm completely in the clear.",
                            },
                            ["TL"] = {
                                "Walang kagat! Masaya akong sabihing ligtas na ligtas ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Skin is clean. Thank you for doing the hard safety checks.",
                            },
                            ["TL"] = {
                                "Malinis ang balat ko. Salamat sa pagsasagawa ng mahigpit na pagsusuri.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "You can breathe easy, no bites on me.",
                            },
                            ["TL"] = {
                                "Makakahinga ka nang maluwag, walang kagat sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "All clear on the bite front. Thank you for your care.",
                            },
                            ["TL"] = {
                                "Walang anumang kagat. Salamat sa pag-aalala mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Not bitten at all, friend. I'm staying right here with you.",
                            },
                            ["TL"] = {
                                "Hinding-hindi nakagat, kaibigan. Mananatili ako rito kasama mo.",
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
