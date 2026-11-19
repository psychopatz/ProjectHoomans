-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "question_backstory",
        ["domainPath"] = "question_backstory",
        ["exchangeFamily"] = {
            ["familyID"] = "question.backstory.known",
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
                                ["fallback"] = "Before all this, I was %1.",
                                ["id"] = "default",
                                ["templateID"] = "convo.question.backstory.known.say.1.default",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "I studied %1.",
                                ["id"] = "education",
                                ["templateID"] = "convo.question.backstory.known.say.1.education",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "My family was %1.",
                                ["id"] = "family_background",
                                ["templateID"] = "convo.question.backstory.known.say.1.family_background",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "I have always been afraid of %1.",
                                ["id"] = "fear",
                                ["templateID"] = "convo.question.backstory.known.say.1.fear",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "I worked as %1 before all this.",
                                ["id"] = "former_job",
                                ["templateID"] = "convo.question.backstory.known.say.1.former_job",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "I used to enjoy %1.",
                                ["id"] = "hobby",
                                ["templateID"] = "convo.question.backstory.known.say.1.hobby",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "I grew up in %1.",
                                ["id"] = "hometown",
                                ["templateID"] = "convo.question.backstory.known.say.1.hometown",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "Something happened: %1.",
                                ["id"] = "tragedy",
                                ["templateID"] = "convo.question.backstory.known.say.1.tragedy",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.backstory",
            ["textRoles"] = {
                {
                    ["fallback"] = "Before all this, I was %1.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.backstory.known.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I studied %1.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.backstory.known.say.1.education",
                    ["variantID"] = "education",
                },
                {
                    ["fallback"] = "My family was %1.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.backstory.known.say.1.family_background",
                    ["variantID"] = "family_background",
                },
                {
                    ["fallback"] = "I have always been afraid of %1.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.backstory.known.say.1.fear",
                    ["variantID"] = "fear",
                },
                {
                    ["fallback"] = "I worked as %1 before all this.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.backstory.known.say.1.former_job",
                    ["variantID"] = "former_job",
                },
                {
                    ["fallback"] = "I used to enjoy %1.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.backstory.known.say.1.hobby",
                    ["variantID"] = "hobby",
                },
                {
                    ["fallback"] = "I grew up in %1.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.backstory.known.say.1.hometown",
                    ["variantID"] = "hometown",
                },
                {
                    ["fallback"] = "Something happened: %1.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.backstory.known.say.1.tragedy",
                    ["variantID"] = "tragedy",
                },
            },
        },
        ["id"] = "question.backstory.known",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "known",
            ["sourceId"] = "question.backstory.known",
            ["sourcePath"] = "dialogue/question_backstory/question_backstory_known.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/QuestionBackstory",
        ["namespace"] = "question.backstory",
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
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["memories"] = {
                {
                    ["id"] = "backstory_memory",
                    ["scope"] = "durable",
                },
            },
            ["metadata"] = {
                ["responseAct"] = "KNOWN",
                ["responsePoolID"] = "question.backstory.known",
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
                                ["fallback"] = "Before all this, I was %1.",
                                ["id"] = "default",
                                ["metadata"] = {
                                    ["fallback"] = "Before all this, I was %1.",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryKnown",
                                    ["translationArgs"] = {
                                        ["content"] = "fact_content",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "I studied %1.",
                                ["id"] = "education",
                                ["metadata"] = {
                                    ["fallback"] = "I studied %1.",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryEducation",
                                    ["translationArgs"] = {
                                        ["content"] = "fact_content",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "My family was %1.",
                                ["id"] = "family_background",
                                ["metadata"] = {
                                    ["fallback"] = "My family was %1.",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFamily",
                                    ["translationArgs"] = {
                                        ["content"] = "fact_content",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "I have always been afraid of %1.",
                                ["id"] = "fear",
                                ["metadata"] = {
                                    ["fallback"] = "I have always been afraid of %1.",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFear",
                                    ["translationArgs"] = {
                                        ["content"] = "fact_content",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "I worked as %1 before all this.",
                                ["id"] = "former_job",
                                ["metadata"] = {
                                    ["fallback"] = "I worked as %1 before all this.",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFormerJob",
                                    ["translationArgs"] = {
                                        ["content"] = "fact_content",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "I used to enjoy %1.",
                                ["id"] = "hobby",
                                ["metadata"] = {
                                    ["fallback"] = "I used to enjoy %1.",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryHobby",
                                    ["translationArgs"] = {
                                        ["content"] = "fact_content",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "I grew up in %1.",
                                ["id"] = "hometown",
                                ["metadata"] = {
                                    ["fallback"] = "I grew up in %1.",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryHometown",
                                    ["translationArgs"] = {
                                        ["content"] = "fact_content",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "Something happened: %1.",
                                ["id"] = "tragedy",
                                ["metadata"] = {
                                    ["fallback"] = "Something happened: %1.",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryTragedy",
                                    ["translationArgs"] = {
                                        ["content"] = "fact_content",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "backstory",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "KNOWN",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.backstory.known",
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
                            ["fallback"] = "Before all this, I was %1.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.backstory.known.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["subject"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "subject",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/question_backstory/question_backstory_known.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Before all this, I was %1.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.backstory.known.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I studied %1.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.backstory.known.say.1.education",
                ["variantID"] = "education",
            },
            {
                ["fallback"] = "My family was %1.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.backstory.known.say.1.family_background",
                ["variantID"] = "family_background",
            },
            {
                ["fallback"] = "I have always been afraid of %1.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.backstory.known.say.1.fear",
                ["variantID"] = "fear",
            },
            {
                ["fallback"] = "I worked as %1 before all this.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.backstory.known.say.1.former_job",
                ["variantID"] = "former_job",
            },
            {
                ["fallback"] = "I used to enjoy %1.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.backstory.known.say.1.hobby",
                ["variantID"] = "hobby",
            },
            {
                ["fallback"] = "I grew up in %1.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.backstory.known.say.1.hometown",
                ["variantID"] = "hometown",
            },
            {
                ["fallback"] = "Something happened: %1.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.backstory.known.say.1.tragedy",
                ["variantID"] = "tragedy",
            },
        },
        ["when"] = nil,
    },
}
