-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.hunger_alt.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.hunger_alt.neutral",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[17]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_wellbeing_hunger_alt_neutral",
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
                ["responseTemplateID"] = "semantic.question.wellbeing.hunger_alt",
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
                                "I'm getting hungry. Could you spare something to eat?",
                            },
                            ["TL"] = {
                                "Nagugutom na ako. Maaari ba akong makahingi ng makakain?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Could use some food soon. My energy is dipping low.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng pagkain maya-maya. Bumababa na ang lakas ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Starting to feel hollow inside. Any food left?",
                            },
                            ["TL"] = {
                                "Parang hungkag na ang sikmura ko. May natira pa bang pagkain?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "A small bite would go a long way right now.",
                            },
                            ["TL"] = {
                                "Malaking tulong ang kahit kaunting subo ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Gotta find something to eat before too long.",
                            },
                            ["TL"] = {
                                "Kailangang makahanap ng makakain sa lalong madaling panahon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "My pack is empty of food. Got anything to share?",
                            },
                            ["TL"] = {
                                "Wala nang laman ang bag ko. May maibabahagi ka ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Thinking about food constantly. Need a meal soon.",
                            },
                            ["TL"] = {
                                "Pagkain lang ang nasa isip ko. Kailangang makakain agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Even a crust of bread would help me keep going.",
                            },
                            ["TL"] = {
                                "Kahit balat ng tinapay makakatulong sa akin para magpatuloy.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Stomach's rumbling loud enough to draw attention. Got food?",
                            },
                            ["TL"] = {
                                "Baka marinig pa ng iba ang kulo ng tiyan ko. May pagkain ka?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Running low on fuel. Spare a bite if you've got extra?",
                            },
                            ["TL"] = {
                                "Nauubusan na ako ng enerhiya. Pahingi naman ng konting makakain kung sobra?",
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
