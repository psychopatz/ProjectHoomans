-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "wellbeing_content",
        ["exchangeFamily"] = {
            ["familyID"] = "question.wellbeing.thirst_alt",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "I could really use a drink. Do you have any water?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.question.wellbeing.thirst_alt.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I could really use a drink. Do you have any water?",
                                        "Dying for a drink of water out here.",
                                        "Throat is scratching with thirst. Got a bottle?",
                                        "Would give almost anything for a cold sip right now.",
                                        "Looking for clean water everywhere. Got any to spare?",
                                        "Dehydration is starting to set in. Water would help immensely.",
                                        "Got a spare flask of water? My tongue feels like sandpaper.",
                                        "Can't go much further without something to drink.",
                                        "Just a small swallow of water would keep me going.",
                                        "My lips are chapped from thirst. Spare any water?",
                                    },
                                    ["TL"] = {
                                        "Kailangan ko talaga ng maiinom. May tubig ka ba?",
                                        "Gusto ko na talagang makainom ng tubig dito sa init.",
                                        "Makati na ang lalamunan ko sa uhaw. May botelya ka ba?",
                                        "Kahit ano ibibigay ko para sa malamig na lagok ng tubig ngayon.",
                                        "Naghahanap ako ng malinis na tubig kung saan-saan. May sobra ka?",
                                        "Inaabutan na ako ng dehydration. Malaking tulong ang tubig.",
                                        "May sobra ka bang lalagyan ng tubig? Parang liha na ang dila ko.",
                                        "Hindi na ako makakalayo kapag walang maiinom.",
                                        "Kahit isang lagok lang ng tubig makakatulong na sa akin.",
                                        "Bitak-bitak na ang labi ko sa uhaw. Pahingi naman ng tubig?",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.wellbeing",
            ["textRoles"] = {
                {
                    ["fallback"] = "I could really use a drink. Do you have any water?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.thirst_alt.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I could really use a drink. Do you have any water?",
                            "Dying for a drink of water out here.",
                            "Throat is scratching with thirst. Got a bottle?",
                            "Would give almost anything for a cold sip right now.",
                            "Looking for clean water everywhere. Got any to spare?",
                            "Dehydration is starting to set in. Water would help immensely.",
                            "Got a spare flask of water? My tongue feels like sandpaper.",
                            "Can't go much further without something to drink.",
                            "Just a small swallow of water would keep me going.",
                            "My lips are chapped from thirst. Spare any water?",
                        },
                        ["TL"] = {
                            "Kailangan ko talaga ng maiinom. May tubig ka ba?",
                            "Gusto ko na talagang makainom ng tubig dito sa init.",
                            "Makati na ang lalamunan ko sa uhaw. May botelya ka ba?",
                            "Kahit ano ibibigay ko para sa malamig na lagok ng tubig ngayon.",
                            "Naghahanap ako ng malinis na tubig kung saan-saan. May sobra ka?",
                            "Inaabutan na ako ng dehydration. Malaking tulong ang tubig.",
                            "May sobra ka bang lalagyan ng tubig? Parang liha na ang dila ko.",
                            "Hindi na ako makakalayo kapag walang maiinom.",
                            "Kahit isang lagok lang ng tubig makakatulong na sa akin.",
                            "Bitak-bitak na ang labi ko sa uhaw. Pahingi naman ng tubig?",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "question.wellbeing.thirst_alt",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "thirst_alt",
            ["sourceId"] = "question.wellbeing.thirst_alt",
            ["sourcePath"] = "adopters/hoomans/dialogue/wellbeing_content/question_wellbeing_thirst_alt.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/WellbeingContent__5728baa5",
        ["namespace"] = "question.wellbeing",
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
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/needs.json",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "I could really use a drink. Do you have any water?",
                                        "Dying for a drink of water out here.",
                                        "Throat is scratching with thirst. Got a bottle?",
                                        "Would give almost anything for a cold sip right now.",
                                        "Looking for clean water everywhere. Got any to spare?",
                                        "Dehydration is starting to set in. Water would help immensely.",
                                        "Got a spare flask of water? My tongue feels like sandpaper.",
                                        "Can't go much further without something to drink.",
                                        "Just a small swallow of water would keep me going.",
                                        "My lips are chapped from thirst. Spare any water?",
                                    },
                                    ["TL"] = {
                                        "Kailangan ko talaga ng maiinom. May tubig ka ba?",
                                        "Gusto ko na talagang makainom ng tubig dito sa init.",
                                        "Makati na ang lalamunan ko sa uhaw. May botelya ka ba?",
                                        "Kahit ano ibibigay ko para sa malamig na lagok ng tubig ngayon.",
                                        "Naghahanap ako ng malinis na tubig kung saan-saan. May sobra ka?",
                                        "Inaabutan na ako ng dehydration. Malaking tulong ang tubig.",
                                        "May sobra ka bang lalagyan ng tubig? Parang liha na ang dila ko.",
                                        "Hindi na ako makakalayo kapag walang maiinom.",
                                        "Kahit isang lagok lang ng tubig makakatulong na sa akin.",
                                        "Bitak-bitak na ang labi ko sa uhaw. Pahingi naman ng tubig?",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.wellbeing.thirst_alt",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I could really use a drink. Do you have any water?",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.question.wellbeing.thirst_alt.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/wellbeing_content/question_wellbeing_thirst_alt.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I could really use a drink. Do you have any water?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.thirst_alt.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I could really use a drink. Do you have any water?",
                        "Dying for a drink of water out here.",
                        "Throat is scratching with thirst. Got a bottle?",
                        "Would give almost anything for a cold sip right now.",
                        "Looking for clean water everywhere. Got any to spare?",
                        "Dehydration is starting to set in. Water would help immensely.",
                        "Got a spare flask of water? My tongue feels like sandpaper.",
                        "Can't go much further without something to drink.",
                        "Just a small swallow of water would keep me going.",
                        "My lips are chapped from thirst. Spare any water?",
                    },
                    ["TL"] = {
                        "Kailangan ko talaga ng maiinom. May tubig ka ba?",
                        "Gusto ko na talagang makainom ng tubig dito sa init.",
                        "Makati na ang lalamunan ko sa uhaw. May botelya ka ba?",
                        "Kahit ano ibibigay ko para sa malamig na lagok ng tubig ngayon.",
                        "Naghahanap ako ng malinis na tubig kung saan-saan. May sobra ka?",
                        "Inaabutan na ako ng dehydration. Malaking tulong ang tubig.",
                        "May sobra ka bang lalagyan ng tubig? Parang liha na ang dila ko.",
                        "Hindi na ako makakalayo kapag walang maiinom.",
                        "Kahit isang lagok lang ng tubig makakatulong na sa akin.",
                        "Bitak-bitak na ang labi ko sa uhaw. Pahingi naman ng tubig?",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
