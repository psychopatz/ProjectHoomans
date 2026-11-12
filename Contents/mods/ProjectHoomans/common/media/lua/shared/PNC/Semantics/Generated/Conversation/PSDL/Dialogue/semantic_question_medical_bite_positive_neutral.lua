-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.medical_bite.positive.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.medical_bite.positive.neutral",
            ["sourcePath"] = "psdl/dialogue/health_content.json#records[17]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_medical_bite_positive_neutral",
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
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Yes, I've been bitten.",
                            },
                            ["TL"] = {
                                "Oo, nakagat ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "One of them got their teeth in me. It's bad.",
                            },
                            ["TL"] = {
                                "Nabaon ng isa sa kanila ang ngipin sa akin. Masama ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I got bitten during the struggle. No denying it.",
                            },
                            ["TL"] = {
                                "Nakagat ako habang nagpupumiglas. Hindi maikakaila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "There's a bite mark on my shoulder. I'm infected.",
                            },
                            ["TL"] = {
                                "May bakas ng kagat sa balikat ko. Nahawaan ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "It broke the skin. I know what's coming.",
                            },
                            ["TL"] = {
                                "Bumaon sa balat. Alam ko kung ano ang kahihinatnan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Yes, unfortunately. I was bitten.",
                            },
                            ["TL"] = {
                                "Oo, sa kasamaang-palad. Nakagat ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "They got through my sleeve. It's a bite.",
                            },
                            ["TL"] = {
                                "Lumusot sa manggas ko. Kagat nga.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I've been bitten. We need to plan for what comes next.",
                            },
                            ["TL"] = {
                                "Nakagat ako. Kailangan nating pag-isipan ang susunod na gagawin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Found the mark earlier. I was bitten.",
                            },
                            ["TL"] = {
                                "Nakita ko ang marka kanina. Nakagat talaga ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I'm infected. A walker bit me.",
                            },
                            ["TL"] = {
                                "Nahawaan na ako. Kinagat ako ng patay.",
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
