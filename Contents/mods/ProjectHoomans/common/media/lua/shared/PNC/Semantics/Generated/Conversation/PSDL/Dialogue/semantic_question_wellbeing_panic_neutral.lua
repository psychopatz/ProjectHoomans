-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.panic.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.panic.neutral",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_wellbeing_panic_neutral",
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
                ["responseTemplateID"] = "semantic.question.wellbeing.panic",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/emotional.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm pretty shaken up right now.",
                            },
                            ["TL"] = {
                                "Nanginginig pa rin ako ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "My heart is pounding out of my chest.",
                            },
                            ["TL"] = {
                                "Napakabilis ng tibok ng puso ko sa kaba.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "That was way too close. Need a minute to breathe.",
                            },
                            ["TL"] = {
                                "Muntik na 'yon. Kailangan ko ng sandali para kumalma.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Trying to keep my hands from shaking.",
                            },
                            ["TL"] = {
                                "Pinipigilan ko ang panginginig ng mga kamay ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Terrified, if I'm being honest with you.",
                            },
                            ["TL"] = {
                                "Natatakot ako, kung sasabihin ko ang totoo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Felt like my heart was going to stop back there.",
                            },
                            ["TL"] = {
                                "Pakiramdam ko hihinto na ang puso ko kanina.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Need to catch my breath and calm my nerves.",
                            },
                            ["TL"] = {
                                "Kailangang huminga nang malalim at pakalmahin ang sarili.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Adrenaline is surging. Hard to think straight.",
                            },
                            ["TL"] = {
                                "Mataas pa ang adrenaline ko. Hirap mag-isip nang tuwid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Still feeling the panic creeping up on me.",
                            },
                            ["TL"] = {
                                "Nararamdaman ko pa rin ang takot na gumagapang sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Give me a second to get my head together.",
                            },
                            ["TL"] = {
                                "Bigyan mo ako ng ilang sandali para makabawi ng katinuan.",
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
