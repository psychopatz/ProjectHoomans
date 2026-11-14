-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_semantic_responses",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Okay, I'll get started.",
                                    },
                                    ["TL"] = {
                                        "Okay, I'll get started.",
                                    },
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
                                ["templateID"] = "convo.accept.say.1.accept.dataset.pending_care",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "All right. I can take care of that.",
                                    },
                                    ["TL"] = {
                                        "All right. I can take care of that.",
                                    },
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
            ["textRoles"] = {
                {
                    ["fallback"] = "Okay, I'll get started.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.accept.say.1.accept.dataset.pending_started",
                    ["translations"] = {
                        ["EN"] = {
                            "Okay, I'll get started.",
                        },
                        ["TL"] = {
                            "Okay, I'll get started.",
                        },
                    },
                    ["variantID"] = "accept.dataset.pending_started",
                },
                {
                    ["fallback"] = "All right. I can take care of that.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.accept.say.1.accept.dataset.pending_care",
                    ["translations"] = {
                        ["EN"] = {
                            "All right. I can take care of that.",
                        },
                        ["TL"] = {
                            "All right. I can take care of that.",
                        },
                    },
                    ["variantID"] = "accept.dataset.pending_care",
                },
            },
        },
        ["id"] = "accept",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "accept",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/accept.json",
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
                                ["id"] = "accept.dataset.pending_started",
                                ["metadata"] = {
                                    ["fallback"] = "Okay, I'll get started.",
                                    ["priority"] = 1,
                                    ["templateID"] = "accept.dataset.pending_started",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "Okay, I'll get started.",
                                    },
                                    ["TL"] = {
                                        "Okay, I'll get started.",
                                    },
                                },
                                ["when"] = {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.hasPendingRequest",
                                    ["value"] = true,
                                },
                            },
                            {
                                ["id"] = "accept.dataset.pending_care",
                                ["metadata"] = {
                                    ["fallback"] = "All right. I can take care of that.",
                                    ["priority"] = 1,
                                    ["templateID"] = "accept.dataset.pending_care",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "All right. I can take care of that.",
                                    },
                                    ["TL"] = {
                                        "All right. I can take care of that.",
                                    },
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/accept.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "Okay, I'll get started.",
                    },
                    ["TL"] = {
                        "Okay, I'll get started.",
                    },
                },
                ["variantID"] = "accept.dataset.pending_started",
            },
            {
                ["fallback"] = "All right. I can take care of that.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.accept.say.1.accept.dataset.pending_care",
                ["translations"] = {
                    ["EN"] = {
                        "All right. I can take care of that.",
                    },
                    ["TL"] = {
                        "All right. I can take care of that.",
                    },
                },
                ["variantID"] = "accept.dataset.pending_care",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "That's kind of you. I appreciate it.",
                                    },
                                    ["TL"] = {
                                        "That's kind of you. I appreciate it.",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "Aw, thank you. That means a lot.",
                                ["id"] = "compliment.dataset.means_a_lot",
                                ["templateID"] = "convo.compliment.say.1.compliment.dataset.means_a_lot",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Aw, thank you. That means a lot.",
                                    },
                                    ["TL"] = {
                                        "Aw, thank you. That means a lot.",
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
                    ["fallback"] = "That's kind of you. I appreciate it.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.compliment.say.1.compliment.dataset.kind_of_you",
                    ["translations"] = {
                        ["EN"] = {
                            "That's kind of you. I appreciate it.",
                        },
                        ["TL"] = {
                            "That's kind of you. I appreciate it.",
                        },
                    },
                    ["variantID"] = "compliment.dataset.kind_of_you",
                },
                {
                    ["fallback"] = "Aw, thank you. That means a lot.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.compliment.say.1.compliment.dataset.means_a_lot",
                    ["translations"] = {
                        ["EN"] = {
                            "Aw, thank you. That means a lot.",
                        },
                        ["TL"] = {
                            "Aw, thank you. That means a lot.",
                        },
                    },
                    ["variantID"] = "compliment.dataset.means_a_lot",
                },
            },
        },
        ["id"] = "compliment",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "compliment",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/compliment.json",
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
                                ["id"] = "compliment.dataset.kind_of_you",
                                ["metadata"] = {
                                    ["fallback"] = "That's kind of you. I appreciate it.",
                                    ["templateID"] = "compliment.dataset.kind_of_you",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "That's kind of you. I appreciate it.",
                                    },
                                    ["TL"] = {
                                        "That's kind of you. I appreciate it.",
                                    },
                                },
                            },
                            {
                                ["id"] = "compliment.dataset.means_a_lot",
                                ["metadata"] = {
                                    ["fallback"] = "Aw, thank you. That means a lot.",
                                    ["templateID"] = "compliment.dataset.means_a_lot",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "Aw, thank you. That means a lot.",
                                    },
                                    ["TL"] = {
                                        "Aw, thank you. That means a lot.",
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/compliment.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "That's kind of you. I appreciate it.",
                    },
                    ["TL"] = {
                        "That's kind of you. I appreciate it.",
                    },
                },
                ["variantID"] = "compliment.dataset.kind_of_you",
            },
            {
                ["fallback"] = "Aw, thank you. That means a lot.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.compliment.say.1.compliment.dataset.means_a_lot",
                ["translations"] = {
                    ["EN"] = {
                        "Aw, thank you. That means a lot.",
                    },
                    ["TL"] = {
                        "Aw, thank you. That means a lot.",
                    },
                },
                ["variantID"] = "compliment.dataset.means_a_lot",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "It is raining right now. We can return to that proposal when you are ready.",
                                    },
                                    ["TL"] = {
                                        "Umuulan ngayon. Maaari tayong bumalik sa panukalang iyon kapag handa ka na.",
                                    },
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
            ["namespace"] = "flow.weather",
            ["textRoles"] = {
                {
                    ["fallback"] = "It is raining right now. We can return to that proposal when you are ready.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.weather.raining.say.1.flow.weather.raining.dataset.contextual_switch",
                    ["translations"] = {
                        ["EN"] = {
                            "It is raining right now. We can return to that proposal when you are ready.",
                        },
                        ["TL"] = {
                            "Umuulan ngayon. Maaari tayong bumalik sa panukalang iyon kapag handa ka na.",
                        },
                    },
                    ["variantID"] = "flow.weather.raining.dataset.contextual_switch",
                },
            },
        },
        ["id"] = "flow.weather.raining",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "raining",
            ["sourceId"] = "flow.weather.raining",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/flow_weather_raining.json",
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
                                                        ["translations"] = {
                                                            ["EN"] = "It is raining right now. We can return to that proposal when you are ready.",
                                                            ["TL"] = "Umuulan ngayon. Maaari tayong bumalik sa panukalang iyon kapag handa ka na.",
                                                        },
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
                                ["text"] = {
                                    ["EN"] = {
                                        "It is raining right now. We can return to that proposal when you are ready.",
                                    },
                                    ["TL"] = {
                                        "Umuulan ngayon. Maaari tayong bumalik sa panukalang iyon kapag handa ka na.",
                                    },
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/flow_weather_raining.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "It is raining right now. We can return to that proposal when you are ready.",
                    },
                    ["TL"] = {
                        "Umuulan ngayon. Maaari tayong bumalik sa panukalang iyon kapag handa ka na.",
                    },
                },
                ["variantID"] = "flow.weather.raining.dataset.contextual_switch",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Hey. How are you holding up?",
                                    },
                                    ["TL"] = {
                                        "Hey. How are you holding up?",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "Good to see you again.",
                                ["id"] = "greeting.dataset.good_to_see",
                                ["templateID"] = "convo.greeting.say.1.greeting.dataset.good_to_see",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Good to see you again.",
                                    },
                                    ["TL"] = {
                                        "Good to see you again.",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "Hey. How are things going?",
                                ["id"] = "greeting.dataset.how_things",
                                ["templateID"] = "convo.greeting.say.1.greeting.dataset.how_things",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Hey. How are things going?",
                                    },
                                    ["TL"] = {
                                        "Hey. How are things going?",
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
                    ["fallback"] = "Hey. How are you holding up?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.greeting.say.1.greeting.dataset.holding_up",
                    ["translations"] = {
                        ["EN"] = {
                            "Hey. How are you holding up?",
                        },
                        ["TL"] = {
                            "Hey. How are you holding up?",
                        },
                    },
                    ["variantID"] = "greeting.dataset.holding_up",
                },
                {
                    ["fallback"] = "Good to see you again.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.greeting.say.1.greeting.dataset.good_to_see",
                    ["translations"] = {
                        ["EN"] = {
                            "Good to see you again.",
                        },
                        ["TL"] = {
                            "Good to see you again.",
                        },
                    },
                    ["variantID"] = "greeting.dataset.good_to_see",
                },
                {
                    ["fallback"] = "Hey. How are things going?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.greeting.say.1.greeting.dataset.how_things",
                    ["translations"] = {
                        ["EN"] = {
                            "Hey. How are things going?",
                        },
                        ["TL"] = {
                            "Hey. How are things going?",
                        },
                    },
                    ["variantID"] = "greeting.dataset.how_things",
                },
            },
        },
        ["id"] = "greeting",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "greeting",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/greeting.json",
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
                                ["id"] = "greeting.dataset.holding_up",
                                ["metadata"] = {
                                    ["fallback"] = "Hey. How are you holding up?",
                                    ["templateID"] = "greeting.dataset.holding_up",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "Hey. How are you holding up?",
                                    },
                                    ["TL"] = {
                                        "Hey. How are you holding up?",
                                    },
                                },
                            },
                            {
                                ["id"] = "greeting.dataset.good_to_see",
                                ["metadata"] = {
                                    ["fallback"] = "Good to see you again.",
                                    ["templateID"] = "greeting.dataset.good_to_see",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "Good to see you again.",
                                    },
                                    ["TL"] = {
                                        "Good to see you again.",
                                    },
                                },
                            },
                            {
                                ["id"] = "greeting.dataset.how_things",
                                ["metadata"] = {
                                    ["fallback"] = "Hey. How are things going?",
                                    ["templateID"] = "greeting.dataset.how_things",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "Hey. How are things going?",
                                    },
                                    ["TL"] = {
                                        "Hey. How are things going?",
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/greeting.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "Hey. How are you holding up?",
                    },
                    ["TL"] = {
                        "Hey. How are you holding up?",
                    },
                },
                ["variantID"] = "greeting.dataset.holding_up",
            },
            {
                ["fallback"] = "Good to see you again.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.greeting.say.1.greeting.dataset.good_to_see",
                ["translations"] = {
                    ["EN"] = {
                        "Good to see you again.",
                    },
                    ["TL"] = {
                        "Good to see you again.",
                    },
                },
                ["variantID"] = "greeting.dataset.good_to_see",
            },
            {
                ["fallback"] = "Hey. How are things going?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.greeting.say.1.greeting.dataset.how_things",
                ["translations"] = {
                    ["EN"] = {
                        "Hey. How are things going?",
                    },
                    ["TL"] = {
                        "Hey. How are things going?",
                    },
                },
                ["variantID"] = "greeting.dataset.how_things",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "That would help a lot. Could I have some?",
                                    },
                                    ["TL"] = {
                                        "That would help a lot. Could I have some?",
                                    },
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
                                ["templateID"] = "convo.offer.say.1.offer.dataset.hungry_appreciate",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'd appreciate a bite. Would you share?",
                                    },
                                    ["TL"] = {
                                        "I'd appreciate a bite. Would you share?",
                                    },
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
            ["textRoles"] = {
                {
                    ["fallback"] = "That would help a lot. Could I have some?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.offer.say.1.offer.dataset.hungry_share",
                    ["translations"] = {
                        ["EN"] = {
                            "That would help a lot. Could I have some?",
                        },
                        ["TL"] = {
                            "That would help a lot. Could I have some?",
                        },
                    },
                    ["variantID"] = "offer.dataset.hungry_share",
                },
                {
                    ["fallback"] = "I'd appreciate a bite. Would you share?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.offer.say.1.offer.dataset.hungry_appreciate",
                    ["translations"] = {
                        ["EN"] = {
                            "I'd appreciate a bite. Would you share?",
                        },
                        ["TL"] = {
                            "I'd appreciate a bite. Would you share?",
                        },
                    },
                    ["variantID"] = "offer.dataset.hungry_appreciate",
                },
            },
        },
        ["id"] = "offer",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "offer",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/offer.json",
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
                                ["id"] = "offer.dataset.hungry_share",
                                ["metadata"] = {
                                    ["fallback"] = "That would help a lot. Could I have some?",
                                    ["priority"] = 2,
                                    ["templateID"] = "offer.dataset.hungry_share",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "That would help a lot. Could I have some?",
                                    },
                                    ["TL"] = {
                                        "That would help a lot. Could I have some?",
                                    },
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
                                ["id"] = "offer.dataset.hungry_appreciate",
                                ["metadata"] = {
                                    ["fallback"] = "I'd appreciate a bite. Would you share?",
                                    ["priority"] = 2,
                                    ["templateID"] = "offer.dataset.hungry_appreciate",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "I'd appreciate a bite. Would you share?",
                                    },
                                    ["TL"] = {
                                        "I'd appreciate a bite. Would you share?",
                                    },
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/offer.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "That would help a lot. Could I have some?",
                    },
                    ["TL"] = {
                        "That would help a lot. Could I have some?",
                    },
                },
                ["variantID"] = "offer.dataset.hungry_share",
            },
            {
                ["fallback"] = "I'd appreciate a bite. Would you share?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.offer.say.1.offer.dataset.hungry_appreciate",
                ["translations"] = {
                    ["EN"] = {
                        "I'd appreciate a bite. Would you share?",
                    },
                    ["TL"] = {
                        "I'd appreciate a bite. Would you share?",
                    },
                },
                ["variantID"] = "offer.dataset.hungry_appreciate",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Just doing what I can to keep things moving.",
                                    },
                                    ["TL"] = {
                                        "Just doing what I can to keep things moving.",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "A little bit of everything.",
                                ["id"] = "question.activity.dataset.bit_of_everything",
                                ["templateID"] = "convo.question.activity.say.1.question.activity.dataset.bit_of_everything",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "A little bit of everything.",
                                    },
                                    ["TL"] = {
                                        "A little bit of everything.",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "Just taking care of what needs doing.",
                                ["id"] = "question.activity.dataset.taking_care",
                                ["templateID"] = "convo.question.activity.say.1.question.activity.dataset.taking_care",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Just taking care of what needs doing.",
                                    },
                                    ["TL"] = {
                                        "Just taking care of what needs doing.",
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
                    ["fallback"] = "Just doing what I can to keep things moving.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.activity.say.1.question.activity.dataset.keep_moving",
                    ["translations"] = {
                        ["EN"] = {
                            "Just doing what I can to keep things moving.",
                        },
                        ["TL"] = {
                            "Just doing what I can to keep things moving.",
                        },
                    },
                    ["variantID"] = "question.activity.dataset.keep_moving",
                },
                {
                    ["fallback"] = "A little bit of everything.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.activity.say.1.question.activity.dataset.bit_of_everything",
                    ["translations"] = {
                        ["EN"] = {
                            "A little bit of everything.",
                        },
                        ["TL"] = {
                            "A little bit of everything.",
                        },
                    },
                    ["variantID"] = "question.activity.dataset.bit_of_everything",
                },
                {
                    ["fallback"] = "Just taking care of what needs doing.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.activity.say.1.question.activity.dataset.taking_care",
                    ["translations"] = {
                        ["EN"] = {
                            "Just taking care of what needs doing.",
                        },
                        ["TL"] = {
                            "Just taking care of what needs doing.",
                        },
                    },
                    ["variantID"] = "question.activity.dataset.taking_care",
                },
            },
        },
        ["id"] = "question.activity",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "activity",
            ["sourceId"] = "question.activity",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_activity.json",
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
                                ["id"] = "question.activity.dataset.keep_moving",
                                ["metadata"] = {
                                    ["fallback"] = "Just doing what I can to keep things moving.",
                                    ["templateID"] = "question.activity.dataset.keep_moving",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "Just doing what I can to keep things moving.",
                                    },
                                    ["TL"] = {
                                        "Just doing what I can to keep things moving.",
                                    },
                                },
                            },
                            {
                                ["id"] = "question.activity.dataset.bit_of_everything",
                                ["metadata"] = {
                                    ["fallback"] = "A little bit of everything.",
                                    ["templateID"] = "question.activity.dataset.bit_of_everything",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "A little bit of everything.",
                                    },
                                    ["TL"] = {
                                        "A little bit of everything.",
                                    },
                                },
                            },
                            {
                                ["id"] = "question.activity.dataset.taking_care",
                                ["metadata"] = {
                                    ["fallback"] = "Just taking care of what needs doing.",
                                    ["templateID"] = "question.activity.dataset.taking_care",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "Just taking care of what needs doing.",
                                    },
                                    ["TL"] = {
                                        "Just taking care of what needs doing.",
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_activity.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "Just doing what I can to keep things moving.",
                    },
                    ["TL"] = {
                        "Just doing what I can to keep things moving.",
                    },
                },
                ["variantID"] = "question.activity.dataset.keep_moving",
            },
            {
                ["fallback"] = "A little bit of everything.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.activity.say.1.question.activity.dataset.bit_of_everything",
                ["translations"] = {
                    ["EN"] = {
                        "A little bit of everything.",
                    },
                    ["TL"] = {
                        "A little bit of everything.",
                    },
                },
                ["variantID"] = "question.activity.dataset.bit_of_everything",
            },
            {
                ["fallback"] = "Just taking care of what needs doing.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.activity.say.1.question.activity.dataset.taking_care",
                ["translations"] = {
                    ["EN"] = {
                        "Just taking care of what needs doing.",
                    },
                    ["TL"] = {
                        "Just taking care of what needs doing.",
                    },
                },
                ["variantID"] = "question.activity.dataset.taking_care",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Which part of my past do you mean?",
                                    },
                                    ["TL"] = {
                                        "Aling bahagi ng nakaraan ko ang ibig mong sabihin?",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "Which part of my past do you mean?",
                        },
                        ["TL"] = {
                            "Aling bahagi ng nakaraan ko ang ibig mong sabihin?",
                        },
                    },
                    ["variantID"] = "question.backstory.ambiguous.authored",
                },
            },
        },
        ["id"] = "question.backstory.ambiguous",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "ambiguous",
            ["sourceId"] = "question.backstory.ambiguous",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_ambiguous.json",
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
                                ["id"] = "question.backstory.ambiguous.authored",
                                ["metadata"] = {
                                    ["fallback"] = "Which part of my past do you mean?",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryAmbiguous",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "Which part of my past do you mean?",
                                    },
                                    ["TL"] = {
                                        "Aling bahagi ng nakaraan ko ang ibig mong sabihin?",
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_ambiguous.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "Which part of my past do you mean?",
                    },
                    ["TL"] = {
                        "Aling bahagi ng nakaraan ko ang ibig mong sabihin?",
                    },
                },
                ["variantID"] = "question.backstory.ambiguous.authored",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "I remember that part of my life, but I don't have more detail about where it was.",
                                    },
                                    ["TL"] = {
                                        "Naaalala ko ang bahaging iyon ng buhay ko, pero wala akong higit na detalye kung saan iyon.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "I remember that part of my life, but I don't have more detail about where it was.",
                        },
                        ["TL"] = {
                            "Naaalala ko ang bahaging iyon ng buhay ko, pero wala akong higit na detalye kung saan iyon.",
                        },
                    },
                    ["variantID"] = "question.backstory.follow_up.location.authored",
                },
            },
        },
        ["id"] = "question.backstory.follow_up.location",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "location",
            ["sourceId"] = "question.backstory.follow_up.location",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_follow_up_location.json",
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
                                ["id"] = "question.backstory.follow_up.location.authored",
                                ["metadata"] = {
                                    ["fallback"] = "I remember that part of my life, but I don't have more detail about where it was.",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFollowUpLocation",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "I remember that part of my life, but I don't have more detail about where it was.",
                                    },
                                    ["TL"] = {
                                        "Naaalala ko ang bahaging iyon ng buhay ko, pero wala akong higit na detalye kung saan iyon.",
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_follow_up_location.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "I remember that part of my life, but I don't have more detail about where it was.",
                    },
                    ["TL"] = {
                        "Naaalala ko ang bahaging iyon ng buhay ko, pero wala akong higit na detalye kung saan iyon.",
                    },
                },
                ["variantID"] = "question.backstory.follow_up.location.authored",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Sometimes. I still think about that part of my life.",
                                    },
                                    ["TL"] = {
                                        "Minsan. Naiisip ko pa rin ang bahaging iyon ng buhay ko.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "Sometimes. I still think about that part of my life.",
                        },
                        ["TL"] = {
                            "Minsan. Naiisip ko pa rin ang bahaging iyon ng buhay ko.",
                        },
                    },
                    ["variantID"] = "question.backstory.follow_up.miss.authored",
                },
            },
        },
        ["id"] = "question.backstory.follow_up.miss",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "miss",
            ["sourceId"] = "question.backstory.follow_up.miss",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_follow_up_miss.json",
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
                                ["id"] = "question.backstory.follow_up.miss.authored",
                                ["metadata"] = {
                                    ["fallback"] = "Sometimes. I still think about that part of my life.",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFollowUpMiss",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "Sometimes. I still think about that part of my life.",
                                    },
                                    ["TL"] = {
                                        "Minsan. Naiisip ko pa rin ang bahaging iyon ng buhay ko.",
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_follow_up_miss.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "Sometimes. I still think about that part of my life.",
                    },
                    ["TL"] = {
                        "Minsan. Naiisip ko pa rin ang bahaging iyon ng buhay ko.",
                    },
                },
                ["variantID"] = "question.backstory.follow_up.miss.authored",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
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
                                ["id"] = "question.backstory.known.authored",
                                ["templateID"] = "convo.question.backstory.known.say.1.question.backstory.known.authored",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Before all this, I was %1.",
                                    },
                                    ["TL"] = {
                                        "Bago ang lahat ng ito, ako ay %1.",
                                    },
                                },
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
                    ["templateID"] = "convo.question.backstory.known.say.1.question.backstory.known.authored",
                    ["translations"] = {
                        ["EN"] = {
                            "Before all this, I was %1.",
                        },
                        ["TL"] = {
                            "Bago ang lahat ng ito, ako ay %1.",
                        },
                    },
                    ["variantID"] = "question.backstory.known.authored",
                },
            },
        },
        ["id"] = "question.backstory.known",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "known",
            ["sourceId"] = "question.backstory.known",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known.json",
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
                                ["id"] = "question.backstory.known.authored",
                                ["metadata"] = {
                                    ["fallback"] = "Before all this, I was %1.",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryKnown",
                                    ["translationArgs"] = {
                                        ["content"] = "fact_content",
                                    },
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "Before all this, I was %1.",
                                    },
                                    ["TL"] = {
                                        "Bago ang lahat ng ito, ako ay %1.",
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known.json",
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
                ["templateID"] = "convo.question.backstory.known.say.1.question.backstory.known.authored",
                ["translations"] = {
                    ["EN"] = {
                        "Before all this, I was %1.",
                    },
                    ["TL"] = {
                        "Bago ang lahat ng ito, ako ay %1.",
                    },
                },
                ["variantID"] = "question.backstory.known.authored",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "question.backstory.known.education",
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
                                ["fallback"] = "I studied %1.",
                                ["id"] = "question.backstory.known.education.authored",
                                ["templateID"] = "convo.question.backstory.known.education.say.1.question.backstory.known.education.authored",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I studied %1.",
                                    },
                                    ["TL"] = {
                                        "Nag-aral ako ng %1.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.backstory.known",
            ["textRoles"] = {
                {
                    ["fallback"] = "I studied %1.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.backstory.known.education.say.1.question.backstory.known.education.authored",
                    ["translations"] = {
                        ["EN"] = {
                            "I studied %1.",
                        },
                        ["TL"] = {
                            "Nag-aral ako ng %1.",
                        },
                    },
                    ["variantID"] = "question.backstory.known.education.authored",
                },
            },
        },
        ["id"] = "question.backstory.known.education",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "education",
            ["sourceId"] = "question.backstory.known.education",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_education.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "question.backstory.known",
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
                ["responseAct"] = "EDUCATION",
                ["responsePoolID"] = "question.backstory.known.education",
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
                                ["id"] = "question.backstory.known.education.authored",
                                ["metadata"] = {
                                    ["fallback"] = "I studied %1.",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryEducation",
                                    ["translationArgs"] = {
                                        ["content"] = "fact_content",
                                    },
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "I studied %1.",
                                    },
                                    ["TL"] = {
                                        "Nag-aral ako ng %1.",
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
            ["dialogueAct"] = "EDUCATION",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.backstory.known.education",
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
                            ["fallback"] = "I studied %1.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.backstory.known.education.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_education.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I studied %1.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.backstory.known.education.say.1.question.backstory.known.education.authored",
                ["translations"] = {
                    ["EN"] = {
                        "I studied %1.",
                    },
                    ["TL"] = {
                        "Nag-aral ako ng %1.",
                    },
                },
                ["variantID"] = "question.backstory.known.education.authored",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "question.backstory.known.family_background",
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
                                ["fallback"] = "My family was %1.",
                                ["id"] = "question.backstory.known.family_background.authored",
                                ["templateID"] = "convo.question.backstory.known.family_background.say.1.question.backstory.known.family_background.authored",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "My family was %1.",
                                    },
                                    ["TL"] = {
                                        "Ang pamilya ko ay %1.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.backstory.known",
            ["textRoles"] = {
                {
                    ["fallback"] = "My family was %1.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.backstory.known.family_background.say.1.question.backstory.known.family_background.authored",
                    ["translations"] = {
                        ["EN"] = {
                            "My family was %1.",
                        },
                        ["TL"] = {
                            "Ang pamilya ko ay %1.",
                        },
                    },
                    ["variantID"] = "question.backstory.known.family_background.authored",
                },
            },
        },
        ["id"] = "question.backstory.known.family_background",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "family_background",
            ["sourceId"] = "question.backstory.known.family_background",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_family_background.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "question.backstory.known",
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
                ["responseAct"] = "FAMILY_BACKGROUND",
                ["responsePoolID"] = "question.backstory.known.family_background",
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
                                ["id"] = "question.backstory.known.family_background.authored",
                                ["metadata"] = {
                                    ["fallback"] = "My family was %1.",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFamily",
                                    ["translationArgs"] = {
                                        ["content"] = "fact_content",
                                    },
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "My family was %1.",
                                    },
                                    ["TL"] = {
                                        "Ang pamilya ko ay %1.",
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
            ["dialogueAct"] = "FAMILY_BACKGROUND",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.backstory.known.family_background",
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
                            ["fallback"] = "My family was %1.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.backstory.known.family_background.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_family_background.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "My family was %1.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.backstory.known.family_background.say.1.question.backstory.known.family_background.authored",
                ["translations"] = {
                    ["EN"] = {
                        "My family was %1.",
                    },
                    ["TL"] = {
                        "Ang pamilya ko ay %1.",
                    },
                },
                ["variantID"] = "question.backstory.known.family_background.authored",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "question.backstory.known.fear",
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
                                ["fallback"] = "I have always been afraid of %1.",
                                ["id"] = "question.backstory.known.fear.authored",
                                ["templateID"] = "convo.question.backstory.known.fear.say.1.question.backstory.known.fear.authored",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I have always been afraid of %1.",
                                    },
                                    ["TL"] = {
                                        "Palagi akong natatakot sa %1.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.backstory.known",
            ["textRoles"] = {
                {
                    ["fallback"] = "I have always been afraid of %1.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.backstory.known.fear.say.1.question.backstory.known.fear.authored",
                    ["translations"] = {
                        ["EN"] = {
                            "I have always been afraid of %1.",
                        },
                        ["TL"] = {
                            "Palagi akong natatakot sa %1.",
                        },
                    },
                    ["variantID"] = "question.backstory.known.fear.authored",
                },
            },
        },
        ["id"] = "question.backstory.known.fear",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "fear",
            ["sourceId"] = "question.backstory.known.fear",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_fear.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "question.backstory.known",
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
                ["responseAct"] = "FEAR",
                ["responsePoolID"] = "question.backstory.known.fear",
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
                                ["id"] = "question.backstory.known.fear.authored",
                                ["metadata"] = {
                                    ["fallback"] = "I have always been afraid of %1.",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFear",
                                    ["translationArgs"] = {
                                        ["content"] = "fact_content",
                                    },
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "I have always been afraid of %1.",
                                    },
                                    ["TL"] = {
                                        "Palagi akong natatakot sa %1.",
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
            ["dialogueAct"] = "FEAR",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.backstory.known.fear",
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
                            ["fallback"] = "I have always been afraid of %1.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.backstory.known.fear.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_fear.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I have always been afraid of %1.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.backstory.known.fear.say.1.question.backstory.known.fear.authored",
                ["translations"] = {
                    ["EN"] = {
                        "I have always been afraid of %1.",
                    },
                    ["TL"] = {
                        "Palagi akong natatakot sa %1.",
                    },
                },
                ["variantID"] = "question.backstory.known.fear.authored",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "question.backstory.known.former_job",
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
                                ["fallback"] = "I worked as %1 before all this.",
                                ["id"] = "question.backstory.known.former_job.authored",
                                ["templateID"] = "convo.question.backstory.known.former_job.say.1.question.backstory.known.former_job.authored",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I worked as %1 before all this.",
                                    },
                                    ["TL"] = {
                                        "Nagtrabaho ako bilang %1 bago ang lahat ng ito.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.backstory.known",
            ["textRoles"] = {
                {
                    ["fallback"] = "I worked as %1 before all this.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.backstory.known.former_job.say.1.question.backstory.known.former_job.authored",
                    ["translations"] = {
                        ["EN"] = {
                            "I worked as %1 before all this.",
                        },
                        ["TL"] = {
                            "Nagtrabaho ako bilang %1 bago ang lahat ng ito.",
                        },
                    },
                    ["variantID"] = "question.backstory.known.former_job.authored",
                },
            },
        },
        ["id"] = "question.backstory.known.former_job",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "former_job",
            ["sourceId"] = "question.backstory.known.former_job",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_former_job.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "question.backstory.known",
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
                ["responseAct"] = "FORMER_JOB",
                ["responsePoolID"] = "question.backstory.known.former_job",
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
                                ["id"] = "question.backstory.known.former_job.authored",
                                ["metadata"] = {
                                    ["fallback"] = "I worked as %1 before all this.",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFormerJob",
                                    ["translationArgs"] = {
                                        ["content"] = "fact_content",
                                    },
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "I worked as %1 before all this.",
                                    },
                                    ["TL"] = {
                                        "Nagtrabaho ako bilang %1 bago ang lahat ng ito.",
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
            ["dialogueAct"] = "FORMER_JOB",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.backstory.known.former_job",
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
                            ["fallback"] = "I worked as %1 before all this.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.backstory.known.former_job.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_former_job.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I worked as %1 before all this.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.backstory.known.former_job.say.1.question.backstory.known.former_job.authored",
                ["translations"] = {
                    ["EN"] = {
                        "I worked as %1 before all this.",
                    },
                    ["TL"] = {
                        "Nagtrabaho ako bilang %1 bago ang lahat ng ito.",
                    },
                },
                ["variantID"] = "question.backstory.known.former_job.authored",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "question.backstory.known.hobby",
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
                                ["fallback"] = "I used to enjoy %1.",
                                ["id"] = "question.backstory.known.hobby.authored",
                                ["templateID"] = "convo.question.backstory.known.hobby.say.1.question.backstory.known.hobby.authored",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I used to enjoy %1.",
                                    },
                                    ["TL"] = {
                                        "Mahilig ako noon sa %1.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.backstory.known",
            ["textRoles"] = {
                {
                    ["fallback"] = "I used to enjoy %1.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.backstory.known.hobby.say.1.question.backstory.known.hobby.authored",
                    ["translations"] = {
                        ["EN"] = {
                            "I used to enjoy %1.",
                        },
                        ["TL"] = {
                            "Mahilig ako noon sa %1.",
                        },
                    },
                    ["variantID"] = "question.backstory.known.hobby.authored",
                },
            },
        },
        ["id"] = "question.backstory.known.hobby",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "hobby",
            ["sourceId"] = "question.backstory.known.hobby",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_hobby.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "question.backstory.known",
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
                ["responseAct"] = "HOBBY",
                ["responsePoolID"] = "question.backstory.known.hobby",
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
                                ["id"] = "question.backstory.known.hobby.authored",
                                ["metadata"] = {
                                    ["fallback"] = "I used to enjoy %1.",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryHobby",
                                    ["translationArgs"] = {
                                        ["content"] = "fact_content",
                                    },
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "I used to enjoy %1.",
                                    },
                                    ["TL"] = {
                                        "Mahilig ako noon sa %1.",
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
            ["dialogueAct"] = "HOBBY",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.backstory.known.hobby",
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
                            ["fallback"] = "I used to enjoy %1.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.backstory.known.hobby.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_hobby.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I used to enjoy %1.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.backstory.known.hobby.say.1.question.backstory.known.hobby.authored",
                ["translations"] = {
                    ["EN"] = {
                        "I used to enjoy %1.",
                    },
                    ["TL"] = {
                        "Mahilig ako noon sa %1.",
                    },
                },
                ["variantID"] = "question.backstory.known.hobby.authored",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "question.backstory.known.hometown",
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
                                ["fallback"] = "I grew up in %1.",
                                ["id"] = "question.backstory.known.hometown.authored",
                                ["templateID"] = "convo.question.backstory.known.hometown.say.1.question.backstory.known.hometown.authored",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I grew up in %1.",
                                    },
                                    ["TL"] = {
                                        "Lumaki ako sa %1.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.backstory.known",
            ["textRoles"] = {
                {
                    ["fallback"] = "I grew up in %1.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.backstory.known.hometown.say.1.question.backstory.known.hometown.authored",
                    ["translations"] = {
                        ["EN"] = {
                            "I grew up in %1.",
                        },
                        ["TL"] = {
                            "Lumaki ako sa %1.",
                        },
                    },
                    ["variantID"] = "question.backstory.known.hometown.authored",
                },
            },
        },
        ["id"] = "question.backstory.known.hometown",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "hometown",
            ["sourceId"] = "question.backstory.known.hometown",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_hometown.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "question.backstory.known",
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
                ["responseAct"] = "HOMETOWN",
                ["responsePoolID"] = "question.backstory.known.hometown",
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
                                ["id"] = "question.backstory.known.hometown.authored",
                                ["metadata"] = {
                                    ["fallback"] = "I grew up in %1.",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryHometown",
                                    ["translationArgs"] = {
                                        ["content"] = "fact_content",
                                    },
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "I grew up in %1.",
                                    },
                                    ["TL"] = {
                                        "Lumaki ako sa %1.",
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
            ["dialogueAct"] = "HOMETOWN",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.backstory.known.hometown",
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
                            ["fallback"] = "I grew up in %1.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.backstory.known.hometown.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_hometown.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I grew up in %1.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.backstory.known.hometown.say.1.question.backstory.known.hometown.authored",
                ["translations"] = {
                    ["EN"] = {
                        "I grew up in %1.",
                    },
                    ["TL"] = {
                        "Lumaki ako sa %1.",
                    },
                },
                ["variantID"] = "question.backstory.known.hometown.authored",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "question.backstory.known.tragedy",
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
                                ["fallback"] = "Something happened: %1.",
                                ["id"] = "question.backstory.known.tragedy.authored",
                                ["templateID"] = "convo.question.backstory.known.tragedy.say.1.question.backstory.known.tragedy.authored",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Something happened: %1.",
                                    },
                                    ["TL"] = {
                                        "May nangyari: %1.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.backstory.known",
            ["textRoles"] = {
                {
                    ["fallback"] = "Something happened: %1.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.backstory.known.tragedy.say.1.question.backstory.known.tragedy.authored",
                    ["translations"] = {
                        ["EN"] = {
                            "Something happened: %1.",
                        },
                        ["TL"] = {
                            "May nangyari: %1.",
                        },
                    },
                    ["variantID"] = "question.backstory.known.tragedy.authored",
                },
            },
        },
        ["id"] = "question.backstory.known.tragedy",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "tragedy",
            ["sourceId"] = "question.backstory.known.tragedy",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_tragedy.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "question.backstory.known",
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
                ["responseAct"] = "TRAGEDY",
                ["responsePoolID"] = "question.backstory.known.tragedy",
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
                                ["id"] = "question.backstory.known.tragedy.authored",
                                ["metadata"] = {
                                    ["fallback"] = "Something happened: %1.",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryTragedy",
                                    ["translationArgs"] = {
                                        ["content"] = "fact_content",
                                    },
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "Something happened: %1.",
                                    },
                                    ["TL"] = {
                                        "May nangyari: %1.",
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
            ["dialogueAct"] = "TRAGEDY",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.backstory.known.tragedy",
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
                            ["fallback"] = "Something happened: %1.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.backstory.known.tragedy.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_tragedy.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Something happened: %1.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.backstory.known.tragedy.say.1.question.backstory.known.tragedy.authored",
                ["translations"] = {
                    ["EN"] = {
                        "Something happened: %1.",
                    },
                    ["TL"] = {
                        "May nangyari: %1.",
                    },
                },
                ["variantID"] = "question.backstory.known.tragedy.authored",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'm not ready to talk about that yet.",
                                    },
                                    ["TL"] = {
                                        "Hindi pa ako handang pag-usapan iyan.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "I'm not ready to talk about that yet.",
                        },
                        ["TL"] = {
                            "Hindi pa ako handang pag-usapan iyan.",
                        },
                    },
                    ["variantID"] = "question.backstory.refusal.authored",
                },
            },
        },
        ["id"] = "question.backstory.refusal",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "refusal",
            ["sourceId"] = "question.backstory.refusal",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_refusal.json",
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
                                ["id"] = "question.backstory.refusal.authored",
                                ["metadata"] = {
                                    ["fallback"] = "I'm not ready to talk about that yet.",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryRefusal",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "I'm not ready to talk about that yet.",
                                    },
                                    ["TL"] = {
                                        "Hindi pa ako handang pag-usapan iyan.",
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_refusal.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "I'm not ready to talk about that yet.",
                    },
                    ["TL"] = {
                        "Hindi pa ako handang pag-usapan iyan.",
                    },
                },
                ["variantID"] = "question.backstory.refusal.authored",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "I think it was %1, but I could be mistaken.",
                                    },
                                    ["TL"] = {
                                        "Sa tingin ko ay %1 iyon, pero maaaring mali ako.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "I think it was %1, but I could be mistaken.",
                        },
                        ["TL"] = {
                            "Sa tingin ko ay %1 iyon, pero maaaring mali ako.",
                        },
                    },
                    ["variantID"] = "question.backstory.suspected.authored",
                },
            },
        },
        ["id"] = "question.backstory.suspected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "suspected",
            ["sourceId"] = "question.backstory.suspected",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_suspected.json",
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
                                ["id"] = "question.backstory.suspected.authored",
                                ["metadata"] = {
                                    ["fallback"] = "I think it was %1, but I could be mistaken.",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstorySuspected",
                                    ["translationArgs"] = {
                                        ["content"] = "fact_content",
                                    },
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "I think it was %1, but I could be mistaken.",
                                    },
                                    ["TL"] = {
                                        "Sa tingin ko ay %1 iyon, pero maaaring mali ako.",
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_suspected.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "I think it was %1, but I could be mistaken.",
                    },
                    ["TL"] = {
                        "Sa tingin ko ay %1 iyon, pero maaaring mali ako.",
                    },
                },
                ["variantID"] = "question.backstory.suspected.authored",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "question.needs.proposal",
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
                                ["fallback"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                                ["id"] = "question.needs.proposal.dataset.thirst",
                                ["templateID"] = "convo.question.needs.proposal.say.1.question.needs.proposal.dataset.thirst",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                                    },
                                    ["TL"] = {
                                        "Maaari ko iyong ituring na panukala, pero kailangan ko pa ang item at dami bago ako magtala ng pangako.",
                                    },
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
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.needs",
            ["textRoles"] = {
                {
                    ["fallback"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.needs.proposal.say.1.question.needs.proposal.dataset.thirst",
                    ["translations"] = {
                        ["EN"] = {
                            "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                        },
                        ["TL"] = {
                            "Maaari ko iyong ituring na panukala, pero kailangan ko pa ang item at dami bago ako magtala ng pangako.",
                        },
                    },
                    ["variantID"] = "question.needs.proposal.dataset.thirst",
                },
            },
        },
        ["id"] = "question.needs.proposal",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "proposal",
            ["sourceId"] = "question.needs.proposal",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_needs_proposal.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "question.needs",
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
                ["responseAct"] = "PROPOSAL",
                ["responsePoolID"] = "question.needs.proposal",
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
                                ["id"] = "question.needs.proposal.dataset.thirst",
                                ["metadata"] = {
                                    ["fallback"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                                    ["plan"] = {
                                        ["dialogueAct"] = "PROMISE_ACKNOWLEDGEMENT",
                                        ["groundedFactRefs"] = {
                                            "npc.needs.thirst",
                                        },
                                        ["sourcePoolID"] = "semantic.question.needs.proposal",
                                        ["tone"] = "direct",
                                        ["topic"] = "NEEDS",
                                        ["turns"] = {
                                            {
                                                ["continuation"] = "continue",
                                                ["id"] = "dataset_proposal_acknowledged",
                                                ["segments"] = {
                                                    {
                                                        ["fallback"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                                                        ["kind"] = "translation",
                                                        ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetNeedsPromiseThirst",
                                                        ["translations"] = {
                                                            ["EN"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                                                            ["TL"] = "Maaari ko iyong ituring na panukala, pero kailangan ko pa ang item at dami bago ako magtala ng pangako.",
                                                        },
                                                    },
                                                },
                                            },
                                        },
                                        ["uncertainty"] = "pending",
                                    },
                                    ["priority"] = 4,
                                    ["reviewed"] = true,
                                    ["sourceRefs"] = {
                                        "MASSIVE",
                                        "SGD",
                                    },
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetNeedsPromiseThirst",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                                    },
                                    ["TL"] = {
                                        "Maaari ko iyong ituring na panukala, pero kailangan ko pa ang item at dami bago ako magtala ng pangako.",
                                    },
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
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "PROPOSAL",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.needs.proposal",
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
                            ["fallback"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.needs.proposal.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_needs_proposal.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.needs.proposal.say.1.question.needs.proposal.dataset.thirst",
                ["translations"] = {
                    ["EN"] = {
                        "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                    },
                    ["TL"] = {
                        "Maaari ko iyong ituring na panukala, pero kailangan ko pa ang item at dami bago ako magtala ng pangako.",
                    },
                },
                ["variantID"] = "question.needs.proposal.dataset.thirst",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "question.needs.quantity",
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
                                ["fallback"] = "I can confirm water is a need, but which item do you mean?",
                                ["id"] = "question.needs.quantity.dataset.clarify_thirst",
                                ["templateID"] = "convo.question.needs.quantity.say.1.question.needs.quantity.dataset.clarify_thirst",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I can confirm water is a need, but which item do you mean?",
                                    },
                                    ["TL"] = {
                                        "Makukumpirma kong kailangan ang tubig, pero aling item ang ibig mong sabihin?",
                                    },
                                },
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.lastIntent",
                                            ["value"] = "CLARIFY",
                                        },
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.needType",
                                            ["value"] = "thirst",
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.needs",
            ["textRoles"] = {
                {
                    ["fallback"] = "I can confirm water is a need, but which item do you mean?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.needs.quantity.say.1.question.needs.quantity.dataset.clarify_thirst",
                    ["translations"] = {
                        ["EN"] = {
                            "I can confirm water is a need, but which item do you mean?",
                        },
                        ["TL"] = {
                            "Makukumpirma kong kailangan ang tubig, pero aling item ang ibig mong sabihin?",
                        },
                    },
                    ["variantID"] = "question.needs.quantity.dataset.clarify_thirst",
                },
            },
        },
        ["id"] = "question.needs.quantity",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "quantity",
            ["sourceId"] = "question.needs.quantity",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_needs_quantity.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "question.needs",
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
                ["responseAct"] = "QUANTITY",
                ["responsePoolID"] = "question.needs.quantity",
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
                                ["id"] = "question.needs.quantity.dataset.clarify_thirst",
                                ["metadata"] = {
                                    ["fallback"] = "I can confirm water is a need, but which item do you mean?",
                                    ["plan"] = {
                                        ["dialogueAct"] = "ASK_CLARIFICATION",
                                        ["groundedFactRefs"] = {
                                            "npc.needs.thirst",
                                        },
                                        ["sourcePoolID"] = "semantic.question.needs.quantity",
                                        ["tone"] = "clarifying",
                                        ["topic"] = "NEEDS",
                                        ["turns"] = {
                                            {
                                                ["continuation"] = "continue",
                                                ["id"] = "dataset_needs_clarification",
                                                ["segments"] = {
                                                    {
                                                        ["fallback"] = "I can confirm water is a need, but which item do you mean?",
                                                        ["kind"] = "translation",
                                                        ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetNeedsClarifyThirst",
                                                        ["translations"] = {
                                                            ["EN"] = "I can confirm water is a need, but which item do you mean?",
                                                            ["TL"] = "Makukumpirma kong kailangan ang tubig, pero aling item ang ibig mong sabihin?",
                                                        },
                                                    },
                                                },
                                            },
                                        },
                                        ["uncertainty"] = "ambiguous",
                                    },
                                    ["priority"] = 4,
                                    ["reviewed"] = true,
                                    ["sourceRefs"] = {
                                        "MASSIVE",
                                        "SGD",
                                    },
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetNeedsClarifyThirst",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "I can confirm water is a need, but which item do you mean?",
                                    },
                                    ["TL"] = {
                                        "Makukumpirma kong kailangan ang tubig, pero aling item ang ibig mong sabihin?",
                                    },
                                },
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.lastIntent",
                                            ["value"] = "CLARIFY",
                                        },
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.needType",
                                            ["value"] = "thirst",
                                        },
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
            ["dialogueAct"] = "QUANTITY",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.needs.quantity",
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
                            ["fallback"] = "I can confirm water is a need, but which item do you mean?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.needs.quantity.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_needs_quantity.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I can confirm water is a need, but which item do you mean?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.needs.quantity.say.1.question.needs.quantity.dataset.clarify_thirst",
                ["translations"] = {
                    ["EN"] = {
                        "I can confirm water is a need, but which item do you mean?",
                    },
                    ["TL"] = {
                        "Makukumpirma kong kailangan ang tubig, pero aling item ang ibig mong sabihin?",
                    },
                },
                ["variantID"] = "question.needs.quantity.dataset.clarify_thirst",
            },
        },
        ["when"] = nil,
    },
}
