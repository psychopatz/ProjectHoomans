-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.thirst_alt.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.thirst_alt.neutral",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[19]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_wellbeing_thirst_alt_neutral",
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
                ["responseTemplateID"] = "semantic.question.wellbeing.thirst_alt",
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
                                "I could really use a drink. Do you have any water?",
                            },
                            ["TL"] = {
                                "Kailangan ko talaga ng maiinom. May tubig ka ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Dying for a drink of water out here.",
                            },
                            ["TL"] = {
                                "Gusto ko na talagang makainom ng tubig dito sa init.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Throat is scratching with thirst. Got a bottle?",
                            },
                            ["TL"] = {
                                "Makati na ang lalamunan ko sa uhaw. May botelya ka ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Would give almost anything for a cold sip right now.",
                            },
                            ["TL"] = {
                                "Kahit ano ibibigay ko para sa malamig na lagok ng tubig ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Looking for clean water everywhere. Got any to spare?",
                            },
                            ["TL"] = {
                                "Naghahanap ako ng malinis na tubig kung saan-saan. May sobra ka?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Dehydration is starting to set in. Water would help immensely.",
                            },
                            ["TL"] = {
                                "Inaabutan na ako ng dehydration. Malaking tulong ang tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Got a spare flask of water? My tongue feels like sandpaper.",
                            },
                            ["TL"] = {
                                "May sobra ka bang lalagyan ng tubig? Parang liha na ang dila ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Can't go much further without something to drink.",
                            },
                            ["TL"] = {
                                "Hindi na ako makakalayo kapag walang maiinom.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Just a small swallow of water would keep me going.",
                            },
                            ["TL"] = {
                                "Kahit isang lagok lang ng tubig makakatulong na sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "My lips are chapped from thirst. Spare any water?",
                            },
                            ["TL"] = {
                                "Bitak-bitak na ang labi ko sa uhaw. Pahingi naman ng tubig?",
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
