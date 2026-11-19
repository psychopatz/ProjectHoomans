-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "wellbeing_content",
        ["domainPath"] = "wellbeing_content",
        ["exchangeFamily"] = {
            ["familyID"] = "question.wellbeing.dataset.getting_by",
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
                                ["fallback"] = "I'm getting by, one day at a time. How about you?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.question.wellbeing.dataset.getting_by.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I'm getting by. Leave it there.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.question.wellbeing.dataset.getting_by.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Getting by.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.question.wellbeing.dataset.getting_by.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I'm getting by. Thanks for asking.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.question.wellbeing.dataset.getting_by.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.wellbeing.dataset",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm getting by, one day at a time. How about you?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.dataset.getting_by.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I'm getting by. Leave it there.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.dataset.getting_by.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Getting by.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.dataset.getting_by.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "I'm getting by. Thanks for asking.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.dataset.getting_by.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "question.wellbeing.dataset.getting_by",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "getting_by",
            ["sourceId"] = "question.wellbeing.dataset.getting_by",
            ["sourcePath"] = "dialogue/wellbeing_content/question_wellbeing_dataset_getting_by.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/WellbeingContent",
        ["namespace"] = "question.wellbeing.dataset",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseAct"] = "REACT",
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
                                ["fallback"] = "I'm getting by, one day at a time. How about you?",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "I'm getting by. Leave it there.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Getting by.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "I'm getting by. Thanks for asking.",
                                ["id"] = "warm",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.wellbeing.dataset.getting_by",
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
                            ["fallback"] = "I'm getting by, one day at a time. How about you?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.wellbeing.dataset.getting_by.say_1",
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
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/wellbeing_content/question_wellbeing_dataset_getting_by.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm getting by, one day at a time. How about you?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.dataset.getting_by.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I'm getting by. Leave it there.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.dataset.getting_by.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Getting by.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.dataset.getting_by.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "I'm getting by. Thanks for asking.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.dataset.getting_by.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["domainPath"] = "wellbeing_content",
        ["exchangeFamily"] = {
            ["familyID"] = "question.wellbeing.default",
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
                                ["fallback"] = "I'm okay. How about you?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.question.wellbeing.default.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I'm managing. Don't press me.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.question.wellbeing.default.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I'm okay.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.question.wellbeing.default.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I'm doing okay. Thanks for asking.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.question.wellbeing.default.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.wellbeing",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm okay. How about you?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.default.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I'm managing. Don't press me.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.default.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "I'm okay.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.default.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "I'm doing okay. Thanks for asking.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.default.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "question.wellbeing.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "default",
            ["sourceId"] = "question.wellbeing.default",
            ["sourcePath"] = "dialogue/wellbeing_content/question_wellbeing_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/WellbeingContent",
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
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseAct"] = "REACT",
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
                                ["fallback"] = "I'm okay. How about you?",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "I'm managing. Don't press me.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "I'm okay.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "I'm doing okay. Thanks for asking.",
                                ["id"] = "warm",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.wellbeing.default",
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
                            ["fallback"] = "I'm okay. How about you?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.wellbeing.default.say_1",
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
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/wellbeing_content/question_wellbeing_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm okay. How about you?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.default.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I'm managing. Don't press me.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.default.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "I'm okay.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.default.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "I'm doing okay. Thanks for asking.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.default.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["domainPath"] = "wellbeing_content",
        ["exchangeFamily"] = {
            ["familyID"] = "question.wellbeing.fatigue",
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
                                ["fallback"] = "I'm worn out, but I can still manage.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.question.wellbeing.fatigue.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.wellbeing",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm worn out, but I can still manage.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.fatigue.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "question.wellbeing.fatigue",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "fatigue",
            ["sourceId"] = "question.wellbeing.fatigue",
            ["sourcePath"] = "dialogue/wellbeing_content/question_wellbeing_fatigue.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/WellbeingContent",
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
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseAct"] = "REACT",
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
                                ["fallback"] = "I'm worn out, but I can still manage.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.wellbeing.fatigue",
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
                            ["fallback"] = "I'm worn out, but I can still manage.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.wellbeing.fatigue.say_1",
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
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/wellbeing_content/question_wellbeing_fatigue.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm worn out, but I can still manage.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.fatigue.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["domainPath"] = "wellbeing_content",
        ["exchangeFamily"] = {
            ["familyID"] = "question.wellbeing.fatigue_alt",
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
                                ["fallback"] = "I'm tired. A little rest would help.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.question.wellbeing.fatigue_alt.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.wellbeing",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm tired. A little rest would help.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.fatigue_alt.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "question.wellbeing.fatigue_alt",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "fatigue_alt",
            ["sourceId"] = "question.wellbeing.fatigue_alt",
            ["sourcePath"] = "dialogue/wellbeing_content/question_wellbeing_fatigue_alt.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/WellbeingContent",
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
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseAct"] = "REACT",
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
                                ["fallback"] = "I'm tired. A little rest would help.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.wellbeing.fatigue_alt",
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
                            ["fallback"] = "I'm tired. A little rest would help.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.wellbeing.fatigue_alt.say_1",
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
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/wellbeing_content/question_wellbeing_fatigue_alt.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm tired. A little rest would help.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.fatigue_alt.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["domainPath"] = "wellbeing_content",
        ["exchangeFamily"] = {
            ["familyID"] = "question.wellbeing.follow_up.responses",
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
                                ["fallback"] = "Doing okay, all things considered.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.question.wellbeing.follow_up.responses.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.wellbeing.follow_up",
            ["textRoles"] = {
                {
                    ["fallback"] = "Doing okay, all things considered.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.follow_up.responses.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "question.wellbeing.follow_up.responses",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "responses",
            ["sourceId"] = "question.wellbeing.follow_up.responses",
            ["sourcePath"] = "dialogue/wellbeing_content/question_wellbeing_follow_up.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/WellbeingContent",
        ["namespace"] = "question.wellbeing.follow_up",
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
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["fallback"] = "Doing okay, all things considered.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionWellbeingDatasetAllThingsConsidered",
                    },
                    {
                        ["fallback"] = "I'm getting by, one day at a time. How about you?",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionWellbeingDatasetGettingBy",
                    },
                    {
                        ["fallback"] = "I'm hanging in there. Thanks for asking.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionWellbeingDatasetHangingIn",
                    },
                    {
                        ["fallback"] = "I'm hungry, but I'll manage. If you have food to spare, I'd appreciate it.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionWellbeingDatasetHungry",
                    },
                    {
                        ["fallback"] = "I'm pretty thirsty. If you have water, could you spare some?",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionWellbeingDatasetThirsty",
                    },
                    {
                        ["fallback"] = "I'm tired, though I can manage for now.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionWellbeingDatasetTired",
                    },
                    {
                        ["fallback"] = "I don't have enough detail to say what's wrong yet.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionWellbeingFollowUpDefault",
                    },
                    {
                        ["fallback"] = "I'm still worn out.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionWellbeingFollowUpFatigue",
                    },
                    {
                        ["fallback"] = "I'm still hungry.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionWellbeingFollowUpHunger",
                    },
                    {
                        ["fallback"] = "I took a bad hit. It's still bothering me.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionWellbeingFollowUpInjured",
                    },
                    {
                        ["fallback"] = "I'm still pretty shaken up.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionWellbeingFollowUpPanic",
                    },
                    {
                        ["fallback"] = "I'm still tense and having trouble settling down.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionWellbeingFollowUpStress",
                    },
                    {
                        ["fallback"] = "I'm still pretty thirsty.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionWellbeingFollowUpThirst",
                    },
                    {
                        ["fallback"] = "I don't have enough detail to say what's wrong yet.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionWellbeingFollowUpUnknown",
                    },
                    {
                        ["fallback"] = "I took a bad hit, but I'm steady enough to keep moving.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionWellbeingGroundedFriendlyFact",
                    },
                    {
                        ["fallback"] = "Thanks for checking in.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionWellbeingGroundedFriendlyTone",
                    },
                    {
                        ["fallback"] = "I'm hurt, but I'm managing.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionWellbeingGroundedWithdrawnFact",
                    },
                    {
                        ["fallback"] = "I'd rather not make a big thing of it.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionWellbeingGroundedWithdrawnTone",
                    },
                },
                ["textTarget"] = "convo/SemanticResponses",
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
                                ["fallback"] = "Doing okay, all things considered.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.wellbeing.follow_up.responses",
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
                            ["fallback"] = "Doing okay, all things considered.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.wellbeing.follow_up.responses.say_1",
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
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/wellbeing_content/question_wellbeing_follow_up.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Doing okay, all things considered.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.follow_up.responses.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["domainPath"] = "wellbeing_content",
        ["exchangeFamily"] = {
            ["familyID"] = "question.wellbeing.hunger",
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
                                ["fallback"] = "I'm pretty hungry, if I'm honest. Do you have anything to eat?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.question.wellbeing.hunger.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.wellbeing",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm pretty hungry, if I'm honest. Do you have anything to eat?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.hunger.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "question.wellbeing.hunger",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "hunger",
            ["sourceId"] = "question.wellbeing.hunger",
            ["sourcePath"] = "dialogue/wellbeing_content/question_wellbeing_hunger.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/WellbeingContent",
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
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseAct"] = "REACT",
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
                                ["fallback"] = "I'm pretty hungry, if I'm honest. Do you have anything to eat?",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.wellbeing.hunger",
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
                            ["fallback"] = "I'm pretty hungry, if I'm honest. Do you have anything to eat?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.wellbeing.hunger.say_1",
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
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/wellbeing_content/question_wellbeing_hunger.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm pretty hungry, if I'm honest. Do you have anything to eat?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.hunger.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["domainPath"] = "wellbeing_content",
        ["exchangeFamily"] = {
            ["familyID"] = "question.wellbeing.hunger_alt",
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
                                ["fallback"] = "I'm getting hungry. Could you spare something to eat?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.question.wellbeing.hunger_alt.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.wellbeing",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm getting hungry. Could you spare something to eat?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.hunger_alt.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "question.wellbeing.hunger_alt",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "hunger_alt",
            ["sourceId"] = "question.wellbeing.hunger_alt",
            ["sourcePath"] = "dialogue/wellbeing_content/question_wellbeing_hunger_alt.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/WellbeingContent",
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
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseAct"] = "REACT",
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
                                ["fallback"] = "I'm getting hungry. Could you spare something to eat?",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.wellbeing.hunger_alt",
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
                            ["fallback"] = "I'm getting hungry. Could you spare something to eat?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.wellbeing.hunger_alt.say_1",
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
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/wellbeing_content/question_wellbeing_hunger_alt.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm getting hungry. Could you spare something to eat?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.hunger_alt.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["domainPath"] = "wellbeing_content",
        ["exchangeFamily"] = {
            ["familyID"] = "question.wellbeing.injured",
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
                                ["fallback"] = "A little banged up, but I'll manage.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.question.wellbeing.injured.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I'm hurt. That's all I can say.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.question.wellbeing.injured.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I'm hurt. I can manage.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.question.wellbeing.injured.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I took a hit, but I'm steady enough to keep going.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.question.wellbeing.injured.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.wellbeing",
            ["textRoles"] = {
                {
                    ["fallback"] = "A little banged up, but I'll manage.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.injured.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I'm hurt. That's all I can say.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.injured.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "I'm hurt. I can manage.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.injured.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "I took a hit, but I'm steady enough to keep going.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.injured.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "question.wellbeing.injured",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "injured",
            ["sourceId"] = "question.wellbeing.injured",
            ["sourcePath"] = "dialogue/wellbeing_content/question_wellbeing_injured.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/WellbeingContent",
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
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseAct"] = "REACT",
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
                                ["fallback"] = "A little banged up, but I'll manage.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "I'm hurt. That's all I can say.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "I'm hurt. I can manage.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "I took a hit, but I'm steady enough to keep going.",
                                ["id"] = "warm",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.wellbeing.injured",
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
                            ["fallback"] = "A little banged up, but I'll manage.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.wellbeing.injured.say_1",
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
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/wellbeing_content/question_wellbeing_injured.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "A little banged up, but I'll manage.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.injured.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I'm hurt. That's all I can say.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.injured.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "I'm hurt. I can manage.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.injured.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "I took a hit, but I'm steady enough to keep going.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.injured.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["domainPath"] = "wellbeing_content",
        ["exchangeFamily"] = {
            ["familyID"] = "question.wellbeing.panic",
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
                                ["fallback"] = "I'm pretty shaken up right now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.question.wellbeing.panic.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.wellbeing",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm pretty shaken up right now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.panic.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "question.wellbeing.panic",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "panic",
            ["sourceId"] = "question.wellbeing.panic",
            ["sourcePath"] = "dialogue/wellbeing_content/question_wellbeing_panic.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/WellbeingContent",
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
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseAct"] = "REACT",
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
                                ["fallback"] = "I'm pretty shaken up right now.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.wellbeing.panic",
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
                            ["fallback"] = "I'm pretty shaken up right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.wellbeing.panic.say_1",
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
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/wellbeing_content/question_wellbeing_panic.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm pretty shaken up right now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.panic.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["domainPath"] = "wellbeing_content",
        ["exchangeFamily"] = {
            ["familyID"] = "question.wellbeing.stress",
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
                                ["fallback"] = "I'm tense, but I can keep going.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.question.wellbeing.stress.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.wellbeing",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm tense, but I can keep going.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.stress.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "question.wellbeing.stress",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "stress",
            ["sourceId"] = "question.wellbeing.stress",
            ["sourcePath"] = "dialogue/wellbeing_content/question_wellbeing_stress.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/WellbeingContent",
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
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseAct"] = "REACT",
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
                                ["fallback"] = "I'm tense, but I can keep going.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.wellbeing.stress",
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
                            ["fallback"] = "I'm tense, but I can keep going.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.wellbeing.stress.say_1",
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
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/wellbeing_content/question_wellbeing_stress.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm tense, but I can keep going.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.stress.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["domainPath"] = "wellbeing_content",
        ["exchangeFamily"] = {
            ["familyID"] = "question.wellbeing.thirst",
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
                                ["fallback"] = "I'm pretty thirsty. Could you spare some water?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.question.wellbeing.thirst.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.wellbeing",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm pretty thirsty. Could you spare some water?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.thirst.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "question.wellbeing.thirst",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "thirst",
            ["sourceId"] = "question.wellbeing.thirst",
            ["sourcePath"] = "dialogue/wellbeing_content/question_wellbeing_thirst.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/WellbeingContent",
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
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseAct"] = "REACT",
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
                                ["fallback"] = "I'm pretty thirsty. Could you spare some water?",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.wellbeing.thirst",
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
                            ["fallback"] = "I'm pretty thirsty. Could you spare some water?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.wellbeing.thirst.say_1",
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
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/wellbeing_content/question_wellbeing_thirst.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm pretty thirsty. Could you spare some water?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.thirst.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["domainPath"] = "wellbeing_content",
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
                                ["variantCount"] = 10,
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
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "question.wellbeing.thirst_alt",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "thirst_alt",
            ["sourceId"] = "question.wellbeing.thirst_alt",
            ["sourcePath"] = "dialogue/wellbeing_content/question_wellbeing_thirst_alt.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/WellbeingContent",
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
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseAct"] = "REACT",
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
                                ["fallback"] = "I could really use a drink. Do you have any water?",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "social_interaction",
                },
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
                            ["templateID"] = "convo.question.wellbeing.thirst_alt.say_1",
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
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/wellbeing_content/question_wellbeing_thirst_alt.json",
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
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
