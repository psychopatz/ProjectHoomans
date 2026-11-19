-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_semantic_responses",
        ["domainPath"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "accept",
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
                                ["fallback"] = "Okay, I'll get started.",
                                ["id"] = "accept.dataset.pending_started",
                                ["templateID"] = "convo.accept.say.1.accept.dataset.pending_started",
                                ["textRole"] = "spoken_action",
                                ["when"] = {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.hasPendingRequest",
                                    ["value"] = true,
                                },
                            },
                            {
                                ["fallback"] = "All right. I can take care of that.",
                                ["id"] = "accept.dataset.pending_care",
                                ["templateID"] = "convo.accept.say.1.accept.dataset.pending_care",
                                ["textRole"] = "spoken_action",
                                ["when"] = {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.hasPendingRequest",
                                    ["value"] = true,
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "Okay, I'll get started.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.accept.say.1.accept.dataset.pending_started",
                    ["variantID"] = "accept.dataset.pending_started",
                },
                {
                    ["fallback"] = "All right. I can take care of that.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.accept.say.1.accept.dataset.pending_care",
                    ["variantID"] = "accept.dataset.pending_care",
                },
            },
        },
        ["id"] = "accept",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["sourceId"] = "accept",
            ["sourcePath"] = "dialogue/core_semantic_responses/accept.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
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
                ["responseAct"] = "ACCEPT",
                ["responsePoolID"] = "accept",
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
                                ["fallback"] = "Okay, I'll get started.",
                                ["id"] = "accept.dataset.pending_started",
                                ["metadata"] = {
                                    ["fallback"] = "Okay, I'll get started.",
                                    ["priority"] = 1,
                                    ["templateID"] = "accept.dataset.pending_started",
                                },
                                ["when"] = {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.hasPendingRequest",
                                    ["value"] = true,
                                },
                            },
                            {
                                ["fallback"] = "All right. I can take care of that.",
                                ["id"] = "accept.dataset.pending_care",
                                ["metadata"] = {
                                    ["fallback"] = "All right. I can take care of that.",
                                    ["priority"] = 1,
                                    ["templateID"] = "accept.dataset.pending_care",
                                },
                                ["when"] = {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.hasPendingRequest",
                                    ["value"] = true,
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
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "ACCEPT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "accept",
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
                            ["fallback"] = "Okay, I'll get started.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.accept.say_1",
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
        ["sourceShard"] = "dialogue/core_semantic_responses/accept.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Okay, I'll get started.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.accept.say.1.accept.dataset.pending_started",
                ["variantID"] = "accept.dataset.pending_started",
            },
            {
                ["fallback"] = "All right. I can take care of that.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.accept.say.1.accept.dataset.pending_care",
                ["variantID"] = "accept.dataset.pending_care",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["domainPath"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "compliment",
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
                                ["fallback"] = "That's kind of you. I appreciate it.",
                                ["id"] = "compliment.dataset.kind_of_you",
                                ["templateID"] = "convo.compliment.say.1.compliment.dataset.kind_of_you",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "Aw, thank you. That means a lot.",
                                ["id"] = "compliment.dataset.means_a_lot",
                                ["templateID"] = "convo.compliment.say.1.compliment.dataset.means_a_lot",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "That's kind of you. I appreciate it.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.compliment.say.1.compliment.dataset.kind_of_you",
                    ["variantID"] = "compliment.dataset.kind_of_you",
                },
                {
                    ["fallback"] = "Aw, thank you. That means a lot.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.compliment.say.1.compliment.dataset.means_a_lot",
                    ["variantID"] = "compliment.dataset.means_a_lot",
                },
            },
        },
        ["id"] = "compliment",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["sourceId"] = "compliment",
            ["sourcePath"] = "dialogue/core_semantic_responses/compliment.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
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
                ["responseAct"] = "COMPLIMENT",
                ["responsePoolID"] = "compliment",
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
                                ["fallback"] = "That's kind of you. I appreciate it.",
                                ["id"] = "compliment.dataset.kind_of_you",
                                ["metadata"] = {
                                    ["fallback"] = "That's kind of you. I appreciate it.",
                                    ["templateID"] = "compliment.dataset.kind_of_you",
                                },
                            },
                            {
                                ["fallback"] = "Aw, thank you. That means a lot.",
                                ["id"] = "compliment.dataset.means_a_lot",
                                ["metadata"] = {
                                    ["fallback"] = "Aw, thank you. That means a lot.",
                                    ["templateID"] = "compliment.dataset.means_a_lot",
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
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "COMPLIMENT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "compliment",
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
                            ["fallback"] = "That's kind of you. I appreciate it.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.compliment.say_1",
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
        ["sourceShard"] = "dialogue/core_semantic_responses/compliment.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That's kind of you. I appreciate it.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.compliment.say.1.compliment.dataset.kind_of_you",
                ["variantID"] = "compliment.dataset.kind_of_you",
            },
            {
                ["fallback"] = "Aw, thank you. That means a lot.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.compliment.say.1.compliment.dataset.means_a_lot",
                ["variantID"] = "compliment.dataset.means_a_lot",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["domainPath"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "flow.weather.raining",
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
                                ["fallback"] = "It is raining right now. We can return to that proposal when you are ready.",
                                ["id"] = "flow.weather.raining.dataset.contextual_switch",
                                ["templateID"] = "convo.flow.weather.raining.say.1.flow.weather.raining.dataset.contextual_switch",
                                ["textRole"] = "spoken_action",
                                ["when"] = {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.pattern",
                                    ["value"] = "pnc.dataset.question.weather.can_we_talk_about_the_weather",
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "flow.weather",
            ["textRoles"] = {
                {
                    ["fallback"] = "It is raining right now. We can return to that proposal when you are ready.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.weather.raining.say.1.flow.weather.raining.dataset.contextual_switch",
                    ["variantID"] = "flow.weather.raining.dataset.contextual_switch",
                },
            },
        },
        ["id"] = "flow.weather.raining",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "raining",
            ["sourceId"] = "flow.weather.raining",
            ["sourcePath"] = "dialogue/core_semantic_responses/flow_weather_raining.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "flow.weather",
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
                ["responseAct"] = "RAINING",
                ["responsePoolID"] = "flow.weather.raining",
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
                                ["fallback"] = "It is raining right now. We can return to that proposal when you are ready.",
                                ["id"] = "flow.weather.raining.dataset.contextual_switch",
                                ["metadata"] = {
                                    ["fallback"] = "It is raining right now. We can return to that proposal when you are ready.",
                                    ["plan"] = {
                                        ["dialogueAct"] = "WEATHER_REPORT",
                                        ["groundedFactRefs"] = {
                                            "world.weather.raining",
                                        },
                                        ["personalityStyle"] = "contextual",
                                        ["sourcePoolID"] = "semantic.flow.weather.raining",
                                        ["tone"] = "conversational",
                                        ["topic"] = "WEATHER",
                                        ["turns"] = {
                                            {
                                                ["continuation"] = "continue",
                                                ["id"] = "dataset_contextual_weather_switch",
                                                ["segments"] = {
                                                    {
                                                        ["fallback"] = "It is raining right now. We can return to that proposal when you are ready.",
                                                        ["kind"] = "translation",
                                                        ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetWeatherContextualSwitch",
                                                    },
                                                },
                                            },
                                        },
                                        ["uncertainty"] = "known",
                                    },
                                    ["priority"] = 4,
                                    ["reviewed"] = true,
                                    ["sourceRefs"] = {
                                        "MASSIVE",
                                        "SGD",
                                    },
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetWeatherContextualSwitch",
                                },
                                ["when"] = {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.pattern",
                                    ["value"] = "pnc.dataset.question.weather.can_we_talk_about_the_weather",
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
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "RAINING",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "flow.weather.raining",
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
                            ["fallback"] = "It is raining right now. We can return to that proposal when you are ready.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.flow.weather.raining.say_1",
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
        ["sourceShard"] = "dialogue/core_semantic_responses/flow_weather_raining.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "It is raining right now. We can return to that proposal when you are ready.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.weather.raining.say.1.flow.weather.raining.dataset.contextual_switch",
                ["variantID"] = "flow.weather.raining.dataset.contextual_switch",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["domainPath"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "greeting",
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
                                ["fallback"] = "Hey. How are you holding up?",
                                ["id"] = "greeting.dataset.holding_up",
                                ["templateID"] = "convo.greeting.say.1.greeting.dataset.holding_up",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "Good to see you again.",
                                ["id"] = "greeting.dataset.good_to_see",
                                ["templateID"] = "convo.greeting.say.1.greeting.dataset.good_to_see",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "Hey. How are things going?",
                                ["id"] = "greeting.dataset.how_things",
                                ["templateID"] = "convo.greeting.say.1.greeting.dataset.how_things",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "Hey. How are you holding up?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.greeting.say.1.greeting.dataset.holding_up",
                    ["variantID"] = "greeting.dataset.holding_up",
                },
                {
                    ["fallback"] = "Good to see you again.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.greeting.say.1.greeting.dataset.good_to_see",
                    ["variantID"] = "greeting.dataset.good_to_see",
                },
                {
                    ["fallback"] = "Hey. How are things going?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.greeting.say.1.greeting.dataset.how_things",
                    ["variantID"] = "greeting.dataset.how_things",
                },
            },
        },
        ["id"] = "greeting",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["sourceId"] = "greeting",
            ["sourcePath"] = "dialogue/core_semantic_responses/greeting.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
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
                ["responseAct"] = "GREETING",
                ["responsePoolID"] = "greeting",
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
                                ["fallback"] = "Hey. How are you holding up?",
                                ["id"] = "greeting.dataset.holding_up",
                                ["metadata"] = {
                                    ["fallback"] = "Hey. How are you holding up?",
                                    ["templateID"] = "greeting.dataset.holding_up",
                                },
                            },
                            {
                                ["fallback"] = "Good to see you again.",
                                ["id"] = "greeting.dataset.good_to_see",
                                ["metadata"] = {
                                    ["fallback"] = "Good to see you again.",
                                    ["templateID"] = "greeting.dataset.good_to_see",
                                },
                            },
                            {
                                ["fallback"] = "Hey. How are things going?",
                                ["id"] = "greeting.dataset.how_things",
                                ["metadata"] = {
                                    ["fallback"] = "Hey. How are things going?",
                                    ["templateID"] = "greeting.dataset.how_things",
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
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "GREETING",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "greeting",
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
                            ["fallback"] = "Hey. How are you holding up?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.greeting.say_1",
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
        ["sourceShard"] = "dialogue/core_semantic_responses/greeting.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Hey. How are you holding up?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.greeting.say.1.greeting.dataset.holding_up",
                ["variantID"] = "greeting.dataset.holding_up",
            },
            {
                ["fallback"] = "Good to see you again.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.greeting.say.1.greeting.dataset.good_to_see",
                ["variantID"] = "greeting.dataset.good_to_see",
            },
            {
                ["fallback"] = "Hey. How are things going?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.greeting.say.1.greeting.dataset.how_things",
                ["variantID"] = "greeting.dataset.how_things",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["domainPath"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "offer",
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
                                ["fallback"] = "That would help a lot. Could I have some?",
                                ["id"] = "offer.dataset.hungry_share",
                                ["templateID"] = "convo.offer.say.1.offer.dataset.hungry_share",
                                ["textRole"] = "spoken_action",
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.needType",
                                            ["value"] = "hunger",
                                        },
                                        {
                                            ["op"] = "in",
                                            ["path"] = "conversation.needUrgency",
                                            ["values"] = {
                                                "moderate",
                                                "severe",
                                                "emergency",
                                                "critical",
                                            },
                                        },
                                    },
                                },
                            },
                            {
                                ["fallback"] = "I'd appreciate a bite. Would you share?",
                                ["id"] = "offer.dataset.hungry_appreciate",
                                ["templateID"] = "convo.offer.say.1.offer.dataset.hungry_appreciate",
                                ["textRole"] = "spoken_action",
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.needType",
                                            ["value"] = "hunger",
                                        },
                                        {
                                            ["op"] = "in",
                                            ["path"] = "conversation.needUrgency",
                                            ["values"] = {
                                                "moderate",
                                                "severe",
                                                "emergency",
                                                "critical",
                                            },
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "That would help a lot. Could I have some?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.offer.say.1.offer.dataset.hungry_share",
                    ["variantID"] = "offer.dataset.hungry_share",
                },
                {
                    ["fallback"] = "I'd appreciate a bite. Would you share?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.offer.say.1.offer.dataset.hungry_appreciate",
                    ["variantID"] = "offer.dataset.hungry_appreciate",
                },
            },
        },
        ["id"] = "offer",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["sourceId"] = "offer",
            ["sourcePath"] = "dialogue/core_semantic_responses/offer.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
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
                ["responseAct"] = "OFFER",
                ["responsePoolID"] = "offer",
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
                                ["fallback"] = "That would help a lot. Could I have some?",
                                ["id"] = "offer.dataset.hungry_share",
                                ["metadata"] = {
                                    ["fallback"] = "That would help a lot. Could I have some?",
                                    ["priority"] = 2,
                                    ["templateID"] = "offer.dataset.hungry_share",
                                },
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.needType",
                                            ["value"] = "hunger",
                                        },
                                        {
                                            ["op"] = "in",
                                            ["path"] = "conversation.needUrgency",
                                            ["values"] = {
                                                "moderate",
                                                "severe",
                                                "emergency",
                                                "critical",
                                            },
                                        },
                                    },
                                },
                            },
                            {
                                ["fallback"] = "I'd appreciate a bite. Would you share?",
                                ["id"] = "offer.dataset.hungry_appreciate",
                                ["metadata"] = {
                                    ["fallback"] = "I'd appreciate a bite. Would you share?",
                                    ["priority"] = 2,
                                    ["templateID"] = "offer.dataset.hungry_appreciate",
                                },
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.needType",
                                            ["value"] = "hunger",
                                        },
                                        {
                                            ["op"] = "in",
                                            ["path"] = "conversation.needUrgency",
                                            ["values"] = {
                                                "moderate",
                                                "severe",
                                                "emergency",
                                                "critical",
                                            },
                                        },
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
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "OFFER",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "offer",
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
                            ["fallback"] = "That would help a lot. Could I have some?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.offer.say_1",
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
        ["sourceShard"] = "dialogue/core_semantic_responses/offer.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That would help a lot. Could I have some?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.offer.say.1.offer.dataset.hungry_share",
                ["variantID"] = "offer.dataset.hungry_share",
            },
            {
                ["fallback"] = "I'd appreciate a bite. Would you share?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.offer.say.1.offer.dataset.hungry_appreciate",
                ["variantID"] = "offer.dataset.hungry_appreciate",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["domainPath"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "question.activity",
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
                                ["fallback"] = "Just doing what I can to keep things moving.",
                                ["id"] = "question.activity.dataset.keep_moving",
                                ["templateID"] = "convo.question.activity.say.1.question.activity.dataset.keep_moving",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "A little bit of everything.",
                                ["id"] = "question.activity.dataset.bit_of_everything",
                                ["templateID"] = "convo.question.activity.say.1.question.activity.dataset.bit_of_everything",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "Just taking care of what needs doing.",
                                ["id"] = "question.activity.dataset.taking_care",
                                ["templateID"] = "convo.question.activity.say.1.question.activity.dataset.taking_care",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question",
            ["textRoles"] = {
                {
                    ["fallback"] = "Just doing what I can to keep things moving.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.activity.say.1.question.activity.dataset.keep_moving",
                    ["variantID"] = "question.activity.dataset.keep_moving",
                },
                {
                    ["fallback"] = "A little bit of everything.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.activity.say.1.question.activity.dataset.bit_of_everything",
                    ["variantID"] = "question.activity.dataset.bit_of_everything",
                },
                {
                    ["fallback"] = "Just taking care of what needs doing.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.activity.say.1.question.activity.dataset.taking_care",
                    ["variantID"] = "question.activity.dataset.taking_care",
                },
            },
        },
        ["id"] = "question.activity",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "activity",
            ["sourceId"] = "question.activity",
            ["sourcePath"] = "dialogue/core_semantic_responses/question_activity.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "question",
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
                ["responseAct"] = "ACTIVITY",
                ["responsePoolID"] = "question.activity",
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
                                ["fallback"] = "Just doing what I can to keep things moving.",
                                ["id"] = "question.activity.dataset.keep_moving",
                                ["metadata"] = {
                                    ["fallback"] = "Just doing what I can to keep things moving.",
                                    ["templateID"] = "question.activity.dataset.keep_moving",
                                },
                            },
                            {
                                ["fallback"] = "A little bit of everything.",
                                ["id"] = "question.activity.dataset.bit_of_everything",
                                ["metadata"] = {
                                    ["fallback"] = "A little bit of everything.",
                                    ["templateID"] = "question.activity.dataset.bit_of_everything",
                                },
                            },
                            {
                                ["fallback"] = "Just taking care of what needs doing.",
                                ["id"] = "question.activity.dataset.taking_care",
                                ["metadata"] = {
                                    ["fallback"] = "Just taking care of what needs doing.",
                                    ["templateID"] = "question.activity.dataset.taking_care",
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
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "ACTIVITY",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.activity",
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
                            ["fallback"] = "Just doing what I can to keep things moving.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.activity.say_1",
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
        ["sourceShard"] = "dialogue/core_semantic_responses/question_activity.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Just doing what I can to keep things moving.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.activity.say.1.question.activity.dataset.keep_moving",
                ["variantID"] = "question.activity.dataset.keep_moving",
            },
            {
                ["fallback"] = "A little bit of everything.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.activity.say.1.question.activity.dataset.bit_of_everything",
                ["variantID"] = "question.activity.dataset.bit_of_everything",
            },
            {
                ["fallback"] = "Just taking care of what needs doing.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.activity.say.1.question.activity.dataset.taking_care",
                ["variantID"] = "question.activity.dataset.taking_care",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["domainPath"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "question.backstory.ambiguous",
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
                                ["fallback"] = "Which part of my past do you mean?",
                                ["id"] = "question.backstory.ambiguous.authored",
                                ["templateID"] = "convo.question.backstory.ambiguous.say.1.question.backstory.ambiguous.authored",
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
                    ["fallback"] = "Which part of my past do you mean?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.backstory.ambiguous.say.1.question.backstory.ambiguous.authored",
                    ["variantID"] = "question.backstory.ambiguous.authored",
                },
            },
        },
        ["id"] = "question.backstory.ambiguous",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "ambiguous",
            ["sourceId"] = "question.backstory.ambiguous",
            ["sourcePath"] = "dialogue/core_semantic_responses/question_backstory_ambiguous.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
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
                ["responseAct"] = "AMBIGUOUS",
                ["responsePoolID"] = "question.backstory.ambiguous",
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
                                ["fallback"] = "Which part of my past do you mean?",
                                ["id"] = "question.backstory.ambiguous.authored",
                                ["metadata"] = {
                                    ["fallback"] = "Which part of my past do you mean?",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryAmbiguous",
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
            ["dialogueAct"] = "AMBIGUOUS",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.backstory.ambiguous",
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
                            ["fallback"] = "Which part of my past do you mean?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.backstory.ambiguous.say_1",
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
        ["sourceShard"] = "dialogue/core_semantic_responses/question_backstory_ambiguous.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Which part of my past do you mean?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.backstory.ambiguous.say.1.question.backstory.ambiguous.authored",
                ["variantID"] = "question.backstory.ambiguous.authored",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["domainPath"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "question.backstory.follow_up.location",
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
                                ["fallback"] = "I remember that part of my life, but I don't have more detail about where it was.",
                                ["id"] = "question.backstory.follow_up.location.authored",
                                ["templateID"] = "convo.question.backstory.follow_up.location.say.1.question.backstory.follow_up.location.authored",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.backstory.follow_up",
            ["textRoles"] = {
                {
                    ["fallback"] = "I remember that part of my life, but I don't have more detail about where it was.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.backstory.follow_up.location.say.1.question.backstory.follow_up.location.authored",
                    ["variantID"] = "question.backstory.follow_up.location.authored",
                },
            },
        },
        ["id"] = "question.backstory.follow_up.location",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "location",
            ["sourceId"] = "question.backstory.follow_up.location",
            ["sourcePath"] = "dialogue/core_semantic_responses/question_backstory_follow_up_location.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "question.backstory.follow_up",
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
                ["responseAct"] = "LOCATION",
                ["responsePoolID"] = "question.backstory.follow_up.location",
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
                                ["fallback"] = "I remember that part of my life, but I don't have more detail about where it was.",
                                ["id"] = "question.backstory.follow_up.location.authored",
                                ["metadata"] = {
                                    ["fallback"] = "I remember that part of my life, but I don't have more detail about where it was.",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFollowUpLocation",
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
            ["dialogueAct"] = "LOCATION",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.backstory.follow_up.location",
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
                            ["fallback"] = "I remember that part of my life, but I don't have more detail about where it was.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.backstory.follow_up.location.say_1",
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
        ["sourceShard"] = "dialogue/core_semantic_responses/question_backstory_follow_up_location.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I remember that part of my life, but I don't have more detail about where it was.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.backstory.follow_up.location.say.1.question.backstory.follow_up.location.authored",
                ["variantID"] = "question.backstory.follow_up.location.authored",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["domainPath"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "question.backstory.follow_up.miss",
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
                                ["fallback"] = "Sometimes. I still think about that part of my life.",
                                ["id"] = "question.backstory.follow_up.miss.authored",
                                ["templateID"] = "convo.question.backstory.follow_up.miss.say.1.question.backstory.follow_up.miss.authored",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.backstory.follow_up",
            ["textRoles"] = {
                {
                    ["fallback"] = "Sometimes. I still think about that part of my life.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.backstory.follow_up.miss.say.1.question.backstory.follow_up.miss.authored",
                    ["variantID"] = "question.backstory.follow_up.miss.authored",
                },
            },
        },
        ["id"] = "question.backstory.follow_up.miss",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "miss",
            ["sourceId"] = "question.backstory.follow_up.miss",
            ["sourcePath"] = "dialogue/core_semantic_responses/question_backstory_follow_up_miss.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "question.backstory.follow_up",
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
                ["responseAct"] = "MISS",
                ["responsePoolID"] = "question.backstory.follow_up.miss",
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
                                ["fallback"] = "Sometimes. I still think about that part of my life.",
                                ["id"] = "question.backstory.follow_up.miss.authored",
                                ["metadata"] = {
                                    ["fallback"] = "Sometimes. I still think about that part of my life.",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFollowUpMiss",
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
            ["dialogueAct"] = "MISS",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.backstory.follow_up.miss",
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
                            ["fallback"] = "Sometimes. I still think about that part of my life.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.backstory.follow_up.miss.say_1",
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
        ["sourceShard"] = "dialogue/core_semantic_responses/question_backstory_follow_up_miss.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Sometimes. I still think about that part of my life.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.backstory.follow_up.miss.say.1.question.backstory.follow_up.miss.authored",
                ["variantID"] = "question.backstory.follow_up.miss.authored",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["domainPath"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "question.backstory.refusal",
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
                                ["fallback"] = "I'm not ready to talk about that yet.",
                                ["id"] = "question.backstory.refusal.authored",
                                ["templateID"] = "convo.question.backstory.refusal.say.1.question.backstory.refusal.authored",
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
                    ["fallback"] = "I'm not ready to talk about that yet.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.backstory.refusal.say.1.question.backstory.refusal.authored",
                    ["variantID"] = "question.backstory.refusal.authored",
                },
            },
        },
        ["id"] = "question.backstory.refusal",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "refusal",
            ["sourceId"] = "question.backstory.refusal",
            ["sourcePath"] = "dialogue/core_semantic_responses/question_backstory_refusal.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
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
                ["responseAct"] = "REFUSAL",
                ["responsePoolID"] = "question.backstory.refusal",
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
                                ["fallback"] = "I'm not ready to talk about that yet.",
                                ["id"] = "question.backstory.refusal.authored",
                                ["metadata"] = {
                                    ["fallback"] = "I'm not ready to talk about that yet.",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryRefusal",
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
            ["dialogueAct"] = "REFUSAL",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.backstory.refusal",
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
                            ["fallback"] = "I'm not ready to talk about that yet.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.backstory.refusal.say_1",
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
        ["sourceShard"] = "dialogue/core_semantic_responses/question_backstory_refusal.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm not ready to talk about that yet.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.backstory.refusal.say.1.question.backstory.refusal.authored",
                ["variantID"] = "question.backstory.refusal.authored",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["domainPath"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "question.backstory.suspected",
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
                                ["fallback"] = "I think it was %1, but I could be mistaken.",
                                ["id"] = "question.backstory.suspected.authored",
                                ["templateID"] = "convo.question.backstory.suspected.say.1.question.backstory.suspected.authored",
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
                    ["fallback"] = "I think it was %1, but I could be mistaken.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.backstory.suspected.say.1.question.backstory.suspected.authored",
                    ["variantID"] = "question.backstory.suspected.authored",
                },
            },
        },
        ["id"] = "question.backstory.suspected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "suspected",
            ["sourceId"] = "question.backstory.suspected",
            ["sourcePath"] = "dialogue/core_semantic_responses/question_backstory_suspected.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
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
                ["responseAct"] = "SUSPECTED",
                ["responsePoolID"] = "question.backstory.suspected",
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
                                ["fallback"] = "I think it was %1, but I could be mistaken.",
                                ["id"] = "question.backstory.suspected.authored",
                                ["metadata"] = {
                                    ["fallback"] = "I think it was %1, but I could be mistaken.",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstorySuspected",
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
            ["dialogueAct"] = "SUSPECTED",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.backstory.suspected",
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
                            ["fallback"] = "I think it was %1, but I could be mistaken.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.backstory.suspected.say_1",
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
        ["sourceShard"] = "dialogue/core_semantic_responses/question_backstory_suspected.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I think it was %1, but I could be mistaken.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.backstory.suspected.say.1.question.backstory.suspected.authored",
                ["variantID"] = "question.backstory.suspected.authored",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["domainPath"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "question.wellbeing",
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
                                ["fallback"] = "I'm hanging in there. Thanks for asking.",
                                ["id"] = "question.wellbeing.dataset.hanging_in",
                                ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.hanging_in",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "Doing okay, all things considered.",
                                ["id"] = "question.wellbeing.dataset.all_things_considered",
                                ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.all_things_considered",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "I'm getting by, one day at a time. How about you?",
                                ["id"] = "question.wellbeing.dataset.getting_by",
                                ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.getting_by",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "I'm hungry, but I'll manage. If you have food to spare, I'd appreciate it.",
                                ["id"] = "question.wellbeing.dataset.hungry",
                                ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.hungry",
                                ["textRole"] = "spoken_action",
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.needType",
                                            ["value"] = "hunger",
                                        },
                                        {
                                            ["op"] = "in",
                                            ["path"] = "conversation.needUrgency",
                                            ["values"] = {
                                                "moderate",
                                                "severe",
                                                "emergency",
                                                "critical",
                                            },
                                        },
                                    },
                                },
                            },
                            {
                                ["fallback"] = "I'm pretty thirsty. If you have water, could you spare some?",
                                ["id"] = "question.wellbeing.dataset.thirsty",
                                ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.thirsty",
                                ["textRole"] = "spoken_action",
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.needType",
                                            ["value"] = "thirst",
                                        },
                                        {
                                            ["op"] = "in",
                                            ["path"] = "conversation.needUrgency",
                                            ["values"] = {
                                                "moderate",
                                                "severe",
                                                "emergency",
                                                "critical",
                                            },
                                        },
                                    },
                                },
                            },
                            {
                                ["fallback"] = "I'm tired, though I can manage for now.",
                                ["id"] = "question.wellbeing.dataset.tired",
                                ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.tired",
                                ["textRole"] = "spoken_action",
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.needType",
                                            ["value"] = "fatigue",
                                        },
                                        {
                                            ["op"] = "in",
                                            ["path"] = "conversation.needUrgency",
                                            ["values"] = {
                                                "moderate",
                                                "severe",
                                                "emergency",
                                                "critical",
                                            },
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm hanging in there. Thanks for asking.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.hanging_in",
                    ["variantID"] = "question.wellbeing.dataset.hanging_in",
                },
                {
                    ["fallback"] = "Doing okay, all things considered.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.all_things_considered",
                    ["variantID"] = "question.wellbeing.dataset.all_things_considered",
                },
                {
                    ["fallback"] = "I'm getting by, one day at a time. How about you?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.getting_by",
                    ["variantID"] = "question.wellbeing.dataset.getting_by",
                },
                {
                    ["fallback"] = "I'm hungry, but I'll manage. If you have food to spare, I'd appreciate it.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.hungry",
                    ["variantID"] = "question.wellbeing.dataset.hungry",
                },
                {
                    ["fallback"] = "I'm pretty thirsty. If you have water, could you spare some?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.thirsty",
                    ["variantID"] = "question.wellbeing.dataset.thirsty",
                },
                {
                    ["fallback"] = "I'm tired, though I can manage for now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.tired",
                    ["variantID"] = "question.wellbeing.dataset.tired",
                },
            },
        },
        ["id"] = "question.wellbeing",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "wellbeing",
            ["sourceId"] = "question.wellbeing",
            ["sourcePath"] = "dialogue/core_semantic_responses/question_wellbeing.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "question",
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
                ["responseAct"] = "WELLBEING",
                ["responsePoolID"] = "question.wellbeing",
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
                                ["fallback"] = "I'm hanging in there. Thanks for asking.",
                                ["id"] = "question.wellbeing.dataset.hanging_in",
                                ["metadata"] = {
                                    ["fallback"] = "I'm hanging in there. Thanks for asking.",
                                    ["templateID"] = "question.wellbeing.dataset.hanging_in",
                                },
                            },
                            {
                                ["fallback"] = "Doing okay, all things considered.",
                                ["id"] = "question.wellbeing.dataset.all_things_considered",
                                ["metadata"] = {
                                    ["fallback"] = "Doing okay, all things considered.",
                                    ["templateID"] = "question.wellbeing.dataset.all_things_considered",
                                },
                            },
                            {
                                ["fallback"] = "I'm getting by, one day at a time. How about you?",
                                ["id"] = "question.wellbeing.dataset.getting_by",
                                ["metadata"] = {
                                    ["fallback"] = "I'm getting by, one day at a time. How about you?",
                                    ["templateID"] = "question.wellbeing.dataset.getting_by",
                                },
                            },
                            {
                                ["fallback"] = "I'm hungry, but I'll manage. If you have food to spare, I'd appreciate it.",
                                ["id"] = "question.wellbeing.dataset.hungry",
                                ["metadata"] = {
                                    ["fallback"] = "I'm hungry, but I'll manage. If you have food to spare, I'd appreciate it.",
                                    ["priority"] = 2,
                                    ["templateID"] = "question.wellbeing.dataset.hungry",
                                },
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.needType",
                                            ["value"] = "hunger",
                                        },
                                        {
                                            ["op"] = "in",
                                            ["path"] = "conversation.needUrgency",
                                            ["values"] = {
                                                "moderate",
                                                "severe",
                                                "emergency",
                                                "critical",
                                            },
                                        },
                                    },
                                },
                            },
                            {
                                ["fallback"] = "I'm pretty thirsty. If you have water, could you spare some?",
                                ["id"] = "question.wellbeing.dataset.thirsty",
                                ["metadata"] = {
                                    ["fallback"] = "I'm pretty thirsty. If you have water, could you spare some?",
                                    ["priority"] = 3,
                                    ["templateID"] = "question.wellbeing.dataset.thirsty",
                                },
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.needType",
                                            ["value"] = "thirst",
                                        },
                                        {
                                            ["op"] = "in",
                                            ["path"] = "conversation.needUrgency",
                                            ["values"] = {
                                                "moderate",
                                                "severe",
                                                "emergency",
                                                "critical",
                                            },
                                        },
                                    },
                                },
                            },
                            {
                                ["fallback"] = "I'm tired, though I can manage for now.",
                                ["id"] = "question.wellbeing.dataset.tired",
                                ["metadata"] = {
                                    ["fallback"] = "I'm tired, though I can manage for now.",
                                    ["priority"] = 2,
                                    ["templateID"] = "question.wellbeing.dataset.tired",
                                },
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.needType",
                                            ["value"] = "fatigue",
                                        },
                                        {
                                            ["op"] = "in",
                                            ["path"] = "conversation.needUrgency",
                                            ["values"] = {
                                                "moderate",
                                                "severe",
                                                "emergency",
                                                "critical",
                                            },
                                        },
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
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "WELLBEING",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.wellbeing",
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
                            ["fallback"] = "I'm hanging in there. Thanks for asking.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.wellbeing.say_1",
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
        ["sourceShard"] = "dialogue/core_semantic_responses/question_wellbeing.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm hanging in there. Thanks for asking.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.hanging_in",
                ["variantID"] = "question.wellbeing.dataset.hanging_in",
            },
            {
                ["fallback"] = "Doing okay, all things considered.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.all_things_considered",
                ["variantID"] = "question.wellbeing.dataset.all_things_considered",
            },
            {
                ["fallback"] = "I'm getting by, one day at a time. How about you?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.getting_by",
                ["variantID"] = "question.wellbeing.dataset.getting_by",
            },
            {
                ["fallback"] = "I'm hungry, but I'll manage. If you have food to spare, I'd appreciate it.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.hungry",
                ["variantID"] = "question.wellbeing.dataset.hungry",
            },
            {
                ["fallback"] = "I'm pretty thirsty. If you have water, could you spare some?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.thirsty",
                ["variantID"] = "question.wellbeing.dataset.thirsty",
            },
            {
                ["fallback"] = "I'm tired, though I can manage for now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.tired",
                ["variantID"] = "question.wellbeing.dataset.tired",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["domainPath"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "question.wellbeing.unknown",
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
                                ["fallback"] = "I can tell something is off, but I do not know what caused it yet.",
                                ["id"] = "question.wellbeing.unknown.dataset.causal_followup",
                                ["templateID"] = "convo.question.wellbeing.unknown.say.1.question.wellbeing.unknown.dataset.causal_followup",
                                ["textRole"] = "spoken_action",
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.healthState",
                                            ["value"] = "unknown",
                                        },
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.pattern",
                                            ["value"] = "pnc.dataset.question.wellbeing.what_is_going_on_with_you",
                                        },
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
                    ["fallback"] = "I can tell something is off, but I do not know what caused it yet.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.unknown.say.1.question.wellbeing.unknown.dataset.causal_followup",
                    ["variantID"] = "question.wellbeing.unknown.dataset.causal_followup",
                },
            },
        },
        ["id"] = "question.wellbeing.unknown",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "unknown",
            ["sourceId"] = "question.wellbeing.unknown",
            ["sourcePath"] = "dialogue/core_semantic_responses/question_wellbeing_unknown.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
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
                ["responseAct"] = "UNKNOWN",
                ["responsePoolID"] = "question.wellbeing.unknown",
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
                                ["fallback"] = "I can tell something is off, but I do not know what caused it yet.",
                                ["id"] = "question.wellbeing.unknown.dataset.causal_followup",
                                ["metadata"] = {
                                    ["fallback"] = "I can tell something is off, but I do not know what caused it yet.",
                                    ["plan"] = {
                                        ["dialogueAct"] = "ASK_CLARIFICATION",
                                        ["groundedFactRefs"] = {
                                        },
                                        ["personalityStyle"] = "truthful",
                                        ["sourcePoolID"] = "semantic.question.wellbeing.unknown",
                                        ["tone"] = "clarifying",
                                        ["topic"] = "WELLBEING",
                                        ["turns"] = {
                                            {
                                                ["continuation"] = "continue",
                                                ["id"] = "dataset_causal_wellbeing_unknown",
                                                ["segments"] = {
                                                    {
                                                        ["fallback"] = "I can tell something is off, but I do not know what caused it yet.",
                                                        ["kind"] = "translation",
                                                        ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetWellbeingCausalUnknown",
                                                    },
                                                },
                                            },
                                        },
                                        ["uncertainty"] = "unknown",
                                    },
                                    ["priority"] = 4,
                                    ["reviewed"] = true,
                                    ["sourceRefs"] = {
                                        "MASSIVE",
                                        "SGD",
                                    },
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetWellbeingCausalUnknown",
                                },
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.healthState",
                                            ["value"] = "unknown",
                                        },
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.pattern",
                                            ["value"] = "pnc.dataset.question.wellbeing.what_is_going_on_with_you",
                                        },
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
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "UNKNOWN",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.wellbeing.unknown",
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
                            ["fallback"] = "I can tell something is off, but I do not know what caused it yet.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.wellbeing.unknown.say_1",
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
        ["sourceShard"] = "dialogue/core_semantic_responses/question_wellbeing_unknown.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I can tell something is off, but I do not know what caused it yet.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.unknown.say.1.question.wellbeing.unknown.dataset.causal_followup",
                ["variantID"] = "question.wellbeing.unknown.dataset.causal_followup",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["domainPath"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "refuse",
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
                                ["fallback"] = "I can't take that on right now.",
                                ["id"] = "refuse.dataset.pending_unavailable",
                                ["templateID"] = "convo.refuse.say.1.refuse.dataset.pending_unavailable",
                                ["textRole"] = "spoken_action",
                                ["when"] = {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.hasPendingRequest",
                                    ["value"] = true,
                                },
                            },
                            {
                                ["fallback"] = "Not this time. I have enough to manage.",
                                ["id"] = "refuse.dataset.pending_enough",
                                ["templateID"] = "convo.refuse.say.1.refuse.dataset.pending_enough",
                                ["textRole"] = "spoken_action",
                                ["when"] = {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.hasPendingRequest",
                                    ["value"] = true,
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "I can't take that on right now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.refuse.say.1.refuse.dataset.pending_unavailable",
                    ["variantID"] = "refuse.dataset.pending_unavailable",
                },
                {
                    ["fallback"] = "Not this time. I have enough to manage.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.refuse.say.1.refuse.dataset.pending_enough",
                    ["variantID"] = "refuse.dataset.pending_enough",
                },
            },
        },
        ["id"] = "refuse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["sourceId"] = "refuse",
            ["sourcePath"] = "dialogue/core_semantic_responses/refuse.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
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
                ["responseAct"] = "REFUSE",
                ["responsePoolID"] = "refuse",
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
                                ["fallback"] = "I can't take that on right now.",
                                ["id"] = "refuse.dataset.pending_unavailable",
                                ["metadata"] = {
                                    ["fallback"] = "I can't take that on right now.",
                                    ["priority"] = 1,
                                    ["templateID"] = "refuse.dataset.pending_unavailable",
                                },
                                ["when"] = {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.hasPendingRequest",
                                    ["value"] = true,
                                },
                            },
                            {
                                ["fallback"] = "Not this time. I have enough to manage.",
                                ["id"] = "refuse.dataset.pending_enough",
                                ["metadata"] = {
                                    ["fallback"] = "Not this time. I have enough to manage.",
                                    ["priority"] = 1,
                                    ["templateID"] = "refuse.dataset.pending_enough",
                                },
                                ["when"] = {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.hasPendingRequest",
                                    ["value"] = true,
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
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REFUSE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "refuse",
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
                            ["fallback"] = "I can't take that on right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.refuse.say_1",
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
        ["sourceShard"] = "dialogue/core_semantic_responses/refuse.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I can't take that on right now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.refuse.say.1.refuse.dataset.pending_unavailable",
                ["variantID"] = "refuse.dataset.pending_unavailable",
            },
            {
                ["fallback"] = "Not this time. I have enough to manage.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.refuse.say.1.refuse.dataset.pending_enough",
                ["variantID"] = "refuse.dataset.pending_enough",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["domainPath"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "response_pool.question.identity",
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
                                ["fallback"] = "I keep my name to myself until I know someone better. What should I call you?",
                                ["id"] = "question.identity.dataset.stranger_alt_1",
                                ["templateID"] = "convo.response_pool.question.identity.say.1.question.identity.dataset.stranger_alt_1",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "Let's get to know each other first. What do people call you?",
                                ["id"] = "question.identity.dataset.stranger_alt_2",
                                ["templateID"] = "convo.response_pool.question.identity.say.1.question.identity.dataset.stranger_alt_2",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "I don't trust you enough to share my name. Who are you, really?",
                                ["id"] = "question.identity.dataset.wary_alt_1",
                                ["templateID"] = "convo.response_pool.question.identity.say.1.question.identity.dataset.wary_alt_1",
                                ["textRole"] = "spoken_action",
                                ["when"] = {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.identityTrust",
                                    ["value"] = "untrustworthy",
                                },
                            },
                            {
                                ["fallback"] = "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                                ["id"] = "question.identity.dataset.wary_alt_2",
                                ["templateID"] = "convo.response_pool.question.identity.say.1.question.identity.dataset.wary_alt_2",
                                ["textRole"] = "spoken_action",
                                ["when"] = {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.identityTrust",
                                    ["value"] = "untrustworthy",
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "response_pool.question",
            ["textRoles"] = {
                {
                    ["fallback"] = "I keep my name to myself until I know someone better. What should I call you?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response_pool.question.identity.say.1.question.identity.dataset.stranger_alt_1",
                    ["variantID"] = "question.identity.dataset.stranger_alt_1",
                },
                {
                    ["fallback"] = "Let's get to know each other first. What do people call you?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response_pool.question.identity.say.1.question.identity.dataset.stranger_alt_2",
                    ["variantID"] = "question.identity.dataset.stranger_alt_2",
                },
                {
                    ["fallback"] = "I don't trust you enough to share my name. Who are you, really?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response_pool.question.identity.say.1.question.identity.dataset.wary_alt_1",
                    ["variantID"] = "question.identity.dataset.wary_alt_1",
                },
                {
                    ["fallback"] = "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response_pool.question.identity.say.1.question.identity.dataset.wary_alt_2",
                    ["variantID"] = "question.identity.dataset.wary_alt_2",
                },
            },
        },
        ["id"] = "response_pool.question.identity",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "identity",
            ["sourceId"] = "response_pool.question.identity",
            ["sourcePath"] = "dialogue/core_semantic_responses/question_identity.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "response_pool.question",
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
                ["responseAct"] = "IDENTITY",
                ["responsePoolID"] = "question.identity",
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
                                ["fallback"] = "I keep my name to myself until I know someone better. What should I call you?",
                                ["id"] = "question.identity.dataset.stranger_alt_1",
                                ["metadata"] = {
                                    ["fallback"] = "I keep my name to myself until I know someone better. What should I call you?",
                                    ["templateID"] = "question.identity.stranger_alt_1",
                                },
                            },
                            {
                                ["fallback"] = "Let's get to know each other first. What do people call you?",
                                ["id"] = "question.identity.dataset.stranger_alt_2",
                                ["metadata"] = {
                                    ["fallback"] = "Let's get to know each other first. What do people call you?",
                                    ["templateID"] = "question.identity.stranger_alt_2",
                                },
                            },
                            {
                                ["fallback"] = "I don't trust you enough to share my name. Who are you, really?",
                                ["id"] = "question.identity.dataset.wary_alt_1",
                                ["metadata"] = {
                                    ["fallback"] = "I don't trust you enough to share my name. Who are you, really?",
                                    ["priority"] = 2,
                                    ["templateID"] = "question.identity.wary_alt_1",
                                },
                                ["when"] = {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.identityTrust",
                                    ["value"] = "untrustworthy",
                                },
                            },
                            {
                                ["fallback"] = "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                                ["id"] = "question.identity.dataset.wary_alt_2",
                                ["metadata"] = {
                                    ["fallback"] = "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                                    ["priority"] = 2,
                                    ["templateID"] = "question.identity.wary_alt_2",
                                },
                                ["when"] = {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.identityTrust",
                                    ["value"] = "untrustworthy",
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
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "IDENTITY",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "response_pool.question.identity",
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
                            ["fallback"] = "I keep my name to myself until I know someone better. What should I call you?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.response_pool.question.identity.say_1",
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
        ["sourceShard"] = "dialogue/core_semantic_responses/question_identity.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I keep my name to myself until I know someone better. What should I call you?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response_pool.question.identity.say.1.question.identity.dataset.stranger_alt_1",
                ["variantID"] = "question.identity.dataset.stranger_alt_1",
            },
            {
                ["fallback"] = "Let's get to know each other first. What do people call you?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response_pool.question.identity.say.1.question.identity.dataset.stranger_alt_2",
                ["variantID"] = "question.identity.dataset.stranger_alt_2",
            },
            {
                ["fallback"] = "I don't trust you enough to share my name. Who are you, really?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response_pool.question.identity.say.1.question.identity.dataset.wary_alt_1",
                ["variantID"] = "question.identity.dataset.wary_alt_1",
            },
            {
                ["fallback"] = "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response_pool.question.identity.say.1.question.identity.dataset.wary_alt_2",
                ["variantID"] = "question.identity.dataset.wary_alt_2",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["domainPath"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "thanks",
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
                                ["fallback"] = "No problem at all.",
                                ["id"] = "thanks.dataset.no_problem",
                                ["templateID"] = "convo.thanks.say.1.thanks.dataset.no_problem",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "Anytime.",
                                ["id"] = "thanks.dataset.anytime",
                                ["templateID"] = "convo.thanks.say.1.thanks.dataset.anytime",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "Glad I could help.",
                                ["id"] = "thanks.dataset.glady",
                                ["templateID"] = "convo.thanks.say.1.thanks.dataset.glady",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "No problem at all.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.thanks.say.1.thanks.dataset.no_problem",
                    ["variantID"] = "thanks.dataset.no_problem",
                },
                {
                    ["fallback"] = "Anytime.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.thanks.say.1.thanks.dataset.anytime",
                    ["variantID"] = "thanks.dataset.anytime",
                },
                {
                    ["fallback"] = "Glad I could help.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.thanks.say.1.thanks.dataset.glady",
                    ["variantID"] = "thanks.dataset.glady",
                },
            },
        },
        ["id"] = "thanks",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["sourceId"] = "thanks",
            ["sourcePath"] = "dialogue/core_semantic_responses/thanks.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
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
                ["responseAct"] = "THANKS",
                ["responsePoolID"] = "thanks",
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
                                ["fallback"] = "No problem at all.",
                                ["id"] = "thanks.dataset.no_problem",
                                ["metadata"] = {
                                    ["fallback"] = "No problem at all.",
                                    ["templateID"] = "thanks.dataset.no_problem",
                                },
                            },
                            {
                                ["fallback"] = "Anytime.",
                                ["id"] = "thanks.dataset.anytime",
                                ["metadata"] = {
                                    ["fallback"] = "Anytime.",
                                    ["templateID"] = "thanks.dataset.anytime",
                                },
                            },
                            {
                                ["fallback"] = "Glad I could help.",
                                ["id"] = "thanks.dataset.glady",
                                ["metadata"] = {
                                    ["fallback"] = "Glad I could help.",
                                    ["templateID"] = "thanks.dataset.glady",
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
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "THANKS",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "thanks",
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
                            ["fallback"] = "No problem at all.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.thanks.say_1",
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
        ["sourceShard"] = "dialogue/core_semantic_responses/thanks.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "No problem at all.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.thanks.say.1.thanks.dataset.no_problem",
                ["variantID"] = "thanks.dataset.no_problem",
            },
            {
                ["fallback"] = "Anytime.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.thanks.say.1.thanks.dataset.anytime",
                ["variantID"] = "thanks.dataset.anytime",
            },
            {
                ["fallback"] = "Glad I could help.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.thanks.say.1.thanks.dataset.glady",
                ["variantID"] = "thanks.dataset.glady",
            },
        },
        ["when"] = nil,
    },
}
