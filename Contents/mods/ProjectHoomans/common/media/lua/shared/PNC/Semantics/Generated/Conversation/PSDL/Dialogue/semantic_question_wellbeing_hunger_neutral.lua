-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.hunger.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.hunger.neutral",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[16]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_wellbeing_hunger_neutral",
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
                ["responseTemplateID"] = "semantic.question.wellbeing.hunger",
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
                                "I'm pretty hungry, if I'm honest. Do you have anything to eat?",
                            },
                            ["TL"] = {
                                "Medyo gutom ako, kung tutuusin. May makakain ka ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "My stomach has been growling for hours. Got any food to spare?",
                            },
                            ["TL"] = {
                                "Kanina pa kumakalam ang sikmura ko. May maibibigay ka bang pagkain?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Really feeling the hunger right now. Could use a bite.",
                            },
                            ["TL"] = {
                                "Ramdam na ramdam ko ang gutom ngayon. Kailangan ko ng makakain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Haven't had a proper meal in a while. Any rations on you?",
                            },
                            ["TL"] = {
                                "Medyo matagal na mula noong huli akong kumain. May rasyon ka ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Need some calories before my strength fades. Got anything?",
                            },
                            ["TL"] = {
                                "Kailangan ko ng lakas bago ako manghina. Mayroon ka ba riyan?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'm starving out here. Even stale crackers would do.",
                            },
                            ["TL"] = {
                                "Gutom na gutom na ako rito. Kahit lumang biskwit tatanggapin ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Food is getting urgent for me. Anything in your pack?",
                            },
                            ["TL"] = {
                                "Kailangan ko na talagang kumain. May laman ba ang bag mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Hard to focus when your stomach is this empty. Spare any food?",
                            },
                            ["TL"] = {
                                "Mahirap mag-isip kapag walang laman ang tiyan. Penge namang makakain?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I could really use a snack or some canned goods right now.",
                            },
                            ["TL"] = {
                                "Kailangan ko talaga ng meryenda o de-lata ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Getting weak from hunger. Do you have any rations to share?",
                            },
                            ["TL"] = {
                                "Nanghihina na ako sa gutom. May maibabahagi ka bang rasyon?",
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
