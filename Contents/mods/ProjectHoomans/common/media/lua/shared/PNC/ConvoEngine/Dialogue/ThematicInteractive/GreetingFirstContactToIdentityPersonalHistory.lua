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
                ["accepted"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "social.identity.personal_history",
                            "knowledge.gossip.exchange",
                        },
                    },
                    ["outcome"] = "accepted",
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
                                        ["fallback"] = "Fair enough—lower the crowbar and come under the awning out of sight.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.greeting.first_contact.reply.accepted.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
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
                    ["after"] = {
                        ["recommend"] = {
                            "knowledge.gossip.exchange",
                        },
                    },
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
                ["end_conversation"] = {
                    ["outcome"] = "end_conversation",
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
                                        ["fallback"] = "No trouble here—passing along and letting you keep your corner.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.greeting.first_contact.reply.end_conversation.say.1.default",
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
                ["rejected"] = {
                    ["outcome"] = "rejected",
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
                                        ["fallback"] = "Keep walking down the shoulder. We aren't taking strangers inside tonight.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.greeting.first_contact.reply.rejected.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["reluctant"] = {
                    ["outcome"] = "reluctant",
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
                                        ["fallback"] = "You get two minutes by the curb to state your piece, nothing closer.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.greeting.first_contact.reply.reluctant.say.1.default",
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
                    ["after"] = {
                        ["recommend"] = {
                            "social.identity.personal_history",
                            "knowledge.gossip.exchange",
                        },
                    },
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
                    ["fallback"] = "Fair enough—lower the crowbar and come under the awning out of sight.",
                    ["outcome"] = "accepted",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.greeting.first_contact.reply.accepted.say.1.default",
                    ["variantID"] = "default",
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
                    ["fallback"] = "No trouble here—passing along and letting you keep your corner.",
                    ["outcome"] = "end_conversation",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.greeting.first_contact.reply.end_conversation.say.1.default",
                    ["variantID"] = "default",
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
                    ["fallback"] = "Keep walking down the shoulder. We aren't taking strangers inside tonight.",
                    ["outcome"] = "rejected",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.greeting.first_contact.reply.rejected.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "You get two minutes by the curb to state your piece, nothing closer.",
                    ["outcome"] = "reluctant",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.greeting.first_contact.reply.reluctant.say.1.default",
                    ["variantID"] = "default",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/ThematicInteractive/GreetingFirstContactToIdentityPersonalHistory",
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
                                    ["stateValue"] = "business",
                                    ["subject"] = "FIRST_CONTACT",
                                },
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["stateValue"] = "peaceful",
                                    ["subject"] = "FIRST_CONTACT",
                                },
                                {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
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
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["stateValue"] = "business",
                                        ["subject"] = "FIRST_CONTACT",
                                    },
                                    ["id"] = "first_contact.state_road_business",
                                    ["labelFallback"] = "Say where you came from",
                                    ["labelKey"] = "UI_PNC_FirstContact_RoadBiz_Label",
                                    ["utteranceFallback"] = "Cut across from the west highway—just checking shutters for clean water.",
                                    ["utteranceKey"] = "UI_PNC_FirstContact_RoadBiz_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "eq",
                                        ["path"] = "inventory.armed",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["stateValue"] = "peaceful",
                                        ["subject"] = "FIRST_CONTACT",
                                    },
                                    ["id"] = "first_contact.show_holstered",
                                    ["labelFallback"] = "Keep weapon slung low",
                                    ["labelKey"] = "UI_PNC_FirstContact_Holstered_Label",
                                    ["utteranceFallback"] = "Crowbar stays lowered at my side—just passing to the gas station.",
                                    ["utteranceKey"] = "UI_PNC_FirstContact_Holstered_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "eq",
                                        ["path"] = "environment.isIndoors",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "QUESTION",
                                        ["speechAct"] = "QUESTION",
                                        ["subject"] = "FIRST_CONTACT",
                                    },
                                    ["id"] = "first_contact.ask_shelter_indoors",
                                    ["labelFallback"] = "Ask if room is secure inside",
                                    ["labelKey"] = "UI_PNC_FirstContact_Indoors_Label",
                                    ["utteranceFallback"] = "Door behind you stays barred? Just checking before we talk in the lane.",
                                    ["utteranceKey"] = "UI_PNC_FirstContact_Indoors_Utterance",
                                },
                            },
                            ["onClarify"] = "name_and_intent",
                            ["onMatch"] = "verify_trust",
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
                                    ["stateValue"] = "positive",
                                },
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["stateValue"] = "neutral",
                                    ["subject"] = "FIRST_CONTACT",
                                },
                                {
                                    ["intent"] = "CLARIFY",
                                    ["speechAct"] = "CLARIFY",
                                    ["subject"] = "FIRST_CONTACT",
                                },
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["stateValue"] = "cautious",
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
                                    ["labelKey"] = "UI_PNC_FirstContact_Friendly_Label",
                                    ["utteranceFallback"] = "Easy—just passing through. Good seeing someone alive around here.",
                                    ["utteranceKey"] = "UI_PNC_FirstContact_Friendly_Utterance",
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
                                    ["labelKey"] = "UI_PNC_FirstContact_Cautious_Label",
                                    ["utteranceFallback"] = "Hands open in plain sight. Not looking to pick a fight.",
                                    ["utteranceKey"] = "UI_PNC_FirstContact_Cautious_Utterance",
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
                                    ["labelFallback"] = "Ask who holds the block",
                                    ["labelKey"] = "UI_PNC_FirstContact_Clarify_Label",
                                    ["utteranceFallback"] = "Depends—you alone out here, or watching this street for a camp?",
                                    ["utteranceKey"] = "UI_PNC_FirstContact_Clarify_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "eq",
                                        ["path"] = "worldKnowledge.recentAlarmOrGunfire",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["stateValue"] = "cautious",
                                        ["subject"] = "FIRST_CONTACT",
                                    },
                                    ["id"] = "first_contact.note_alarm_noise",
                                    ["labelFallback"] = "Note recent shots or alarm",
                                    ["labelKey"] = "UI_PNC_FirstContact_Alarm_Label",
                                    ["utteranceFallback"] = "Wasn't me tripping that racket east of here—kept low until it quieted.",
                                    ["utteranceKey"] = "UI_PNC_FirstContact_Alarm_Utterance",
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
                                    ["selfDirected"] = true,
                                    ["speechAct"] = "INFORM",
                                },
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["stateValue"] = "guarded",
                                    ["subject"] = "FIRST_CONTACT",
                                },
                                {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "NEWS",
                                },
                                {
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                },
                            },
                            ["branchOffers"] = {
                                {
                                    ["constraints"] = {
                                        ["op"] = "gte",
                                        ["path"] = "relationship.trust",
                                        ["value"] = -10,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["identityClaim"] = true,
                                        ["intent"] = "INFORM",
                                        ["selfDirected"] = true,
                                        ["speechAct"] = "INFORM",
                                    },
                                    ["id"] = "first_contact.share_name",
                                    ["labelFallback"] = "Give your name and trade notes",
                                    ["labelKey"] = "UI_PNC_FirstContact_ShareName_Label",
                                    ["utteranceFallback"] = "I'm no raider—just keeping track of which streets are passable and who survived.",
                                    ["utteranceKey"] = "UI_PNC_FirstContact_ShareName_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["stateValue"] = "guarded",
                                        ["subject"] = "FIRST_CONTACT",
                                    },
                                    ["id"] = "first_contact.keep_brief",
                                    ["labelFallback"] = "Stay anonymous for now",
                                    ["labelKey"] = "UI_PNC_FirstContact_KeepBrief_Label",
                                    ["utteranceFallback"] = "Call me traveler for now—just checking roads, not digging into anyone's stash.",
                                    ["utteranceKey"] = "UI_PNC_FirstContact_KeepBrief_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "QUESTION",
                                        ["speechAct"] = "QUESTION",
                                        ["subject"] = "NEWS",
                                    },
                                    ["id"] = "first_contact.ask_recent_news",
                                    ["labelFallback"] = "Trade street condition before parting",
                                    ["labelKey"] = "UI_PNC_FirstContact_AskNews_Label",
                                    ["utteranceFallback"] = "Seen anything suspicious down by the crossroads today?",
                                    ["utteranceKey"] = "UI_PNC_FirstContact_AskNews_Utterance",
                                },
                            },
                            ["onMatch"] = "settle_standing",
                            ["onRefuse"] = "guarded_parting",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.social.greeting.first_contact.exchange",
                        },
                        ["settle_standing"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "THANK",
                                    ["speechAct"] = "THANK",
                                },
                                {
                                    ["intent"] = "ACKNOWLEDGE",
                                    ["speechAct"] = "ACKNOWLEDGE",
                                },
                                {
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                    ["stateValue"] = "end_conversation",
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
                                        ["intent"] = "THANK",
                                        ["speechAct"] = "THANK",
                                    },
                                    ["id"] = "first_contact.part_friendly",
                                    ["labelFallback"] = "Leave on steady terms",
                                    ["labelKey"] = "UI_PNC_FirstContact_PartFriendly_Label",
                                    ["utteranceFallback"] = "Good talking. Sing out if you spot smoke or trouble down my way.",
                                    ["utteranceKey"] = "UI_PNC_FirstContact_PartFriendly_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "ACKNOWLEDGE",
                                        ["speechAct"] = "ACKNOWLEDGE",
                                    },
                                    ["id"] = "first_contact.part_cautious",
                                    ["labelFallback"] = "Keep terms cautious",
                                    ["labelKey"] = "UI_PNC_FirstContact_PartCautious_Label",
                                    ["utteranceFallback"] = "Remember I was clear on this street—stay safe out there.",
                                    ["utteranceKey"] = "UI_PNC_FirstContact_PartCautious_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "REFUSE",
                                        ["speechAct"] = "REFUSE",
                                        ["stateValue"] = "end_conversation",
                                    },
                                    ["id"] = "first_contact.end_short",
                                    ["labelFallback"] = "Close contact briefly",
                                    ["labelKey"] = "UI_PNC_FirstContact_EndShort_Label",
                                    ["utteranceFallback"] = "Moving out before dark. Watch the corner.",
                                    ["utteranceKey"] = "UI_PNC_FirstContact_EndShort_Utterance",
                                },
                            },
                            ["onMatch"] = "complete",
                            ["onRefuse"] = "guarded_parting",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.social.greeting.first_contact.standing",
                        },
                        ["verify_trust"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "OFFER",
                                    ["speechAct"] = "OFFER",
                                    ["subject"] = "NEWS",
                                },
                                {
                                    ["intent"] = "ACCEPT",
                                    ["speechAct"] = "ACCEPT",
                                    ["stateValue"] = "reluctant",
                                    ["subject"] = "FIRST_CONTACT",
                                },
                                {
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                    ["stateValue"] = "end_conversation",
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
                                        ["intent"] = "OFFER",
                                        ["speechAct"] = "OFFER",
                                        ["subject"] = "NEWS",
                                    },
                                    ["id"] = "first_contact.offer_water_trade",
                                    ["labelFallback"] = "Offer quick news in good faith",
                                    ["labelKey"] = "UI_PNC_FirstContact_WaterTrade_Label",
                                    ["utteranceFallback"] = "Road north is piled with wrecks—figure fair warning beats sneaking by.",
                                    ["utteranceKey"] = "UI_PNC_FirstContact_WaterTrade_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "ACCEPT",
                                        ["speechAct"] = "ACCEPT",
                                        ["stateValue"] = "reluctant",
                                        ["subject"] = "FIRST_CONTACT",
                                    },
                                    ["id"] = "first_contact.reluctant_parley",
                                    ["labelFallback"] = "Keep talk strictly on the curb",
                                    ["labelKey"] = "UI_PNC_FirstContact_Reluctant_Label",
                                    ["utteranceFallback"] = "Fine—we talk from ten feet apart and move on before dark.",
                                    ["utteranceKey"] = "UI_PNC_FirstContact_Reluctant_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "REFUSE",
                                        ["speechAct"] = "REFUSE",
                                        ["stateValue"] = "end_conversation",
                                    },
                                    ["id"] = "first_contact.walk_away",
                                    ["labelFallback"] = "Move along quietly",
                                    ["labelKey"] = "UI_PNC_FirstContact_WalkAway_Label",
                                    ["utteranceFallback"] = "Fair enough—no trouble. Moving along now.",
                                    ["utteranceKey"] = "UI_PNC_FirstContact_WalkAway_Utterance",
                                },
                            },
                            ["onMatch"] = "name_and_intent",
                            ["onRefuse"] = "guarded_parting",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.social.greeting.first_contact.clarify",
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
                    "accepted",
                    "rejected",
                    "reluctant",
                    "end_conversation",
                },
                ["replySemantics"] = {
                    ["accepted"] = {
                        ["outcome"] = "accepted",
                        ["stance"] = "positive",
                    },
                    ["blocked"] = {
                        ["outcome"] = "blocked",
                        ["stance"] = "negative",
                    },
                    ["cautious"] = {
                        ["outcome"] = "cautious",
                        ["stance"] = "contextual",
                    },
                    ["declined"] = {
                        ["outcome"] = "rejected",
                        ["stance"] = "negative",
                    },
                    ["end_conversation"] = {
                        ["outcome"] = "end_conversation",
                        ["stance"] = "neutral",
                    },
                    ["evasive"] = {
                        ["outcome"] = "evasive",
                        ["stance"] = "neutral",
                    },
                    ["rejected"] = {
                        ["outcome"] = "rejected",
                        ["stance"] = "negative",
                    },
                    ["reluctant"] = {
                        ["outcome"] = "reluctant",
                        ["stance"] = "contextual",
                    },
                    ["welcomed"] = {
                        ["outcome"] = "accepted",
                        ["stance"] = "positive",
                    },
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
                ["accepted"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "social.identity.personal_history",
                            "knowledge.gossip.exchange",
                        },
                    },
                    ["outcome"] = "accepted",
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
                                        ["fallback"] = "Fair enough—lower the crowbar and come under the awning out of sight.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
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
                    ["after"] = {
                        ["recommend"] = {
                            "knowledge.gossip.exchange",
                        },
                    },
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
                ["end_conversation"] = {
                    ["outcome"] = "end_conversation",
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
                                        ["fallback"] = "No trouble here—passing along and letting you keep your corner.",
                                        ["id"] = "default",
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
                ["rejected"] = {
                    ["outcome"] = "rejected",
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
                                        ["fallback"] = "Keep walking down the shoulder. We aren't taking strangers inside tonight.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["reluctant"] = {
                    ["outcome"] = "reluctant",
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
                                        ["fallback"] = "You get two minutes by the curb to state your piece, nothing closer.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["welcomed"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "social.identity.personal_history",
                            "knowledge.gossip.exchange",
                        },
                    },
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
                ["fallback"] = "Fair enough—lower the crowbar and come under the awning out of sight.",
                ["outcome"] = "accepted",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.greeting.first_contact.reply.accepted.say.1.default",
                ["variantID"] = "default",
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
                ["fallback"] = "No trouble here—passing along and letting you keep your corner.",
                ["outcome"] = "end_conversation",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.greeting.first_contact.reply.end_conversation.say.1.default",
                ["variantID"] = "default",
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
                ["fallback"] = "Keep walking down the shoulder. We aren't taking strangers inside tonight.",
                ["outcome"] = "rejected",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.greeting.first_contact.reply.rejected.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "You get two minutes by the curb to state your piece, nothing closer.",
                ["outcome"] = "reluctant",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.greeting.first_contact.reply.reluctant.say.1.default",
                ["variantID"] = "default",
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
                    ["after"] = {
                        ["recommend"] = {
                            "wellbeing.needs.checkin",
                        },
                    },
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
                ["protect_source"] = {
                    ["outcome"] = "protect_source",
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
                                        ["fallback"] = "Not giving names for folks who didn't ask to be dragged back into Knox County's mess.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.identity.personal_history.reply.protect_source.say.1.default",
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
                ["reveal_source"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "knowledge.gossip.exchange",
                        },
                    },
                    ["outcome"] = "reveal_source",
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
                                        ["fallback"] = "Alright, {addressee.name}—our old crew split near the rail yard, and that's where I got my rig.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.identity.personal_history.reply.reveal_source.say.1.default",
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
                    ["after"] = {
                        ["recommend"] = {
                            "knowledge.gossip.exchange",
                            "colony.work.status_exchange",
                        },
                    },
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
                ["withdraw"] = {
                    ["outcome"] = "withdraw",
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
                                        ["fallback"] = "Enough looking back. Past won't bar tonight's windows.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.identity.personal_history.reply.withdraw.say.1.default",
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
                    ["fallback"] = "Not giving names for folks who didn't ask to be dragged back into Knox County's mess.",
                    ["outcome"] = "protect_source",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.identity.personal_history.reply.protect_source.say.1.default",
                    ["variantID"] = "default",
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
                    ["fallback"] = "Alright, {addressee.name}—our old crew split near the rail yard, and that's where I got my rig.",
                    ["outcome"] = "reveal_source",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.identity.personal_history.reply.reveal_source.say.1.default",
                    ["variantID"] = "default",
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
                {
                    ["fallback"] = "Enough looking back. Past won't bar tonight's windows.",
                    ["outcome"] = "withdraw",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.identity.personal_history.reply.withdraw.say.1.default",
                    ["variantID"] = "default",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/ThematicInteractive/GreetingFirstContactToIdentityPersonalHistory",
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
                                    ["stateValue"] = "positive",
                                    ["subject"] = "BACKSTORY",
                                },
                                {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "IDENTITY",
                                },
                                {
                                    ["intent"] = "CLARIFY",
                                    ["speechAct"] = "CLARIFY",
                                    ["subject"] = "BACKSTORY",
                                },
                                {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["stateValue"] = "shared",
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
                                        ["stateValue"] = "positive",
                                        ["subject"] = "BACKSTORY",
                                    },
                                    ["id"] = "identity.history.share_roots",
                                    ["labelFallback"] = "Mention where you lived before",
                                    ["labelKey"] = "UI_PNC_IdentityHistory_ShareRoots_Label",
                                    ["utteranceFallback"] = "Worked garages south of Muldraugh before the highway roadblocks locked down.",
                                    ["utteranceKey"] = "UI_PNC_IdentityHistory_ShareRoots_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "QUESTION",
                                        ["speechAct"] = "QUESTION",
                                        ["subject"] = "IDENTITY",
                                    },
                                    ["id"] = "identity.history.ask_trade",
                                    ["labelFallback"] = "Ask what work they knew",
                                    ["labelKey"] = "UI_PNC_IdentityHistory_AskTrade_Label",
                                    ["utteranceFallback"] = "What did you used to do before everyone ended up scavenging alleys?",
                                    ["utteranceKey"] = "UI_PNC_IdentityHistory_AskTrade_Utterance",
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
                                    ["labelFallback"] = "Ask which town they survived",
                                    ["labelKey"] = "UI_PNC_IdentityHistory_ClarifyOrigin_Label",
                                    ["utteranceFallback"] = "Muldraugh, Rosewood, or caught on the Louisville river crossing?",
                                    ["utteranceKey"] = "UI_PNC_IdentityHistory_ClarifyOrigin_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "eq",
                                        ["path"] = "worldKnowledge.sharedSettlementHistory",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "QUESTION",
                                        ["speechAct"] = "QUESTION",
                                        ["stateValue"] = "shared",
                                        ["subject"] = "BACKSTORY",
                                    },
                                    ["id"] = "identity.history.ask_shared_town",
                                    ["labelFallback"] = "Mention shared neighborhood landmarks",
                                    ["labelKey"] = "UI_PNC_IdentityHistory_SharedTown_Label",
                                    ["utteranceFallback"] = "Sounded like you knew the old clinic by the rail spur—used to live that side?",
                                    ["utteranceKey"] = "UI_PNC_IdentityHistory_SharedTown_Utterance",
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
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["stateValue"] = "protect_source",
                                    ["subject"] = "BACKSTORY",
                                },
                                {
                                    ["intent"] = "DEFER",
                                    ["speechAct"] = "DEFER",
                                    ["subject"] = "IDENTITY",
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
                                    ["labelFallback"] = "Confirm crossing the checkpoint early",
                                    ["labelKey"] = "UI_PNC_IdentityHistory_ConfirmTown_Label",
                                    ["utteranceFallback"] = "Slipped past the cordon back in early July before the power gave out.",
                                    ["utteranceKey"] = "UI_PNC_IdentityHistory_ConfirmTown_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["stateValue"] = "protect_source",
                                        ["subject"] = "BACKSTORY",
                                    },
                                    ["id"] = "identity.history.protect_crew_names",
                                    ["labelFallback"] = "Leave old companions unnamed",
                                    ["labelKey"] = "UI_PNC_IdentityHistory_ProtectCrew_Label",
                                    ["utteranceFallback"] = "Keep old camp names out of it—some folks still prefer staying ghosts.",
                                    ["utteranceKey"] = "UI_PNC_IdentityHistory_ProtectCrew_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "eq",
                                        ["path"] = "scene.hasThirdPartyWitness",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "DEFER",
                                        ["speechAct"] = "DEFER",
                                        ["subject"] = "IDENTITY",
                                    },
                                    ["id"] = "identity.history.note_witness_listen",
                                    ["labelFallback"] = "Keep talk guarded with bystanders",
                                    ["labelKey"] = "UI_PNC_IdentityHistory_WitnessListen_Label",
                                    ["utteranceFallback"] = "Maybe save names for later when fewer ears are standing in the doorway.",
                                    ["utteranceKey"] = "UI_PNC_IdentityHistory_WitnessListen_Utterance",
                                },
                            },
                            ["onClarify"] = "share_history",
                            ["onMatch"] = "weigh_disclosure",
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
                            ["responsePool"] = "semantic.social.identity.personal_history.refused",
                            ["terminal"] = true,
                        },
                        ["reflect_bond"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "THANK",
                                    ["speechAct"] = "THANK",
                                },
                                {
                                    ["intent"] = "ACCEPT",
                                    ["speechAct"] = "ACCEPT",
                                },
                                {
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                    ["stateValue"] = "withdraw",
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
                                        ["intent"] = "THANK",
                                        ["speechAct"] = "THANK",
                                    },
                                    ["id"] = "identity.history.close_warm",
                                    ["labelFallback"] = "Close on warmer trust",
                                    ["labelKey"] = "UI_PNC_IdentityHistory_CloseWarm_Label",
                                    ["utteranceFallback"] = "Good knowing who's actually standing beside me in this mess.",
                                    ["utteranceKey"] = "UI_PNC_IdentityHistory_CloseWarm_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "ACCEPT",
                                        ["speechAct"] = "ACCEPT",
                                    },
                                    ["id"] = "identity.history.close_quiet",
                                    ["labelFallback"] = "Part respectfully",
                                    ["labelKey"] = "UI_PNC_IdentityHistory_CloseQuiet_Label",
                                    ["utteranceFallback"] = "Understood. We stick together when the sirens start up.",
                                    ["utteranceKey"] = "UI_PNC_IdentityHistory_CloseQuiet_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "REFUSE",
                                        ["speechAct"] = "REFUSE",
                                        ["stateValue"] = "withdraw",
                                    },
                                    ["id"] = "identity.history.close_guarded",
                                    ["labelFallback"] = "End past talk cleanly",
                                    ["labelKey"] = "UI_PNC_IdentityHistory_CloseGuarded_Label",
                                    ["utteranceFallback"] = "Enough stories for today. Keep eyes on the block.",
                                    ["utteranceKey"] = "UI_PNC_IdentityHistory_CloseGuarded_Utterance",
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
                                    ["intent"] = "AGREE",
                                    ["speechAct"] = "AGREE",
                                    ["stateValue"] = "shared",
                                    ["subject"] = "BACKSTORY",
                                },
                                {
                                    ["intent"] = "ACKNOWLEDGE",
                                    ["speechAct"] = "ACKNOWLEDGE",
                                    ["subject"] = "IDENTITY",
                                },
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["stateValue"] = "protect_source",
                                    ["subject"] = "IDENTITY",
                                },
                                {
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                },
                            },
                            ["branchOffers"] = {
                                {
                                    ["constraints"] = {
                                        ["op"] = "gte",
                                        ["path"] = "relationship.approval",
                                        ["value"] = 0,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "AGREE",
                                        ["speechAct"] = "AGREE",
                                        ["stateValue"] = "shared",
                                        ["subject"] = "BACKSTORY",
                                    },
                                    ["id"] = "identity.history.connect_family",
                                    ["labelFallback"] = "Share family or crew connection",
                                    ["labelKey"] = "UI_PNC_IdentityHistory_ConnectFamily_Label",
                                    ["utteranceFallback"] = "Sounds like we crossed some of the same checkpoints before they closed.",
                                    ["utteranceKey"] = "UI_PNC_IdentityHistory_ConnectFamily_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "ACKNOWLEDGE",
                                        ["speechAct"] = "ACKNOWLEDGE",
                                        ["subject"] = "IDENTITY",
                                    },
                                    ["id"] = "identity.history.acknowledge_past",
                                    ["labelFallback"] = "Acknowledge shared survival",
                                    ["labelKey"] = "UI_PNC_IdentityHistory_AckPast_Label",
                                    ["utteranceFallback"] = "Long road to still be standing here. Glad it wasn't for nothing.",
                                    ["utteranceKey"] = "UI_PNC_IdentityHistory_AckPast_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["stateValue"] = "protect_source",
                                        ["subject"] = "IDENTITY",
                                    },
                                    ["id"] = "identity.history.guard_origin",
                                    ["labelFallback"] = "Protect where old allies went",
                                    ["labelKey"] = "UI_PNC_IdentityHistory_GuardOrigin_Label",
                                    ["utteranceFallback"] = "Left them heading west—won't point anyone else after them.",
                                    ["utteranceKey"] = "UI_PNC_IdentityHistory_GuardOrigin_Utterance",
                                },
                            },
                            ["onMatch"] = "reflect_bond",
                            ["onRefuse"] = "kept_private",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.social.identity.personal_history.exchange",
                            ["slots"] = {
                                ["faction"] = {
                                    ["owner"] = "social",
                                    ["source"] = "slots.faction",
                                    ["type"] = "string",
                                },
                            },
                        },
                        ["weigh_disclosure"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["stateValue"] = "reveal_source",
                                    ["subject"] = "IDENTITY",
                                },
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["stateValue"] = "guarded",
                                    ["subject"] = "BACKSTORY",
                                },
                                {
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                    ["stateValue"] = "withdraw",
                                },
                                {
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                },
                            },
                            ["branchOffers"] = {
                                {
                                    ["constraints"] = {
                                        ["op"] = "gte",
                                        ["path"] = "relationship.trust",
                                        ["value"] = 25,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["stateValue"] = "reveal_source",
                                        ["subject"] = "IDENTITY",
                                    },
                                    ["id"] = "identity.history.trust_with_crew",
                                    ["labelFallback"] = "Name who taught you fieldcraft",
                                    ["labelKey"] = "UI_PNC_IdentityHistory_TrustCrew_Label",
                                    ["utteranceFallback"] = "My uncle ran mechanics out of Riverside—that's where I learned wiring.",
                                    ["utteranceKey"] = "UI_PNC_IdentityHistory_TrustCrew_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["stateValue"] = "guarded",
                                        ["subject"] = "BACKSTORY",
                                    },
                                    ["id"] = "identity.history.stay_vague",
                                    ["labelFallback"] = "Keep details light",
                                    ["labelKey"] = "UI_PNC_IdentityHistory_StayVague_Label",
                                    ["utteranceFallback"] = "Passed through two camps and kept moving—nothing fancy.",
                                    ["utteranceKey"] = "UI_PNC_IdentityHistory_StayVague_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "REFUSE",
                                        ["speechAct"] = "REFUSE",
                                        ["stateValue"] = "withdraw",
                                    },
                                    ["id"] = "identity.history.withdraw_past",
                                    ["labelFallback"] = "Pass on sharing personal past",
                                    ["labelKey"] = "UI_PNC_IdentityHistory_WithdrawPast_Label",
                                    ["utteranceFallback"] = "Rather keep the past buried and focus on surviving this week.",
                                    ["utteranceKey"] = "UI_PNC_IdentityHistory_WithdrawPast_Utterance",
                                },
                            },
                            ["onMatch"] = "share_history",
                            ["onRefuse"] = "kept_private",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.social.identity.personal_history.clarify",
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
                    "reveal_source",
                    "protect_source",
                    "withdraw",
                },
                ["replySemantics"] = {
                    ["blocked"] = {
                        ["outcome"] = "blocked",
                        ["stance"] = "negative",
                    },
                    ["evasive"] = {
                        ["outcome"] = "evasive",
                        ["stance"] = "neutral",
                    },
                    ["guarded"] = {
                        ["outcome"] = "guarded",
                        ["stance"] = "contextual",
                    },
                    ["protect_source"] = {
                        ["outcome"] = "protect_source",
                        ["stance"] = "contextual",
                    },
                    ["refused"] = {
                        ["outcome"] = "refused",
                        ["stance"] = "negative",
                    },
                    ["reveal_source"] = {
                        ["outcome"] = "reveal_source",
                        ["stance"] = "positive",
                    },
                    ["shared"] = {
                        ["outcome"] = "shared",
                        ["stance"] = "positive",
                    },
                    ["withdraw"] = {
                        ["outcome"] = "withdraw",
                        ["stance"] = "neutral",
                    },
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
                    ["after"] = {
                        ["recommend"] = {
                            "wellbeing.needs.checkin",
                        },
                    },
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
                ["protect_source"] = {
                    ["outcome"] = "protect_source",
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
                                        ["fallback"] = "Not giving names for folks who didn't ask to be dragged back into Knox County's mess.",
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
                ["reveal_source"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "knowledge.gossip.exchange",
                        },
                    },
                    ["outcome"] = "reveal_source",
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
                                        ["fallback"] = "Alright, {addressee.name}—our old crew split near the rail yard, and that's where I got my rig.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["shared"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "knowledge.gossip.exchange",
                            "colony.work.status_exchange",
                        },
                    },
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
                ["withdraw"] = {
                    ["outcome"] = "withdraw",
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
                                        ["fallback"] = "Enough looking back. Past won't bar tonight's windows.",
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
                ["fallback"] = "Not giving names for folks who didn't ask to be dragged back into Knox County's mess.",
                ["outcome"] = "protect_source",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.identity.personal_history.reply.protect_source.say.1.default",
                ["variantID"] = "default",
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
                ["fallback"] = "Alright, {addressee.name}—our old crew split near the rail yard, and that's where I got my rig.",
                ["outcome"] = "reveal_source",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.identity.personal_history.reply.reveal_source.say.1.default",
                ["variantID"] = "default",
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
            {
                ["fallback"] = "Enough looking back. Past won't bar tonight's windows.",
                ["outcome"] = "withdraw",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.identity.personal_history.reply.withdraw.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
}
