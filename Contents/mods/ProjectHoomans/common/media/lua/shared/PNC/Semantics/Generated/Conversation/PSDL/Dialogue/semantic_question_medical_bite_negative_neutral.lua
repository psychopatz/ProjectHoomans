-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.medical_bite.negative.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.medical_bite.negative.neutral",
            ["sourcePath"] = "psdl/dialogue/health_content.json#records[13]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_medical_bite_negative_neutral",
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
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "No, I don't have a recorded bite.",
                            },
                            ["TL"] = {
                                "Hindi, wala akong naitalang kagat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Checked myself over. No bites anywhere.",
                            },
                            ["TL"] = {
                                "Sinuri ko ang sarili ko. Walang kagat kahit saan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'm clean. None of them got their teeth in me.",
                            },
                            ["TL"] = {
                                "Malinis ako. Walang nakakagat sa akin sa kanila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "No bite marks at all, thankfully.",
                            },
                            ["TL"] = {
                                "Walang anumang bakas ng kagat, salamat sa Diyos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Skin's intact. No bites from the dead.",
                            },
                            ["TL"] = {
                                "Buo ang balat ko. Walang kagat mula sa mga patay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I made sure to inspect every scratch. No bites.",
                            },
                            ["TL"] = {
                                "Tiningnan ko bawat gasgas. Walang kagat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Free and clear of any bite wounds.",
                            },
                            ["TL"] = {
                                "Ligtas at malinis ako sa anumang sugat ng kagat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Didn't get bitten. The armor held up.",
                            },
                            ["TL"] = {
                                "Hindi nakagat. Nakatulong ang proteksyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "No bites on me, I can assure you.",
                            },
                            ["TL"] = {
                                "Walang kagat sa akin, makakasiguro ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I checked carefully. No bites, just scratches.",
                            },
                            ["TL"] = {
                                "Sinuri kong mabuti. Walang kagat, gasgas lang.",
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
