-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.fatigue.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.fatigue.neutral",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[14]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_wellbeing_fatigue_neutral",
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
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseTemplateID"] = "semantic.question.wellbeing.fatigue",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/needs.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm worn out, but I can still manage.",
                            },
                            ["TL"] = {
                                "Pagod na pagod ako, pero kaya ko pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "My limbs feel heavy. I've been on my feet too long.",
                            },
                            ["TL"] = {
                                "Mabigat ang mga binti ko. Napakatagal ko nang nakatayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Could definitely use a breather soon.",
                            },
                            ["TL"] = {
                                "Kailangan ko na talagang makapagpahinga sandali.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Running on fumes right now, but I'll push through.",
                            },
                            ["TL"] = {
                                "Ubos na ang lakas ko, pero pipilitin kong magpatuloy.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Need to catch my breath before the next run.",
                            },
                            ["TL"] = {
                                "Kailangang makabawi ng hininga bago ang susunod na lakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Feeling exhausted, to be honest with you.",
                            },
                            ["TL"] = {
                                "Sobrang pagod na ako, sa totoo lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "My body is aching for some decent sleep.",
                            },
                            ["TL"] = {
                                "Sumasakit na ang buong katawan ko sa puyat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'm drained, but I won't drop my guard.",
                            },
                            ["TL"] = {
                                "Puyat at pagod ako, pero hindi ako magpapabaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "A quick sit-down would do wonders right now.",
                            },
                            ["TL"] = {
                                "Malaking tulong ang sandaling pag-upo ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Exhaustion is catching up with me today.",
                            },
                            ["TL"] = {
                                "Inaabutan na ako ng matinding pagod ngayon.",
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
        ["sourceShard"] = "psdl/dialogue/wellbeing_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
