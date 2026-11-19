-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_apology",
        ["domainPath"] = "social_apology",
        ["exchangeFamily"] = {
            ["familyID"] = "social.apology.default",
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
                                ["fallback"] = "What are you apologizing for?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.apology.default.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "What are you apologizing for?",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.social.apology.default.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "What are you apologizing for?",
                                ["id"] = "terse",
                                ["templateID"] = "convo.social.apology.default.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "What are you apologizing for?",
                                ["id"] = "warm",
                                ["templateID"] = "convo.social.apology.default.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.apology",
            ["textRoles"] = {
                {
                    ["fallback"] = "What are you apologizing for?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.apology.default.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "What are you apologizing for?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.apology.default.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "What are you apologizing for?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.apology.default.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "What are you apologizing for?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.apology.default.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "social.apology.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "default",
            ["sourceId"] = "social.apology.default",
            ["sourcePath"] = "dialogue/social_apology/social_apology_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialApology",
        ["namespace"] = "social.apology",
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
                ["category"] = "projecthoomans:social.apology",
                ["responseAct"] = "APOLOGY_RESPONSE",
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
                                ["fallback"] = "What are you apologizing for?",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "What are you apologizing for?",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "What are you apologizing for?",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "What are you apologizing for?",
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
            ["dialogueAct"] = "APOLOGY_RESPONSE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.apology.default",
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
                            ["fallback"] = "What are you apologizing for?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.apology.default.say_1",
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
        ["sourceShard"] = "dialogue/social_apology/social_apology_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "What are you apologizing for?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.apology.default.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "What are you apologizing for?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.apology.default.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "What are you apologizing for?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.apology.default.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "What are you apologizing for?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.apology.default.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_apology",
        ["domainPath"] = "social_apology",
        ["exchangeFamily"] = {
            ["familyID"] = "social.apology.friendly",
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
                                ["fallback"] = "It's okay. We can put that behind us.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.apology.friendly.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I heard you. Leave it there.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.social.apology.friendly.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "It's okay.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.social.apology.friendly.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "It's okay. I appreciate you saying that.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.social.apology.friendly.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.apology",
            ["textRoles"] = {
                {
                    ["fallback"] = "It's okay. We can put that behind us.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.apology.friendly.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I heard you. Leave it there.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.apology.friendly.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "It's okay.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.apology.friendly.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "It's okay. I appreciate you saying that.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.apology.friendly.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "social.apology.friendly",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "friendly",
            ["sourceId"] = "social.apology.friendly",
            ["sourcePath"] = "dialogue/social_apology/social_apology.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialApology",
        ["namespace"] = "social.apology",
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
                ["category"] = "projecthoomans:social.apology",
                ["responseAct"] = "APOLOGY_RESPONSE",
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
                                ["fallback"] = "It's okay. We can put that behind us.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "I heard you. Leave it there.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "It's okay.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "It's okay. I appreciate you saying that.",
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
            ["dialogueAct"] = "APOLOGY_RESPONSE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.apology.friendly",
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
                            ["fallback"] = "It's okay. We can put that behind us.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.apology.friendly.say_1",
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
        ["sourceShard"] = "dialogue/social_apology/social_apology.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "It's okay. We can put that behind us.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.apology.friendly.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I heard you. Leave it there.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.apology.friendly.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "It's okay.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.apology.friendly.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "It's okay. I appreciate you saying that.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.apology.friendly.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_apology",
        ["domainPath"] = "social_apology",
        ["exchangeFamily"] = {
            ["familyID"] = "social.apology.stressed",
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
                                ["fallback"] = "I know things are tense. Let's keep it calm.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.apology.stressed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Things are tense. Leave it there.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.social.apology.stressed.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Keep it calm.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.social.apology.stressed.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I know things are tense. Thanks for saying that.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.social.apology.stressed.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.apology",
            ["textRoles"] = {
                {
                    ["fallback"] = "I know things are tense. Let's keep it calm.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.apology.stressed.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Things are tense. Leave it there.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.apology.stressed.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Keep it calm.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.apology.stressed.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "I know things are tense. Thanks for saying that.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.apology.stressed.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "social.apology.stressed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "stressed",
            ["sourceId"] = "social.apology.stressed",
            ["sourcePath"] = "dialogue/social_apology/social_apology_stressed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialApology",
        ["namespace"] = "social.apology",
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
                ["category"] = "projecthoomans:social.apology",
                ["responseAct"] = "APOLOGY_RESPONSE",
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
                                ["fallback"] = "I know things are tense. Let's keep it calm.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Things are tense. Leave it there.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Keep it calm.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "I know things are tense. Thanks for saying that.",
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
            ["dialogueAct"] = "APOLOGY_RESPONSE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.apology.stressed",
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
                            ["fallback"] = "I know things are tense. Let's keep it calm.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.apology.stressed.say_1",
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
        ["sourceShard"] = "dialogue/social_apology/social_apology_stressed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I know things are tense. Let's keep it calm.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.apology.stressed.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Things are tense. Leave it there.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.apology.stressed.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Keep it calm.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.apology.stressed.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "I know things are tense. Thanks for saying that.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.apology.stressed.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_apology",
        ["domainPath"] = "social_apology",
        ["exchangeFamily"] = {
            ["familyID"] = "social.apology.withdrawn",
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
                                ["fallback"] = "All right. Let's leave it there.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.apology.withdrawn.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "All right. Leave it there.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.social.apology.withdrawn.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Leave it.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.social.apology.withdrawn.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "All right. Let's leave it there for now.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.social.apology.withdrawn.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.apology",
            ["textRoles"] = {
                {
                    ["fallback"] = "All right. Let's leave it there.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.apology.withdrawn.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "All right. Leave it there.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.apology.withdrawn.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Leave it.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.apology.withdrawn.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "All right. Let's leave it there for now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.apology.withdrawn.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "social.apology.withdrawn",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "withdrawn",
            ["sourceId"] = "social.apology.withdrawn",
            ["sourcePath"] = "dialogue/social_apology/social_apology_withdrawn.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialApology",
        ["namespace"] = "social.apology",
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
                ["category"] = "projecthoomans:social.apology",
                ["responseAct"] = "APOLOGY_RESPONSE",
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
                                ["fallback"] = "All right. Let's leave it there.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "All right. Leave it there.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Leave it.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "All right. Let's leave it there for now.",
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
            ["dialogueAct"] = "APOLOGY_RESPONSE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.apology.withdrawn",
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
                            ["fallback"] = "All right. Let's leave it there.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.apology.withdrawn.say_1",
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
        ["sourceShard"] = "dialogue/social_apology/social_apology_withdrawn.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "All right. Let's leave it there.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.apology.withdrawn.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "All right. Leave it there.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.apology.withdrawn.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Leave it.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.apology.withdrawn.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "All right. Let's leave it there for now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.apology.withdrawn.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
}
