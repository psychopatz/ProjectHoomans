-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_whats_up",
        ["domainPath"] = "conversation_whats_up",
        ["exchangeFamily"] = {
            ["familyID"] = "question.whats_up.busy",
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
                                ["fallback"] = "I'm keeping busy and trying to stay useful.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.question.whats_up.busy.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Keeping busy. Don't distract me.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.question.whats_up.busy.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Keeping busy.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.question.whats_up.busy.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I'm keeping busy and trying to stay useful. There's always something to do.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.question.whats_up.busy.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.whats_up",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm keeping busy and trying to stay useful.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.whats_up.busy.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Keeping busy. Don't distract me.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.whats_up.busy.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Keeping busy.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.whats_up.busy.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "I'm keeping busy and trying to stay useful. There's always something to do.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.whats_up.busy.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "question.whats_up.busy",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "busy",
            ["sourceId"] = "question.whats_up.busy",
            ["sourcePath"] = "dialogue/conversation_whats_up/question_whats_up_busy.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationWhatsUp",
        ["namespace"] = "question.whats_up",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
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
                                ["fallback"] = "I'm keeping busy and trying to stay useful.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Keeping busy. Don't distract me.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Keeping busy.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "I'm keeping busy and trying to stay useful. There's always something to do.",
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
            ["responsePlanID"] = "question.whats_up.busy",
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
                            ["fallback"] = "I'm keeping busy and trying to stay useful.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.whats_up.busy.say_1",
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
        ["sourceShard"] = "dialogue/conversation_whats_up/question_whats_up_busy.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm keeping busy and trying to stay useful.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.whats_up.busy.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Keeping busy. Don't distract me.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.whats_up.busy.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Keeping busy.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.whats_up.busy.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "I'm keeping busy and trying to stay useful. There's always something to do.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.whats_up.busy.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_whats_up",
        ["domainPath"] = "conversation_whats_up",
        ["exchangeFamily"] = {
            ["familyID"] = "question.whats_up.default",
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
                                ["fallback"] = "Not much. I'm just trying to keep things together.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.question.whats_up.default.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Nothing worth discussing. Stay alert.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.question.whats_up.default.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Just getting by.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.question.whats_up.default.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Not much. I'm just trying to keep things together. Good to see you, though.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.question.whats_up.default.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.whats_up",
            ["textRoles"] = {
                {
                    ["fallback"] = "Not much. I'm just trying to keep things together.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.whats_up.default.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Nothing worth discussing. Stay alert.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.whats_up.default.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Just getting by.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.whats_up.default.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "Not much. I'm just trying to keep things together. Good to see you, though.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.whats_up.default.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "question.whats_up.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "default",
            ["sourceId"] = "question.whats_up.default",
            ["sourcePath"] = "dialogue/conversation_whats_up/question_whats_up_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationWhatsUp",
        ["namespace"] = "question.whats_up",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
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
                                ["fallback"] = "Not much. I'm just trying to keep things together.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Nothing worth discussing. Stay alert.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Just getting by.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "Not much. I'm just trying to keep things together. Good to see you, though.",
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
            ["responsePlanID"] = "question.whats_up.default",
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
                            ["fallback"] = "Not much. I'm just trying to keep things together.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.whats_up.default.say_1",
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
        ["sourceShard"] = "dialogue/conversation_whats_up/question_whats_up_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Not much. I'm just trying to keep things together.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.whats_up.default.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Nothing worth discussing. Stay alert.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.whats_up.default.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Just getting by.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.whats_up.default.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "Not much. I'm just trying to keep things together. Good to see you, though.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.whats_up.default.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_whats_up",
        ["domainPath"] = "conversation_whats_up",
        ["exchangeFamily"] = {
            ["familyID"] = "question.whats_up.default_alt",
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
                                ["fallback"] = "Same as ever. Staying alive and watching the road.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.question.whats_up.default_alt.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Staying alive. Keep your eyes open.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.question.whats_up.default_alt.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Staying alive.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.question.whats_up.default_alt.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Same as ever. Staying alive and watching the road. What about you?",
                                ["id"] = "warm",
                                ["templateID"] = "convo.question.whats_up.default_alt.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.whats_up",
            ["textRoles"] = {
                {
                    ["fallback"] = "Same as ever. Staying alive and watching the road.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.whats_up.default_alt.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Staying alive. Keep your eyes open.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.whats_up.default_alt.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Staying alive.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.whats_up.default_alt.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "Same as ever. Staying alive and watching the road. What about you?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.whats_up.default_alt.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "question.whats_up.default_alt",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "default_alt",
            ["sourceId"] = "question.whats_up.default_alt",
            ["sourcePath"] = "dialogue/conversation_whats_up/question_whats_up_default_alt.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationWhatsUp",
        ["namespace"] = "question.whats_up",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
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
                                ["fallback"] = "Same as ever. Staying alive and watching the road.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Staying alive. Keep your eyes open.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Staying alive.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "Same as ever. Staying alive and watching the road. What about you?",
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
            ["responsePlanID"] = "question.whats_up.default_alt",
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
                            ["fallback"] = "Same as ever. Staying alive and watching the road.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.whats_up.default_alt.say_1",
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
        ["sourceShard"] = "dialogue/conversation_whats_up/question_whats_up_default_alt.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Same as ever. Staying alive and watching the road.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.whats_up.default_alt.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Staying alive. Keep your eyes open.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.whats_up.default_alt.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Staying alive.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.whats_up.default_alt.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "Same as ever. Staying alive and watching the road. What about you?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.whats_up.default_alt.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_whats_up",
        ["domainPath"] = "conversation_whats_up",
        ["exchangeFamily"] = {
            ["familyID"] = "question.whats_up.traveling",
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
                                ["fallback"] = "I'm keeping moving and watching what is ahead.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.question.whats_up.traveling.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Keeping moving. Don't slow me down.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.question.whats_up.traveling.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Keeping moving.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.question.whats_up.traveling.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I'm keeping moving and watching what is ahead. Come along if you want.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.question.whats_up.traveling.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.whats_up",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm keeping moving and watching what is ahead.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.whats_up.traveling.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Keeping moving. Don't slow me down.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.whats_up.traveling.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Keeping moving.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.whats_up.traveling.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "I'm keeping moving and watching what is ahead. Come along if you want.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.whats_up.traveling.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "question.whats_up.traveling",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "traveling",
            ["sourceId"] = "question.whats_up.traveling",
            ["sourcePath"] = "dialogue/conversation_whats_up/question_whats_up_traveling.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationWhatsUp",
        ["namespace"] = "question.whats_up",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
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
                                ["fallback"] = "I'm keeping moving and watching what is ahead.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Keeping moving. Don't slow me down.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Keeping moving.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "I'm keeping moving and watching what is ahead. Come along if you want.",
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
            ["responsePlanID"] = "question.whats_up.traveling",
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
                            ["fallback"] = "I'm keeping moving and watching what is ahead.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.whats_up.traveling.say_1",
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
        ["sourceShard"] = "dialogue/conversation_whats_up/question_whats_up_traveling.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm keeping moving and watching what is ahead.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.whats_up.traveling.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Keeping moving. Don't slow me down.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.whats_up.traveling.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Keeping moving.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.whats_up.traveling.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "I'm keeping moving and watching what is ahead. Come along if you want.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.whats_up.traveling.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_whats_up",
        ["domainPath"] = "conversation_whats_up",
        ["exchangeFamily"] = {
            ["familyID"] = "question.whats_up.weather",
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
                                ["fallback"] = "The weather is the main thing on my mind right now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.question.whats_up.weather.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Watching the weather. Stay focused.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.question.whats_up.weather.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Watching the weather.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.question.whats_up.weather.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "The weather is the main thing on my mind right now. How are you holding up?",
                                ["id"] = "warm",
                                ["templateID"] = "convo.question.whats_up.weather.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.whats_up",
            ["textRoles"] = {
                {
                    ["fallback"] = "The weather is the main thing on my mind right now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.whats_up.weather.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Watching the weather. Stay focused.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.whats_up.weather.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Watching the weather.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.whats_up.weather.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "The weather is the main thing on my mind right now. How are you holding up?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.whats_up.weather.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "question.whats_up.weather",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "weather",
            ["sourceId"] = "question.whats_up.weather",
            ["sourcePath"] = "dialogue/conversation_whats_up/question_whats_up_weather.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationWhatsUp",
        ["namespace"] = "question.whats_up",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
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
                                ["fallback"] = "The weather is the main thing on my mind right now.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Watching the weather. Stay focused.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Watching the weather.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "The weather is the main thing on my mind right now. How are you holding up?",
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
            ["responsePlanID"] = "question.whats_up.weather",
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
                            ["fallback"] = "The weather is the main thing on my mind right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.whats_up.weather.say_1",
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
        ["sourceShard"] = "dialogue/conversation_whats_up/question_whats_up_weather.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "The weather is the main thing on my mind right now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.whats_up.weather.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Watching the weather. Stay focused.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.whats_up.weather.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Watching the weather.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.whats_up.weather.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "The weather is the main thing on my mind right now. How are you holding up?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.whats_up.weather.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
}
