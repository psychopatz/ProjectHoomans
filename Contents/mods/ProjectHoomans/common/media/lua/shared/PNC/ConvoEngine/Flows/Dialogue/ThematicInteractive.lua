-- Generated; do not edit by hand.
return {
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
        ["domain"] = "semantic",
        ["id"] = "colony.work.status_exchange",
        ["initial"] = "check_chore_status",
        ["nodes"] = {
            ["agreed"] = {
                ["terminal"] = true,
            },
            ["check_chore_status"] = {
                ["accepts"] = {
                    {
                        ["intent"] = "OFFER",
                        ["speechAct"] = "OFFER",
                        ["subject"] = "COLONY_WORK",
                    },
                    {
                        ["intent"] = "SUGGEST",
                        ["speechAct"] = "SUGGEST",
                        ["stateValue"] = "deferred",
                        ["subject"] = "COLONY_WORK",
                    },
                    {
                        ["intent"] = "CLARIFY",
                        ["speechAct"] = "CLARIFY",
                        ["subject"] = "COLONY_WORK",
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
                            ["subject"] = "COLONY_WORK",
                        },
                        ["id"] = "colony.work.offer_help",
                        ["labelFallback"] = "Pitch in on the chore",
                        ["labelKey"] = "UI_PNC_ColonyWork_OfferHelp_Label",
                        ["utteranceFallback"] = "Need another pair of hands on that?",
                        ["utteranceKey"] = "UI_PNC_ColonyWork_OfferHelp_Utterance",
                    },
                    {
                        ["consumers"] = {
                            "participant",
                        },
                        ["frame"] = {
                            ["intent"] = "CLARIFY",
                            ["speechAct"] = "CLARIFY",
                            ["subject"] = "COLONY_WORK",
                        },
                        ["id"] = "colony.work.clarify_task",
                        ["labelFallback"] = "Ask which job needs doing",
                        ["labelKey"] = "UI_PNC_ColonyWork_ClarifyTask_Label",
                        ["utteranceFallback"] = "Are we talking about the back fence or the rain barrels?",
                        ["utteranceKey"] = "UI_PNC_ColonyWork_ClarifyTask_Utterance",
                    },
                    {
                        ["consumers"] = {
                            "participant",
                        },
                        ["frame"] = {
                            ["intent"] = "SUGGEST",
                            ["speechAct"] = "SUGGEST",
                            ["stateValue"] = "deferred",
                            ["subject"] = "COLONY_WORK",
                        },
                        ["id"] = "colony.work.defer_shift",
                        ["labelFallback"] = "Hold off until later",
                        ["labelKey"] = "UI_PNC_ColonyWork_DeferShift_Label",
                        ["utteranceFallback"] = "Better leave the hammering until morning.",
                        ["utteranceKey"] = "UI_PNC_ColonyWork_DeferShift_Utterance",
                    },
                },
                ["onClarify"] = "clarify_chore",
                ["onMatch"] = "confirm_assignment",
                ["onRefuse"] = "declined",
                ["onUnrelated"] = "suspend",
                ["slots"] = {
                    ["settlement"] = {
                        ["owner"] = "colony.work.status_exchange",
                        ["source"] = "slots.settlement.value",
                        ["type"] = "string",
                    },
                    ["task"] = {
                        ["owner"] = "colony.work.status_exchange",
                        ["source"] = "slots.task.value",
                        ["type"] = "string",
                    },
                },
            },
            ["clarify_chore"] = {
                ["accepts"] = {
                    {
                        ["intent"] = "INFORM",
                        ["speechAct"] = "INFORM",
                        ["subject"] = "COLONY_WORK",
                    },
                    {
                        ["intent"] = "OFFER",
                        ["speechAct"] = "OFFER",
                        ["subject"] = "COLONY_WORK",
                    },
                    {
                        ["intent"] = "AGREE",
                        ["speechAct"] = "AGREE",
                        ["subject"] = "COLONY_WORK",
                    },
                },
                ["onMatch"] = "confirm_assignment",
                ["onRefuse"] = "declined",
                ["onUnrelated"] = "suspend",
                ["slots"] = {
                    ["task"] = {
                        ["owner"] = "colony.work.status_exchange",
                        ["source"] = "slots.task.value",
                        ["type"] = "string",
                    },
                },
            },
            ["confirm_assignment"] = {
                ["accepts"] = {
                    {
                        ["intent"] = "AGREE",
                        ["speechAct"] = "AGREE",
                        ["subject"] = "COLONY_WORK",
                    },
                    {
                        ["intent"] = "ACCEPT",
                    },
                    {
                        ["intent"] = "DEFER",
                        ["speechAct"] = "DEFER",
                        ["subject"] = "COLONY_WORK",
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
                            ["subject"] = "COLONY_WORK",
                        },
                        ["id"] = "colony.work.agree_plan",
                        ["labelFallback"] = "Agree to split the work",
                        ["labelKey"] = "UI_PNC_ColonyWork_AgreePlan_Label",
                        ["utteranceFallback"] = "Alright, I'll grab the hammer and meet you out back.",
                        ["utteranceKey"] = "UI_PNC_ColonyWork_AgreePlan_Utterance",
                    },
                    {
                        ["consumers"] = {
                            "participant",
                        },
                        ["frame"] = {
                            ["intent"] = "DEFER",
                            ["speechAct"] = "DEFER",
                            ["subject"] = "COLONY_WORK",
                        },
                        ["id"] = "colony.work.pause_later",
                        ["labelFallback"] = "Pick it up later",
                        ["labelKey"] = "UI_PNC_ColonyWork_PauseLater_Label",
                        ["utteranceFallback"] = "Keep an eye on it; we'll finish it at first light.",
                        ["utteranceKey"] = "UI_PNC_ColonyWork_PauseLater_Utterance",
                    },
                },
                ["onMatch"] = "agreed",
                ["onRefuse"] = "declined",
                ["onUnrelated"] = "suspend",
            },
            ["declined"] = {
                ["terminal"] = true,
            },
        },
        ["owner"] = "ProjectHoomans",
        ["triggers"] = {
            {
                ["intent"] = "QUESTION",
                ["subject"] = "COLONY_WORK",
            },
            {
                ["intent"] = "INFORM",
                ["subject"] = "COLONY_WORK",
            },
        },
        ["version"] = 1,
    },
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
        ["domain"] = "semantic",
        ["id"] = "combat.aftermath.debrief_exchange",
        ["initial"] = "catch_breath",
        ["nodes"] = {
            ["assess_aftermath"] = {
                ["accepts"] = {
                    {
                        ["intent"] = "INFORM",
                        ["speechAct"] = "INFORM",
                        ["stateValue"] = "clear",
                        ["subject"] = "COMBAT_AFTERMATH",
                    },
                    {
                        ["intent"] = "INFORM",
                        ["speechAct"] = "INFORM",
                        ["stateValue"] = "shaken",
                        ["subject"] = "WELLBEING",
                    },
                    {
                        ["intent"] = "AGREE",
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
                            ["stateValue"] = "clear",
                            ["subject"] = "COMBAT_AFTERMATH",
                        },
                        ["id"] = "combat.aftermath.steady_down",
                        ["labelFallback"] = "Confirm the alley is clear",
                        ["labelKey"] = "UI_PNC_CombatAftermath_SteadyDown_Label",
                        ["utteranceFallback"] = "Looks like we lost the rest of them down the side street.",
                        ["utteranceKey"] = "UI_PNC_CombatAftermath_SteadyDown_Utterance",
                    },
                    {
                        ["consumers"] = {
                            "participant",
                        },
                        ["frame"] = {
                            ["intent"] = "INFORM",
                            ["speechAct"] = "INFORM",
                            ["stateValue"] = "shaken",
                            ["subject"] = "WELLBEING",
                        },
                        ["id"] = "combat.aftermath.admit_shaken",
                        ["labelFallback"] = "Take a minute to steady",
                        ["labelKey"] = "UI_PNC_CombatAftermath_AdmitShaken_Label",
                        ["utteranceFallback"] = "My hands are still shaking. Just give me a minute.",
                        ["utteranceKey"] = "UI_PNC_CombatAftermath_AdmitShaken_Utterance",
                    },
                },
                ["onMatch"] = "debriefed",
                ["onRefuse"] = "shaken_withdrawal",
                ["onUnrelated"] = "suspend",
            },
            ["catch_breath"] = {
                ["accepts"] = {
                    {
                        ["intent"] = "QUESTION",
                        ["speechAct"] = "QUESTION",
                        ["subject"] = "WELLBEING",
                    },
                    {
                        ["intent"] = "OFFER",
                        ["speechAct"] = "OFFER",
                        ["subject"] = "COMBAT_AFTERMATH",
                    },
                    {
                        ["intent"] = "INFORM",
                        ["speechAct"] = "INFORM",
                        ["subject"] = "WELLBEING",
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
                            ["subject"] = "WELLBEING",
                        },
                        ["id"] = "combat.aftermath.check_wounds",
                        ["labelFallback"] = "Check for bites or tears",
                        ["labelKey"] = "UI_PNC_CombatAftermath_CheckWounds_Label",
                        ["utteranceFallback"] = "You alright? Any scratches or rips in your jacket?",
                        ["utteranceKey"] = "UI_PNC_CombatAftermath_CheckWounds_Utterance",
                    },
                    {
                        ["consumers"] = {
                            "participant",
                        },
                        ["frame"] = {
                            ["intent"] = "OFFER",
                            ["speechAct"] = "OFFER",
                            ["subject"] = "COMBAT_AFTERMATH",
                        },
                        ["id"] = "combat.aftermath.secure_area",
                        ["labelFallback"] = "Bar the back door",
                        ["labelKey"] = "UI_PNC_CombatAftermath_SecureArea_Label",
                        ["utteranceFallback"] = "I'll wedge a chair under the back door while you catch your breath.",
                        ["utteranceKey"] = "UI_PNC_CombatAftermath_SecureArea_Utterance",
                    },
                },
                ["onMatch"] = "assess_aftermath",
                ["onRefuse"] = "shaken_withdrawal",
                ["onUnrelated"] = "suspend",
                ["slots"] = {
                    ["location"] = {
                        ["owner"] = "combat.aftermath.debrief_exchange",
                        ["source"] = "slots.location.value",
                        ["type"] = "string",
                    },
                    ["threat"] = {
                        ["owner"] = "combat.aftermath.debrief_exchange",
                        ["source"] = "slots.threat.value",
                        ["type"] = "string",
                    },
                },
            },
            ["debriefed"] = {
                ["terminal"] = true,
            },
            ["shaken_withdrawal"] = {
                ["terminal"] = true,
            },
        },
        ["owner"] = "ProjectHoomans",
        ["triggers"] = {
            {
                ["intent"] = "QUESTION",
                ["subject"] = "COMBAT_AFTERMATH",
            },
            {
                ["intent"] = "INFORM",
                ["subject"] = "COMBAT_AFTERMATH",
            },
        },
        ["version"] = 1,
    },
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
        ["domain"] = "semantic",
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
                        ["labelKey"] = "UI_PNC_Conversation_Suggestion_GossipAskRoads_Label",
                        ["utteranceFallback"] = "Heard any word on whether the highway north is clear or choked with wrecks?",
                        ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_GossipAskRoads_Utterance",
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
                        ["labelFallback"] = "Share what you heard",
                        ["labelKey"] = "UI_PNC_Conversation_Suggestion_GossipShareRumor_Label",
                        ["utteranceFallback"] = "Someone swore there's still power running in a few blocks west of here, though I haven't seen it myself.",
                        ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_GossipShareRumor_Utterance",
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
                        ["labelKey"] = "UI_PNC_Conversation_Suggestion_GossipClarifySource_Label",
                        ["utteranceFallback"] = "Did you see that with your own eyes, or hear it secondhand?",
                        ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_GossipClarifySource_Utterance",
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
                        ["labelKey"] = "UI_PNC_Conversation_Suggestion_GossipFirsthand_Label",
                        ["utteranceFallback"] = "Saw the smoke from the rooftops two days back—wasn't just radio talk.",
                        ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_GossipFirsthand_Utterance",
                    },
                },
                ["onMatch"] = "weigh_rumor",
                ["onRefuse"] = "refused_rumor",
                ["onUnrelated"] = "suspend",
                ["responsePool"] = "semantic.knowledge.gossip.exchange.clarify",
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
                    ["person"] = {
                        ["owner"] = "social",
                        ["source"] = "slots.person",
                        ["type"] = "string",
                    },
                },
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
                        ["labelKey"] = "UI_PNC_Conversation_Suggestion_GossipThanks_Label",
                        ["utteranceFallback"] = "Good to know. If you hear anything else on the radio or the road, pass it along.",
                        ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_GossipThanks_Utterance",
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
            ["refused_rumor"] = {
                ["responsePool"] = "semantic.knowledge.gossip.exchange.refused",
                ["terminal"] = true,
            },
            ["weigh_rumor"] = {
                ["accepts"] = {
                    {
                        ["intent"] = "AGREE",
                        ["speechAct"] = "AGREE",
                    },
                    {
                        ["intent"] = "INFORM",
                        ["speechAct"] = "INFORM",
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
                            ["intent"] = "AGREE",
                            ["speechAct"] = "AGREE",
                            ["stateValue"] = "known",
                        },
                        ["id"] = "knowledge.gossip.mark_known",
                        ["labelFallback"] = "Confirm the details",
                        ["labelKey"] = "UI_PNC_Conversation_Suggestion_GossipConfirm_Label",
                        ["utteranceFallback"] = "Lines up with what I saw near the strip mall—worth keeping in mind.",
                        ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_GossipConfirm_Utterance",
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
                        ["labelFallback"] = "Stay skeptical",
                        ["labelKey"] = "UI_PNC_Conversation_Suggestion_GossipDoubt_Label",
                        ["utteranceFallback"] = "Could be true, could be folks talking out of fear. I wouldn't bet my neck on it.",
                        ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_GossipDoubt_Utterance",
                    },
                },
                ["onMatch"] = "close_exchange",
                ["onRefuse"] = "refused_rumor",
                ["onUnrelated"] = "suspend",
                ["responsePool"] = "semantic.knowledge.gossip.exchange.weigh",
                ["slots"] = {
                    ["event"] = {
                        ["owner"] = "world",
                        ["source"] = "slots.event",
                        ["type"] = "string",
                    },
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
        },
        ["owner"] = "ProjectHoomans",
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
        ["version"] = 1,
    },
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
        ["domain"] = "semantic",
        ["id"] = "social.conflict.mediate_exchange",
        ["initial"] = "air_grievance",
        ["nodes"] = {
            ["air_grievance"] = {
                ["accepts"] = {
                    {
                        ["intent"] = "CLARIFY",
                        ["speechAct"] = "CLARIFY",
                        ["subject"] = "CONFLICT",
                    },
                    {
                        ["intent"] = "INFORM",
                        ["speechAct"] = "INFORM",
                        ["subject"] = "CONFLICT",
                    },
                    {
                        ["intent"] = "DISAGREE",
                        ["speechAct"] = "DISAGREE",
                        ["subject"] = "CONFLICT",
                    },
                },
                ["branchOffers"] = {
                    {
                        ["consumers"] = {
                            "participant",
                        },
                        ["frame"] = {
                            ["intent"] = "CLARIFY",
                            ["speechAct"] = "CLARIFY",
                            ["subject"] = "CONFLICT",
                        },
                        ["id"] = "social.conflict.listen_calmly",
                        ["labelFallback"] = "Hear them out calmly",
                        ["labelKey"] = "UI_PNC_SocialConflict_ListenCalmly_Label",
                        ["utteranceFallback"] = "Alright, tell me what happened without shouting.",
                        ["utteranceKey"] = "UI_PNC_SocialConflict_ListenCalmly_Utterance",
                    },
                    {
                        ["consumers"] = {
                            "participant",
                        },
                        ["frame"] = {
                            ["intent"] = "DISAGREE",
                            ["speechAct"] = "DISAGREE",
                            ["subject"] = "CONFLICT",
                        },
                        ["id"] = "social.conflict.push_back",
                        ["labelFallback"] = "Push back on the blame",
                        ["labelKey"] = "UI_PNC_SocialConflict_PushBack_Label",
                        ["utteranceFallback"] = "That's not fair and you know it.",
                        ["utteranceKey"] = "UI_PNC_SocialConflict_PushBack_Utterance",
                    },
                },
                ["onClarify"] = "seek_middle_ground",
                ["onMatch"] = "seek_middle_ground",
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
            ["reconciled"] = {
                ["terminal"] = true,
            },
            ["seek_middle_ground"] = {
                ["accepts"] = {
                    {
                        ["intent"] = "AGREE",
                        ["speechAct"] = "AGREE",
                        ["subject"] = "CONFLICT",
                    },
                    {
                        ["intent"] = "ACCEPT",
                    },
                    {
                        ["intent"] = "DEFER",
                        ["speechAct"] = "DEFER",
                        ["subject"] = "CONFLICT",
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
                            ["subject"] = "CONFLICT",
                        },
                        ["id"] = "social.conflict.reconcile",
                        ["labelFallback"] = "Call it even",
                        ["labelKey"] = "UI_PNC_SocialConflict_Reconcile_Label",
                        ["utteranceFallback"] = "Fine. We both made a mess of it. Let's drop it and move on.",
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
                        ["labelFallback"] = "Take some space",
                        ["labelKey"] = "UI_PNC_SocialConflict_CoolOff_Label",
                        ["utteranceFallback"] = "Let's leave it alone until we've both had some sleep.",
                        ["utteranceKey"] = "UI_PNC_SocialConflict_CoolOff_Utterance",
                    },
                },
                ["onMatch"] = "reconciled",
                ["onRefuse"] = "strained",
                ["onUnrelated"] = "suspend",
            },
            ["strained"] = {
                ["terminal"] = true,
            },
        },
        ["owner"] = "ProjectHoomans",
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
        ["version"] = 1,
    },
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
        ["domain"] = "semantic",
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
        ["version"] = 1,
    },
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
        ["domain"] = "semantic",
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
        ["version"] = 1,
    },
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
        ["domain"] = "semantic",
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
        ["version"] = 1,
    },
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
        ["domain"] = "semantic",
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
        ["version"] = 1,
    },
}
