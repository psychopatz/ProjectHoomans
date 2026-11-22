-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "thematic_interactive",
        ["domainPath"] = "thematic_interactive",
        ["exchangeFamily"] = {
            ["familyID"] = "colony.work.status_exchange",
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
                                ["fallback"] = "Back fence still has a loose plank {scene.location}, {addressee.name}, and the rain barrels need checking. How are we looking on chores?",
                                ["id"] = "default",
                                ["templateID"] = "convo.colony.work.status_exchange.say.1.default",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "colony.work",
            ["replies"] = {
                ["agreed"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "wellbeing.needs.checkin",
                        },
                    },
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
                                        ["fallback"] = "Good, {addressee.name}. Grab a hammer and some nails—we'll get it buttoned up before dark.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.colony.work.status_exchange.reply.agreed.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["checked_in"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "social.conflict.mediate_exchange",
                        },
                    },
                    ["outcome"] = "checked_in",
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
                                        ["fallback"] = "It's holding for now {scene.location}, {addressee.name}, just needs another pair of hands when we get a quiet hour.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.colony.work.status_exchange.reply.checked_in.say.1.default",
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
                            "knowledge.gossip.exchange",
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
                                        ["fallback"] = "Fair enough. Let's leave the heavy hammering until morning so we don't draw anything.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.colony.work.status_exchange.reply.deferred.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["negotiate"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "social.conflict.mediate_exchange",
                        },
                    },
                    ["outcome"] = "negotiate",
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
                                        ["fallback"] = "I'll haul timber for you, {addressee.name}, as long as somebody splits dusk watch with me.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.colony.work.status_exchange.reply.negotiate.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["refuse_unsafe_work"] = {
                    ["outcome"] = "refuse_unsafe_work",
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
                                        ["fallback"] = "Not walking out on an open roof while alarms and shots are echoing two blocks away.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.colony.work.status_exchange.reply.refuse_unsafe_work.say.1.default",
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
                                        ["fallback"] = "Not the time for chores. Keep your eyes on the yard.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.colony.work.status_exchange.reply.refused.say.1.default",
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
                                        ["fallback"] = "Alright, though my back's tight—we're keeping it brief and quiet.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.colony.work.status_exchange.reply.reluctant.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["volunteer"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "wellbeing.needs.checkin",
                        },
                    },
                    ["outcome"] = "volunteer",
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
                                        ["fallback"] = "Hand me the crowbar—I'll knock that job out right now so nobody pulls double duty.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.colony.work.status_exchange.reply.volunteer.say.1.default",
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
                    ["fallback"] = "Back fence still has a loose plank {scene.location}, {addressee.name}, and the rain barrels need checking. How are we looking on chores?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.colony.work.status_exchange.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Good, {addressee.name}. Grab a hammer and some nails—we'll get it buttoned up before dark.",
                    ["outcome"] = "agreed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.colony.work.status_exchange.reply.agreed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "It's holding for now {scene.location}, {addressee.name}, just needs another pair of hands when we get a quiet hour.",
                    ["outcome"] = "checked_in",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.colony.work.status_exchange.reply.checked_in.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Fair enough. Let's leave the heavy hammering until morning so we don't draw anything.",
                    ["outcome"] = "deferred",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.colony.work.status_exchange.reply.deferred.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I'll haul timber for you, {addressee.name}, as long as somebody splits dusk watch with me.",
                    ["outcome"] = "negotiate",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.colony.work.status_exchange.reply.negotiate.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Not walking out on an open roof while alarms and shots are echoing two blocks away.",
                    ["outcome"] = "refuse_unsafe_work",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.colony.work.status_exchange.reply.refuse_unsafe_work.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Not the time for chores. Keep your eyes on the yard.",
                    ["outcome"] = "refused",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.colony.work.status_exchange.reply.refused.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Alright, though my back's tight—we're keeping it brief and quiet.",
                    ["outcome"] = "reluctant",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.colony.work.status_exchange.reply.reluctant.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Hand me the crowbar—I'll knock that job out right now so nobody pulls double duty.",
                    ["outcome"] = "volunteer",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.colony.work.status_exchange.reply.volunteer.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "colony.work.status_exchange",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "status_exchange",
            ["sourceId"] = "colony.work.status_exchange",
            ["sourcePath"] = "dialogue/thematic_interactive/colony_work_exchange.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ThematicInteractive/ColonyWorkStatusExchangeToCombatAftermathDebriefExchange",
        ["namespace"] = "colony.work",
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
                ["episodeId"] = "colony_work_status_exchange",
            },
            ["domains"] = {
                {
                    ["domain"] = "colony",
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
                                    ["intent"] = "CLARIFY",
                                    ["speechAct"] = "CLARIFY",
                                    ["subject"] = "COLONY_WORK",
                                },
                                {
                                    ["intent"] = "OFFER",
                                    ["speechAct"] = "OFFER",
                                    ["stateValue"] = "volunteer",
                                    ["subject"] = "COLONY_WORK",
                                },
                                {
                                    ["intent"] = "SUGGEST",
                                    ["speechAct"] = "SUGGEST",
                                    ["stateValue"] = "negotiate",
                                    ["subject"] = "COLONY_WORK",
                                },
                                {
                                    ["intent"] = "DEFER",
                                    ["speechAct"] = "DEFER",
                                    ["stateValue"] = "deferred",
                                    ["subject"] = "COLONY_WORK",
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
                                    ["utteranceFallback"] = "Are we patching the back fence or sorting the water barrels first?",
                                    ["utteranceKey"] = "UI_PNC_ColonyWork_ClarifyTask_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "eq",
                                        ["path"] = "inventory.hasTools",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "OFFER",
                                        ["speechAct"] = "OFFER",
                                        ["stateValue"] = "volunteer",
                                        ["subject"] = "COLONY_WORK",
                                    },
                                    ["id"] = "colony.work.volunteer_with_tools",
                                    ["labelFallback"] = "Volunteer with spare hammer and nails",
                                    ["labelKey"] = "UI_PNC_ColonyWork_VolunteerTools_Label",
                                    ["utteranceFallback"] = "Already have hammer and nails clipped on my belt—let me take the hinge repair.",
                                    ["utteranceKey"] = "UI_PNC_ColonyWork_VolunteerTools_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "eq",
                                        ["path"] = "worldKnowledge.powerOrWaterCutoff",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "SUGGEST",
                                        ["speechAct"] = "SUGGEST",
                                        ["stateValue"] = "negotiate",
                                        ["subject"] = "COLONY_WORK",
                                    },
                                    ["id"] = "colony.work.pivot_utility_backup",
                                    ["labelFallback"] = "Switch priority due to cutoff",
                                    ["labelKey"] = "UI_PNC_ColonyWork_UtilityBackup_Label",
                                    ["utteranceFallback"] = "Grid and taps are dead—rain catchment and generator fuel take priority over tidyups.",
                                    ["utteranceKey"] = "UI_PNC_ColonyWork_UtilityBackup_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "DEFER",
                                        ["speechAct"] = "DEFER",
                                        ["stateValue"] = "deferred",
                                        ["subject"] = "COLONY_WORK",
                                    },
                                    ["id"] = "colony.work.defer_shift",
                                    ["labelFallback"] = "Hold off until later",
                                    ["labelKey"] = "UI_PNC_ColonyWork_DeferShift_Label",
                                    ["utteranceFallback"] = "Better leave heavy hammering until daylight.",
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
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                    ["stateValue"] = "refuse_unsafe_work",
                                    ["subject"] = "COLONY_WORK",
                                },
                                {
                                    ["intent"] = "SUGGEST",
                                    ["speechAct"] = "SUGGEST",
                                    ["stateValue"] = "negotiate",
                                    ["subject"] = "COLONY_WORK",
                                },
                                {
                                    ["intent"] = "OFFER",
                                    ["speechAct"] = "OFFER",
                                    ["stateValue"] = "volunteer",
                                    ["subject"] = "COLONY_WORK",
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
                                        ["path"] = "environment.outdoorHazard",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "REFUSE",
                                        ["speechAct"] = "REFUSE",
                                        ["stateValue"] = "refuse_unsafe_work",
                                        ["subject"] = "COLONY_WORK",
                                    },
                                    ["id"] = "colony.work.flag_outside_danger",
                                    ["labelFallback"] = "Refuse unsafe outside task",
                                    ["labelKey"] = "UI_PNC_ColonyWork_UnsafeOutdoor_Label",
                                    ["utteranceFallback"] = "Not banging nails outside while commotion's still active down the block.",
                                    ["utteranceKey"] = "UI_PNC_ColonyWork_UnsafeOutdoor_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "SUGGEST",
                                        ["speechAct"] = "SUGGEST",
                                        ["stateValue"] = "negotiate",
                                        ["subject"] = "COLONY_WORK",
                                    },
                                    ["id"] = "colony.work.pick_interior_job",
                                    ["labelFallback"] = "Propose quieter indoor sorting",
                                    ["labelKey"] = "UI_PNC_ColonyWork_PickInside_Label",
                                    ["utteranceFallback"] = "Wait out the noise indoors sorting tools and boiling water instead.",
                                    ["utteranceKey"] = "UI_PNC_ColonyWork_PickInside_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "OFFER",
                                        ["speechAct"] = "OFFER",
                                        ["stateValue"] = "volunteer",
                                        ["subject"] = "COLONY_WORK",
                                    },
                                    ["id"] = "colony.work.take_fence",
                                    ["labelFallback"] = "Take perimeter reinforcement",
                                    ["labelKey"] = "UI_PNC_ColonyWork_TakeFence_Label",
                                    ["utteranceFallback"] = "Hand me planks—fence gap takes ten minutes to brace.",
                                    ["utteranceKey"] = "UI_PNC_ColonyWork_TakeFence_Utterance",
                                },
                            },
                            ["onClarify"] = "confirm_assignment",
                            ["onMatch"] = "negotiate_terms",
                            ["onRefuse"] = "refused_unsafe",
                            ["onUnrelated"] = "suspend",
                        },
                        ["confirm_assignment"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "AGREE",
                                    ["speechAct"] = "AGREE",
                                    ["subject"] = "COLONY_WORK",
                                },
                                {
                                    ["intent"] = "DEFER",
                                    ["speechAct"] = "DEFER",
                                    ["stateValue"] = "deferred",
                                    ["subject"] = "COLONY_WORK",
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
                                        ["stateValue"] = "deferred",
                                        ["subject"] = "COLONY_WORK",
                                    },
                                    ["id"] = "colony.work.pause_later",
                                    ["labelFallback"] = "Pick it up at first light",
                                    ["labelKey"] = "UI_PNC_ColonyWork_PauseLater_Label",
                                    ["utteranceFallback"] = "Keep an eye on it; we'll button it up at first light.",
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
                        ["negotiate_terms"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "SUGGEST",
                                    ["speechAct"] = "SUGGEST",
                                    ["stateValue"] = "negotiate",
                                    ["subject"] = "COLONY_WORK",
                                },
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["stateValue"] = "reluctant",
                                    ["subject"] = "COLONY_WORK",
                                },
                                {
                                    ["intent"] = "AGREE",
                                    ["speechAct"] = "AGREE",
                                    ["subject"] = "COLONY_WORK",
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
                                        ["path"] = "relationship.respect",
                                        ["value"] = 10,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "SUGGEST",
                                        ["speechAct"] = "SUGGEST",
                                        ["stateValue"] = "negotiate",
                                        ["subject"] = "COLONY_WORK",
                                    },
                                    ["id"] = "colony.work.trade_shift",
                                    ["labelFallback"] = "Trade chore for off-watch rest",
                                    ["labelKey"] = "UI_PNC_ColonyWork_TradeShift_Label",
                                    ["utteranceFallback"] = "I'll haul the crates if you take first watch tonight.",
                                    ["utteranceKey"] = "UI_PNC_ColonyWork_TradeShift_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "gte",
                                        ["path"] = "npcState.fatigue",
                                        ["value"] = 55,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["stateValue"] = "reluctant",
                                        ["subject"] = "COLONY_WORK",
                                    },
                                    ["id"] = "colony.work.admit_fatigue",
                                    ["labelFallback"] = "Admit worn down",
                                    ["labelKey"] = "UI_PNC_ColonyWork_Fatigue_Label",
                                    ["utteranceFallback"] = "Arms are dead tired—give me lighter prep instead of timber lifting.",
                                    ["utteranceKey"] = "UI_PNC_ColonyWork_Fatigue_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "AGREE",
                                        ["speechAct"] = "AGREE",
                                        ["subject"] = "COLONY_WORK",
                                    },
                                    ["id"] = "colony.work.accept_split",
                                    ["labelFallback"] = "Split the workload evenly",
                                    ["labelKey"] = "UI_PNC_ColonyWork_AcceptSplit_Label",
                                    ["utteranceFallback"] = "Pair up and we wrap both tasks in half the time.",
                                    ["utteranceKey"] = "UI_PNC_ColonyWork_AcceptSplit_Utterance",
                                },
                            },
                            ["onMatch"] = "confirm_assignment",
                            ["onRefuse"] = "declined",
                            ["onUnrelated"] = "suspend",
                        },
                        ["refused_unsafe"] = {
                            ["terminal"] = true,
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
                    ["checked_in"] = {
                        ["outcome"] = "checked_in",
                        ["stance"] = "neutral",
                    },
                    ["deferred"] = {
                        ["outcome"] = "deferred",
                        ["stance"] = "contextual",
                    },
                    ["negotiate"] = {
                        ["outcome"] = "negotiate",
                        ["stance"] = "contextual",
                    },
                    ["refuse_unsafe_work"] = {
                        ["outcome"] = "refuse_unsafe_work",
                        ["stance"] = "negative",
                    },
                    ["refused"] = {
                        ["outcome"] = "refused",
                        ["stance"] = "negative",
                    },
                    ["reluctant"] = {
                        ["outcome"] = "reluctant",
                        ["stance"] = "contextual",
                    },
                    ["volunteer"] = {
                        ["outcome"] = "volunteer",
                        ["stance"] = "positive",
                    },
                },
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
            },
            ["repeatPolicy"] = "repeatable",
            ["reply"] = {
                ["agreed"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "wellbeing.needs.checkin",
                        },
                    },
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
                                        ["fallback"] = "Good, {addressee.name}. Grab a hammer and some nails—we'll get it buttoned up before dark.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["checked_in"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "social.conflict.mediate_exchange",
                        },
                    },
                    ["outcome"] = "checked_in",
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
                                        ["fallback"] = "It's holding for now {scene.location}, {addressee.name}, just needs another pair of hands when we get a quiet hour.",
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
                            "knowledge.gossip.exchange",
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
                                        ["fallback"] = "Fair enough. Let's leave the heavy hammering until morning so we don't draw anything.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["negotiate"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "social.conflict.mediate_exchange",
                        },
                    },
                    ["outcome"] = "negotiate",
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
                                        ["fallback"] = "I'll haul timber for you, {addressee.name}, as long as somebody splits dusk watch with me.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["refuse_unsafe_work"] = {
                    ["outcome"] = "refuse_unsafe_work",
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
                                        ["fallback"] = "Not walking out on an open roof while alarms and shots are echoing two blocks away.",
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
                                        ["fallback"] = "Not the time for chores. Keep your eyes on the yard.",
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
                                        ["fallback"] = "Alright, though my back's tight—we're keeping it brief and quiet.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["volunteer"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "wellbeing.needs.checkin",
                        },
                    },
                    ["outcome"] = "volunteer",
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
                                        ["fallback"] = "Hand me the crowbar—I'll knock that job out right now so nobody pulls double duty.",
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
                                ["fallback"] = "Back fence still has a loose plank {scene.location}, {addressee.name}, and the rain barrels need checking. How are we looking on chores?",
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
                    ["id"] = "colony_work_ready",
                    ["outcome"] = "actionable",
                    ["reason"] = "ready",
                },
            },
            ["topics"] = {
                {
                    ["domain"] = "colony",
                    ["id"] = "colony_work",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "colony.work.status_exchange",
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
                            ["fallback"] = "Back fence still has a loose plank {scene.location}, {addressee.name}, and the rain barrels need checking. How are we looking on chores?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.colony.work.status_exchange.say_1",
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
        ["sourceShard"] = "dialogue/thematic_interactive/colony_work_exchange.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Back fence still has a loose plank {scene.location}, {addressee.name}, and the rain barrels need checking. How are we looking on chores?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.colony.work.status_exchange.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Good, {addressee.name}. Grab a hammer and some nails—we'll get it buttoned up before dark.",
                ["outcome"] = "agreed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.colony.work.status_exchange.reply.agreed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "It's holding for now {scene.location}, {addressee.name}, just needs another pair of hands when we get a quiet hour.",
                ["outcome"] = "checked_in",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.colony.work.status_exchange.reply.checked_in.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Fair enough. Let's leave the heavy hammering until morning so we don't draw anything.",
                ["outcome"] = "deferred",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.colony.work.status_exchange.reply.deferred.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I'll haul timber for you, {addressee.name}, as long as somebody splits dusk watch with me.",
                ["outcome"] = "negotiate",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.colony.work.status_exchange.reply.negotiate.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Not walking out on an open roof while alarms and shots are echoing two blocks away.",
                ["outcome"] = "refuse_unsafe_work",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.colony.work.status_exchange.reply.refuse_unsafe_work.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Not the time for chores. Keep your eyes on the yard.",
                ["outcome"] = "refused",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.colony.work.status_exchange.reply.refused.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Alright, though my back's tight—we're keeping it brief and quiet.",
                ["outcome"] = "reluctant",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.colony.work.status_exchange.reply.reluctant.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Hand me the crowbar—I'll knock that job out right now so nobody pulls double duty.",
                ["outcome"] = "volunteer",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.colony.work.status_exchange.reply.volunteer.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "thematic_interactive",
        ["domainPath"] = "thematic_interactive",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.aftermath.debrief_exchange",
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
                                ["fallback"] = "That got ugly fast, {addressee.name}. You catch any scratches or bites back there?",
                                ["id"] = "default",
                                ["templateID"] = "convo.combat.aftermath.debrief_exchange.say.1.default",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.aftermath",
            ["replies"] = {
                ["cleared"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "colony.work.status_exchange",
                        },
                    },
                    ["outcome"] = "cleared",
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
                                        ["fallback"] = "Looks like the rest of them wandered off down the alley. Keep it quiet for a minute.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.cleared.say.1.default",
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
                                        ["fallback"] = "Those weren't raiders, {addressee.name}—some panicked kid set off a burglar alarm down the block.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.contradicted.say.1.default",
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
                            "wellbeing.needs.checkin",
                            "travel.excursion.plan_exchange",
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
                                        ["fallback"] = "Yeah, counted the same shots from the back window—there's still stragglers down that lane.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.corroborated.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["debriefed"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "wellbeing.needs.checkin",
                        },
                    },
                    ["outcome"] = "debriefed",
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
                                        ["fallback"] = "Nothing through the jacket, thank God, {addressee.name}. Door's wedged shut—let's catch our breath and check our gear.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.debriefed.say.1.default",
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
                                        ["fallback"] = "Don't crowd me right now. Watch the window.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.refused.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["shaken"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "wellbeing.needs.checkin",
                        },
                    },
                    ["outcome"] = "shaken",
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
                                        ["fallback"] = "I'm not bit, just rattled. Give me a second to get my hands steady.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.shaken.say.1.default",
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
                                        ["fallback"] = "Talk later. Reloading first and bolting the back door.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.withdraw.say.1.default",
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
                    ["fallback"] = "That got ugly fast, {addressee.name}. You catch any scratches or bites back there?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.aftermath.debrief_exchange.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Looks like the rest of them wandered off down the alley. Keep it quiet for a minute.",
                    ["outcome"] = "cleared",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.cleared.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Those weren't raiders, {addressee.name}—some panicked kid set off a burglar alarm down the block.",
                    ["outcome"] = "contradicted",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.contradicted.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Yeah, counted the same shots from the back window—there's still stragglers down that lane.",
                    ["outcome"] = "corroborated",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.corroborated.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Nothing through the jacket, thank God, {addressee.name}. Door's wedged shut—let's catch our breath and check our gear.",
                    ["outcome"] = "debriefed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.debriefed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Don't crowd me right now. Watch the window.",
                    ["outcome"] = "refused",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.refused.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I'm not bit, just rattled. Give me a second to get my hands steady.",
                    ["outcome"] = "shaken",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.shaken.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Talk later. Reloading first and bolting the back door.",
                    ["outcome"] = "withdraw",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.withdraw.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "combat.aftermath.debrief_exchange",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "debrief_exchange",
            ["sourceId"] = "combat.aftermath.debrief_exchange",
            ["sourcePath"] = "dialogue/thematic_interactive/combat_aftermath_exchange.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ThematicInteractive/ColonyWorkStatusExchangeToCombatAftermathDebriefExchange",
        ["namespace"] = "combat.aftermath",
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
                ["episodeId"] = "combat_aftermath_debrief_exchange",
            },
            ["domains"] = {
                {
                    ["domain"] = "combat",
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
                    ["id"] = "combat.aftermath.debrief_exchange",
                    ["initial"] = "catch_breath",
                    ["nodes"] = {
                        ["assess_aftermath"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "AGREE",
                                    ["speechAct"] = "AGREE",
                                    ["subject"] = "COMBAT_AFTERMATH",
                                },
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["stateValue"] = "shaken",
                                    ["subject"] = "COMBAT_AFTERMATH",
                                },
                                {
                                    ["intent"] = "WARN",
                                    ["speechAct"] = "WARN",
                                    ["stateValue"] = "low_ammo",
                                    ["subject"] = "COMBAT_AFTERMATH",
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
                                        ["subject"] = "COMBAT_AFTERMATH",
                                    },
                                    ["id"] = "combat.aftermath.steady_down",
                                    ["labelFallback"] = "Debrief and keep guard",
                                    ["labelKey"] = "UI_PNC_CombatAftermath_SteadyDown_Label",
                                    ["utteranceFallback"] = "Clean work keeping everyone upright. Let's rotate watch.",
                                    ["utteranceKey"] = "UI_PNC_CombatAftermath_SteadyDown_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "gte",
                                        ["path"] = "npcState.panic",
                                        ["value"] = 30,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["stateValue"] = "shaken",
                                        ["subject"] = "COMBAT_AFTERMATH",
                                    },
                                    ["id"] = "combat.aftermath.admit_shaken",
                                    ["labelFallback"] = "Admit still shaken",
                                    ["labelKey"] = "UI_PNC_CombatAftermath_AdmitShaken_Label",
                                    ["utteranceFallback"] = "My hands won't stop trembling—give me two minutes off the window.",
                                    ["utteranceKey"] = "UI_PNC_CombatAftermath_AdmitShaken_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "eq",
                                        ["path"] = "inventory.lowAmmo",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "WARN",
                                        ["speechAct"] = "WARN",
                                        ["stateValue"] = "low_ammo",
                                        ["subject"] = "COMBAT_AFTERMATH",
                                    },
                                    ["id"] = "combat.aftermath.count_shells",
                                    ["labelFallback"] = "Flag ammunition running low",
                                    ["labelKey"] = "UI_PNC_CombatAftermath_LowAmmo_Label",
                                    ["utteranceFallback"] = "Down to three shells in the belt—we cannot pick another fight right now.",
                                    ["utteranceKey"] = "UI_PNC_CombatAftermath_LowAmmo_Utterance",
                                },
                            },
                            ["onClarify"] = "corroborate_account",
                            ["onMatch"] = "debrief_gear",
                            ["onRefuse"] = "shaken_withdrawal",
                            ["onUnrelated"] = "suspend",
                        },
                        ["catch_breath"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "COMBAT_AFTERMATH",
                                },
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["subject"] = "COMBAT_AFTERMATH",
                                },
                                {
                                    ["intent"] = "WARN",
                                    ["speechAct"] = "WARN",
                                    ["stateValue"] = "gunfire",
                                    ["subject"] = "COMBAT_AFTERMATH",
                                },
                                {
                                    ["intent"] = "REQUEST",
                                    ["speechAct"] = "REQUEST",
                                    ["stateValue"] = "injured",
                                    ["subject"] = "COMBAT_AFTERMATH",
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
                                        ["subject"] = "COMBAT_AFTERMATH",
                                    },
                                    ["id"] = "combat.aftermath.check_wounds",
                                    ["labelFallback"] = "Check injuries and bites",
                                    ["labelKey"] = "UI_PNC_CombatAftermath_CheckWounds_Label",
                                    ["utteranceFallback"] = "Anybody get scratched or bitten in that scramble?",
                                    ["utteranceKey"] = "UI_PNC_CombatAftermath_CheckWounds_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["subject"] = "COMBAT_AFTERMATH",
                                    },
                                    ["id"] = "combat.aftermath.secure_area",
                                    ["labelFallback"] = "Confirm doors and sightlines clear",
                                    ["labelKey"] = "UI_PNC_CombatAftermath_SecureArea_Label",
                                    ["utteranceFallback"] = "Back door's barred, porch is clear—catch a breath and reload.",
                                    ["utteranceKey"] = "UI_PNC_CombatAftermath_SecureArea_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "eq",
                                        ["path"] = "worldKnowledge.recentGunfireOrAlarm",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "WARN",
                                        ["speechAct"] = "WARN",
                                        ["stateValue"] = "gunfire",
                                        ["subject"] = "COMBAT_AFTERMATH",
                                    },
                                    ["id"] = "combat.aftermath.report_gunfire_source",
                                    ["labelFallback"] = "Report nearby gunfire or alarm",
                                    ["labelKey"] = "UI_PNC_CombatAftermath_Gunfire_Label",
                                    ["utteranceFallback"] = "Those shots and that siren a block east are going to pull every shambler this way.",
                                    ["utteranceKey"] = "UI_PNC_CombatAftermath_Gunfire_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "eq",
                                        ["path"] = "npcState.injured",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "REQUEST",
                                        ["speechAct"] = "REQUEST",
                                        ["stateValue"] = "injured",
                                        ["subject"] = "COMBAT_AFTERMATH",
                                    },
                                    ["id"] = "combat.aftermath.triage_cut",
                                    ["labelFallback"] = "Ask partner to look at wound",
                                    ["labelKey"] = "UI_PNC_CombatAftermath_TriageCut_Label",
                                    ["utteranceFallback"] = "Think glass tore my sleeve back there—keep watch while I check.",
                                    ["utteranceKey"] = "UI_PNC_CombatAftermath_TriageCut_Utterance",
                                },
                            },
                            ["onClarify"] = "verify_perimeter",
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
                        ["cleared_report"] = {
                            ["terminal"] = true,
                        },
                        ["corroborate_account"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "AGREE",
                                    ["speechAct"] = "AGREE",
                                    ["stateValue"] = "corroborated",
                                    ["subject"] = "COMBAT_AFTERMATH",
                                },
                                {
                                    ["intent"] = "DISAGREE",
                                    ["speechAct"] = "DISAGREE",
                                    ["stateValue"] = "contradicted",
                                    ["subject"] = "COMBAT_AFTERMATH",
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
                                        ["intent"] = "AGREE",
                                        ["speechAct"] = "AGREE",
                                        ["stateValue"] = "corroborated",
                                        ["subject"] = "COMBAT_AFTERMATH",
                                    },
                                    ["id"] = "combat.aftermath.agree_report",
                                    ["labelFallback"] = "Corroborate threat count",
                                    ["labelKey"] = "UI_PNC_CombatAftermath_Corroborate_Label",
                                    ["utteranceFallback"] = "Same tally from here—half dozen split east, rest gone.",
                                    ["utteranceKey"] = "UI_PNC_CombatAftermath_Corroborate_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "DISAGREE",
                                        ["speechAct"] = "DISAGREE",
                                        ["stateValue"] = "contradicted",
                                        ["subject"] = "COMBAT_AFTERMATH",
                                    },
                                    ["id"] = "combat.aftermath.disagree_report",
                                    ["labelFallback"] = "Correct the headcount",
                                    ["labelKey"] = "UI_PNC_CombatAftermath_ContradictAccount_Label",
                                    ["utteranceFallback"] = "More than half a dozen—saw another cluster behind the garage before dark.",
                                    ["utteranceKey"] = "UI_PNC_CombatAftermath_ContradictAccount_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "ACCEPT",
                                        ["speechAct"] = "ACCEPT",
                                    },
                                    ["id"] = "combat.aftermath.end_debrief",
                                    ["labelFallback"] = "End debrief cleanly",
                                    ["labelKey"] = "UI_PNC_CombatAftermath_EndDebrief_Label",
                                    ["utteranceFallback"] = "Good enough. Eyes sharp on next shift.",
                                    ["utteranceKey"] = "UI_PNC_CombatAftermath_EndDebrief_Utterance",
                                },
                            },
                            ["onClarify"] = "cleared_report",
                            ["onMatch"] = "debriefed",
                            ["onRefuse"] = "shaken_withdrawal",
                            ["onUnrelated"] = "suspend",
                        },
                        ["debrief_gear"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "ACKNOWLEDGE",
                                    ["speechAct"] = "ACKNOWLEDGE",
                                    ["subject"] = "COMBAT_AFTERMATH",
                                },
                                {
                                    ["intent"] = "DEFER",
                                    ["speechAct"] = "DEFER",
                                    ["stateValue"] = "withdraw",
                                    ["subject"] = "COMBAT_AFTERMATH",
                                },
                                {
                                    ["intent"] = "AGREE",
                                    ["speechAct"] = "AGREE",
                                    ["stateValue"] = "cleared",
                                    ["subject"] = "COMBAT_AFTERMATH",
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
                                        ["subject"] = "COMBAT_AFTERMATH",
                                    },
                                    ["id"] = "combat.aftermath.inspect_blades",
                                    ["labelFallback"] = "Check weapons and bandages",
                                    ["labelKey"] = "UI_PNC_CombatAftermath_InspectGear_Label",
                                    ["utteranceFallback"] = "Wipe blades clean and count spare strips while it's quiet.",
                                    ["utteranceKey"] = "UI_PNC_CombatAftermath_InspectGear_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "DEFER",
                                        ["speechAct"] = "DEFER",
                                        ["stateValue"] = "withdraw",
                                        ["subject"] = "COMBAT_AFTERMATH",
                                    },
                                    ["id"] = "combat.aftermath.request_rest",
                                    ["labelFallback"] = "Step back from watch briefly",
                                    ["labelKey"] = "UI_PNC_CombatAftermath_ReqRest_Label",
                                    ["utteranceFallback"] = "Cover this hallway a minute while I tighten my boots and catch wind.",
                                    ["utteranceKey"] = "UI_PNC_CombatAftermath_ReqRest_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "AGREE",
                                        ["speechAct"] = "AGREE",
                                        ["stateValue"] = "cleared",
                                        ["subject"] = "COMBAT_AFTERMATH",
                                    },
                                    ["id"] = "combat.aftermath.move_on",
                                    ["labelFallback"] = "Mark corridor safe enough",
                                    ["labelKey"] = "UI_PNC_CombatAftermath_MoveOn_Label",
                                    ["utteranceFallback"] = "No fresh movement outside—calling the yard clear for now.",
                                    ["utteranceKey"] = "UI_PNC_CombatAftermath_MoveOn_Utterance",
                                },
                            },
                            ["onMatch"] = "corroborate_account",
                            ["onRefuse"] = "shaken_withdrawal",
                            ["onUnrelated"] = "suspend",
                        },
                        ["debriefed"] = {
                            ["terminal"] = true,
                        },
                        ["shaken_withdrawal"] = {
                            ["terminal"] = true,
                        },
                        ["verify_perimeter"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "CLARIFY",
                                    ["speechAct"] = "CLARIFY",
                                    ["stateValue"] = "corroborated",
                                    ["subject"] = "COMBAT_AFTERMATH",
                                },
                                {
                                    ["intent"] = "DISAGREE",
                                    ["speechAct"] = "DISAGREE",
                                    ["stateValue"] = "contradicted",
                                    ["subject"] = "COMBAT_AFTERMATH",
                                },
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["stateValue"] = "cleared",
                                    ["subject"] = "COMBAT_AFTERMATH",
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
                                        ["intent"] = "CLARIFY",
                                        ["speechAct"] = "CLARIFY",
                                        ["stateValue"] = "corroborated",
                                        ["subject"] = "COMBAT_AFTERMATH",
                                    },
                                    ["id"] = "combat.aftermath.witness_direction",
                                    ["labelFallback"] = "Cross-check direction with witness",
                                    ["labelKey"] = "UI_PNC_CombatAftermath_WitnessDir_Label",
                                    ["utteranceFallback"] = "Ask them too—pretty sure the noise peeled off down the alley, not toward us.",
                                    ["utteranceKey"] = "UI_PNC_CombatAftermath_WitnessDir_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "DISAGREE",
                                        ["speechAct"] = "DISAGREE",
                                        ["stateValue"] = "contradicted",
                                        ["subject"] = "COMBAT_AFTERMATH",
                                    },
                                    ["id"] = "combat.aftermath.contradict_raid",
                                    ["labelFallback"] = "Clarify it was only a false alarm",
                                    ["labelKey"] = "UI_PNC_CombatAftermath_Contradict_Label",
                                    ["utteranceFallback"] = "Hold steady—it wasn't an ambush, just an old burglar siren triggering down the street.",
                                    ["utteranceKey"] = "UI_PNC_CombatAftermath_Contradict_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["stateValue"] = "cleared",
                                        ["subject"] = "COMBAT_AFTERMATH",
                                    },
                                    ["id"] = "combat.aftermath.bolt_entry",
                                    ["labelFallback"] = "Report perimeter secured",
                                    ["labelKey"] = "UI_PNC_CombatAftermath_BoltEntry_Label",
                                    ["utteranceFallback"] = "Shutters latched and deadbolts turned. Nothing's stepping over the threshold.",
                                    ["utteranceKey"] = "UI_PNC_CombatAftermath_BoltEntry_Utterance",
                                },
                            },
                            ["onClarify"] = "debrief_gear",
                            ["onMatch"] = "assess_aftermath",
                            ["onRefuse"] = "shaken_withdrawal",
                            ["onUnrelated"] = "suspend",
                        },
                    },
                    ["owner"] = "ProjectHoomans",
                    ["version"] = 1,
                },
                ["replySemantics"] = {
                    ["cleared"] = {
                        ["outcome"] = "cleared",
                        ["stance"] = "neutral",
                    },
                    ["contradicted"] = {
                        ["outcome"] = "contradicted",
                        ["stance"] = "negative",
                    },
                    ["corroborated"] = {
                        ["outcome"] = "corroborated",
                        ["stance"] = "positive",
                    },
                    ["debriefed"] = {
                        ["outcome"] = "debriefed",
                        ["stance"] = "positive",
                    },
                    ["refused"] = {
                        ["outcome"] = "refused",
                        ["stance"] = "negative",
                    },
                    ["shaken"] = {
                        ["outcome"] = "shaken",
                        ["stance"] = "contextual",
                    },
                    ["withdraw"] = {
                        ["outcome"] = "withdraw",
                        ["stance"] = "contextual",
                    },
                },
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
            },
            ["repeatPolicy"] = "repeatable",
            ["reply"] = {
                ["cleared"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "colony.work.status_exchange",
                        },
                    },
                    ["outcome"] = "cleared",
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
                                        ["fallback"] = "Looks like the rest of them wandered off down the alley. Keep it quiet for a minute.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["contradicted"] = {
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
                                        ["fallback"] = "Those weren't raiders, {addressee.name}—some panicked kid set off a burglar alarm down the block.",
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
                            "wellbeing.needs.checkin",
                            "travel.excursion.plan_exchange",
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
                                        ["fallback"] = "Yeah, counted the same shots from the back window—there's still stragglers down that lane.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["debriefed"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "wellbeing.needs.checkin",
                        },
                    },
                    ["outcome"] = "debriefed",
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
                                        ["fallback"] = "Nothing through the jacket, thank God, {addressee.name}. Door's wedged shut—let's catch our breath and check our gear.",
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
                                        ["fallback"] = "Don't crowd me right now. Watch the window.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["shaken"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "wellbeing.needs.checkin",
                        },
                    },
                    ["outcome"] = "shaken",
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
                                        ["fallback"] = "I'm not bit, just rattled. Give me a second to get my hands steady.",
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
                                        ["fallback"] = "Talk later. Reloading first and bolting the back door.",
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
                                ["fallback"] = "That got ugly fast, {addressee.name}. You catch any scratches or bites back there?",
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
                    ["id"] = "combat_aftermath_ready",
                    ["outcome"] = "actionable",
                    ["reason"] = "ready",
                },
            },
            ["topics"] = {
                {
                    ["domain"] = "combat",
                    ["id"] = "combat_aftermath",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "combat.aftermath.debrief_exchange",
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
                            ["fallback"] = "That got ugly fast, {addressee.name}. You catch any scratches or bites back there?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.aftermath.debrief_exchange.say_1",
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
        ["sourceShard"] = "dialogue/thematic_interactive/combat_aftermath_exchange.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That got ugly fast, {addressee.name}. You catch any scratches or bites back there?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.aftermath.debrief_exchange.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Looks like the rest of them wandered off down the alley. Keep it quiet for a minute.",
                ["outcome"] = "cleared",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.cleared.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Those weren't raiders, {addressee.name}—some panicked kid set off a burglar alarm down the block.",
                ["outcome"] = "contradicted",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.contradicted.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Yeah, counted the same shots from the back window—there's still stragglers down that lane.",
                ["outcome"] = "corroborated",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.corroborated.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Nothing through the jacket, thank God, {addressee.name}. Door's wedged shut—let's catch our breath and check our gear.",
                ["outcome"] = "debriefed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.debriefed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Don't crowd me right now. Watch the window.",
                ["outcome"] = "refused",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.refused.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I'm not bit, just rattled. Give me a second to get my hands steady.",
                ["outcome"] = "shaken",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.shaken.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Talk later. Reloading first and bolting the back door.",
                ["outcome"] = "withdraw",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.withdraw.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
}
