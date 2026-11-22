-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "thematic_interactive",
        ["domainPath"] = "thematic_interactive",
        ["exchangeFamily"] = {
            ["familyID"] = "wellbeing.needs.checkin",
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
                                ["fallback"] = "You holding up all right? You look like you've had a rough stretch.",
                                ["id"] = "default",
                                ["templateID"] = "convo.wellbeing.needs.checkin.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Glad to see you still on your feet. Need anything while we've got a quiet moment?",
                                ["id"] = "positive",
                                ["templateID"] = "convo.wellbeing.needs.checkin.say.1.positive",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Just checking in. Running low on clean water, food, or anything to patch up with?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.wellbeing.needs.checkin.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "You look half-spent. Don't tell me you're fine if you're running on empty.",
                                ["id"] = "negative",
                                ["templateID"] = "convo.wellbeing.needs.checkin.say.1.negative",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "With the water pressure gone and the nights getting colder, how are you keeping up?",
                                ["id"] = "contextual",
                                ["templateID"] = "convo.wellbeing.needs.checkin.say.1.contextual",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "wellbeing.needs",
            ["replies"] = {
                ["blocked"] = {
                    ["outcome"] = "blocked",
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
                                        ["fallback"] = "Can't do this right now—keep your eyes up.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.wellbeing.needs.checkin.reply.blocked.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "Leave it. I've got bigger problems in front of me.",
                                        ["id"] = "negative",
                                        ["templateID"] = "convo.wellbeing.needs.checkin.reply.blocked.say.1.negative",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["declined"] = {
                    ["outcome"] = "declined",
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
                                        ["fallback"] = "I'm fine. Worry about your own pack.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.wellbeing.needs.checkin.reply.declined.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "Don't fuss over me. I'll handle my own business.",
                                        ["id"] = "negative",
                                        ["templateID"] = "convo.wellbeing.needs.checkin.reply.declined.say.1.negative",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["deferred"] = {
                    ["outcome"] = "deferred",
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
                                        ["fallback"] = "Let's get somewhere with four walls first, then we'll sort out what's short.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.wellbeing.needs.checkin.reply.deferred.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "Holding steady for now. Ask me again once we're off the open road.",
                                        ["id"] = "neutral",
                                        ["templateID"] = "convo.wellbeing.needs.checkin.reply.deferred.say.1.neutral",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "I'll manage until dusk—just need a quiet roof and five minutes off my feet.",
                                        ["id"] = "contextual",
                                        ["templateID"] = "convo.wellbeing.needs.checkin.reply.deferred.say.1.contextual",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["evasive"] = {
                    ["outcome"] = "evasive",
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
                                        ["fallback"] = "Getting by well enough. No sense complaining about it.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.wellbeing.needs.checkin.reply.evasive.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "Same as everybody else—tired, hungry, still kicking.",
                                        ["id"] = "neutral",
                                        ["templateID"] = "convo.wellbeing.needs.checkin.reply.evasive.say.1.neutral",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["supported"] = {
                    ["outcome"] = "supported",
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
                                        ["fallback"] = "Appreciate that. Knowing someone's got an eye out helps more than you'd think.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.wellbeing.needs.checkin.reply.supported.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "Thanks, {addressee.name}. A little help goes a long way out here.",
                                        ["id"] = "positive",
                                        ["templateID"] = "convo.wellbeing.needs.checkin.reply.supported.say.1.positive",
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
                    ["fallback"] = "You holding up all right? You look like you've had a rough stretch.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.wellbeing.needs.checkin.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Glad to see you still on your feet. Need anything while we've got a quiet moment?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.wellbeing.needs.checkin.say.1.positive",
                    ["variantID"] = "positive",
                },
                {
                    ["fallback"] = "Just checking in. Running low on clean water, food, or anything to patch up with?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.wellbeing.needs.checkin.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "You look half-spent. Don't tell me you're fine if you're running on empty.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.wellbeing.needs.checkin.say.1.negative",
                    ["variantID"] = "negative",
                },
                {
                    ["fallback"] = "With the water pressure gone and the nights getting colder, how are you keeping up?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.wellbeing.needs.checkin.say.1.contextual",
                    ["variantID"] = "contextual",
                },
                {
                    ["fallback"] = "Can't do this right now—keep your eyes up.",
                    ["outcome"] = "blocked",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.wellbeing.needs.checkin.reply.blocked.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Leave it. I've got bigger problems in front of me.",
                    ["outcome"] = "blocked",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.wellbeing.needs.checkin.reply.blocked.say.1.negative",
                    ["variantID"] = "negative",
                },
                {
                    ["fallback"] = "I'm fine. Worry about your own pack.",
                    ["outcome"] = "declined",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.wellbeing.needs.checkin.reply.declined.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Don't fuss over me. I'll handle my own business.",
                    ["outcome"] = "declined",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.wellbeing.needs.checkin.reply.declined.say.1.negative",
                    ["variantID"] = "negative",
                },
                {
                    ["fallback"] = "Let's get somewhere with four walls first, then we'll sort out what's short.",
                    ["outcome"] = "deferred",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.wellbeing.needs.checkin.reply.deferred.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Holding steady for now. Ask me again once we're off the open road.",
                    ["outcome"] = "deferred",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.wellbeing.needs.checkin.reply.deferred.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I'll manage until dusk—just need a quiet roof and five minutes off my feet.",
                    ["outcome"] = "deferred",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.wellbeing.needs.checkin.reply.deferred.say.1.contextual",
                    ["variantID"] = "contextual",
                },
                {
                    ["fallback"] = "Getting by well enough. No sense complaining about it.",
                    ["outcome"] = "evasive",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.wellbeing.needs.checkin.reply.evasive.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Same as everybody else—tired, hungry, still kicking.",
                    ["outcome"] = "evasive",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.wellbeing.needs.checkin.reply.evasive.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Appreciate that. Knowing someone's got an eye out helps more than you'd think.",
                    ["outcome"] = "supported",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.wellbeing.needs.checkin.reply.supported.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Thanks, {addressee.name}. A little help goes a long way out here.",
                    ["outcome"] = "supported",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.wellbeing.needs.checkin.reply.supported.say.1.positive",
                    ["variantID"] = "positive",
                },
            },
        },
        ["id"] = "wellbeing.needs.checkin",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "checkin",
            ["sourceId"] = "wellbeing.needs.checkin",
            ["sourcePath"] = "dialogue/thematic_interactive/wellbeing_needs_checkin.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ThematicInteractive/WellbeingNeedsCheckin",
        ["namespace"] = "wellbeing.needs",
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
                    ["domain"] = "wellbeing",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["inputPolicy"] = "typed_parity",
            ["metadata"] = {
                ["category"] = "projecthoomans:thematic_interactive",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
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
                                ["op"] = "not_in",
                                ["path"] = "npcState.healthState",
                                ["values"] = {
                                    "dead",
                                    "incapacitated",
                                },
                            },
                        },
                    },
                    ["id"] = "wellbeing.needs.checkin",
                    ["initial"] = "checkin_opening",
                    ["nodes"] = {
                        ["assess_need"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "PROMISE",
                                    ["speechAct"] = "PROMISE",
                                    ["subject"] = "NEEDS",
                                },
                                {
                                    ["intent"] = "SUGGEST",
                                    ["speechAct"] = "SUGGEST",
                                    ["subject"] = "WELLBEING",
                                },
                                {
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                },
                            },
                            ["branchOffers"] = {
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "PROMISE",
                                        ["speechAct"] = "PROMISE",
                                        ["subject"] = "NEEDS",
                                    },
                                    ["id"] = "wellbeing.checkin.offer_help",
                                    ["labelFallback"] = "Offer to pitch in",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_WellbeingOfferHelp_Label",
                                    ["utteranceFallback"] = "I can spare a bottle or a bandage if we're splitting the load.",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_WellbeingOfferHelp_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "SUGGEST",
                                        ["speechAct"] = "SUGGEST",
                                        ["subject"] = "WELLBEING",
                                    },
                                    ["id"] = "wellbeing.checkin.defer_rest",
                                    ["labelFallback"] = "Suggest resting first",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_WellbeingDefer_Label",
                                    ["utteranceFallback"] = "Let's get off the street and catch our breath before we sort supplies.",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_WellbeingDefer_Utterance",
                                },
                            },
                            ["onMatch"] = "resolve_checkin",
                            ["onRefuse"] = "declined_help",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.wellbeing.needs.checkin.assess",
                            ["slots"] = {
                                ["item"] = {
                                    ["owner"] = "inventory",
                                    ["source"] = "slots.item",
                                    ["type"] = "string",
                                },
                                ["location"] = {
                                    ["owner"] = "world",
                                    ["source"] = "slots.location",
                                    ["type"] = "string",
                                },
                            },
                        },
                        ["checkin_opening"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "NEEDS",
                                },
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["stateType"] = "WELLBEING",
                                },
                                {
                                    ["intent"] = "CLARIFY",
                                    ["speechAct"] = "CLARIFY",
                                    ["subject"] = "WELLBEING",
                                },
                                {
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                },
                            },
                            ["branchOffers"] = {
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "QUESTION",
                                        ["speechAct"] = "QUESTION",
                                        ["subject"] = "NEEDS",
                                    },
                                    ["id"] = "wellbeing.checkin.admit_need",
                                    ["labelFallback"] = "Ask what's running low",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_WellbeingAdmitNeed_Label",
                                    ["utteranceFallback"] = "Don't sugarcoat it—water, food, bandages, what are you short on?",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_WellbeingAdmitNeed_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["selfDirected"] = true,
                                        ["speechAct"] = "INFORM",
                                        ["stateType"] = "WELLBEING",
                                        ["stateValue"] = "positive",
                                    },
                                    ["id"] = "wellbeing.checkin.holding_steady",
                                    ["labelFallback"] = "Say you're holding up",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_WellbeingSteady_Label",
                                    ["utteranceFallback"] = "Still on my feet. Tired, sure, but I've got enough to get through tonight.",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_WellbeingSteady_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "CLARIFY",
                                        ["speechAct"] = "CLARIFY",
                                        ["subject"] = "WELLBEING",
                                    },
                                    ["id"] = "wellbeing.checkin.clarify_condition",
                                    ["labelFallback"] = "Check if injured",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_WellbeingClarify_Label",
                                    ["utteranceFallback"] = "You're favoring your side—is that a scrape, or are you just worn down?",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_WellbeingClarify_Utterance",
                                },
                            },
                            ["onClarify"] = "clarify_condition",
                            ["onMatch"] = "assess_need",
                            ["onRefuse"] = "declined_help",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.wellbeing.needs.checkin.opening",
                            ["slots"] = {
                                ["item"] = {
                                    ["owner"] = "inventory",
                                    ["source"] = "slots.item",
                                    ["type"] = "string",
                                },
                                ["person"] = {
                                    ["owner"] = "social",
                                    ["source"] = "slots.person",
                                    ["type"] = "string",
                                },
                            },
                        },
                        ["clarify_condition"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["subject"] = "NEEDS",
                                },
                                {
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                },
                            },
                            ["branchOffers"] = {
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["subject"] = "NEEDS",
                                    },
                                    ["id"] = "wellbeing.checkin.name_need",
                                    ["labelFallback"] = "Name what's needed",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_WellbeingNameNeed_Label",
                                    ["utteranceFallback"] = "Clean water and a strip of cloth would go a long way right now.",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_WellbeingNameNeed_Utterance",
                                },
                            },
                            ["onMatch"] = "assess_need",
                            ["onRefuse"] = "declined_help",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.wellbeing.needs.checkin.clarify",
                            ["slots"] = {
                                ["item"] = {
                                    ["owner"] = "inventory",
                                    ["source"] = "slots.item",
                                    ["type"] = "string",
                                },
                            },
                        },
                        ["complete"] = {
                            ["responsePool"] = "semantic.wellbeing.needs.checkin.complete",
                            ["terminal"] = true,
                        },
                        ["declined_help"] = {
                            ["responsePool"] = "semantic.wellbeing.needs.checkin.declined",
                            ["terminal"] = true,
                        },
                        ["resolve_checkin"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "ACCEPT",
                                    ["speechAct"] = "ACCEPT",
                                },
                                {
                                    ["intent"] = "AGREE",
                                    ["speechAct"] = "AGREE",
                                },
                                {
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                },
                            },
                            ["branchOffers"] = {
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "ACCEPT",
                                        ["speechAct"] = "ACCEPT",
                                    },
                                    ["id"] = "wellbeing.checkin.confirm_support",
                                    ["labelFallback"] = "Confirm check-in",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_WellbeingConfirm_Label",
                                    ["utteranceFallback"] = "Good. Sing out before things get worse—no sense toughing it out alone.",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_WellbeingConfirm_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "AGREE",
                                        ["speechAct"] = "AGREE",
                                    },
                                    ["id"] = "wellbeing.checkin.agree_steady",
                                    ["labelFallback"] = "Keep watching out",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_WellbeingAgree_Label",
                                    ["utteranceFallback"] = "Appreciate it. Stay hydrated and keep your head on a swivel.",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_WellbeingAgree_Utterance",
                                },
                            },
                            ["onMatch"] = "complete",
                            ["onRefuse"] = "declined_help",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.wellbeing.needs.checkin.resolve",
                        },
                    },
                    ["owner"] = "ProjectHoomans",
                    ["version"] = 1,
                },
                ["outcomes"] = {
                    "supported",
                    "deferred",
                    "declined",
                    "evasive",
                    "blocked",
                },
                ["stances"] = {
                    "positive",
                    "neutral",
                    "negative",
                    "contextual",
                },
                ["triggers"] = {
                    {
                        ["intent"] = "QUESTION",
                        ["subject"] = "WELLBEING",
                    },
                    {
                        ["intent"] = "QUESTION",
                        ["subject"] = "NEEDS",
                    },
                },
            },
            ["repeatPolicy"] = "repeatable",
            ["reply"] = {
                ["blocked"] = {
                    ["outcome"] = "blocked",
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
                                        ["fallback"] = "Can't do this right now—keep your eyes up.",
                                        ["id"] = "default",
                                    },
                                    {
                                        ["fallback"] = "Leave it. I've got bigger problems in front of me.",
                                        ["id"] = "negative",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["declined"] = {
                    ["outcome"] = "declined",
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
                                        ["fallback"] = "I'm fine. Worry about your own pack.",
                                        ["id"] = "default",
                                    },
                                    {
                                        ["fallback"] = "Don't fuss over me. I'll handle my own business.",
                                        ["id"] = "negative",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["deferred"] = {
                    ["outcome"] = "deferred",
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
                                        ["fallback"] = "Let's get somewhere with four walls first, then we'll sort out what's short.",
                                        ["id"] = "default",
                                    },
                                    {
                                        ["fallback"] = "Holding steady for now. Ask me again once we're off the open road.",
                                        ["id"] = "neutral",
                                    },
                                    {
                                        ["fallback"] = "I'll manage until dusk—just need a quiet roof and five minutes off my feet.",
                                        ["id"] = "contextual",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["evasive"] = {
                    ["outcome"] = "evasive",
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
                                        ["fallback"] = "Getting by well enough. No sense complaining about it.",
                                        ["id"] = "default",
                                    },
                                    {
                                        ["fallback"] = "Same as everybody else—tired, hungry, still kicking.",
                                        ["id"] = "neutral",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["supported"] = {
                    ["outcome"] = "supported",
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
                                        ["fallback"] = "Appreciate that. Knowing someone's got an eye out helps more than you'd think.",
                                        ["id"] = "default",
                                    },
                                    {
                                        ["fallback"] = "Thanks, {addressee.name}. A little help goes a long way out here.",
                                        ["id"] = "positive",
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
                                ["fallback"] = "You holding up all right? You look like you've had a rough stretch.",
                                ["id"] = "default",
                            },
                            {
                                ["fallback"] = "Glad to see you still on your feet. Need anything while we've got a quiet moment?",
                                ["id"] = "positive",
                            },
                            {
                                ["fallback"] = "Just checking in. Running low on clean water, food, or anything to patch up with?",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "You look half-spent. Don't tell me you're fine if you're running on empty.",
                                ["id"] = "negative",
                            },
                            {
                                ["fallback"] = "With the water pressure gone and the nights getting colder, how are you keeping up?",
                                ["id"] = "contextual",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["statePolicy"] = {
                {
                    ["admission"] = "no_op",
                    ["id"] = "blocked_unavailable_or_hostile",
                    ["outcome"] = "blocked",
                    ["reason"] = "hostile_busy_or_incapacitated",
                    ["replyOutcome"] = "blocked",
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
                            {
                                ["op"] = "in",
                                ["path"] = "npcState.healthState",
                                ["values"] = {
                                    "dead",
                                    "incapacitated",
                                },
                            },
                        },
                    },
                },
                {
                    ["admission"] = "dispatch",
                    ["id"] = "wellbeing_checkin_ready",
                    ["outcome"] = "actionable",
                    ["reason"] = "ready",
                },
            },
            ["topics"] = {
                {
                    ["domain"] = "wellbeing",
                    ["id"] = "wellbeing",
                },
                {
                    ["domain"] = "wellbeing",
                    ["id"] = "needs",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "wellbeing.needs.checkin",
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
                            ["fallback"] = "You holding up all right? You look like you've had a rough stretch.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.wellbeing.needs.checkin.say_1",
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
        ["sourceShard"] = "dialogue/thematic_interactive/wellbeing_needs_checkin.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "You holding up all right? You look like you've had a rough stretch.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.wellbeing.needs.checkin.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Glad to see you still on your feet. Need anything while we've got a quiet moment?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.wellbeing.needs.checkin.say.1.positive",
                ["variantID"] = "positive",
            },
            {
                ["fallback"] = "Just checking in. Running low on clean water, food, or anything to patch up with?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.wellbeing.needs.checkin.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "You look half-spent. Don't tell me you're fine if you're running on empty.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.wellbeing.needs.checkin.say.1.negative",
                ["variantID"] = "negative",
            },
            {
                ["fallback"] = "With the water pressure gone and the nights getting colder, how are you keeping up?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.wellbeing.needs.checkin.say.1.contextual",
                ["variantID"] = "contextual",
            },
            {
                ["fallback"] = "Can't do this right now—keep your eyes up.",
                ["outcome"] = "blocked",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.wellbeing.needs.checkin.reply.blocked.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Leave it. I've got bigger problems in front of me.",
                ["outcome"] = "blocked",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.wellbeing.needs.checkin.reply.blocked.say.1.negative",
                ["variantID"] = "negative",
            },
            {
                ["fallback"] = "I'm fine. Worry about your own pack.",
                ["outcome"] = "declined",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.wellbeing.needs.checkin.reply.declined.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Don't fuss over me. I'll handle my own business.",
                ["outcome"] = "declined",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.wellbeing.needs.checkin.reply.declined.say.1.negative",
                ["variantID"] = "negative",
            },
            {
                ["fallback"] = "Let's get somewhere with four walls first, then we'll sort out what's short.",
                ["outcome"] = "deferred",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.wellbeing.needs.checkin.reply.deferred.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Holding steady for now. Ask me again once we're off the open road.",
                ["outcome"] = "deferred",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.wellbeing.needs.checkin.reply.deferred.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I'll manage until dusk—just need a quiet roof and five minutes off my feet.",
                ["outcome"] = "deferred",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.wellbeing.needs.checkin.reply.deferred.say.1.contextual",
                ["variantID"] = "contextual",
            },
            {
                ["fallback"] = "Getting by well enough. No sense complaining about it.",
                ["outcome"] = "evasive",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.wellbeing.needs.checkin.reply.evasive.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Same as everybody else—tired, hungry, still kicking.",
                ["outcome"] = "evasive",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.wellbeing.needs.checkin.reply.evasive.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Appreciate that. Knowing someone's got an eye out helps more than you'd think.",
                ["outcome"] = "supported",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.wellbeing.needs.checkin.reply.supported.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Thanks, {addressee.name}. A little help goes a long way out here.",
                ["outcome"] = "supported",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.wellbeing.needs.checkin.reply.supported.say.1.positive",
                ["variantID"] = "positive",
            },
        },
        ["when"] = nil,
    },
}
