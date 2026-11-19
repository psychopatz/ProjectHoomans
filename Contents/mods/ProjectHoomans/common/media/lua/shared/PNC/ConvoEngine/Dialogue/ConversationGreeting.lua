-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_greeting",
        ["domainPath"] = "conversation_greeting",
        ["id"] = "conversation.landing.whats_up",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "whats_up",
            ["sourceId"] = "conversation.landing.whats_up",
            ["sourcePath"] = "dialogue/conversation_greeting/conversation_landing_whats_up.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationGreeting",
        ["namespace"] = "conversation.landing",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "player",
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
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["playerChoice"] = {
                    ["choiceFallback"] = "What's up?",
                    ["hubID"] = "whats_up",
                    ["id"] = "conversation.landing:whats_up",
                    ["kind"] = "player_landing_choice",
                    ["labelFallback"] = "What's up",
                    ["route"] = "semantic_hub",
                },
            },
            ["response"] = {
                ["act"] = "QUESTION",
                ["variants"] = {
                },
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
        ["sourceShard"] = "dialogue/conversation_greeting/conversation_landing_whats_up.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_greeting",
        ["domainPath"] = "conversation_greeting",
        ["exchangeFamily"] = {
            ["familyID"] = "flow.greeting.exchange",
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
                                ["fallback"] = "Hello.",
                                ["id"] = "default",
                                ["templateID"] = "convo.flow.greeting.exchange.say.1.default",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "flow.greeting",
            ["replies"] = {
                ["friendly"] = {
                    ["outcome"] = "friendly",
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
                                        ["fallback"] = "Good to see you.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.flow.greeting.exchange.reply.friendly.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["hostile"] = {
                    ["outcome"] = "hostile",
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
                                        ["fallback"] = "Stay back.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.flow.greeting.exchange.reply.hostile.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "Hello.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.greeting.exchange.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Good to see you.",
                    ["outcome"] = "friendly",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.flow.greeting.exchange.reply.friendly.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Stay back.",
                    ["outcome"] = "hostile",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.flow.greeting.exchange.reply.hostile.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "flow.greeting.exchange",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "exchange",
            ["sourceId"] = "flow.greeting.exchange",
            ["sourcePath"] = "dialogue/conversation_greeting/flow_greeting_exchange.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationGreeting",
        ["namespace"] = "flow.greeting",
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
            ["closure"] = {
                ["closureClass"] = "none",
            },
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["inputPolicy"] = "typed_parity",
            ["metadata"] = {
                ["flow"] = {
                    ["constraints"] = {
                        ["all"] = {
                            {
                                ["op"] = "not_in",
                                ["path"] = "npcState.activeBehavior",
                                ["values"] = {
                                    "hostile",
                                    "combat",
                                    "busy",
                                    "dead",
                                },
                            },
                            {
                                ["op"] = "not_in",
                                ["path"] = "situation.activeBehavior",
                                ["values"] = {
                                    "hostile",
                                    "combat",
                                    "busy",
                                    "dead",
                                },
                            },
                            {
                                ["op"] = "neq",
                                ["path"] = "roles.hostile",
                                ["value"] = true,
                            },
                            {
                                ["op"] = "neq",
                                ["path"] = "actorConversationContext.roles.hostile",
                                ["value"] = true,
                            },
                            {
                                ["op"] = "not_in",
                                ["path"] = "actorConversationContext.situation.activeBehavior",
                                ["values"] = {
                                    "hostile",
                                    "combat",
                                    "busy",
                                    "dead",
                                },
                            },
                            {
                                ["op"] = "not_in",
                                ["path"] = "npcState.healthState",
                                ["values"] = {
                                    "dead",
                                    "incapacitated",
                                },
                            },
                        },
                    },
                    ["id"] = "greeting",
                    ["initial"] = "await_thanks",
                    ["nodes"] = {
                        ["await_thanks"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "THANK",
                                    ["speechAct"] = "THANK",
                                },
                                {
                                    ["intent"] = "INFORM",
                                    ["selfDirected"] = true,
                                    ["speechAct"] = "INFORM",
                                    ["stateType"] = "WELLBEING",
                                    ["target"] = "SELF",
                                },
                            },
                            ["branchOffers"] = {
                                {
                                    ["constraints"] = {
                                        ["all"] = {
                                            {
                                                ["op"] = "not_in",
                                                ["path"] = "npcState.activeBehavior",
                                                ["values"] = {
                                                    "hostile",
                                                    "combat",
                                                    "busy",
                                                    "dead",
                                                },
                                            },
                                            {
                                                ["op"] = "not_in",
                                                ["path"] = "npcState.healthState",
                                                ["values"] = {
                                                    "dead",
                                                    "incapacitated",
                                                },
                                            },
                                        },
                                    },
                                    ["frame"] = {
                                        ["intent"] = "THANK",
                                        ["speechAct"] = "THANK",
                                    },
                                    ["id"] = "greeting.thanks",
                                    ["labelFallback"] = "Thank them",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_GreetingThank_Label",
                                    ["utteranceFallback"] = "Thanks.",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_GreetingThank_Utterance",
                                },
                            },
                            ["onMatch"] = "complete",
                            ["onRefuse"] = "cancel",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.flow.greeting.opening",
                        },
                        ["complete"] = {
                            ["responsePool"] = "semantic.flow.greeting.followup",
                            ["terminal"] = true,
                        },
                    },
                    ["owner"] = "ProjectHoomans",
                    ["version"] = 1,
                },
                ["triggers"] = {
                    {
                        ["intent"] = "GREET",
                        ["speechAct"] = "GREET",
                    },
                },
            },
            ["repeatPolicy"] = "repeatable",
            ["reply"] = {
                ["friendly"] = {
                    ["outcome"] = "friendly",
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
                                        ["fallback"] = "Good to see you.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["hostile"] = {
                    ["outcome"] = "hostile",
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
                                        ["fallback"] = "Stay back.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
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
                                ["fallback"] = "Hello.",
                                ["id"] = "default",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["statePolicy"] = {
                {
                    ["admission"] = "no_op",
                    ["id"] = "hostile_or_blocked_greeting",
                    ["outcome"] = "blocked",
                    ["reason"] = "hostile_or_busy_npc",
                    ["replyOutcome"] = "hostile",
                    ["when"] = {
                        ["any"] = {
                            {
                                ["op"] = "in",
                                ["path"] = "npcState.activeBehavior",
                                ["values"] = {
                                    "hostile",
                                    "combat",
                                    "busy",
                                    "dead",
                                },
                            },
                            {
                                ["op"] = "in",
                                ["path"] = "situation.activeBehavior",
                                ["values"] = {
                                    "hostile",
                                    "combat",
                                    "busy",
                                    "dead",
                                },
                            },
                            {
                                ["op"] = "eq",
                                ["path"] = "roles.hostile",
                                ["value"] = true,
                            },
                        },
                    },
                },
                {
                    ["admission"] = "dispatch",
                    ["id"] = "friendly_greeting",
                    ["outcome"] = "actionable",
                    ["reason"] = "ready",
                },
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "greeting",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "flow.greeting.exchange",
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
                            ["fallback"] = "Hello.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.flow.greeting.exchange.say_1",
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
        ["sourceShard"] = "dialogue/conversation_greeting/flow_greeting_exchange.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Hello.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.greeting.exchange.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Good to see you.",
                ["outcome"] = "friendly",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.flow.greeting.exchange.reply.friendly.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Stay back.",
                ["outcome"] = "hostile",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.flow.greeting.exchange.reply.hostile.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_greeting",
        ["domainPath"] = "conversation_greeting",
        ["exchangeFamily"] = {
            ["familyID"] = "flow.greeting.followup",
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
                                ["fallback"] = "You're welcome. It's good to see you too.",
                                ["id"] = "friendly",
                                ["templateID"] = "convo.flow.greeting.followup.say.1.friendly",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "You're welcome. Take care.",
                                ["id"] = "default",
                                ["templateID"] = "convo.flow.greeting.followup.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "flow.greeting",
            ["textRoles"] = {
                {
                    ["fallback"] = "You're welcome. It's good to see you too.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.greeting.followup.say.1.friendly",
                    ["variantID"] = "friendly",
                },
                {
                    ["fallback"] = "You're welcome. Take care.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.greeting.followup.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "flow.greeting.followup",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "followup",
            ["sourceId"] = "flow.greeting.followup",
            ["sourcePath"] = "dialogue/conversation_greeting/flow_greeting_followup.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationGreeting",
        ["namespace"] = "flow.greeting",
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
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
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
                                ["fallback"] = "You're welcome. It's good to see you too.",
                                ["id"] = "friendly",
                            },
                            {
                                ["fallback"] = "You're welcome. Take care.",
                                ["id"] = "default",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "greeting",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "flow.greeting.followup",
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
                            ["fallback"] = "You're welcome. It's good to see you too.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.flow.greeting.followup.say_1",
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
        ["sourceShard"] = "dialogue/conversation_greeting/flow_greeting_followup.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "You're welcome. It's good to see you too.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.greeting.followup.say.1.friendly",
                ["variantID"] = "friendly",
            },
            {
                ["fallback"] = "You're welcome. Take care.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.greeting.followup.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_greeting",
        ["domainPath"] = "conversation_greeting",
        ["exchangeFamily"] = {
            ["familyID"] = "flow.greeting.opening",
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
                                ["fallback"] = "Hey there. Good to see you.",
                                ["id"] = "default",
                                ["templateID"] = "convo.flow.greeting.opening.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "State your business. Keep your distance.",
                                ["id"] = "default.guarded",
                                ["templateID"] = "convo.flow.greeting.opening.say.1.default.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Hello.",
                                ["id"] = "default.terse",
                                ["templateID"] = "convo.flow.greeting.opening.say.1.default.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Hey! It is good to see you.",
                                ["id"] = "default.warm",
                                ["templateID"] = "convo.flow.greeting.opening.say.1.default.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Good to see you.",
                                ["id"] = "friendly",
                                ["templateID"] = "convo.flow.greeting.opening.say.1.friendly",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Hey. Everything holding together?",
                                ["id"] = "friendly.guarded",
                                ["templateID"] = "convo.flow.greeting.opening.say.1.friendly.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Back again? You holding up?",
                                ["id"] = "friendly.terse",
                                ["templateID"] = "convo.flow.greeting.opening.say.1.friendly.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "There you are! Good to see you.",
                                ["id"] = "friendly.warm",
                                ["templateID"] = "convo.flow.greeting.opening.say.1.friendly.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "How have you been?",
                                ["id"] = "question.default",
                                ["templateID"] = "convo.flow.greeting.opening.say.1.question.default",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "How have you been holding up lately?",
                                ["id"] = "question.friendly",
                                ["templateID"] = "convo.flow.greeting.opening.say.1.question.friendly",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "flow.greeting",
            ["textRoles"] = {
                {
                    ["fallback"] = "Hey there. Good to see you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.greeting.opening.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "State your business. Keep your distance.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.greeting.opening.say.1.default.guarded",
                    ["variantID"] = "default.guarded",
                },
                {
                    ["fallback"] = "Hello.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.greeting.opening.say.1.default.terse",
                    ["variantID"] = "default.terse",
                },
                {
                    ["fallback"] = "Hey! It is good to see you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.greeting.opening.say.1.default.warm",
                    ["variantID"] = "default.warm",
                },
                {
                    ["fallback"] = "Good to see you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.greeting.opening.say.1.friendly",
                    ["variantID"] = "friendly",
                },
                {
                    ["fallback"] = "Hey. Everything holding together?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.greeting.opening.say.1.friendly.guarded",
                    ["variantID"] = "friendly.guarded",
                },
                {
                    ["fallback"] = "Back again? You holding up?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.greeting.opening.say.1.friendly.terse",
                    ["variantID"] = "friendly.terse",
                },
                {
                    ["fallback"] = "There you are! Good to see you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.greeting.opening.say.1.friendly.warm",
                    ["variantID"] = "friendly.warm",
                },
                {
                    ["fallback"] = "How have you been?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.greeting.opening.say.1.question.default",
                    ["variantID"] = "question.default",
                },
                {
                    ["fallback"] = "How have you been holding up lately?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.greeting.opening.say.1.question.friendly",
                    ["variantID"] = "question.friendly",
                },
            },
        },
        ["id"] = "flow.greeting.opening",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "opening",
            ["sourceId"] = "flow.greeting.opening",
            ["sourcePath"] = "dialogue/conversation_greeting/flow_greeting_opening.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationGreeting",
        ["namespace"] = "flow.greeting",
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
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
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
                                ["fallback"] = "Hey there. Good to see you.",
                                ["id"] = "default",
                            },
                            {
                                ["fallback"] = "State your business. Keep your distance.",
                                ["id"] = "default.guarded",
                            },
                            {
                                ["fallback"] = "Hello.",
                                ["id"] = "default.terse",
                            },
                            {
                                ["fallback"] = "Hey! It is good to see you.",
                                ["id"] = "default.warm",
                            },
                            {
                                ["fallback"] = "Good to see you.",
                                ["id"] = "friendly",
                            },
                            {
                                ["fallback"] = "Hey. Everything holding together?",
                                ["id"] = "friendly.guarded",
                            },
                            {
                                ["fallback"] = "Back again? You holding up?",
                                ["id"] = "friendly.terse",
                            },
                            {
                                ["fallback"] = "There you are! Good to see you.",
                                ["id"] = "friendly.warm",
                            },
                            {
                                ["fallback"] = "How have you been?",
                                ["id"] = "question.default",
                            },
                            {
                                ["fallback"] = "How have you been holding up lately?",
                                ["id"] = "question.friendly",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "greeting",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "flow.greeting.opening",
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
                            ["fallback"] = "Hey there. Good to see you.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.flow.greeting.opening.say_1",
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
        ["sourceShard"] = "dialogue/conversation_greeting/flow_greeting_opening.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Hey there. Good to see you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.greeting.opening.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "State your business. Keep your distance.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.greeting.opening.say.1.default.guarded",
                ["variantID"] = "default.guarded",
            },
            {
                ["fallback"] = "Hello.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.greeting.opening.say.1.default.terse",
                ["variantID"] = "default.terse",
            },
            {
                ["fallback"] = "Hey! It is good to see you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.greeting.opening.say.1.default.warm",
                ["variantID"] = "default.warm",
            },
            {
                ["fallback"] = "Good to see you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.greeting.opening.say.1.friendly",
                ["variantID"] = "friendly",
            },
            {
                ["fallback"] = "Hey. Everything holding together?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.greeting.opening.say.1.friendly.guarded",
                ["variantID"] = "friendly.guarded",
            },
            {
                ["fallback"] = "Back again? You holding up?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.greeting.opening.say.1.friendly.terse",
                ["variantID"] = "friendly.terse",
            },
            {
                ["fallback"] = "There you are! Good to see you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.greeting.opening.say.1.friendly.warm",
                ["variantID"] = "friendly.warm",
            },
            {
                ["fallback"] = "How have you been?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.greeting.opening.say.1.question.default",
                ["variantID"] = "question.default",
            },
            {
                ["fallback"] = "How have you been holding up lately?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.greeting.opening.say.1.question.friendly",
                ["variantID"] = "question.friendly",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_greeting",
        ["domainPath"] = "conversation_greeting",
        ["exchangeFamily"] = {
            ["familyID"] = "flow.greeting.opening.rain",
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
                                ["fallback"] = "Hey there. Wet one today.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.flow.greeting.opening.rain.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "flow.greeting.opening",
            ["textRoles"] = {
                {
                    ["fallback"] = "Hey there. Wet one today.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.greeting.opening.rain.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "flow.greeting.opening.rain",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "rain",
            ["sourceId"] = "flow.greeting.opening.rain",
            ["sourcePath"] = "dialogue/conversation_greeting/flow_greeting_opening_rain.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationGreeting",
        ["namespace"] = "flow.greeting.opening",
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
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
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
                                ["fallback"] = "Hey there. Wet one today.",
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
                    ["id"] = "greeting",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "flow.greeting.opening.rain",
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
                            ["fallback"] = "Hey there. Wet one today.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.flow.greeting.opening.rain.say_1",
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
        ["sourceShard"] = "dialogue/conversation_greeting/flow_greeting_opening_rain.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Hey there. Wet one today.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.greeting.opening.rain.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_greeting",
        ["domainPath"] = "conversation_greeting",
        ["exchangeFamily"] = {
            ["familyID"] = "flow.greeting.responses",
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
                                ["fallback"] = "You're welcome. Take care.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.flow.greeting.responses.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "flow.greeting",
            ["textRoles"] = {
                {
                    ["fallback"] = "You're welcome. Take care.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.greeting.responses.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "flow.greeting.responses",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "responses",
            ["sourceId"] = "flow.greeting.responses",
            ["sourcePath"] = "dialogue/conversation_greeting/flow_greeting_responses.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationGreeting",
        ["namespace"] = "flow.greeting",
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
                        ["fallback"] = "You're welcome. Take care.",
                        ["key"] = "UI_PNC_Conversation_Semantic_FlowGreetingFollowup",
                    },
                    {
                        ["fallback"] = "You're welcome. It's good to see you too.",
                        ["key"] = "UI_PNC_Conversation_Semantic_FlowGreetingFollowupFriendly",
                    },
                    {
                        ["fallback"] = "Hey there. Good to see you.",
                        ["key"] = "UI_PNC_Conversation_Semantic_FlowGreetingOpening",
                    },
                    {
                        ["fallback"] = "Hey! Good to see you.",
                        ["key"] = "UI_PNC_Conversation_Semantic_FlowGreetingOpeningFriendly",
                    },
                    {
                        ["fallback"] = "How have you been?",
                        ["key"] = "UI_PNC_Conversation_Semantic_FlowGreetingOpeningQuestion",
                    },
                    {
                        ["fallback"] = "How have you been holding up?",
                        ["key"] = "UI_PNC_Conversation_Semantic_FlowGreetingOpeningQuestionFriendly",
                    },
                    {
                        ["fallback"] = "Hey there. Wet one today.",
                        ["key"] = "UI_PNC_Conversation_Semantic_FlowGreetingOpeningRain",
                    },
                    {
                        ["fallback"] = "The weather looks clear right now.",
                        ["key"] = "UI_PNC_Conversation_Semantic_FlowWeatherClear",
                    },
                    {
                        ["fallback"] = "It is raining right now. I would wait for a break.",
                        ["key"] = "UI_PNC_Conversation_Semantic_FlowWeatherRaining",
                    },
                    {
                        ["fallback"] = "I cannot confirm the weather from here.",
                        ["key"] = "UI_PNC_Conversation_Semantic_FlowWeatherUnknown",
                    },
                    {
                        ["fallback"] = "State your business. Keep your distance.",
                        ["key"] = "UI_PNC_Conversation_Semantic_RealizationGreetingGuarded",
                    },
                    {
                        ["fallback"] = "Hello. Good to see you.",
                        ["key"] = "UI_PNC_Conversation_Semantic_RealizationGreetingNeutral",
                    },
                    {
                        ["fallback"] = "How are things?",
                        ["key"] = "UI_PNC_Conversation_Semantic_RealizationGreetingQuestionGuarded",
                    },
                    {
                        ["fallback"] = "How have you been?",
                        ["key"] = "UI_PNC_Conversation_Semantic_RealizationGreetingQuestionNeutral",
                    },
                    {
                        ["fallback"] = "You okay?",
                        ["key"] = "UI_PNC_Conversation_Semantic_RealizationGreetingQuestionTerse",
                    },
                    {
                        ["fallback"] = "How have you been holding up?",
                        ["key"] = "UI_PNC_Conversation_Semantic_RealizationGreetingQuestionWarm",
                    },
                    {
                        ["fallback"] = "Hello.",
                        ["key"] = "UI_PNC_Conversation_Semantic_RealizationGreetingTerse",
                    },
                    {
                        ["fallback"] = "Hey! It is good to see you.",
                        ["key"] = "UI_PNC_Conversation_Semantic_RealizationGreetingWarm",
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
                                ["fallback"] = "You're welcome. Take care.",
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
                    ["id"] = "greeting",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "flow.greeting.responses",
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
                            ["fallback"] = "You're welcome. Take care.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.flow.greeting.responses.say_1",
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
        ["sourceShard"] = "dialogue/conversation_greeting/flow_greeting_responses.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "You're welcome. Take care.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.greeting.responses.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
