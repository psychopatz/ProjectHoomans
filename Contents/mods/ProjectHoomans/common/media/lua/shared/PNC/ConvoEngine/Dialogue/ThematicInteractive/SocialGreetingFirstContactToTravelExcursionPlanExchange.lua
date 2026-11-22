-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "thematic_interactive",
        ["domainPath"] = "thematic_interactive",
        ["exchangeFamily"] = {
            ["familyID"] = "social.greeting.first_contact",
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
                                ["fallback"] = "Hold up a second. You're still breathing—that's a good start.",
                                ["id"] = "default",
                                ["templateID"] = "convo.social.greeting.first_contact.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Thank goodness, a living face. Steady now, I'm not looking for a fight.",
                                ["id"] = "positive",
                                ["templateID"] = "convo.social.greeting.first_contact.say.1.positive",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Stop right there a moment. Just passing through this block?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.greeting.first_contact.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Stay back a step. I don't know you, and folks out here get jumpy fast.",
                                ["id"] = "negative",
                                ["templateID"] = "convo.social.greeting.first_contact.say.1.negative",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Quiet street to be walking alone. You scavenging these houses or looking for someone?",
                                ["id"] = "contextual",
                                ["templateID"] = "convo.social.greeting.first_contact.say.1.contextual",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.greeting",
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
                                        ["fallback"] = "Not now. Keep moving.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.greeting.first_contact.reply.blocked.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "Back off—this isn't the time to talk.",
                                        ["id"] = "negative",
                                        ["templateID"] = "convo.social.greeting.first_contact.reply.blocked.say.1.negative",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["cautious"] = {
                    ["outcome"] = "cautious",
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
                                        ["fallback"] = "Fair enough. You mind your business, I'll mind mine.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.greeting.first_contact.reply.cautious.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "All right. Keep your weapon low and we won't have a problem.",
                                        ["id"] = "neutral",
                                        ["templateID"] = "convo.social.greeting.first_contact.reply.cautious.say.1.neutral",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "Just keep your eyes on the treeline if you're heading down that road.",
                                        ["id"] = "contextual",
                                        ["templateID"] = "convo.social.greeting.first_contact.reply.cautious.say.1.contextual",
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
                                        ["fallback"] = "Suit yourself. Just keep walking.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.greeting.first_contact.reply.declined.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "Then we're done talking. Move along before you draw the dead.",
                                        ["id"] = "negative",
                                        ["templateID"] = "convo.social.greeting.first_contact.reply.declined.say.1.negative",
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
                                        ["fallback"] = "Keep your secrets if you want. Just don't bring trouble my way.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.greeting.first_contact.reply.evasive.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "Fine, no names needed. Stay safe out there.",
                                        ["id"] = "neutral",
                                        ["templateID"] = "convo.social.greeting.first_contact.reply.evasive.say.1.neutral",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["welcomed"] = {
                    ["outcome"] = "welcomed",
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
                                        ["fallback"] = "All right, you seem decent enough. Name's {speaker.name}—watch the side alleys out here.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.greeting.first_contact.reply.welcomed.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "Glad we didn't jump the gun—I'm {speaker.name}. Good to know there's still decent folks left.",
                                        ["id"] = "positive",
                                        ["templateID"] = "convo.social.greeting.first_contact.reply.welcomed.say.1.positive",
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
                    ["fallback"] = "Hold up a second. You're still breathing—that's a good start.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greeting.first_contact.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Thank goodness, a living face. Steady now, I'm not looking for a fight.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greeting.first_contact.say.1.positive",
                    ["variantID"] = "positive",
                },
                {
                    ["fallback"] = "Stop right there a moment. Just passing through this block?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greeting.first_contact.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Stay back a step. I don't know you, and folks out here get jumpy fast.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greeting.first_contact.say.1.negative",
                    ["variantID"] = "negative",
                },
                {
                    ["fallback"] = "Quiet street to be walking alone. You scavenging these houses or looking for someone?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greeting.first_contact.say.1.contextual",
                    ["variantID"] = "contextual",
                },
                {
                    ["fallback"] = "Not now. Keep moving.",
                    ["outcome"] = "blocked",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.greeting.first_contact.reply.blocked.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Back off—this isn't the time to talk.",
                    ["outcome"] = "blocked",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.greeting.first_contact.reply.blocked.say.1.negative",
                    ["variantID"] = "negative",
                },
                {
                    ["fallback"] = "Fair enough. You mind your business, I'll mind mine.",
                    ["outcome"] = "cautious",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.greeting.first_contact.reply.cautious.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "All right. Keep your weapon low and we won't have a problem.",
                    ["outcome"] = "cautious",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.greeting.first_contact.reply.cautious.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Just keep your eyes on the treeline if you're heading down that road.",
                    ["outcome"] = "cautious",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.greeting.first_contact.reply.cautious.say.1.contextual",
                    ["variantID"] = "contextual",
                },
                {
                    ["fallback"] = "Suit yourself. Just keep walking.",
                    ["outcome"] = "declined",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.greeting.first_contact.reply.declined.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Then we're done talking. Move along before you draw the dead.",
                    ["outcome"] = "declined",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.greeting.first_contact.reply.declined.say.1.negative",
                    ["variantID"] = "negative",
                },
                {
                    ["fallback"] = "Keep your secrets if you want. Just don't bring trouble my way.",
                    ["outcome"] = "evasive",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.greeting.first_contact.reply.evasive.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Fine, no names needed. Stay safe out there.",
                    ["outcome"] = "evasive",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.greeting.first_contact.reply.evasive.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "All right, you seem decent enough. Name's {speaker.name}—watch the side alleys out here.",
                    ["outcome"] = "welcomed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.greeting.first_contact.reply.welcomed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Glad we didn't jump the gun—I'm {speaker.name}. Good to know there's still decent folks left.",
                    ["outcome"] = "welcomed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.greeting.first_contact.reply.welcomed.say.1.positive",
                    ["variantID"] = "positive",
                },
            },
        },
        ["id"] = "social.greeting.first_contact",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "first_contact",
            ["sourceId"] = "social.greeting.first_contact",
            ["sourcePath"] = "dialogue/thematic_interactive/social_greeting_first_contact.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ThematicInteractive/SocialGreetingFirstContactToTravelExcursionPlanExchange",
        ["namespace"] = "social.greeting",
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
                ["category"] = "projecthoomans:thematic_interactive",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
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
                                ["path"] = "npcState.healthState",
                                ["values"] = {
                                    "dead",
                                    "incapacitated",
                                },
                            },
                        },
                    },
                    ["id"] = "social.greeting.first_contact",
                    ["initial"] = "first_contact_challenge",
                    ["nodes"] = {
                        ["clarify_intent"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["subject"] = "FIRST_CONTACT",
                                },
                                {
                                    ["intent"] = "GREET",
                                    ["speechAct"] = "GREET",
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
                                        ["subject"] = "FIRST_CONTACT",
                                    },
                                    ["id"] = "first_contact.state_road_business",
                                    ["labelFallback"] = "Say you're scavenging",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_FirstContactRoad_Label",
                                    ["utteranceFallback"] = "Just checking the houses down the road for supplies.",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_FirstContactRoad_Utterance",
                                },
                            },
                            ["onMatch"] = "name_and_intent",
                            ["onRefuse"] = "guarded_parting",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.social.greeting.first_contact.clarify",
                            ["slots"] = {
                                ["location"] = {
                                    ["owner"] = "world",
                                    ["source"] = "slots.location",
                                    ["type"] = "string",
                                },
                                ["person"] = {
                                    ["owner"] = "social",
                                    ["source"] = "slots.person",
                                    ["type"] = "string",
                                },
                            },
                        },
                        ["complete"] = {
                            ["responsePool"] = "semantic.social.greeting.first_contact.complete",
                            ["terminal"] = true,
                        },
                        ["first_contact_challenge"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "GREET",
                                    ["speechAct"] = "GREET",
                                },
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["subject"] = "FIRST_CONTACT",
                                },
                                {
                                    ["intent"] = "CLARIFY",
                                    ["speechAct"] = "CLARIFY",
                                    ["subject"] = "FIRST_CONTACT",
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
                                        ["intent"] = "GREET",
                                        ["speechAct"] = "GREET",
                                        ["stateValue"] = "positive",
                                    },
                                    ["id"] = "first_contact.friendly_greet",
                                    ["labelFallback"] = "Lower hands and greet",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_FirstContactFriendly_Label",
                                    ["utteranceFallback"] = "Easy—just passing through. Good to see someone still breathing.",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_FirstContactFriendly_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["stateValue"] = "neutral",
                                        ["subject"] = "FIRST_CONTACT",
                                    },
                                    ["id"] = "first_contact.cautious_greet",
                                    ["labelFallback"] = "Keep distance and answer",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_FirstContactCautious_Label",
                                    ["utteranceFallback"] = "Hands are clear. Not looking for trouble out here.",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_FirstContactCautious_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "CLARIFY",
                                        ["speechAct"] = "CLARIFY",
                                        ["subject"] = "FIRST_CONTACT",
                                    },
                                    ["id"] = "first_contact.clarify_intent",
                                    ["labelFallback"] = "Ask who's asking",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_FirstContactClarify_Label",
                                    ["utteranceFallback"] = "Depends—you alone out here, or watching this block for somebody?",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_FirstContactClarify_Utterance",
                                },
                            },
                            ["onClarify"] = "clarify_intent",
                            ["onMatch"] = "name_and_intent",
                            ["onRefuse"] = "guarded_parting",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.social.greeting.first_contact.opening",
                        },
                        ["guarded_parting"] = {
                            ["responsePool"] = "semantic.social.greeting.first_contact.guarded_parting",
                            ["terminal"] = true,
                        },
                        ["name_and_intent"] = {
                            ["accepts"] = {
                                {
                                    ["identityClaim"] = true,
                                    ["intent"] = "INFORM",
                                    ["subject"] = "IDENTITY",
                                },
                                {
                                    ["intent"] = "THANK",
                                    ["speechAct"] = "THANK",
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
                                        ["identityClaim"] = true,
                                        ["intent"] = "INFORM",
                                        ["subject"] = "IDENTITY",
                                    },
                                    ["id"] = "first_contact.share_name",
                                    ["labelFallback"] = "Trade names",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_FirstContactShareName_Label",
                                    ["utteranceFallback"] = "Fair enough. You can call me by my name—what's yours?",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_FirstContactShareName_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "THANK",
                                        ["speechAct"] = "THANK",
                                    },
                                    ["id"] = "first_contact.keep_brief",
                                    ["labelFallback"] = "Keep it brief",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_FirstContactBrief_Label",
                                    ["utteranceFallback"] = "No need for names yet. Just glad neither of us shot first.",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_FirstContactBrief_Utterance",
                                },
                            },
                            ["onMatch"] = "settle_standing",
                            ["onRefuse"] = "guarded_parting",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.social.greeting.first_contact.exchange",
                            ["slots"] = {
                                ["location"] = {
                                    ["owner"] = "world",
                                    ["source"] = "slots.location",
                                    ["type"] = "string",
                                },
                                ["person"] = {
                                    ["owner"] = "social",
                                    ["source"] = "slots.identityClaim.name",
                                    ["type"] = "string",
                                },
                            },
                        },
                        ["settle_standing"] = {
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
                                        ["stateValue"] = "positive",
                                    },
                                    ["id"] = "first_contact.part_friendly",
                                    ["labelFallback"] = "Wish them luck",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_FirstContactWarmClose_Label",
                                    ["utteranceFallback"] = "Watch the side streets. Hope our paths cross again when it's quieter.",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_FirstContactWarmClose_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "AGREE",
                                        ["speechAct"] = "AGREE",
                                        ["stateValue"] = "neutral",
                                    },
                                    ["id"] = "first_contact.part_cautious",
                                    ["labelFallback"] = "Nod and move on",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_FirstContactCautiousClose_Label",
                                    ["utteranceFallback"] = "All right. You watch your end of the street, I'll watch mine.",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_FirstContactCautiousClose_Utterance",
                                },
                            },
                            ["onMatch"] = "complete",
                            ["onRefuse"] = "guarded_parting",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.social.greeting.first_contact.standing",
                        },
                    },
                    ["owner"] = "ProjectHoomans",
                    ["version"] = 1,
                },
                ["outcomes"] = {
                    "welcomed",
                    "cautious",
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
                        ["intent"] = "GREET",
                        ["speechAct"] = "GREET",
                    },
                    {
                        ["intent"] = "GREET",
                        ["subject"] = "FIRST_CONTACT",
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
                                        ["fallback"] = "Not now. Keep moving.",
                                        ["id"] = "default",
                                    },
                                    {
                                        ["fallback"] = "Back off—this isn't the time to talk.",
                                        ["id"] = "negative",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["cautious"] = {
                    ["outcome"] = "cautious",
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
                                        ["fallback"] = "Fair enough. You mind your business, I'll mind mine.",
                                        ["id"] = "default",
                                    },
                                    {
                                        ["fallback"] = "All right. Keep your weapon low and we won't have a problem.",
                                        ["id"] = "neutral",
                                    },
                                    {
                                        ["fallback"] = "Just keep your eyes on the treeline if you're heading down that road.",
                                        ["id"] = "contextual",
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
                                        ["fallback"] = "Suit yourself. Just keep walking.",
                                        ["id"] = "default",
                                    },
                                    {
                                        ["fallback"] = "Then we're done talking. Move along before you draw the dead.",
                                        ["id"] = "negative",
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
                                        ["fallback"] = "Keep your secrets if you want. Just don't bring trouble my way.",
                                        ["id"] = "default",
                                    },
                                    {
                                        ["fallback"] = "Fine, no names needed. Stay safe out there.",
                                        ["id"] = "neutral",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["welcomed"] = {
                    ["outcome"] = "welcomed",
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
                                        ["fallback"] = "All right, you seem decent enough. Name's {speaker.name}—watch the side alleys out here.",
                                        ["id"] = "default",
                                    },
                                    {
                                        ["fallback"] = "Glad we didn't jump the gun—I'm {speaker.name}. Good to know there's still decent folks left.",
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
                                ["fallback"] = "Hold up a second. You're still breathing—that's a good start.",
                                ["id"] = "default",
                            },
                            {
                                ["fallback"] = "Thank goodness, a living face. Steady now, I'm not looking for a fight.",
                                ["id"] = "positive",
                            },
                            {
                                ["fallback"] = "Stop right there a moment. Just passing through this block?",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Stay back a step. I don't know you, and folks out here get jumpy fast.",
                                ["id"] = "negative",
                            },
                            {
                                ["fallback"] = "Quiet street to be walking alone. You scavenging these houses or looking for someone?",
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
                    ["id"] = "first_contact_ready",
                    ["outcome"] = "actionable",
                    ["reason"] = "ready",
                },
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "greeting",
                },
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
            ["responsePlanID"] = "social.greeting.first_contact",
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
                            ["fallback"] = "Hold up a second. You're still breathing—that's a good start.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.greeting.first_contact.say_1",
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
        ["sourceShard"] = "dialogue/thematic_interactive/social_greeting_first_contact.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Hold up a second. You're still breathing—that's a good start.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.greeting.first_contact.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Thank goodness, a living face. Steady now, I'm not looking for a fight.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.greeting.first_contact.say.1.positive",
                ["variantID"] = "positive",
            },
            {
                ["fallback"] = "Stop right there a moment. Just passing through this block?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.greeting.first_contact.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Stay back a step. I don't know you, and folks out here get jumpy fast.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.greeting.first_contact.say.1.negative",
                ["variantID"] = "negative",
            },
            {
                ["fallback"] = "Quiet street to be walking alone. You scavenging these houses or looking for someone?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.greeting.first_contact.say.1.contextual",
                ["variantID"] = "contextual",
            },
            {
                ["fallback"] = "Not now. Keep moving.",
                ["outcome"] = "blocked",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.greeting.first_contact.reply.blocked.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Back off—this isn't the time to talk.",
                ["outcome"] = "blocked",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.greeting.first_contact.reply.blocked.say.1.negative",
                ["variantID"] = "negative",
            },
            {
                ["fallback"] = "Fair enough. You mind your business, I'll mind mine.",
                ["outcome"] = "cautious",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.greeting.first_contact.reply.cautious.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "All right. Keep your weapon low and we won't have a problem.",
                ["outcome"] = "cautious",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.greeting.first_contact.reply.cautious.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Just keep your eyes on the treeline if you're heading down that road.",
                ["outcome"] = "cautious",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.greeting.first_contact.reply.cautious.say.1.contextual",
                ["variantID"] = "contextual",
            },
            {
                ["fallback"] = "Suit yourself. Just keep walking.",
                ["outcome"] = "declined",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.greeting.first_contact.reply.declined.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Then we're done talking. Move along before you draw the dead.",
                ["outcome"] = "declined",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.greeting.first_contact.reply.declined.say.1.negative",
                ["variantID"] = "negative",
            },
            {
                ["fallback"] = "Keep your secrets if you want. Just don't bring trouble my way.",
                ["outcome"] = "evasive",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.greeting.first_contact.reply.evasive.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Fine, no names needed. Stay safe out there.",
                ["outcome"] = "evasive",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.greeting.first_contact.reply.evasive.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "All right, you seem decent enough. Name's {speaker.name}—watch the side alleys out here.",
                ["outcome"] = "welcomed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.greeting.first_contact.reply.welcomed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Glad we didn't jump the gun—I'm {speaker.name}. Good to know there's still decent folks left.",
                ["outcome"] = "welcomed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.greeting.first_contact.reply.welcomed.say.1.positive",
                ["variantID"] = "positive",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "thematic_interactive",
        ["domainPath"] = "thematic_interactive",
        ["exchangeFamily"] = {
            ["familyID"] = "social.identity.personal_history",
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
                                ["fallback"] = "Hard to picture what this county looked like before July. Where were you when things fell apart?",
                                ["id"] = "default",
                                ["templateID"] = "convo.social.identity.personal_history.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Feels good talking to someone who remembers normal life, {addressee.name}. What did you used to do around here?",
                                ["id"] = "positive",
                                ["templateID"] = "convo.social.identity.personal_history.say.1.positive",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Where were you at when the roadblocks went up?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.identity.personal_history.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Folks out here don't talk much about who they used to be. Doesn't always end well.",
                                ["id"] = "negative",
                                ["templateID"] = "convo.social.identity.personal_history.say.1.negative",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Seeing these empty storefronts still throws me off. Did you have family or work out this way?",
                                ["id"] = "contextual",
                                ["templateID"] = "convo.social.identity.personal_history.say.1.contextual",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.identity",
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
                                        ["fallback"] = "Not the time for life stories.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.identity.personal_history.reply.blocked.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "Save it. Keep your eyes on the street.",
                                        ["id"] = "negative",
                                        ["templateID"] = "convo.social.identity.personal_history.reply.blocked.say.1.negative",
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
                                        ["fallback"] = "Doesn't matter much what I did before. Only matters what keeps us alive today.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.identity.personal_history.reply.evasive.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "Long story, and none of it puts food in a pack.",
                                        ["id"] = "neutral",
                                        ["templateID"] = "convo.social.identity.personal_history.reply.evasive.say.1.neutral",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["guarded"] = {
                    ["outcome"] = "guarded",
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
                                        ["fallback"] = "Let's just say I worked with my hands and leave the rest behind.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.identity.personal_history.reply.guarded.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "I lived quiet before, and I'd rather keep it that way now.",
                                        ["id"] = "neutral",
                                        ["templateID"] = "convo.social.identity.personal_history.reply.guarded.say.1.neutral",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "Too many names I don't want to say out loud anymore. Maybe another night.",
                                        ["id"] = "contextual",
                                        ["templateID"] = "convo.social.identity.personal_history.reply.guarded.say.1.contextual",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["refused"] = {
                    ["outcome"] = "refused",
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
                                        ["fallback"] = "I'd rather not dig into all that.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.identity.personal_history.reply.refused.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "Drop it. My past is my own business.",
                                        ["id"] = "negative",
                                        ["templateID"] = "convo.social.identity.personal_history.reply.refused.say.1.negative",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["shared"] = {
                    ["outcome"] = "shared",
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
                                        ["fallback"] = "Funny how fast a regular job turns into useless trivia, huh, {addressee.name}? Good knowing a bit about you.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.identity.personal_history.reply.shared.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "Feels good remembering we had real lives once, {addressee.name}. Appreciate you sharing that.",
                                        ["id"] = "positive",
                                        ["templateID"] = "convo.social.identity.personal_history.reply.shared.say.1.positive",
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
                    ["fallback"] = "Hard to picture what this county looked like before July. Where were you when things fell apart?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.identity.personal_history.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Feels good talking to someone who remembers normal life, {addressee.name}. What did you used to do around here?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.identity.personal_history.say.1.positive",
                    ["variantID"] = "positive",
                },
                {
                    ["fallback"] = "Where were you at when the roadblocks went up?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.identity.personal_history.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Folks out here don't talk much about who they used to be. Doesn't always end well.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.identity.personal_history.say.1.negative",
                    ["variantID"] = "negative",
                },
                {
                    ["fallback"] = "Seeing these empty storefronts still throws me off. Did you have family or work out this way?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.identity.personal_history.say.1.contextual",
                    ["variantID"] = "contextual",
                },
                {
                    ["fallback"] = "Not the time for life stories.",
                    ["outcome"] = "blocked",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.identity.personal_history.reply.blocked.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Save it. Keep your eyes on the street.",
                    ["outcome"] = "blocked",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.identity.personal_history.reply.blocked.say.1.negative",
                    ["variantID"] = "negative",
                },
                {
                    ["fallback"] = "Doesn't matter much what I did before. Only matters what keeps us alive today.",
                    ["outcome"] = "evasive",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.identity.personal_history.reply.evasive.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Long story, and none of it puts food in a pack.",
                    ["outcome"] = "evasive",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.identity.personal_history.reply.evasive.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Let's just say I worked with my hands and leave the rest behind.",
                    ["outcome"] = "guarded",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.identity.personal_history.reply.guarded.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I lived quiet before, and I'd rather keep it that way now.",
                    ["outcome"] = "guarded",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.identity.personal_history.reply.guarded.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Too many names I don't want to say out loud anymore. Maybe another night.",
                    ["outcome"] = "guarded",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.identity.personal_history.reply.guarded.say.1.contextual",
                    ["variantID"] = "contextual",
                },
                {
                    ["fallback"] = "I'd rather not dig into all that.",
                    ["outcome"] = "refused",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.identity.personal_history.reply.refused.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Drop it. My past is my own business.",
                    ["outcome"] = "refused",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.identity.personal_history.reply.refused.say.1.negative",
                    ["variantID"] = "negative",
                },
                {
                    ["fallback"] = "Funny how fast a regular job turns into useless trivia, huh, {addressee.name}? Good knowing a bit about you.",
                    ["outcome"] = "shared",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.identity.personal_history.reply.shared.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Feels good remembering we had real lives once, {addressee.name}. Appreciate you sharing that.",
                    ["outcome"] = "shared",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.identity.personal_history.reply.shared.say.1.positive",
                    ["variantID"] = "positive",
                },
            },
        },
        ["id"] = "social.identity.personal_history",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "personal_history",
            ["sourceId"] = "social.identity.personal_history",
            ["sourcePath"] = "dialogue/thematic_interactive/identity_history_exchange.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ThematicInteractive/SocialGreetingFirstContactToTravelExcursionPlanExchange",
        ["namespace"] = "social.identity",
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
                ["category"] = "projecthoomans:thematic_interactive",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
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
                    ["id"] = "social.identity.personal_history",
                    ["initial"] = "ask_background",
                    ["nodes"] = {
                        ["ask_background"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["subject"] = "BACKSTORY",
                                },
                                {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "BACKSTORY",
                                },
                                {
                                    ["intent"] = "CLARIFY",
                                    ["speechAct"] = "CLARIFY",
                                    ["subject"] = "BACKSTORY",
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
                                        ["subject"] = "BACKSTORY",
                                    },
                                    ["id"] = "identity.history.share_roots",
                                    ["labelFallback"] = "Share where you're from",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_HistoryShareRoots_Label",
                                    ["utteranceFallback"] = "I was working over in Muldraugh when the phones went dead. What about you?",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_HistoryShareRoots_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "QUESTION",
                                        ["speechAct"] = "QUESTION",
                                        ["subject"] = "BACKSTORY",
                                    },
                                    ["id"] = "identity.history.ask_trade",
                                    ["labelFallback"] = "Ask what they did before",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_HistoryAskTrade_Label",
                                    ["utteranceFallback"] = "What did you do before Knox County went to hell?",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_HistoryAskTrade_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "CLARIFY",
                                        ["speechAct"] = "CLARIFY",
                                        ["subject"] = "BACKSTORY",
                                    },
                                    ["id"] = "identity.history.clarify_origin",
                                    ["labelFallback"] = "Ask which town they came from",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_HistoryClarify_Label",
                                    ["utteranceFallback"] = "Did you come up from Rosewood, or further east?",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_HistoryClarify_Utterance",
                                },
                            },
                            ["onClarify"] = "clarify_origin",
                            ["onMatch"] = "share_history",
                            ["onRefuse"] = "kept_private",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.social.identity.personal_history.opening",
                            ["slots"] = {
                                ["location"] = {
                                    ["owner"] = "world",
                                    ["source"] = "slots.location",
                                    ["type"] = "string",
                                },
                                ["person"] = {
                                    ["owner"] = "social",
                                    ["source"] = "slots.person",
                                    ["type"] = "string",
                                },
                            },
                        },
                        ["clarify_origin"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["subject"] = "BACKSTORY",
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
                                        ["subject"] = "BACKSTORY",
                                    },
                                    ["id"] = "identity.history.confirm_town",
                                    ["labelFallback"] = "Mention the highway",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_HistoryConfirmTown_Label",
                                    ["utteranceFallback"] = "Got out right before they blocked the main highway.",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_HistoryConfirmTown_Utterance",
                                },
                            },
                            ["onMatch"] = "share_history",
                            ["onRefuse"] = "kept_private",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.social.identity.personal_history.clarify",
                            ["slots"] = {
                                ["event"] = {
                                    ["owner"] = "world",
                                    ["source"] = "slots.event",
                                    ["type"] = "string",
                                },
                                ["location"] = {
                                    ["owner"] = "world",
                                    ["source"] = "slots.location",
                                    ["type"] = "string",
                                },
                            },
                        },
                        ["complete"] = {
                            ["responsePool"] = "semantic.social.identity.personal_history.complete",
                            ["terminal"] = true,
                        },
                        ["kept_private"] = {
                            ["responsePool"] = "semantic.social.identity.personal_history.kept_private",
                            ["terminal"] = true,
                        },
                        ["reflect_bond"] = {
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
                                    ["id"] = "identity.history.close_warm",
                                    ["labelFallback"] = "Respect their story",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_HistoryCloseWarm_Label",
                                    ["utteranceFallback"] = "Good to know who I'm standing beside out here.",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_HistoryCloseWarm_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "AGREE",
                                        ["speechAct"] = "AGREE",
                                    },
                                    ["id"] = "identity.history.close_quiet",
                                    ["labelFallback"] = "Leave it there",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_HistoryCloseQuiet_Label",
                                    ["utteranceFallback"] = "Fair enough. Past is past—we've got today to worry about.",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_HistoryCloseQuiet_Utterance",
                                },
                            },
                            ["onMatch"] = "complete",
                            ["onRefuse"] = "kept_private",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.social.identity.personal_history.reflect",
                        },
                        ["share_history"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "IDENTITY",
                                },
                                {
                                    ["intent"] = "THANK",
                                    ["speechAct"] = "THANK",
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
                                        ["subject"] = "IDENTITY",
                                    },
                                    ["id"] = "identity.history.connect_family",
                                    ["labelFallback"] = "Ask if anyone made it out",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_HistoryFamily_Label",
                                    ["utteranceFallback"] = "You still looking for anyone from back then?",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_HistoryFamily_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "THANK",
                                        ["speechAct"] = "THANK",
                                    },
                                    ["id"] = "identity.history.acknowledge_past",
                                    ["labelFallback"] = "Acknowledge the memory",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_HistoryAck_Label",
                                    ["utteranceFallback"] = "Feels like a lifetime ago already. Glad you made it this far.",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_HistoryAck_Utterance",
                                },
                            },
                            ["onMatch"] = "reflect_bond",
                            ["onRefuse"] = "kept_private",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.social.identity.personal_history.exchange",
                            ["slots"] = {
                                ["event"] = {
                                    ["owner"] = "world",
                                    ["source"] = "slots.event",
                                    ["type"] = "string",
                                },
                                ["faction"] = {
                                    ["owner"] = "social",
                                    ["source"] = "slots.faction",
                                    ["type"] = "string",
                                },
                                ["person"] = {
                                    ["owner"] = "social",
                                    ["source"] = "slots.person",
                                    ["type"] = "string",
                                },
                            },
                        },
                    },
                    ["owner"] = "ProjectHoomans",
                    ["version"] = 1,
                },
                ["outcomes"] = {
                    "shared",
                    "guarded",
                    "evasive",
                    "refused",
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
                        ["subject"] = "BACKSTORY",
                    },
                    {
                        ["intent"] = "QUESTION",
                        ["subject"] = "IDENTITY",
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
                                        ["fallback"] = "Not the time for life stories.",
                                        ["id"] = "default",
                                    },
                                    {
                                        ["fallback"] = "Save it. Keep your eyes on the street.",
                                        ["id"] = "negative",
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
                                        ["fallback"] = "Doesn't matter much what I did before. Only matters what keeps us alive today.",
                                        ["id"] = "default",
                                    },
                                    {
                                        ["fallback"] = "Long story, and none of it puts food in a pack.",
                                        ["id"] = "neutral",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["guarded"] = {
                    ["outcome"] = "guarded",
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
                                        ["fallback"] = "Let's just say I worked with my hands and leave the rest behind.",
                                        ["id"] = "default",
                                    },
                                    {
                                        ["fallback"] = "I lived quiet before, and I'd rather keep it that way now.",
                                        ["id"] = "neutral",
                                    },
                                    {
                                        ["fallback"] = "Too many names I don't want to say out loud anymore. Maybe another night.",
                                        ["id"] = "contextual",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["refused"] = {
                    ["outcome"] = "refused",
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
                                        ["fallback"] = "I'd rather not dig into all that.",
                                        ["id"] = "default",
                                    },
                                    {
                                        ["fallback"] = "Drop it. My past is my own business.",
                                        ["id"] = "negative",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["shared"] = {
                    ["outcome"] = "shared",
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
                                        ["fallback"] = "Funny how fast a regular job turns into useless trivia, huh, {addressee.name}? Good knowing a bit about you.",
                                        ["id"] = "default",
                                    },
                                    {
                                        ["fallback"] = "Feels good remembering we had real lives once, {addressee.name}. Appreciate you sharing that.",
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
                                ["fallback"] = "Hard to picture what this county looked like before July. Where were you when things fell apart?",
                                ["id"] = "default",
                            },
                            {
                                ["fallback"] = "Feels good talking to someone who remembers normal life, {addressee.name}. What did you used to do around here?",
                                ["id"] = "positive",
                            },
                            {
                                ["fallback"] = "Where were you at when the roadblocks went up?",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Folks out here don't talk much about who they used to be. Doesn't always end well.",
                                ["id"] = "negative",
                            },
                            {
                                ["fallback"] = "Seeing these empty storefronts still throws me off. Did you have family or work out this way?",
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
                    ["id"] = "personal_history_ready",
                    ["outcome"] = "actionable",
                    ["reason"] = "ready",
                },
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "social_interaction",
                },
                {
                    ["domain"] = "social",
                    ["id"] = "identity",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.identity.personal_history",
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
                            ["fallback"] = "Hard to picture what this county looked like before July. Where were you when things fell apart?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.identity.personal_history.say_1",
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
        ["sourceShard"] = "dialogue/thematic_interactive/identity_history_exchange.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Hard to picture what this county looked like before July. Where were you when things fell apart?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.identity.personal_history.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Feels good talking to someone who remembers normal life, {addressee.name}. What did you used to do around here?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.identity.personal_history.say.1.positive",
                ["variantID"] = "positive",
            },
            {
                ["fallback"] = "Where were you at when the roadblocks went up?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.identity.personal_history.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Folks out here don't talk much about who they used to be. Doesn't always end well.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.identity.personal_history.say.1.negative",
                ["variantID"] = "negative",
            },
            {
                ["fallback"] = "Seeing these empty storefronts still throws me off. Did you have family or work out this way?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.identity.personal_history.say.1.contextual",
                ["variantID"] = "contextual",
            },
            {
                ["fallback"] = "Not the time for life stories.",
                ["outcome"] = "blocked",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.identity.personal_history.reply.blocked.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Save it. Keep your eyes on the street.",
                ["outcome"] = "blocked",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.identity.personal_history.reply.blocked.say.1.negative",
                ["variantID"] = "negative",
            },
            {
                ["fallback"] = "Doesn't matter much what I did before. Only matters what keeps us alive today.",
                ["outcome"] = "evasive",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.identity.personal_history.reply.evasive.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Long story, and none of it puts food in a pack.",
                ["outcome"] = "evasive",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.identity.personal_history.reply.evasive.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Let's just say I worked with my hands and leave the rest behind.",
                ["outcome"] = "guarded",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.identity.personal_history.reply.guarded.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I lived quiet before, and I'd rather keep it that way now.",
                ["outcome"] = "guarded",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.identity.personal_history.reply.guarded.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Too many names I don't want to say out loud anymore. Maybe another night.",
                ["outcome"] = "guarded",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.identity.personal_history.reply.guarded.say.1.contextual",
                ["variantID"] = "contextual",
            },
            {
                ["fallback"] = "I'd rather not dig into all that.",
                ["outcome"] = "refused",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.identity.personal_history.reply.refused.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Drop it. My past is my own business.",
                ["outcome"] = "refused",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.identity.personal_history.reply.refused.say.1.negative",
                ["variantID"] = "negative",
            },
            {
                ["fallback"] = "Funny how fast a regular job turns into useless trivia, huh, {addressee.name}? Good knowing a bit about you.",
                ["outcome"] = "shared",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.identity.personal_history.reply.shared.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Feels good remembering we had real lives once, {addressee.name}. Appreciate you sharing that.",
                ["outcome"] = "shared",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.identity.personal_history.reply.shared.say.1.positive",
                ["variantID"] = "positive",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "thematic_interactive",
        ["domainPath"] = "thematic_interactive",
        ["exchangeFamily"] = {
            ["familyID"] = "travel.excursion.plan_exchange",
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
                                ["fallback"] = "We're running low on canned goods and spare batteries, {addressee.name}. Think we can make a quick run {scene.location}?",
                                ["id"] = "default",
                                ["templateID"] = "convo.travel.excursion.plan_exchange.say.1.default",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "travel.excursion",
            ["replies"] = {
                ["agreed"] = {
                    ["outcome"] = "agreed",
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
                                        ["fallback"] = "Alright, {addressee.name}. Pack light, keep the crowbar handy, and we stick to the side streets.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.travel.excursion.plan_exchange.reply.agreed.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["assessed"] = {
                    ["outcome"] = "assessed",
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
                                        ["fallback"] = "Roads looked quiet earlier {scene.location}, {addressee.name}, though there's always a few stragglers near the gas station.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.travel.excursion.plan_exchange.reply.assessed.say.1.default",
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
                                        ["fallback"] = "Better to wait for first light. Fog's too thick out by the highway right now.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.travel.excursion.plan_exchange.reply.deferred.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["refused"] = {
                    ["outcome"] = "refused",
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
                                        ["fallback"] = "No sense going out there right now. Stay put until it's safe.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.travel.excursion.plan_exchange.reply.refused.say.1.default",
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
                    ["fallback"] = "We're running low on canned goods and spare batteries, {addressee.name}. Think we can make a quick run {scene.location}?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.travel.excursion.plan_exchange.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Alright, {addressee.name}. Pack light, keep the crowbar handy, and we stick to the side streets.",
                    ["outcome"] = "agreed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.travel.excursion.plan_exchange.reply.agreed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Roads looked quiet earlier {scene.location}, {addressee.name}, though there's always a few stragglers near the gas station.",
                    ["outcome"] = "assessed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.travel.excursion.plan_exchange.reply.assessed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Better to wait for first light. Fog's too thick out by the highway right now.",
                    ["outcome"] = "deferred",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.travel.excursion.plan_exchange.reply.deferred.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "No sense going out there right now. Stay put until it's safe.",
                    ["outcome"] = "refused",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.travel.excursion.plan_exchange.reply.refused.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "travel.excursion.plan_exchange",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "plan_exchange",
            ["sourceId"] = "travel.excursion.plan_exchange",
            ["sourcePath"] = "dialogue/thematic_interactive/travel_excursion_exchange.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ThematicInteractive/SocialGreetingFirstContactToTravelExcursionPlanExchange",
        ["namespace"] = "travel.excursion",
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
                ["closureClass"] = "resolved_episode",
                ["episodeId"] = "travel_excursion_plan_exchange",
            },
            ["domains"] = {
                {
                    ["domain"] = "travel",
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
                                ["op"] = "not_in",
                                ["path"] = "npcState.healthState",
                                ["values"] = {
                                    "dead",
                                    "incapacitated",
                                },
                            },
                        },
                    },
                    ["id"] = "travel.excursion.plan_exchange",
                    ["initial"] = "propose_route",
                    ["nodes"] = {
                        ["assess_risk"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "AGREE",
                                    ["speechAct"] = "AGREE",
                                    ["subject"] = "EXCURSION",
                                },
                                {
                                    ["intent"] = "ACCEPT",
                                },
                                {
                                    ["intent"] = "DEFER",
                                    ["speechAct"] = "DEFER",
                                    ["subject"] = "EXCURSION",
                                },
                            },
                            ["branchOffers"] = {
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "AGREE",
                                        ["speechAct"] = "AGREE",
                                        ["subject"] = "EXCURSION",
                                    },
                                    ["id"] = "travel.excursion.confirm_departure",
                                    ["labelFallback"] = "Head out together",
                                    ["labelKey"] = "UI_PNC_TravelExcursion_Confirm_Label",
                                    ["utteranceFallback"] = "Grab a crowbar and a spare canteen. We stick to the tree line.",
                                    ["utteranceKey"] = "UI_PNC_TravelExcursion_Confirm_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "DEFER",
                                        ["speechAct"] = "DEFER",
                                        ["subject"] = "EXCURSION",
                                    },
                                    ["id"] = "travel.excursion.postpone",
                                    ["labelFallback"] = "Wait for better light",
                                    ["labelKey"] = "UI_PNC_TravelExcursion_Postpone_Label",
                                    ["utteranceFallback"] = "Let's sleep on it and check the fog at first light.",
                                    ["utteranceKey"] = "UI_PNC_TravelExcursion_Postpone_Utterance",
                                },
                            },
                            ["onMatch"] = "departing",
                            ["onRefuse"] = "called_off",
                            ["onUnrelated"] = "suspend",
                            ["slots"] = {
                                ["threat"] = {
                                    ["owner"] = "travel.excursion.plan_exchange",
                                    ["source"] = "slots.threat.value",
                                    ["type"] = "string",
                                },
                            },
                        },
                        ["called_off"] = {
                            ["terminal"] = true,
                        },
                        ["departing"] = {
                            ["terminal"] = true,
                        },
                        ["propose_route"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["subject"] = "ROUTE",
                                },
                                {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "THREAT",
                                },
                                {
                                    ["intent"] = "AGREE",
                                    ["speechAct"] = "AGREE",
                                    ["subject"] = "EXCURSION",
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
                                        ["subject"] = "ROUTE",
                                    },
                                    ["id"] = "travel.excursion.set_destination",
                                    ["labelFallback"] = "Suggest a supply stop",
                                    ["labelKey"] = "UI_PNC_TravelExcursion_SetDest_Label",
                                    ["utteranceFallback"] = "If we hit the corner market before noon, we can be back before supper.",
                                    ["utteranceKey"] = "UI_PNC_TravelExcursion_SetDest_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "QUESTION",
                                        ["speechAct"] = "QUESTION",
                                        ["subject"] = "THREAT",
                                    },
                                    ["id"] = "travel.excursion.ask_threat",
                                    ["labelFallback"] = "Ask about the road ahead",
                                    ["labelKey"] = "UI_PNC_TravelExcursion_AskThreat_Label",
                                    ["utteranceFallback"] = "You hear anything about deadheads piling up on the highway?",
                                    ["utteranceKey"] = "UI_PNC_TravelExcursion_AskThreat_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "REFUSE",
                                        ["speechAct"] = "REFUSE",
                                        ["subject"] = "EXCURSION",
                                    },
                                    ["id"] = "travel.excursion.call_off",
                                    ["labelFallback"] = "Call off the run",
                                    ["labelKey"] = "UI_PNC_TravelExcursion_CallOff_Label",
                                    ["utteranceFallback"] = "Doesn't feel worth the gas or the noise today.",
                                    ["utteranceKey"] = "UI_PNC_TravelExcursion_CallOff_Utterance",
                                },
                            },
                            ["onClarify"] = "assess_risk",
                            ["onMatch"] = "assess_risk",
                            ["onRefuse"] = "called_off",
                            ["onUnrelated"] = "suspend",
                            ["slots"] = {
                                ["location"] = {
                                    ["owner"] = "travel.excursion.plan_exchange",
                                    ["source"] = "slots.location.value",
                                    ["type"] = "string",
                                },
                                ["threat"] = {
                                    ["owner"] = "travel.excursion.plan_exchange",
                                    ["source"] = "slots.threat.value",
                                    ["type"] = "string",
                                },
                            },
                        },
                    },
                    ["owner"] = "ProjectHoomans",
                    ["version"] = 1,
                },
                ["replySemantics"] = {
                    ["agreed"] = {
                        ["outcome"] = "agreed",
                        ["stance"] = "positive",
                    },
                    ["assessed"] = {
                        ["outcome"] = "assessed",
                        ["stance"] = "neutral",
                    },
                    ["deferred"] = {
                        ["outcome"] = "deferred",
                        ["stance"] = "contextual",
                    },
                    ["refused"] = {
                        ["outcome"] = "refused",
                        ["stance"] = "negative",
                    },
                },
                ["triggers"] = {
                    {
                        ["intent"] = "SUGGEST",
                        ["subject"] = "EXCURSION",
                    },
                    {
                        ["intent"] = "QUESTION",
                        ["subject"] = "ROUTE",
                    },
                },
            },
            ["repeatPolicy"] = "repeatable",
            ["reply"] = {
                ["agreed"] = {
                    ["outcome"] = "agreed",
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
                                        ["fallback"] = "Alright, {addressee.name}. Pack light, keep the crowbar handy, and we stick to the side streets.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["assessed"] = {
                    ["outcome"] = "assessed",
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
                                        ["fallback"] = "Roads looked quiet earlier {scene.location}, {addressee.name}, though there's always a few stragglers near the gas station.",
                                        ["id"] = "default",
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
                                        ["fallback"] = "Better to wait for first light. Fog's too thick out by the highway right now.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["refused"] = {
                    ["outcome"] = "refused",
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
                                        ["fallback"] = "No sense going out there right now. Stay put until it's safe.",
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
                                ["fallback"] = "We're running low on canned goods and spare batteries, {addressee.name}. Think we can make a quick run {scene.location}?",
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
                    ["id"] = "blocked_unsafe_or_hostile",
                    ["outcome"] = "blocked",
                    ["reason"] = "hostile_combat_or_incapacitated",
                    ["replyOutcome"] = "refused",
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
                                ["op"] = "in",
                                ["path"] = "npcState.healthState",
                                ["values"] = {
                                    "dead",
                                    "incapacitated",
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
                    ["id"] = "travel_excursion_ready",
                    ["outcome"] = "actionable",
                    ["reason"] = "ready",
                },
            },
            ["topics"] = {
                {
                    ["domain"] = "travel",
                    ["id"] = "excursion_planning",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "travel.excursion.plan_exchange",
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
                            ["fallback"] = "We're running low on canned goods and spare batteries, {addressee.name}. Think we can make a quick run {scene.location}?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.travel.excursion.plan_exchange.say_1",
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
        ["sourceShard"] = "dialogue/thematic_interactive/travel_excursion_exchange.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "We're running low on canned goods and spare batteries, {addressee.name}. Think we can make a quick run {scene.location}?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.travel.excursion.plan_exchange.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Alright, {addressee.name}. Pack light, keep the crowbar handy, and we stick to the side streets.",
                ["outcome"] = "agreed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.travel.excursion.plan_exchange.reply.agreed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Roads looked quiet earlier {scene.location}, {addressee.name}, though there's always a few stragglers near the gas station.",
                ["outcome"] = "assessed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.travel.excursion.plan_exchange.reply.assessed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Better to wait for first light. Fog's too thick out by the highway right now.",
                ["outcome"] = "deferred",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.travel.excursion.plan_exchange.reply.deferred.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "No sense going out there right now. Stay put until it's safe.",
                ["outcome"] = "refused",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.travel.excursion.plan_exchange.reply.refused.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
}
