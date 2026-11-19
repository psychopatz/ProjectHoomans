-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "navigation",
        ["domainPath"] = "navigation",
        ["exchangeFamily"] = {
            ["familyID"] = "navigation.camp",
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
                                ["fallback"] = "Where should we set up?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.navigation.camp.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Where do you want to risk it?",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.navigation.camp.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Where?",
                                ["id"] = "terse",
                                ["templateID"] = "convo.navigation.camp.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Where should we set up camp?",
                                ["id"] = "warm",
                                ["templateID"] = "convo.navigation.camp.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "navigation",
            ["slots"] = {
                ["location"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.location",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "Where should we set up?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.navigation.camp.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Where do you want to risk it?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.navigation.camp.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Where?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.navigation.camp.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "Where should we set up camp?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.navigation.camp.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "navigation.camp",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "camp",
            ["sourceId"] = "navigation.camp",
            ["sourcePath"] = "dialogue/navigation/navigation_camp.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/Navigation",
        ["namespace"] = "navigation",
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
                    ["domain"] = "navigation",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:navigation",
                ["responseAct"] = "NAVIGATION_RESPONSE",
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
                                ["fallback"] = "Where should we set up?",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Where do you want to risk it?",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Where?",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "Where should we set up camp?",
                                ["id"] = "warm",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "navigation",
                    ["id"] = "navigation",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "NAVIGATION_RESPONSE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "navigation.camp",
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
                            ["fallback"] = "Where should we set up?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.navigation.camp.say_1",
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
            ["location"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.location",
            },
        },
        ["sourceShard"] = "dialogue/navigation/navigation_camp.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Where should we set up?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.navigation.camp.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Where do you want to risk it?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.navigation.camp.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Where?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.navigation.camp.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "Where should we set up camp?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.navigation.camp.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "navigation",
        ["domainPath"] = "navigation",
        ["exchangeFamily"] = {
            ["familyID"] = "navigation.camp_empty",
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
                                ["fallback"] = "I don't see a good place to set up here.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.navigation.camp_empty.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "There is nowhere safe to set up here.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.navigation.camp_empty.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "No good place here.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.navigation.camp_empty.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I don't see a safe place to set up here.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.navigation.camp_empty.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "navigation",
            ["slots"] = {
                ["location"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.location",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "I don't see a good place to set up here.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.navigation.camp_empty.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "There is nowhere safe to set up here.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.navigation.camp_empty.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "No good place here.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.navigation.camp_empty.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "I don't see a safe place to set up here.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.navigation.camp_empty.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "navigation.camp_empty",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "camp_empty",
            ["sourceId"] = "navigation.camp_empty",
            ["sourcePath"] = "dialogue/navigation/navigation_camp_empty.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/Navigation",
        ["namespace"] = "navigation",
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
                    ["domain"] = "navigation",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:navigation",
                ["responseAct"] = "NAVIGATION_RESPONSE",
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
                                ["fallback"] = "I don't see a good place to set up here.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "There is nowhere safe to set up here.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "No good place here.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "I don't see a safe place to set up here.",
                                ["id"] = "warm",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "navigation",
                    ["id"] = "navigation",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "NAVIGATION_RESPONSE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "navigation.camp_empty",
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
                            ["fallback"] = "I don't see a good place to set up here.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.navigation.camp_empty.say_1",
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
            ["location"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.location",
            },
        },
        ["sourceShard"] = "dialogue/navigation/navigation_camp_empty.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I don't see a good place to set up here.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.navigation.camp_empty.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "There is nowhere safe to set up here.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.navigation.camp_empty.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "No good place here.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.navigation.camp_empty.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "I don't see a safe place to set up here.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.navigation.camp_empty.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "navigation",
        ["domainPath"] = "navigation",
        ["exchangeFamily"] = {
            ["familyID"] = "navigation.default",
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
                                ["fallback"] = "All right. What would you like to discuss?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.navigation.default.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "All right. What now?",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.navigation.default.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "What is it?",
                                ["id"] = "terse",
                                ["templateID"] = "convo.navigation.default.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Sure. What would you like to discuss?",
                                ["id"] = "warm",
                                ["templateID"] = "convo.navigation.default.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "navigation",
            ["slots"] = {
                ["location"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.location",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "All right. What would you like to discuss?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.navigation.default.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "All right. What now?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.navigation.default.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "What is it?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.navigation.default.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "Sure. What would you like to discuss?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.navigation.default.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "navigation.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "default",
            ["sourceId"] = "navigation.default",
            ["sourcePath"] = "dialogue/navigation/navigation_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/Navigation",
        ["namespace"] = "navigation",
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
                    ["domain"] = "navigation",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:navigation",
                ["responseAct"] = "NAVIGATION_RESPONSE",
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
                                ["fallback"] = "All right. What would you like to discuss?",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "All right. What now?",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "What is it?",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "Sure. What would you like to discuss?",
                                ["id"] = "warm",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "navigation",
                    ["id"] = "navigation",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "NAVIGATION_RESPONSE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "navigation.default",
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
                            ["fallback"] = "All right. What would you like to discuss?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.navigation.default.say_1",
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
            ["location"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.location",
            },
        },
        ["sourceShard"] = "dialogue/navigation/navigation_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "All right. What would you like to discuss?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.navigation.default.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "All right. What now?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.navigation.default.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "What is it?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.navigation.default.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "Sure. What would you like to discuss?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.navigation.default.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "navigation",
        ["domainPath"] = "navigation",
        ["exchangeFamily"] = {
            ["familyID"] = "navigation.orders",
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
                                ["fallback"] = "All right. What do you need?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.navigation.orders.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "All right. What is it?",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.navigation.orders.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "What do you need?",
                                ["id"] = "terse",
                                ["templateID"] = "convo.navigation.orders.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Sure. What do you need?",
                                ["id"] = "warm",
                                ["templateID"] = "convo.navigation.orders.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "navigation",
            ["slots"] = {
                ["location"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.location",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "All right. What do you need?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.navigation.orders.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "All right. What is it?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.navigation.orders.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "What do you need?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.navigation.orders.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "Sure. What do you need?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.navigation.orders.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "navigation.orders",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "orders",
            ["sourceId"] = "navigation.orders",
            ["sourcePath"] = "dialogue/navigation/navigation_orders.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/Navigation",
        ["namespace"] = "navigation",
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
                    ["domain"] = "navigation",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:navigation",
                ["responseAct"] = "NAVIGATION_RESPONSE",
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
                                ["fallback"] = "All right. What do you need?",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "All right. What is it?",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "What do you need?",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "Sure. What do you need?",
                                ["id"] = "warm",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "navigation",
                    ["id"] = "navigation",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "NAVIGATION_RESPONSE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "navigation.orders",
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
                            ["fallback"] = "All right. What do you need?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.navigation.orders.say_1",
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
            ["location"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.location",
            },
        },
        ["sourceShard"] = "dialogue/navigation/navigation_orders.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "All right. What do you need?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.navigation.orders.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "All right. What is it?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.navigation.orders.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "What do you need?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.navigation.orders.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "Sure. What do you need?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.navigation.orders.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "navigation",
        ["domainPath"] = "navigation",
        ["exchangeFamily"] = {
            ["familyID"] = "navigation.subject_change",
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
                                ["fallback"] = "All right. What did you want to talk about?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.navigation.subject_change.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "All right. What is it?",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.navigation.subject_change.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "What else?",
                                ["id"] = "terse",
                                ["templateID"] = "convo.navigation.subject_change.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Sure. What did you want to talk about?",
                                ["id"] = "warm",
                                ["templateID"] = "convo.navigation.subject_change.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "navigation",
            ["slots"] = {
                ["location"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.location",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "All right. What did you want to talk about?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.navigation.subject_change.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "All right. What is it?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.navigation.subject_change.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "What else?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.navigation.subject_change.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "Sure. What did you want to talk about?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.navigation.subject_change.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "navigation.subject_change",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "subject_change",
            ["sourceId"] = "navigation.subject_change",
            ["sourcePath"] = "dialogue/navigation/navigation_subject_change.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/Navigation",
        ["namespace"] = "navigation",
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
                    ["domain"] = "navigation",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:navigation",
                ["responseAct"] = "NAVIGATION_RESPONSE",
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
                                ["fallback"] = "All right. What did you want to talk about?",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "All right. What is it?",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "What else?",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "Sure. What did you want to talk about?",
                                ["id"] = "warm",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "navigation",
                    ["id"] = "navigation",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "NAVIGATION_RESPONSE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "navigation.subject_change",
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
                            ["fallback"] = "All right. What did you want to talk about?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.navigation.subject_change.say_1",
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
            ["location"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.location",
            },
        },
        ["sourceShard"] = "dialogue/navigation/navigation_subject_change.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "All right. What did you want to talk about?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.navigation.subject_change.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "All right. What is it?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.navigation.subject_change.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "What else?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.navigation.subject_change.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "Sure. What did you want to talk about?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.navigation.subject_change.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
}
