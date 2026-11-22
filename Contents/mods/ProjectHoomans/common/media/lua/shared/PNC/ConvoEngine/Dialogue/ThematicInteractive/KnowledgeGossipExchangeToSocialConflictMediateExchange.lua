-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "thematic_interactive",
        ["domainPath"] = "thematic_interactive",
        ["exchangeFamily"] = {
            ["familyID"] = "knowledge.gossip.exchange",
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
                                ["fallback"] = "Heard any word from down the road? Trying to piece together what's still standing.",
                                ["id"] = "default",
                                ["templateID"] = "convo.knowledge.gossip.exchange.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Good catching you here, {addressee.name}—heard anything useful about clear roads or decent supplies nearby?",
                                ["id"] = "positive",
                                ["templateID"] = "convo.knowledge.gossip.exchange.say.1.positive",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "What's the word around here lately—anything moving on the highway or near town?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.knowledge.gossip.exchange.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Lot of wild rumors flying around lately. You heard anything that actually checks out?",
                                ["id"] = "negative",
                                ["templateID"] = "convo.knowledge.gossip.exchange.say.1.negative",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Saw smoke rising east of the river earlier, and the chopper's been rattling nerves all week. Heard anything?",
                                ["id"] = "contextual",
                                ["templateID"] = "convo.knowledge.gossip.exchange.say.1.contextual",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "knowledge.gossip",
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
                                        ["fallback"] = "Not the time for rumors—keep your head down.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.knowledge.gossip.exchange.reply.blocked.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "Save the chatter. Watch the street.",
                                        ["id"] = "negative",
                                        ["templateID"] = "convo.knowledge.gossip.exchange.reply.blocked.say.1.negative",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["contradicted"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "combat.aftermath.debrief_exchange",
                        },
                    },
                    ["outcome"] = "contradicted",
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
                                        ["fallback"] = "No, that doesn't square with what happened there. Somebody fed you a bad steer.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.knowledge.gossip.exchange.reply.contradicted.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["corroborated"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "travel.excursion.plan_exchange",
                            "colony.work.status_exchange",
                        },
                    },
                    ["outcome"] = "corroborated",
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
                                        ["fallback"] = "That tracks with what I witnessed near {slot.location}, {addressee.name}. Same signs, same direction.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.knowledge.gossip.exchange.reply.corroborated.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "Both reports line up—between the emergency broadcast and firsthand sightings out by {slot.location}, we know it's real.",
                                        ["id"] = "contextual",
                                        ["templateID"] = "convo.knowledge.gossip.exchange.reply.corroborated.say.1.contextual",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["known"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "travel.excursion.plan_exchange",
                            "colony.work.status_exchange",
                        },
                    },
                    ["outcome"] = "known",
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
                                        ["fallback"] = "Yeah, I saw that myself—{slot.location} is choked up, so steer clear if you're smart.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.knowledge.gossip.exchange.reply.known.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "Actually, yes—{addressee.name}, word is solid on that. Worth keeping in your pocket.",
                                        ["id"] = "positive",
                                        ["templateID"] = "convo.knowledge.gossip.exchange.reply.known.say.1.positive",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "Can vouch for part of it, {addressee.name}: saw fresh tracks and open shutters near {slot.location} yesterday.",
                                        ["id"] = "contextual",
                                        ["templateID"] = "convo.knowledge.gossip.exchange.reply.known.say.1.contextual",
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
                                        ["fallback"] = "Doesn't matter who brought word in. Take the warning, skip asking for names.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.knowledge.gossip.exchange.reply.protect_source.say.1.default",
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
                                        ["fallback"] = "I don't trade in gossip. Ask somebody else.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.knowledge.gossip.exchange.reply.refused.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "Keep me out of it. Word gets around, and so does trouble.",
                                        ["id"] = "negative",
                                        ["templateID"] = "convo.knowledge.gossip.exchange.reply.refused.say.1.negative",
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
                            "social.identity.personal_history",
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
                                        ["fallback"] = "I trust you enough to say it straight: spotted it with my own eyes along the shoulder past dusk.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.knowledge.gossip.exchange.reply.reveal_source.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["uncertain"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "social.conflict.mediate_exchange",
                        },
                    },
                    ["outcome"] = "uncertain",
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
                                        ["fallback"] = "Heard folks talking about it, sure, but nobody I'd bet my boots on.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.knowledge.gossip.exchange.reply.uncertain.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "Could be true, could be somebody spooked by shadows. Treat it like a rumor until you see it.",
                                        ["id"] = "contextual",
                                        ["templateID"] = "convo.knowledge.gossip.exchange.reply.uncertain.say.1.contextual",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["unknown"] = {
                    ["outcome"] = "unknown",
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
                                        ["fallback"] = "Couldn't tell you. Haven't heard a peep about that.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.knowledge.gossip.exchange.reply.unknown.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "No idea—I've been keeping my head down on this block, haven't caught any news.",
                                        ["id"] = "neutral",
                                        ["templateID"] = "convo.knowledge.gossip.exchange.reply.unknown.say.1.neutral",
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
                                        ["fallback"] = "Look, drop it. We've both got ears and too much road left to argue rumor.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.knowledge.gossip.exchange.reply.withdraw.say.1.default",
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
                    ["fallback"] = "Heard any word from down the road? Trying to piece together what's still standing.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.knowledge.gossip.exchange.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Good catching you here, {addressee.name}—heard anything useful about clear roads or decent supplies nearby?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.knowledge.gossip.exchange.say.1.positive",
                    ["variantID"] = "positive",
                },
                {
                    ["fallback"] = "What's the word around here lately—anything moving on the highway or near town?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.knowledge.gossip.exchange.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Lot of wild rumors flying around lately. You heard anything that actually checks out?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.knowledge.gossip.exchange.say.1.negative",
                    ["variantID"] = "negative",
                },
                {
                    ["fallback"] = "Saw smoke rising east of the river earlier, and the chopper's been rattling nerves all week. Heard anything?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.knowledge.gossip.exchange.say.1.contextual",
                    ["variantID"] = "contextual",
                },
                {
                    ["fallback"] = "Not the time for rumors—keep your head down.",
                    ["outcome"] = "blocked",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.knowledge.gossip.exchange.reply.blocked.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Save the chatter. Watch the street.",
                    ["outcome"] = "blocked",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.knowledge.gossip.exchange.reply.blocked.say.1.negative",
                    ["variantID"] = "negative",
                },
                {
                    ["fallback"] = "No, that doesn't square with what happened there. Somebody fed you a bad steer.",
                    ["outcome"] = "contradicted",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.knowledge.gossip.exchange.reply.contradicted.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "That tracks with what I witnessed near {slot.location}, {addressee.name}. Same signs, same direction.",
                    ["outcome"] = "corroborated",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.knowledge.gossip.exchange.reply.corroborated.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Both reports line up—between the emergency broadcast and firsthand sightings out by {slot.location}, we know it's real.",
                    ["outcome"] = "corroborated",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.knowledge.gossip.exchange.reply.corroborated.say.1.contextual",
                    ["variantID"] = "contextual",
                },
                {
                    ["fallback"] = "Yeah, I saw that myself—{slot.location} is choked up, so steer clear if you're smart.",
                    ["outcome"] = "known",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.knowledge.gossip.exchange.reply.known.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Actually, yes—{addressee.name}, word is solid on that. Worth keeping in your pocket.",
                    ["outcome"] = "known",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.knowledge.gossip.exchange.reply.known.say.1.positive",
                    ["variantID"] = "positive",
                },
                {
                    ["fallback"] = "Can vouch for part of it, {addressee.name}: saw fresh tracks and open shutters near {slot.location} yesterday.",
                    ["outcome"] = "known",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.knowledge.gossip.exchange.reply.known.say.1.contextual",
                    ["variantID"] = "contextual",
                },
                {
                    ["fallback"] = "Doesn't matter who brought word in. Take the warning, skip asking for names.",
                    ["outcome"] = "protect_source",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.knowledge.gossip.exchange.reply.protect_source.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I don't trade in gossip. Ask somebody else.",
                    ["outcome"] = "refused",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.knowledge.gossip.exchange.reply.refused.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Keep me out of it. Word gets around, and so does trouble.",
                    ["outcome"] = "refused",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.knowledge.gossip.exchange.reply.refused.say.1.negative",
                    ["variantID"] = "negative",
                },
                {
                    ["fallback"] = "I trust you enough to say it straight: spotted it with my own eyes along the shoulder past dusk.",
                    ["outcome"] = "reveal_source",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.knowledge.gossip.exchange.reply.reveal_source.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Heard folks talking about it, sure, but nobody I'd bet my boots on.",
                    ["outcome"] = "uncertain",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.knowledge.gossip.exchange.reply.uncertain.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Could be true, could be somebody spooked by shadows. Treat it like a rumor until you see it.",
                    ["outcome"] = "uncertain",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.knowledge.gossip.exchange.reply.uncertain.say.1.contextual",
                    ["variantID"] = "contextual",
                },
                {
                    ["fallback"] = "Couldn't tell you. Haven't heard a peep about that.",
                    ["outcome"] = "unknown",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.knowledge.gossip.exchange.reply.unknown.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "No idea—I've been keeping my head down on this block, haven't caught any news.",
                    ["outcome"] = "unknown",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.knowledge.gossip.exchange.reply.unknown.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Look, drop it. We've both got ears and too much road left to argue rumor.",
                    ["outcome"] = "withdraw",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.knowledge.gossip.exchange.reply.withdraw.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "knowledge.gossip.exchange",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "exchange",
            ["sourceId"] = "knowledge.gossip.exchange",
            ["sourcePath"] = "dialogue/thematic_interactive/knowledge_gossip_exchange.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ThematicInteractive/KnowledgeGossipExchangeToSocialConflictMediateExchange",
        ["namespace"] = "knowledge.gossip",
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
                    ["domain"] = "knowledge",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["inputPolicy"] = "typed_parity",
            ["metadata"] = {
                ["category"] = "projecthoomans:thematic_interactive",
                ["contentOwner"] = "projecthoomans.dialogue_content.knowledge",
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
                    ["id"] = "knowledge.gossip.exchange",
                    ["initial"] = "ask_word_around",
                    ["nodes"] = {
                        ["ask_word_around"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "NEWS",
                                },
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["subject"] = "RUMOR",
                                },
                                {
                                    ["intent"] = "CLARIFY",
                                    ["speechAct"] = "CLARIFY",
                                    ["subject"] = "RUMOR",
                                },
                                {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["stateValue"] = "helicopter",
                                    ["subject"] = "NEWS",
                                },
                                {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["stateValue"] = "utility",
                                    ["subject"] = "NEWS",
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
                                        ["subject"] = "NEWS",
                                    },
                                    ["id"] = "knowledge.gossip.ask_roads",
                                    ["labelFallback"] = "Ask about nearby roads",
                                    ["labelKey"] = "UI_PNC_Gossip_AskRoads_Label",
                                    ["utteranceFallback"] = "Heard any word on whether the main highway is clear or choked with wrecks?",
                                    ["utteranceKey"] = "UI_PNC_Gossip_AskRoads_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["subject"] = "RUMOR",
                                    },
                                    ["id"] = "knowledge.gossip.share_rumor",
                                    ["labelFallback"] = "Pass on local rumor",
                                    ["labelKey"] = "UI_PNC_Gossip_ShareRumor_Label",
                                    ["utteranceFallback"] = "Folks down the block swore the intersection east of here isn't safe anymore.",
                                    ["utteranceKey"] = "UI_PNC_Gossip_ShareRumor_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "CLARIFY",
                                        ["speechAct"] = "CLARIFY",
                                        ["subject"] = "RUMOR",
                                    },
                                    ["id"] = "knowledge.gossip.clarify_source",
                                    ["labelFallback"] = "Ask who saw it",
                                    ["labelKey"] = "UI_PNC_Gossip_ClarifySource_Label",
                                    ["utteranceFallback"] = "Did someone see that with their own eyes, or hear it secondhand?",
                                    ["utteranceKey"] = "UI_PNC_Gossip_ClarifySource_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "eq",
                                        ["path"] = "worldKnowledge.hasHelicopter",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "QUESTION",
                                        ["speechAct"] = "QUESTION",
                                        ["stateValue"] = "helicopter",
                                        ["subject"] = "NEWS",
                                    },
                                    ["id"] = "knowledge.gossip.ask_helicopter",
                                    ["labelFallback"] = "Ask about the helicopter",
                                    ["labelKey"] = "UI_PNC_Gossip_AskHeli_Label",
                                    ["utteranceFallback"] = "Did you catch which ridge the chopper banked toward before the rotortrail faded?",
                                    ["utteranceKey"] = "UI_PNC_Gossip_AskHeli_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["any"] = {
                                            {
                                                ["op"] = "eq",
                                                ["path"] = "worldKnowledge.hasElectricityCutoff",
                                                ["value"] = true,
                                            },
                                            {
                                                ["op"] = "eq",
                                                ["path"] = "worldKnowledge.hasWaterCutoff",
                                                ["value"] = true,
                                            },
                                        },
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "QUESTION",
                                        ["speechAct"] = "QUESTION",
                                        ["stateValue"] = "utility",
                                        ["subject"] = "NEWS",
                                    },
                                    ["id"] = "knowledge.gossip.ask_cutoffs",
                                    ["labelFallback"] = "Ask about power or water shutoff",
                                    ["labelKey"] = "UI_PNC_Gossip_AskCutoffs_Label",
                                    ["utteranceFallback"] = "Anyone still getting current or clean pressure since the grid gave out?",
                                    ["utteranceKey"] = "UI_PNC_Gossip_AskCutoffs_Utterance",
                                },
                            },
                            ["onClarify"] = "clarify_source",
                            ["onMatch"] = "weigh_rumor",
                            ["onRefuse"] = "refused_rumor",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.knowledge.gossip.exchange.opening",
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
                        ["clarify_source"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["subject"] = "NEWS",
                                },
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["stateValue"] = "radio",
                                    ["subject"] = "NEWS",
                                },
                                {
                                    ["intent"] = "CLARIFY",
                                    ["speechAct"] = "CLARIFY",
                                    ["stateValue"] = "witness",
                                    ["subject"] = "NEWS",
                                },
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["stateValue"] = "protect_source",
                                    ["subject"] = "RUMOR",
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
                                        ["subject"] = "NEWS",
                                    },
                                    ["id"] = "knowledge.gossip.confirm_firsthand",
                                    ["labelFallback"] = "Say you saw signs yourself",
                                    ["labelKey"] = "UI_PNC_Gossip_Firsthand_Label",
                                    ["utteranceFallback"] = "Saw the smoke and bent guardrail from the corner—wasn't just radio static.",
                                    ["utteranceKey"] = "UI_PNC_Gossip_Firsthand_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "in",
                                        ["path"] = "worldKnowledge.epistemicStatus",
                                        ["values"] = {
                                            "known",
                                            "uncertain",
                                        },
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["stateValue"] = "radio",
                                        ["subject"] = "NEWS",
                                    },
                                    ["id"] = "knowledge.gossip.cite_radio",
                                    ["labelFallback"] = "Mention emergency broadcast",
                                    ["labelKey"] = "UI_PNC_Gossip_CiteRadio_Label",
                                    ["utteranceFallback"] = "Caught a broken relay on the emergency frequency calling it an active hazard.",
                                    ["utteranceKey"] = "UI_PNC_Gossip_CiteRadio_Utterance",
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
                                        ["intent"] = "CLARIFY",
                                        ["speechAct"] = "CLARIFY",
                                        ["stateValue"] = "witness",
                                        ["subject"] = "NEWS",
                                    },
                                    ["id"] = "knowledge.gossip.press_witness",
                                    ["labelFallback"] = "Ask bystander to confirm",
                                    ["labelKey"] = "UI_PNC_Gossip_PressWitness_Label",
                                    ["utteranceFallback"] = "Hold on—they were standing right near the turnoff too. Did they see it?",
                                    ["utteranceKey"] = "UI_PNC_Gossip_PressWitness_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["stateValue"] = "protect_source",
                                        ["subject"] = "RUMOR",
                                    },
                                    ["id"] = "knowledge.gossip.protect_source_ref",
                                    ["labelFallback"] = "Protect the source",
                                    ["labelKey"] = "UI_PNC_Gossip_ProtectSource_Label",
                                    ["utteranceFallback"] = "Who told me isn't the point—what matters is staying clear of that corner.",
                                    ["utteranceKey"] = "UI_PNC_Gossip_ProtectSource_Utterance",
                                },
                            },
                            ["onClarify"] = "weigh_rumor",
                            ["onMatch"] = "probe_epistemic_basis",
                            ["onRefuse"] = "refused_rumor",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.knowledge.gossip.exchange.clarify",
                        },
                        ["close_exchange"] = {
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
                                    ["id"] = "knowledge.gossip.thank_word",
                                    ["labelFallback"] = "Thank for the heads-up",
                                    ["labelKey"] = "UI_PNC_Gossip_Thanks_Label",
                                    ["utteranceFallback"] = "Good to know. Anything else over the air or down the road, pass it along.",
                                    ["utteranceKey"] = "UI_PNC_Gossip_Thanks_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "ACCEPT",
                                        ["speechAct"] = "ACCEPT",
                                    },
                                    ["id"] = "knowledge.gossip.agree_share",
                                    ["labelFallback"] = "Promise to share updates",
                                    ["labelKey"] = "UI_PNC_Gossip_AgreeShare_Label",
                                    ["utteranceFallback"] = "Deal—I'll swing back with word if anything shifts around that block.",
                                    ["utteranceKey"] = "UI_PNC_Gossip_AgreeShare_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "REFUSE",
                                        ["speechAct"] = "REFUSE",
                                    },
                                    ["id"] = "knowledge.gossip.stay_silent",
                                    ["labelFallback"] = "Keep own counsel",
                                    ["labelKey"] = "UI_PNC_Gossip_Withdraw_Label",
                                    ["utteranceFallback"] = "Not trading any more talk today. Stay sharp out there.",
                                    ["utteranceKey"] = "UI_PNC_Gossip_Withdraw_Utterance",
                                },
                            },
                            ["onMatch"] = "complete",
                            ["onRefuse"] = "refused_rumor",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.knowledge.gossip.exchange.close",
                        },
                        ["complete"] = {
                            ["responsePool"] = "semantic.knowledge.gossip.exchange.complete",
                            ["terminal"] = true,
                        },
                        ["cross_check_witness"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "AGREE",
                                    ["speechAct"] = "AGREE",
                                    ["stateValue"] = "corroborated",
                                },
                                {
                                    ["intent"] = "ACKNOWLEDGE",
                                    ["speechAct"] = "ACKNOWLEDGE",
                                    ["subject"] = "NEWS",
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
                                        ["op"] = "eq",
                                        ["path"] = "scene.hasThirdPartyWitness",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "AGREE",
                                        ["speechAct"] = "AGREE",
                                        ["stateValue"] = "corroborated",
                                    },
                                    ["id"] = "knowledge.gossip.witness_corroborates",
                                    ["labelFallback"] = "Confirm alongside bystander",
                                    ["labelKey"] = "UI_PNC_Gossip_WitnessCorroborate_Label",
                                    ["utteranceFallback"] = "Right—three separate folks pointing at the same stretch means we reroute.",
                                    ["utteranceKey"] = "UI_PNC_Gossip_WitnessCorroborate_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "ACKNOWLEDGE",
                                        ["speechAct"] = "ACKNOWLEDGE",
                                        ["subject"] = "NEWS",
                                    },
                                    ["id"] = "knowledge.gossip.note_for_patrol",
                                    ["labelFallback"] = "Flag for next patrol",
                                    ["labelKey"] = "UI_PNC_Gossip_NotePatrol_Label",
                                    ["utteranceFallback"] = "Log the location and move on; next team heading east will double-check it.",
                                    ["utteranceKey"] = "UI_PNC_Gossip_NotePatrol_Utterance",
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
                                    ["id"] = "knowledge.gossip.drop_topic",
                                    ["labelFallback"] = "End rumor check",
                                    ["labelKey"] = "UI_PNC_Gossip_DropTopic_Label",
                                    ["utteranceFallback"] = "We've spent enough breath on rumors. Leave it at that.",
                                    ["utteranceKey"] = "UI_PNC_Gossip_DropTopic_Utterance",
                                },
                            },
                            ["onMatch"] = "close_exchange",
                            ["onRefuse"] = "refused_rumor",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.knowledge.gossip.exchange.weigh",
                        },
                        ["probe_epistemic_basis"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["stateValue"] = "environmental",
                                    ["subject"] = "NEWS",
                                },
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["stateValue"] = "witnessed",
                                    ["subject"] = "NEWS",
                                },
                                {
                                    ["intent"] = "CLARIFY",
                                    ["speechAct"] = "CLARIFY",
                                    ["stateValue"] = "uncertain",
                                    ["subject"] = "RUMOR",
                                },
                                {
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                },
                            },
                            ["branchOffers"] = {
                                {
                                    ["constraints"] = {
                                        ["all"] = {
                                            {
                                                ["op"] = "eq",
                                                ["path"] = "environment.isIndoors",
                                                ["value"] = true,
                                            },
                                            {
                                                ["op"] = "eq",
                                                ["path"] = "worldKnowledge.hasHelicopter",
                                                ["value"] = true,
                                            },
                                        },
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["stateValue"] = "environmental",
                                        ["subject"] = "NEWS",
                                    },
                                    ["id"] = "knowledge.gossip.indoor_chopper_heard",
                                    ["labelFallback"] = "Mention hearing it from indoors",
                                    ["labelKey"] = "UI_PNC_Gossip_IndoorHeard_Label",
                                    ["utteranceFallback"] = "Walls shook right overhead while I was shut inside, though I couldn't see its course.",
                                    ["utteranceKey"] = "UI_PNC_Gossip_IndoorHeard_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["all"] = {
                                            {
                                                ["op"] = "eq",
                                                ["path"] = "environment.isIndoors",
                                                ["value"] = false,
                                            },
                                            {
                                                ["op"] = "eq",
                                                ["path"] = "worldKnowledge.hasStoryDiscovery",
                                                ["value"] = true,
                                            },
                                        },
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["stateValue"] = "witnessed",
                                        ["subject"] = "NEWS",
                                    },
                                    ["id"] = "knowledge.gossip.outdoor_crash_seen",
                                    ["labelFallback"] = "Describe scene witnessed outdoors",
                                    ["labelKey"] = "UI_PNC_Gossip_OutdoorSeen_Label",
                                    ["utteranceFallback"] = "Passed the wreck out in the open—flashing lights dead, supplies scattered across the lane.",
                                    ["utteranceKey"] = "UI_PNC_Gossip_OutdoorSeen_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "CLARIFY",
                                        ["speechAct"] = "CLARIFY",
                                        ["stateValue"] = "uncertain",
                                        ["subject"] = "RUMOR",
                                    },
                                    ["id"] = "knowledge.gossip.challenge_hearsay",
                                    ["labelFallback"] = "Point out gaps in story",
                                    ["labelKey"] = "UI_PNC_Gossip_ChallengeHearsay_Label",
                                    ["utteranceFallback"] = "That sounds patched together secondhand. Which block are we actually talking about?",
                                    ["utteranceKey"] = "UI_PNC_Gossip_ChallengeHearsay_Utterance",
                                },
                            },
                            ["onClarify"] = "cross_check_witness",
                            ["onMatch"] = "weigh_rumor",
                            ["onRefuse"] = "refused_rumor",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.knowledge.gossip.exchange.clarify",
                        },
                        ["refused_rumor"] = {
                            ["responsePool"] = "semantic.knowledge.gossip.exchange.refused",
                            ["terminal"] = true,
                        },
                        ["weigh_rumor"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "AGREE",
                                    ["speechAct"] = "AGREE",
                                    ["stateValue"] = "corroborated",
                                },
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["stateValue"] = "uncertain",
                                    ["subject"] = "RUMOR",
                                },
                                {
                                    ["intent"] = "DISAGREE",
                                    ["speechAct"] = "DISAGREE",
                                    ["stateValue"] = "contradicted",
                                    ["subject"] = "RUMOR",
                                },
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["stateValue"] = "reveal_source",
                                    ["subject"] = "NEWS",
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
                                        ["intent"] = "AGREE",
                                        ["speechAct"] = "AGREE",
                                        ["stateValue"] = "corroborated",
                                    },
                                    ["id"] = "knowledge.gossip.mark_known",
                                    ["labelFallback"] = "Corroborate the account",
                                    ["labelKey"] = "UI_PNC_Gossip_Confirm_Label",
                                    ["utteranceFallback"] = "Lines up with everything we've seen near that bend—worth treating as fact.",
                                    ["utteranceKey"] = "UI_PNC_Gossip_Confirm_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["stateValue"] = "uncertain",
                                        ["subject"] = "RUMOR",
                                    },
                                    ["id"] = "knowledge.gossip.mark_uncertain",
                                    ["labelFallback"] = "Flag as unverified",
                                    ["labelKey"] = "UI_PNC_Gossip_Doubt_Label",
                                    ["utteranceFallback"] = "Could be real, could be nerves playing tricks. Let's mark it unconfirmed.",
                                    ["utteranceKey"] = "UI_PNC_Gossip_Doubt_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "DISAGREE",
                                        ["speechAct"] = "DISAGREE",
                                        ["stateValue"] = "contradicted",
                                        ["subject"] = "RUMOR",
                                    },
                                    ["id"] = "knowledge.gossip.contradict_claim",
                                    ["labelFallback"] = "Contradict bad intel",
                                    ["labelKey"] = "UI_PNC_Gossip_Contradict_Label",
                                    ["utteranceFallback"] = "I walked past that street this morning—none of that wreck story holds up.",
                                    ["utteranceKey"] = "UI_PNC_Gossip_Contradict_Utterance",
                                },
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
                                        ["subject"] = "NEWS",
                                    },
                                    ["id"] = "knowledge.gossip.vouch_trusted",
                                    ["labelFallback"] = "Share source privately",
                                    ["labelKey"] = "UI_PNC_Gossip_VouchTrusted_Label",
                                    ["utteranceFallback"] = "Between us, it came from our own scout before dawn—so keep your guard up.",
                                    ["utteranceKey"] = "UI_PNC_Gossip_VouchTrusted_Utterance",
                                },
                            },
                            ["onClarify"] = "close_exchange",
                            ["onMatch"] = "cross_check_witness",
                            ["onRefuse"] = "refused_rumor",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.knowledge.gossip.exchange.weigh",
                            ["slots"] = {
                                ["item"] = {
                                    ["owner"] = "inventory",
                                    ["source"] = "slots.item",
                                    ["type"] = "string",
                                },
                            },
                        },
                    },
                    ["owner"] = "ProjectHoomans",
                    ["version"] = 1,
                },
                ["outcomes"] = {
                    "known",
                    "unknown",
                    "uncertain",
                    "refused",
                    "corroborated",
                    "contradicted",
                    "reveal_source",
                    "protect_source",
                    "withdraw",
                },
                ["replySemantics"] = {
                    ["blocked"] = {
                        ["outcome"] = "blocked",
                        ["stance"] = "negative",
                    },
                    ["contradicted"] = {
                        ["outcome"] = "contradicted",
                        ["stance"] = "negative",
                    },
                    ["corroborated"] = {
                        ["outcome"] = "corroborated",
                        ["stance"] = "positive",
                    },
                    ["known"] = {
                        ["outcome"] = "known",
                        ["stance"] = "positive",
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
                    ["uncertain"] = {
                        ["outcome"] = "uncertain",
                        ["stance"] = "contextual",
                    },
                    ["unknown"] = {
                        ["outcome"] = "unknown",
                        ["stance"] = "neutral",
                    },
                    ["withdraw"] = {
                        ["outcome"] = "withdraw",
                        ["stance"] = "negative",
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
                        ["subject"] = "NEWS",
                    },
                    {
                        ["intent"] = "QUESTION",
                        ["subject"] = "RUMOR",
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
                                        ["fallback"] = "Not the time for rumors—keep your head down.",
                                        ["id"] = "default",
                                    },
                                    {
                                        ["fallback"] = "Save the chatter. Watch the street.",
                                        ["id"] = "negative",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["contradicted"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "combat.aftermath.debrief_exchange",
                        },
                    },
                    ["outcome"] = "contradicted",
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
                                        ["fallback"] = "No, that doesn't square with what happened there. Somebody fed you a bad steer.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["corroborated"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "travel.excursion.plan_exchange",
                            "colony.work.status_exchange",
                        },
                    },
                    ["outcome"] = "corroborated",
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
                                        ["fallback"] = "That tracks with what I witnessed near {slot.location}, {addressee.name}. Same signs, same direction.",
                                        ["id"] = "default",
                                    },
                                    {
                                        ["fallback"] = "Both reports line up—between the emergency broadcast and firsthand sightings out by {slot.location}, we know it's real.",
                                        ["id"] = "contextual",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["known"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "travel.excursion.plan_exchange",
                            "colony.work.status_exchange",
                        },
                    },
                    ["outcome"] = "known",
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
                                        ["fallback"] = "Yeah, I saw that myself—{slot.location} is choked up, so steer clear if you're smart.",
                                        ["id"] = "default",
                                    },
                                    {
                                        ["fallback"] = "Actually, yes—{addressee.name}, word is solid on that. Worth keeping in your pocket.",
                                        ["id"] = "positive",
                                    },
                                    {
                                        ["fallback"] = "Can vouch for part of it, {addressee.name}: saw fresh tracks and open shutters near {slot.location} yesterday.",
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
                                        ["fallback"] = "Doesn't matter who brought word in. Take the warning, skip asking for names.",
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
                                        ["fallback"] = "I don't trade in gossip. Ask somebody else.",
                                        ["id"] = "default",
                                    },
                                    {
                                        ["fallback"] = "Keep me out of it. Word gets around, and so does trouble.",
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
                            "social.identity.personal_history",
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
                                        ["fallback"] = "I trust you enough to say it straight: spotted it with my own eyes along the shoulder past dusk.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["uncertain"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "social.conflict.mediate_exchange",
                        },
                    },
                    ["outcome"] = "uncertain",
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
                                        ["fallback"] = "Heard folks talking about it, sure, but nobody I'd bet my boots on.",
                                        ["id"] = "default",
                                    },
                                    {
                                        ["fallback"] = "Could be true, could be somebody spooked by shadows. Treat it like a rumor until you see it.",
                                        ["id"] = "contextual",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["unknown"] = {
                    ["outcome"] = "unknown",
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
                                        ["fallback"] = "Couldn't tell you. Haven't heard a peep about that.",
                                        ["id"] = "default",
                                    },
                                    {
                                        ["fallback"] = "No idea—I've been keeping my head down on this block, haven't caught any news.",
                                        ["id"] = "neutral",
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
                                        ["fallback"] = "Look, drop it. We've both got ears and too much road left to argue rumor.",
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
                                ["fallback"] = "Heard any word from down the road? Trying to piece together what's still standing.",
                                ["id"] = "default",
                            },
                            {
                                ["fallback"] = "Good catching you here, {addressee.name}—heard anything useful about clear roads or decent supplies nearby?",
                                ["id"] = "positive",
                            },
                            {
                                ["fallback"] = "What's the word around here lately—anything moving on the highway or near town?",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Lot of wild rumors flying around lately. You heard anything that actually checks out?",
                                ["id"] = "negative",
                            },
                            {
                                ["fallback"] = "Saw smoke rising east of the river earlier, and the chopper's been rattling nerves all week. Heard anything?",
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
                    ["admission"] = "no_op",
                    ["id"] = "blocked_uninformed",
                    ["outcome"] = "blocked",
                    ["reason"] = "uninformed",
                    ["replyOutcome"] = "unknown",
                    ["when"] = {
                        ["op"] = "eq",
                        ["path"] = "npcState.uninformed",
                        ["value"] = true,
                    },
                },
                {
                    ["admission"] = "dispatch",
                    ["id"] = "gossip_exchange_ready",
                    ["outcome"] = "actionable",
                    ["reason"] = "ready",
                },
            },
            ["topics"] = {
                {
                    ["domain"] = "knowledge",
                    ["id"] = "news",
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
            ["responsePlanID"] = "knowledge.gossip.exchange",
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
                            ["fallback"] = "Heard any word from down the road? Trying to piece together what's still standing.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.knowledge.gossip.exchange.say_1",
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
        ["sourceShard"] = "dialogue/thematic_interactive/knowledge_gossip_exchange.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Heard any word from down the road? Trying to piece together what's still standing.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.knowledge.gossip.exchange.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Good catching you here, {addressee.name}—heard anything useful about clear roads or decent supplies nearby?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.knowledge.gossip.exchange.say.1.positive",
                ["variantID"] = "positive",
            },
            {
                ["fallback"] = "What's the word around here lately—anything moving on the highway or near town?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.knowledge.gossip.exchange.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Lot of wild rumors flying around lately. You heard anything that actually checks out?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.knowledge.gossip.exchange.say.1.negative",
                ["variantID"] = "negative",
            },
            {
                ["fallback"] = "Saw smoke rising east of the river earlier, and the chopper's been rattling nerves all week. Heard anything?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.knowledge.gossip.exchange.say.1.contextual",
                ["variantID"] = "contextual",
            },
            {
                ["fallback"] = "Not the time for rumors—keep your head down.",
                ["outcome"] = "blocked",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.knowledge.gossip.exchange.reply.blocked.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Save the chatter. Watch the street.",
                ["outcome"] = "blocked",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.knowledge.gossip.exchange.reply.blocked.say.1.negative",
                ["variantID"] = "negative",
            },
            {
                ["fallback"] = "No, that doesn't square with what happened there. Somebody fed you a bad steer.",
                ["outcome"] = "contradicted",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.knowledge.gossip.exchange.reply.contradicted.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "That tracks with what I witnessed near {slot.location}, {addressee.name}. Same signs, same direction.",
                ["outcome"] = "corroborated",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.knowledge.gossip.exchange.reply.corroborated.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Both reports line up—between the emergency broadcast and firsthand sightings out by {slot.location}, we know it's real.",
                ["outcome"] = "corroborated",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.knowledge.gossip.exchange.reply.corroborated.say.1.contextual",
                ["variantID"] = "contextual",
            },
            {
                ["fallback"] = "Yeah, I saw that myself—{slot.location} is choked up, so steer clear if you're smart.",
                ["outcome"] = "known",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.knowledge.gossip.exchange.reply.known.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Actually, yes—{addressee.name}, word is solid on that. Worth keeping in your pocket.",
                ["outcome"] = "known",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.knowledge.gossip.exchange.reply.known.say.1.positive",
                ["variantID"] = "positive",
            },
            {
                ["fallback"] = "Can vouch for part of it, {addressee.name}: saw fresh tracks and open shutters near {slot.location} yesterday.",
                ["outcome"] = "known",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.knowledge.gossip.exchange.reply.known.say.1.contextual",
                ["variantID"] = "contextual",
            },
            {
                ["fallback"] = "Doesn't matter who brought word in. Take the warning, skip asking for names.",
                ["outcome"] = "protect_source",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.knowledge.gossip.exchange.reply.protect_source.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I don't trade in gossip. Ask somebody else.",
                ["outcome"] = "refused",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.knowledge.gossip.exchange.reply.refused.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Keep me out of it. Word gets around, and so does trouble.",
                ["outcome"] = "refused",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.knowledge.gossip.exchange.reply.refused.say.1.negative",
                ["variantID"] = "negative",
            },
            {
                ["fallback"] = "I trust you enough to say it straight: spotted it with my own eyes along the shoulder past dusk.",
                ["outcome"] = "reveal_source",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.knowledge.gossip.exchange.reply.reveal_source.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Heard folks talking about it, sure, but nobody I'd bet my boots on.",
                ["outcome"] = "uncertain",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.knowledge.gossip.exchange.reply.uncertain.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Could be true, could be somebody spooked by shadows. Treat it like a rumor until you see it.",
                ["outcome"] = "uncertain",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.knowledge.gossip.exchange.reply.uncertain.say.1.contextual",
                ["variantID"] = "contextual",
            },
            {
                ["fallback"] = "Couldn't tell you. Haven't heard a peep about that.",
                ["outcome"] = "unknown",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.knowledge.gossip.exchange.reply.unknown.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "No idea—I've been keeping my head down on this block, haven't caught any news.",
                ["outcome"] = "unknown",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.knowledge.gossip.exchange.reply.unknown.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Look, drop it. We've both got ears and too much road left to argue rumor.",
                ["outcome"] = "withdraw",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.knowledge.gossip.exchange.reply.withdraw.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "thematic_interactive",
        ["domainPath"] = "thematic_interactive",
        ["exchangeFamily"] = {
            ["familyID"] = "social.conflict.mediate_exchange",
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
                                ["fallback"] = "Everyone's snapping at each other over the watch schedule and the pantry, {addressee.name}. We need to sort this out before someone walks out.",
                                ["id"] = "default",
                                ["templateID"] = "convo.social.conflict.mediate_exchange.say.1.default",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.conflict",
            ["replies"] = {
                ["acknowledged"] = {
                    ["outcome"] = "acknowledged",
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
                                        ["fallback"] = "I hear you, {addressee.name}. Nobody's trying to shortchange anyone here—we just need clearer rules.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.conflict.mediate_exchange.reply.acknowledged.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["apologize"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "colony.work.status_exchange",
                        },
                    },
                    ["outcome"] = "apologize",
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
                                        ["fallback"] = "You're right—I snapped too hard over the rations. That one's on me, {addressee.name}.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.conflict.mediate_exchange.reply.apologize.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["challenge"] = {
                    ["outcome"] = "challenge",
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
                                        ["fallback"] = "Say that again to my face if you think I'm the one cutting corners around here.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.conflict.mediate_exchange.reply.challenge.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["defend"] = {
                    ["outcome"] = "defend",
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
                                        ["fallback"] = "Hold on—I didn't pocket anything. Somebody moved the crates before dawn watch.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.conflict.mediate_exchange.reply.defend.say.1.default",
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
                    ["after"] = {
                        ["recommend"] = {
                            "wellbeing.needs.checkin",
                        },
                    },
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
                                        ["fallback"] = "Fine. Let's cool off and talk about it after we've both had some water and rest.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.conflict.mediate_exchange.reply.deferred.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["mediate"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "colony.work.status_exchange",
                        },
                    },
                    ["outcome"] = "mediate",
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
                                        ["fallback"] = "Both sides have a point—put the ledger out on the table and we reset shifts fair.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.conflict.mediate_exchange.reply.mediate.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["reconciled"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "colony.work.status_exchange",
                        },
                    },
                    ["outcome"] = "reconciled",
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
                                        ["fallback"] = "Alright, {addressee.name}. We're all tired and short on sleep. Let's split the watch evenly and drop it.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.conflict.mediate_exchange.reply.reconciled.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["strained"] = {
                    ["outcome"] = "strained",
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
                                        ["fallback"] = "Forget it. Not much point talking when nobody's listening.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.conflict.mediate_exchange.reply.strained.say.1.default",
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
                                        ["fallback"] = "Stepping out before this turns into shouting that brings walkers to the fence.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.conflict.mediate_exchange.reply.withdraw.say.1.default",
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
                    ["fallback"] = "Everyone's snapping at each other over the watch schedule and the pantry, {addressee.name}. We need to sort this out before someone walks out.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.conflict.mediate_exchange.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I hear you, {addressee.name}. Nobody's trying to shortchange anyone here—we just need clearer rules.",
                    ["outcome"] = "acknowledged",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.conflict.mediate_exchange.reply.acknowledged.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "You're right—I snapped too hard over the rations. That one's on me, {addressee.name}.",
                    ["outcome"] = "apologize",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.conflict.mediate_exchange.reply.apologize.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Say that again to my face if you think I'm the one cutting corners around here.",
                    ["outcome"] = "challenge",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.conflict.mediate_exchange.reply.challenge.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Hold on—I didn't pocket anything. Somebody moved the crates before dawn watch.",
                    ["outcome"] = "defend",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.conflict.mediate_exchange.reply.defend.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Fine. Let's cool off and talk about it after we've both had some water and rest.",
                    ["outcome"] = "deferred",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.conflict.mediate_exchange.reply.deferred.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Both sides have a point—put the ledger out on the table and we reset shifts fair.",
                    ["outcome"] = "mediate",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.conflict.mediate_exchange.reply.mediate.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Alright, {addressee.name}. We're all tired and short on sleep. Let's split the watch evenly and drop it.",
                    ["outcome"] = "reconciled",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.conflict.mediate_exchange.reply.reconciled.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Forget it. Not much point talking when nobody's listening.",
                    ["outcome"] = "strained",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.conflict.mediate_exchange.reply.strained.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Stepping out before this turns into shouting that brings walkers to the fence.",
                    ["outcome"] = "withdraw",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.conflict.mediate_exchange.reply.withdraw.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "social.conflict.mediate_exchange",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "mediate_exchange",
            ["sourceId"] = "social.conflict.mediate_exchange",
            ["sourcePath"] = "dialogue/thematic_interactive/relationship_conflict_exchange.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ThematicInteractive/KnowledgeGossipExchangeToSocialConflictMediateExchange",
        ["namespace"] = "social.conflict",
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
                ["episodeId"] = "social_conflict_mediate_exchange",
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
                                ["op"] = "not_in",
                                ["path"] = "npcState.healthState",
                                ["values"] = {
                                    "dead",
                                    "incapacitated",
                                },
                            },
                        },
                    },
                    ["id"] = "social.conflict.mediate_exchange",
                    ["initial"] = "air_grievance",
                    ["nodes"] = {
                        ["air_grievance"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "ACKNOWLEDGE",
                                    ["speechAct"] = "ACKNOWLEDGE",
                                    ["subject"] = "CONFLICT",
                                },
                                {
                                    ["intent"] = "DISAGREE",
                                    ["speechAct"] = "DISAGREE",
                                    ["stateValue"] = "defend",
                                    ["subject"] = "CONFLICT",
                                },
                                {
                                    ["intent"] = "CHALLENGE",
                                    ["speechAct"] = "CHALLENGE",
                                    ["stateValue"] = "challenge",
                                    ["subject"] = "CONFLICT",
                                },
                                {
                                    ["intent"] = "CLARIFY",
                                    ["speechAct"] = "CLARIFY",
                                    ["stateValue"] = "mediate",
                                    ["subject"] = "CONFLICT",
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
                                        ["intent"] = "ACKNOWLEDGE",
                                        ["speechAct"] = "ACKNOWLEDGE",
                                        ["subject"] = "CONFLICT",
                                    },
                                    ["id"] = "social.conflict.listen_calmly",
                                    ["labelFallback"] = "Hear both sides calmly",
                                    ["labelKey"] = "UI_PNC_SocialConflict_Listen_Label",
                                    ["utteranceFallback"] = "Slow down and lay out what set this off without yelling.",
                                    ["utteranceKey"] = "UI_PNC_SocialConflict_Listen_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "DISAGREE",
                                        ["speechAct"] = "DISAGREE",
                                        ["stateValue"] = "defend",
                                        ["subject"] = "CONFLICT",
                                    },
                                    ["id"] = "social.conflict.push_back",
                                    ["labelFallback"] = "Push back on accusation",
                                    ["labelKey"] = "UI_PNC_SocialConflict_PushBack_Label",
                                    ["utteranceFallback"] = "Don't pin missed watch on me when nobody checked the chalkboard.",
                                    ["utteranceKey"] = "UI_PNC_SocialConflict_PushBack_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "gte",
                                        ["path"] = "disposition.aggression",
                                        ["value"] = 55,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "CHALLENGE",
                                        ["speechAct"] = "CHALLENGE",
                                        ["stateValue"] = "challenge",
                                        ["subject"] = "CONFLICT",
                                    },
                                    ["id"] = "social.conflict.challenge_bluntly",
                                    ["labelFallback"] = "Confront aggressive behavior",
                                    ["labelKey"] = "UI_PNC_SocialConflict_Challenge_Label",
                                    ["utteranceFallback"] = "Drop the tone right now—shouting won't fix an empty shelf.",
                                    ["utteranceKey"] = "UI_PNC_SocialConflict_Challenge_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "eq",
                                        ["path"] = "scene.hasThirdPartyMediator",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "CLARIFY",
                                        ["speechAct"] = "CLARIFY",
                                        ["stateValue"] = "mediate",
                                        ["subject"] = "CONFLICT",
                                    },
                                    ["id"] = "social.conflict.invite_mediator",
                                    ["labelFallback"] = "Ask third party to weigh in",
                                    ["labelKey"] = "UI_PNC_SocialConflict_InviteMediator_Label",
                                    ["utteranceFallback"] = "They've been watching this whole morning—let them say what actually happened.",
                                    ["utteranceKey"] = "UI_PNC_SocialConflict_InviteMediator_Utterance",
                                },
                            },
                            ["onClarify"] = "witness_mediation",
                            ["onMatch"] = "clarify_responsibility",
                            ["onRefuse"] = "strained",
                            ["onUnrelated"] = "suspend",
                            ["slots"] = {
                                ["person"] = {
                                    ["owner"] = "social.conflict.mediate_exchange",
                                    ["source"] = "slots.person.value",
                                    ["type"] = "string",
                                },
                                ["task"] = {
                                    ["owner"] = "social.conflict.mediate_exchange",
                                    ["source"] = "slots.task.value",
                                    ["type"] = "string",
                                },
                            },
                        },
                        ["clarify_responsibility"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "APOLOGIZE",
                                    ["speechAct"] = "APOLOGIZE",
                                    ["stateValue"] = "apologize",
                                    ["subject"] = "CONFLICT",
                                },
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["stateValue"] = "defend",
                                    ["subject"] = "CONFLICT",
                                },
                                {
                                    ["intent"] = "SUGGEST",
                                    ["speechAct"] = "SUGGEST",
                                    ["stateValue"] = "mediate",
                                    ["subject"] = "CONFLICT",
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
                                        ["path"] = "disposition.forgiveness",
                                        ["value"] = 45,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "APOLOGIZE",
                                        ["speechAct"] = "APOLOGIZE",
                                        ["stateValue"] = "apologize",
                                        ["subject"] = "CONFLICT",
                                    },
                                    ["id"] = "social.conflict.offer_apology",
                                    ["labelFallback"] = "Own your part and apologize",
                                    ["labelKey"] = "UI_PNC_SocialConflict_Apologize_Label",
                                    ["utteranceFallback"] = "My fault—nerves got ahead of sense. Let's square it cleanly.",
                                    ["utteranceKey"] = "UI_PNC_SocialConflict_Apologize_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["stateValue"] = "defend",
                                        ["subject"] = "CONFLICT",
                                    },
                                    ["id"] = "social.conflict.defend_action",
                                    ["labelFallback"] = "Explain why you moved supplies",
                                    ["labelKey"] = "UI_PNC_SocialConflict_Defend_Label",
                                    ["utteranceFallback"] = "Moved the cans off the wet floor, not to hoard them.",
                                    ["utteranceKey"] = "UI_PNC_SocialConflict_Defend_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "SUGGEST",
                                        ["speechAct"] = "SUGGEST",
                                        ["stateValue"] = "mediate",
                                        ["subject"] = "CONFLICT",
                                    },
                                    ["id"] = "social.conflict.request_mediation",
                                    ["labelFallback"] = "Propose written roster reset",
                                    ["labelKey"] = "UI_PNC_SocialConflict_ReqMediate_Label",
                                    ["utteranceFallback"] = "Write every shift down cleanly on paper so there's zero guessing.",
                                    ["utteranceKey"] = "UI_PNC_SocialConflict_ReqMediate_Utterance",
                                },
                            },
                            ["onClarify"] = "witness_mediation",
                            ["onMatch"] = "seek_middle_ground",
                            ["onRefuse"] = "strained",
                            ["onUnrelated"] = "suspend",
                        },
                        ["reconciled"] = {
                            ["terminal"] = true,
                        },
                        ["seek_middle_ground"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "RECONCILE",
                                    ["speechAct"] = "RECONCILE",
                                    ["subject"] = "CONFLICT",
                                },
                                {
                                    ["intent"] = "DEFER",
                                    ["speechAct"] = "DEFER",
                                    ["subject"] = "CONFLICT",
                                },
                                {
                                    ["intent"] = "ACKNOWLEDGE",
                                    ["speechAct"] = "ACKNOWLEDGE",
                                    ["subject"] = "CONFLICT",
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
                                        ["value"] = -20,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "RECONCILE",
                                        ["speechAct"] = "RECONCILE",
                                        ["subject"] = "CONFLICT",
                                    },
                                    ["id"] = "social.conflict.reconcile",
                                    ["labelFallback"] = "Settle differences and reset",
                                    ["labelKey"] = "UI_PNC_SocialConflict_Reconcile_Label",
                                    ["utteranceFallback"] = "Shake on even shifts and put it behind us—we need both heads clear.",
                                    ["utteranceKey"] = "UI_PNC_SocialConflict_Reconcile_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "DEFER",
                                        ["speechAct"] = "DEFER",
                                        ["subject"] = "CONFLICT",
                                    },
                                    ["id"] = "social.conflict.cool_off",
                                    ["labelFallback"] = "Postpone until calmer",
                                    ["labelKey"] = "UI_PNC_SocialConflict_CoolOff_Label",
                                    ["utteranceFallback"] = "Give it an hour after supper and talk straight then.",
                                    ["utteranceKey"] = "UI_PNC_SocialConflict_CoolOff_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "ACKNOWLEDGE",
                                        ["speechAct"] = "ACKNOWLEDGE",
                                        ["subject"] = "CONFLICT",
                                    },
                                    ["id"] = "social.conflict.keep_distance",
                                    ["labelFallback"] = "Work apart for today",
                                    ["labelKey"] = "UI_PNC_SocialConflict_Distance_Label",
                                    ["utteranceFallback"] = "Fine, take separate walls today so we stop stepping on each other.",
                                    ["utteranceKey"] = "UI_PNC_SocialConflict_Distance_Utterance",
                                },
                            },
                            ["onClarify"] = "withdrawn",
                            ["onMatch"] = "reconciled",
                            ["onRefuse"] = "strained",
                            ["onUnrelated"] = "suspend",
                        },
                        ["strained"] = {
                            ["terminal"] = true,
                        },
                        ["withdrawn"] = {
                            ["terminal"] = true,
                        },
                        ["witness_mediation"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "AGREE",
                                    ["speechAct"] = "AGREE",
                                    ["stateValue"] = "mediate",
                                    ["subject"] = "CONFLICT",
                                },
                                {
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                    ["stateValue"] = "refuse_intervention",
                                    ["subject"] = "CONFLICT",
                                },
                                {
                                    ["intent"] = "DEFER",
                                    ["speechAct"] = "DEFER",
                                    ["stateValue"] = "withdraw",
                                    ["subject"] = "CONFLICT",
                                },
                                {
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                },
                            },
                            ["branchOffers"] = {
                                {
                                    ["constraints"] = {
                                        ["op"] = "eq",
                                        ["path"] = "scene.hasThirdPartyMediator",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "AGREE",
                                        ["speechAct"] = "AGREE",
                                        ["stateValue"] = "mediate",
                                        ["subject"] = "CONFLICT",
                                    },
                                    ["id"] = "social.conflict.accept_mediation",
                                    ["labelFallback"] = "Follow mediator proposal",
                                    ["labelKey"] = "UI_PNC_SocialConflict_AcceptMediate_Label",
                                    ["utteranceFallback"] = "Fine—we follow the bystander's rotation and drop the grudge.",
                                    ["utteranceKey"] = "UI_PNC_SocialConflict_AcceptMediate_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "REFUSE",
                                        ["speechAct"] = "REFUSE",
                                        ["stateValue"] = "refuse_intervention",
                                        ["subject"] = "CONFLICT",
                                    },
                                    ["id"] = "social.conflict.refuse_meddling",
                                    ["labelFallback"] = "Reject outside meddling",
                                    ["labelKey"] = "UI_PNC_SocialConflict_RefuseMeddle_Label",
                                    ["utteranceFallback"] = "Stay out of it—this is between the two of us.",
                                    ["utteranceKey"] = "UI_PNC_SocialConflict_RefuseMeddle_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "DEFER",
                                        ["speechAct"] = "DEFER",
                                        ["stateValue"] = "withdraw",
                                        ["subject"] = "CONFLICT",
                                    },
                                    ["id"] = "social.conflict.cool_off_walk",
                                    ["labelFallback"] = "Walk away to cool down",
                                    ["labelKey"] = "UI_PNC_SocialConflict_StepOut_Label",
                                    ["utteranceFallback"] = "Taking ten outside before I say something we can't walk back.",
                                    ["utteranceKey"] = "UI_PNC_SocialConflict_StepOut_Utterance",
                                },
                            },
                            ["onMatch"] = "seek_middle_ground",
                            ["onRefuse"] = "withdrawn",
                            ["onUnrelated"] = "suspend",
                        },
                    },
                    ["owner"] = "ProjectHoomans",
                    ["version"] = 1,
                },
                ["replySemantics"] = {
                    ["acknowledged"] = {
                        ["outcome"] = "acknowledged",
                        ["stance"] = "neutral",
                    },
                    ["apologize"] = {
                        ["outcome"] = "apologize",
                        ["stance"] = "positive",
                    },
                    ["challenge"] = {
                        ["outcome"] = "challenge",
                        ["stance"] = "negative",
                    },
                    ["defend"] = {
                        ["outcome"] = "defend",
                        ["stance"] = "contextual",
                    },
                    ["deferred"] = {
                        ["outcome"] = "deferred",
                        ["stance"] = "contextual",
                    },
                    ["mediate"] = {
                        ["outcome"] = "mediate",
                        ["stance"] = "positive",
                    },
                    ["reconciled"] = {
                        ["outcome"] = "reconciled",
                        ["stance"] = "positive",
                    },
                    ["strained"] = {
                        ["outcome"] = "strained",
                        ["stance"] = "negative",
                    },
                    ["withdraw"] = {
                        ["outcome"] = "withdraw",
                        ["stance"] = "neutral",
                    },
                },
                ["triggers"] = {
                    {
                        ["intent"] = "COMPLAIN",
                        ["subject"] = "CONFLICT",
                    },
                    {
                        ["intent"] = "MEDIATION",
                        ["subject"] = "CONFLICT",
                    },
                },
            },
            ["repeatPolicy"] = "repeatable",
            ["reply"] = {
                ["acknowledged"] = {
                    ["outcome"] = "acknowledged",
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
                                        ["fallback"] = "I hear you, {addressee.name}. Nobody's trying to shortchange anyone here—we just need clearer rules.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["apologize"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "colony.work.status_exchange",
                        },
                    },
                    ["outcome"] = "apologize",
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
                                        ["fallback"] = "You're right—I snapped too hard over the rations. That one's on me, {addressee.name}.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["challenge"] = {
                    ["outcome"] = "challenge",
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
                                        ["fallback"] = "Say that again to my face if you think I'm the one cutting corners around here.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["defend"] = {
                    ["outcome"] = "defend",
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
                                        ["fallback"] = "Hold on—I didn't pocket anything. Somebody moved the crates before dawn watch.",
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
                    ["after"] = {
                        ["recommend"] = {
                            "wellbeing.needs.checkin",
                        },
                    },
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
                                        ["fallback"] = "Fine. Let's cool off and talk about it after we've both had some water and rest.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["mediate"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "colony.work.status_exchange",
                        },
                    },
                    ["outcome"] = "mediate",
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
                                        ["fallback"] = "Both sides have a point—put the ledger out on the table and we reset shifts fair.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["reconciled"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "colony.work.status_exchange",
                        },
                    },
                    ["outcome"] = "reconciled",
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
                                        ["fallback"] = "Alright, {addressee.name}. We're all tired and short on sleep. Let's split the watch evenly and drop it.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["strained"] = {
                    ["outcome"] = "strained",
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
                                        ["fallback"] = "Forget it. Not much point talking when nobody's listening.",
                                        ["id"] = "default",
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
                                        ["fallback"] = "Stepping out before this turns into shouting that brings walkers to the fence.",
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
                                ["fallback"] = "Everyone's snapping at each other over the watch schedule and the pantry, {addressee.name}. We need to sort this out before someone walks out.",
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
                    ["replyOutcome"] = "strained",
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
                    ["id"] = "social_conflict_ready",
                    ["outcome"] = "actionable",
                    ["reason"] = "ready",
                },
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "relationship_conflict",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.conflict.mediate_exchange",
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
                            ["fallback"] = "Everyone's snapping at each other over the watch schedule and the pantry, {addressee.name}. We need to sort this out before someone walks out.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.conflict.mediate_exchange.say_1",
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
        ["sourceShard"] = "dialogue/thematic_interactive/relationship_conflict_exchange.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Everyone's snapping at each other over the watch schedule and the pantry, {addressee.name}. We need to sort this out before someone walks out.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.conflict.mediate_exchange.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I hear you, {addressee.name}. Nobody's trying to shortchange anyone here—we just need clearer rules.",
                ["outcome"] = "acknowledged",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.conflict.mediate_exchange.reply.acknowledged.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "You're right—I snapped too hard over the rations. That one's on me, {addressee.name}.",
                ["outcome"] = "apologize",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.conflict.mediate_exchange.reply.apologize.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Say that again to my face if you think I'm the one cutting corners around here.",
                ["outcome"] = "challenge",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.conflict.mediate_exchange.reply.challenge.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Hold on—I didn't pocket anything. Somebody moved the crates before dawn watch.",
                ["outcome"] = "defend",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.conflict.mediate_exchange.reply.defend.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Fine. Let's cool off and talk about it after we've both had some water and rest.",
                ["outcome"] = "deferred",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.conflict.mediate_exchange.reply.deferred.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Both sides have a point—put the ledger out on the table and we reset shifts fair.",
                ["outcome"] = "mediate",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.conflict.mediate_exchange.reply.mediate.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Alright, {addressee.name}. We're all tired and short on sleep. Let's split the watch evenly and drop it.",
                ["outcome"] = "reconciled",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.conflict.mediate_exchange.reply.reconciled.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Forget it. Not much point talking when nobody's listening.",
                ["outcome"] = "strained",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.conflict.mediate_exchange.reply.strained.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Stepping out before this turns into shouting that brings walkers to the fence.",
                ["outcome"] = "withdraw",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.conflict.mediate_exchange.reply.withdraw.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
}
