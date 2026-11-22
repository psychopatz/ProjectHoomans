-- Generated; do not edit by hand.
return {
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
                    ["after"] = {
                        ["recommend"] = {
                            "combat.aftermath.debrief_exchange",
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
                    ["after"] = {
                        ["recommend"] = {
                            "knowledge.gossip.exchange",
                        },
                    },
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
                ["postpone"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "colony.work.status_exchange",
                        },
                    },
                    ["outcome"] = "postpone",
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
                                        ["fallback"] = "Hold off moving out until the storm breaks and visibility clears.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.travel.excursion.plan_exchange.reply.postpone.say.1.default",
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
                                        ["fallback"] = "I don't love the odds on that road, {addressee.name}, though I'll tag along carefully.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.travel.excursion.plan_exchange.reply.reluctant.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["request_escort"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "wellbeing.needs.checkin",
                        },
                    },
                    ["outcome"] = "request_escort",
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
                                        ["fallback"] = "I'll run that stretch only if we bring a second gun along for cover.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.travel.excursion.plan_exchange.reply.request_escort.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["reroute"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "knowledge.gossip.exchange",
                        },
                    },
                    ["outcome"] = "reroute",
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
                                        ["fallback"] = "Take the service alley west instead—avoids the ambush stretch completely.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.travel.excursion.plan_exchange.reply.reroute.say.1.default",
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
                    ["fallback"] = "Hold off moving out until the storm breaks and visibility clears.",
                    ["outcome"] = "postpone",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.travel.excursion.plan_exchange.reply.postpone.say.1.default",
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
                {
                    ["fallback"] = "I don't love the odds on that road, {addressee.name}, though I'll tag along carefully.",
                    ["outcome"] = "reluctant",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.travel.excursion.plan_exchange.reply.reluctant.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I'll run that stretch only if we bring a second gun along for cover.",
                    ["outcome"] = "request_escort",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.travel.excursion.plan_exchange.reply.request_escort.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Take the service alley west instead—avoids the ambush stretch completely.",
                    ["outcome"] = "reroute",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.travel.excursion.plan_exchange.reply.reroute.say.1.default",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/ThematicInteractive/TravelExcursionPlanExchangeToWellbeingNeedsCheckin",
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
                        ["assess_hazard_intel"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["stateValue"] = "hazard",
                                    ["subject"] = "ROUTE",
                                },
                                {
                                    ["intent"] = "OFFER",
                                    ["speechAct"] = "OFFER",
                                    ["stateValue"] = "escort",
                                    ["subject"] = "EXCURSION",
                                },
                                {
                                    ["intent"] = "CLARIFY",
                                    ["speechAct"] = "CLARIFY",
                                    ["subject"] = "ROUTE",
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
                                        ["path"] = "worldKnowledge.hasStoryDiscovery",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["stateValue"] = "hazard",
                                        ["subject"] = "ROUTE",
                                    },
                                    ["id"] = "travel.excursion.cite_crash",
                                    ["labelFallback"] = "Mention wreck or blockade seen",
                                    ["labelKey"] = "UI_PNC_TravelExcursion_CiteCrash_Label",
                                    ["utteranceFallback"] = "There's an overturned rig drawing walkers right across the eastern bend.",
                                    ["utteranceKey"] = "UI_PNC_TravelExcursion_CiteCrash_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "eq",
                                        ["path"] = "inventory.hasWeaponOrAmmo",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "OFFER",
                                        ["speechAct"] = "OFFER",
                                        ["stateValue"] = "escort",
                                        ["subject"] = "EXCURSION",
                                    },
                                    ["id"] = "travel.excursion.check_armed",
                                    ["labelFallback"] = "Volunteer to cover point",
                                    ["labelKey"] = "UI_PNC_TravelExcursion_CheckArmed_Label",
                                    ["utteranceFallback"] = "Got shells left in my mag—I'll walk point if we stick to side streets.",
                                    ["utteranceKey"] = "UI_PNC_TravelExcursion_CheckArmed_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "CLARIFY",
                                        ["speechAct"] = "CLARIFY",
                                        ["subject"] = "ROUTE",
                                    },
                                    ["id"] = "travel.excursion.probe_detour",
                                    ["labelFallback"] = "Ask about backyard detour",
                                    ["labelKey"] = "UI_PNC_TravelExcursion_ProbeDetour_Label",
                                    ["utteranceFallback"] = "Could we cut behind the warehouse fence instead of walking the strip?",
                                    ["utteranceKey"] = "UI_PNC_TravelExcursion_ProbeDetour_Utterance",
                                },
                            },
                            ["onClarify"] = "assess_risk",
                            ["onMatch"] = "weigh_escort_or_detour",
                            ["onRefuse"] = "called_off",
                            ["onUnrelated"] = "suspend",
                        },
                        ["assess_risk"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "SUGGEST",
                                    ["speechAct"] = "SUGGEST",
                                    ["stateValue"] = "reroute",
                                    ["subject"] = "ROUTE",
                                },
                                {
                                    ["intent"] = "REQUEST",
                                    ["speechAct"] = "REQUEST",
                                    ["stateValue"] = "request_escort",
                                    ["subject"] = "EXCURSION",
                                },
                                {
                                    ["intent"] = "DEFER",
                                    ["speechAct"] = "DEFER",
                                    ["stateValue"] = "postpone",
                                    ["subject"] = "EXCURSION",
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
                                        ["intent"] = "SUGGEST",
                                        ["speechAct"] = "SUGGEST",
                                        ["stateValue"] = "reroute",
                                        ["subject"] = "ROUTE",
                                    },
                                    ["id"] = "travel.excursion.propose_detour",
                                    ["labelFallback"] = "Take back-alley detour",
                                    ["labelKey"] = "UI_PNC_TravelExcursion_Detour_Label",
                                    ["utteranceFallback"] = "Skip the highway—swing behind the yards where sightlines stay tight.",
                                    ["utteranceKey"] = "UI_PNC_TravelExcursion_Detour_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "gte",
                                        ["path"] = "relationship.trust",
                                        ["value"] = 20,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "REQUEST",
                                        ["speechAct"] = "REQUEST",
                                        ["stateValue"] = "request_escort",
                                        ["subject"] = "EXCURSION",
                                    },
                                    ["id"] = "travel.excursion.request_escort",
                                    ["labelFallback"] = "Ask partner to watch back",
                                    ["labelKey"] = "UI_PNC_TravelExcursion_RequestEscort_Label",
                                    ["utteranceFallback"] = "Only heading through there if you've got my six all the way.",
                                    ["utteranceKey"] = "UI_PNC_TravelExcursion_RequestEscort_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "DEFER",
                                        ["speechAct"] = "DEFER",
                                        ["stateValue"] = "postpone",
                                        ["subject"] = "EXCURSION",
                                    },
                                    ["id"] = "travel.excursion.postpone_risk",
                                    ["labelFallback"] = "Wait until light improves",
                                    ["labelKey"] = "UI_PNC_TravelExcursion_Postpone_Label",
                                    ["utteranceFallback"] = "Too sketchy right now. Give it until morning.",
                                    ["utteranceKey"] = "UI_PNC_TravelExcursion_Postpone_Utterance",
                                },
                            },
                            ["onClarify"] = "confirm_departure",
                            ["onMatch"] = "weigh_escort_or_detour",
                            ["onRefuse"] = "called_off",
                            ["onUnrelated"] = "suspend",
                        },
                        ["called_off"] = {
                            ["terminal"] = true,
                        },
                        ["confirm_departure"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "AGREE",
                                    ["speechAct"] = "AGREE",
                                    ["subject"] = "EXCURSION",
                                },
                                {
                                    ["intent"] = "CLARIFY",
                                    ["speechAct"] = "CLARIFY",
                                    ["stateValue"] = "postpone",
                                    ["subject"] = "EXCURSION",
                                },
                                {
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                    ["subject"] = "EXCURSION",
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
                                        ["subject"] = "EXCURSION",
                                    },
                                    ["id"] = "travel.excursion.confirm_departure",
                                    ["labelFallback"] = "Confirm moving out now",
                                    ["labelKey"] = "UI_PNC_TravelExcursion_ConfirmGo_Label",
                                    ["utteranceFallback"] = "Bags checked, crowbars ready—let's step out quiet.",
                                    ["utteranceKey"] = "UI_PNC_TravelExcursion_ConfirmGo_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "CLARIFY",
                                        ["speechAct"] = "CLARIFY",
                                        ["stateValue"] = "postpone",
                                        ["subject"] = "EXCURSION",
                                    },
                                    ["id"] = "travel.excursion.postpone_final",
                                    ["labelFallback"] = "Hold until morning watch",
                                    ["labelKey"] = "UI_PNC_TravelExcursion_PostponeFinal_Label",
                                    ["utteranceFallback"] = "Actually, wait for dawn—safer sweeping that strip in daylight.",
                                    ["utteranceKey"] = "UI_PNC_TravelExcursion_PostponeFinal_Utterance",
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
                                    ["id"] = "travel.excursion.abort_final",
                                    ["labelFallback"] = "Stay put after all",
                                    ["labelKey"] = "UI_PNC_TravelExcursion_AbortFinal_Label",
                                    ["utteranceFallback"] = "Forget it—stay inside till the noise settles.",
                                    ["utteranceKey"] = "UI_PNC_TravelExcursion_AbortFinal_Utterance",
                                },
                            },
                            ["onClarify"] = "postponed_route",
                            ["onMatch"] = "departing",
                            ["onRefuse"] = "called_off",
                            ["onUnrelated"] = "suspend",
                        },
                        ["departing"] = {
                            ["terminal"] = true,
                        },
                        ["postponed_route"] = {
                            ["terminal"] = true,
                        },
                        ["propose_route"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "SUGGEST",
                                    ["speechAct"] = "SUGGEST",
                                    ["subject"] = "EXCURSION",
                                },
                                {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "ROUTE",
                                },
                                {
                                    ["intent"] = "WARN",
                                    ["speechAct"] = "WARN",
                                    ["stateValue"] = "reroute",
                                    ["subject"] = "ROUTE",
                                },
                                {
                                    ["intent"] = "DEFER",
                                    ["speechAct"] = "DEFER",
                                    ["stateValue"] = "postpone",
                                    ["subject"] = "ROUTE",
                                },
                                {
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                    ["subject"] = "EXCURSION",
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
                                        ["intent"] = "SUGGEST",
                                        ["speechAct"] = "SUGGEST",
                                        ["subject"] = "EXCURSION",
                                    },
                                    ["id"] = "travel.excursion.set_destination",
                                    ["labelFallback"] = "Confirm supply run destination",
                                    ["labelKey"] = "UI_PNC_TravelExcursion_SetDest_Label",
                                    ["utteranceFallback"] = "Need canned goods and batteries from down the road before sunset.",
                                    ["utteranceKey"] = "UI_PNC_TravelExcursion_SetDest_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "QUESTION",
                                        ["speechAct"] = "QUESTION",
                                        ["subject"] = "ROUTE",
                                    },
                                    ["id"] = "travel.excursion.ask_threat",
                                    ["labelFallback"] = "Check corridor threats",
                                    ["labelKey"] = "UI_PNC_TravelExcursion_AskThreat_Label",
                                    ["utteranceFallback"] = "Heard anything about hordes or alarms along that street lately?",
                                    ["utteranceKey"] = "UI_PNC_TravelExcursion_AskThreat_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "eq",
                                        ["path"] = "worldKnowledge.routeHazard",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "WARN",
                                        ["speechAct"] = "WARN",
                                        ["stateValue"] = "reroute",
                                        ["subject"] = "ROUTE",
                                    },
                                    ["id"] = "travel.excursion.flag_road_ambush",
                                    ["labelFallback"] = "Warn of road hazard",
                                    ["labelKey"] = "UI_PNC_TravelExcursion_FlagAmbush_Label",
                                    ["utteranceFallback"] = "Word is wrecks and armed stragglers are choking the north avenue—maybe reroute.",
                                    ["utteranceKey"] = "UI_PNC_TravelExcursion_FlagAmbush_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "eq",
                                        ["path"] = "environment.severeWeather",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "DEFER",
                                        ["speechAct"] = "DEFER",
                                        ["stateValue"] = "postpone",
                                        ["subject"] = "ROUTE",
                                    },
                                    ["id"] = "travel.excursion.warn_storm_delay",
                                    ["labelFallback"] = "Propose weather hold",
                                    ["labelKey"] = "UI_PNC_TravelExcursion_StormDelay_Label",
                                    ["utteranceFallback"] = "Visibility's zero in this squall. Postpone until it lets up?",
                                    ["utteranceKey"] = "UI_PNC_TravelExcursion_StormDelay_Utterance",
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
                                    ["labelFallback"] = "Call off the trip",
                                    ["labelKey"] = "UI_PNC_TravelExcursion_CallOff_Label",
                                    ["utteranceFallback"] = "Not worth sticking our necks out right now.",
                                    ["utteranceKey"] = "UI_PNC_TravelExcursion_CallOff_Utterance",
                                },
                            },
                            ["onClarify"] = "assess_hazard_intel",
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
                        ["weigh_escort_or_detour"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "AGREE",
                                    ["speechAct"] = "AGREE",
                                    ["stateValue"] = "reroute",
                                    ["subject"] = "ROUTE",
                                },
                                {
                                    ["intent"] = "DEFER",
                                    ["speechAct"] = "DEFER",
                                    ["stateValue"] = "postpone",
                                    ["subject"] = "EXCURSION",
                                },
                                {
                                    ["intent"] = "ACCEPT",
                                    ["speechAct"] = "ACCEPT",
                                    ["stateValue"] = "reluctant",
                                    ["subject"] = "EXCURSION",
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
                                        ["stateValue"] = "reroute",
                                        ["subject"] = "ROUTE",
                                    },
                                    ["id"] = "travel.excursion.accept_detour",
                                    ["labelFallback"] = "Lock in back-street route",
                                    ["labelKey"] = "UI_PNC_TravelExcursion_AcceptDetour_Label",
                                    ["utteranceFallback"] = "Back route works—stay spaced ten paces and skip heavy loads.",
                                    ["utteranceKey"] = "UI_PNC_TravelExcursion_AcceptDetour_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "gte",
                                        ["path"] = "npcState.fatigue",
                                        ["value"] = 60,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "DEFER",
                                        ["speechAct"] = "DEFER",
                                        ["stateValue"] = "postpone",
                                        ["subject"] = "EXCURSION",
                                    },
                                    ["id"] = "travel.excursion.hold_off_fatigue",
                                    ["labelFallback"] = "Admit too exhausted to hike",
                                    ["labelKey"] = "UI_PNC_TravelExcursion_HoldFatigue_Label",
                                    ["utteranceFallback"] = "My legs are shot right now—we'll make sloppy mistakes if we push out.",
                                    ["utteranceKey"] = "UI_PNC_TravelExcursion_HoldFatigue_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "ACCEPT",
                                        ["speechAct"] = "ACCEPT",
                                        ["stateValue"] = "reluctant",
                                        ["subject"] = "EXCURSION",
                                    },
                                    ["id"] = "travel.excursion.reluctant_go",
                                    ["labelFallback"] = "Agree reluctantly",
                                    ["labelKey"] = "UI_PNC_TravelExcursion_ReluctantGo_Label",
                                    ["utteranceFallback"] = "Still don't like leaving cover today, but let's make it quick.",
                                    ["utteranceKey"] = "UI_PNC_TravelExcursion_ReluctantGo_Utterance",
                                },
                            },
                            ["onClarify"] = "postponed_route",
                            ["onMatch"] = "confirm_departure",
                            ["onRefuse"] = "called_off",
                            ["onUnrelated"] = "suspend",
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
                    ["postpone"] = {
                        ["outcome"] = "postpone",
                        ["stance"] = "contextual",
                    },
                    ["refused"] = {
                        ["outcome"] = "refused",
                        ["stance"] = "negative",
                    },
                    ["reluctant"] = {
                        ["outcome"] = "reluctant",
                        ["stance"] = "contextual",
                    },
                    ["request_escort"] = {
                        ["outcome"] = "request_escort",
                        ["stance"] = "contextual",
                    },
                    ["reroute"] = {
                        ["outcome"] = "reroute",
                        ["stance"] = "positive",
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
                    ["after"] = {
                        ["recommend"] = {
                            "combat.aftermath.debrief_exchange",
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
                    ["after"] = {
                        ["recommend"] = {
                            "knowledge.gossip.exchange",
                        },
                    },
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
                ["postpone"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "colony.work.status_exchange",
                        },
                    },
                    ["outcome"] = "postpone",
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
                                        ["fallback"] = "Hold off moving out until the storm breaks and visibility clears.",
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
                                        ["fallback"] = "I don't love the odds on that road, {addressee.name}, though I'll tag along carefully.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["request_escort"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "wellbeing.needs.checkin",
                        },
                    },
                    ["outcome"] = "request_escort",
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
                                        ["fallback"] = "I'll run that stretch only if we bring a second gun along for cover.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["reroute"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "knowledge.gossip.exchange",
                        },
                    },
                    ["outcome"] = "reroute",
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
                                        ["fallback"] = "Take the service alley west instead—avoids the ambush stretch completely.",
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
                ["fallback"] = "Hold off moving out until the storm breaks and visibility clears.",
                ["outcome"] = "postpone",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.travel.excursion.plan_exchange.reply.postpone.say.1.default",
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
            {
                ["fallback"] = "I don't love the odds on that road, {addressee.name}, though I'll tag along carefully.",
                ["outcome"] = "reluctant",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.travel.excursion.plan_exchange.reply.reluctant.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I'll run that stretch only if we bring a second gun along for cover.",
                ["outcome"] = "request_escort",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.travel.excursion.plan_exchange.reply.request_escort.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Take the service alley west instead—avoids the ambush stretch completely.",
                ["outcome"] = "reroute",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.travel.excursion.plan_exchange.reply.reroute.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
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
                                ["fallback"] = "Glad to see you still on your feet, {addressee.name}. Need anything while we've got a quiet moment?",
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
                ["accept_treatment"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "colony.work.status_exchange",
                        },
                    },
                    ["outcome"] = "accept_treatment",
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
                                        ["fallback"] = "Alright—wrap it tight before it dirties. Appreciate you carrying clean dressing.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.wellbeing.needs.checkin.reply.accept_treatment.say.1.default",
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
                ["dismissed"] = {
                    ["outcome"] = "dismissed",
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
                                        ["fallback"] = "Quit fussing over me. Keep your hands on your weapon.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.wellbeing.needs.checkin.reply.dismissed.say.1.default",
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
                ["holding_up"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "travel.excursion.plan_exchange",
                        },
                    },
                    ["outcome"] = "holding_up",
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
                                        ["fallback"] = "Tired to the bone, sure, but still standing and ready to move.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.wellbeing.needs.checkin.reply.holding_up.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["refuse_treatment"] = {
                    ["outcome"] = "refuse_treatment",
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
                                        ["fallback"] = "Keep your roll for someone bleeding out—I'll stitch myself later.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.wellbeing.needs.checkin.reply.refuse_treatment.say.1.default",
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
                                        ["fallback"] = "Fine, take one look, then get back on watch before anything hears us.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.wellbeing.needs.checkin.reply.reluctant.say.1.default",
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
                                        ["fallback"] = "Running dry without tap water's wearing everyone thin, not just me.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.wellbeing.needs.checkin.reply.strained.say.1.default",
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
                    ["after"] = {
                        ["recommend"] = {
                            "colony.work.status_exchange",
                        },
                    },
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
                                        ["fallback"] = "Appreciate that, {addressee.name}. Knowing someone's got an eye out helps more than you'd think.",
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
                    ["fallback"] = "Glad to see you still on your feet, {addressee.name}. Need anything while we've got a quiet moment?",
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
                    ["fallback"] = "Alright—wrap it tight before it dirties. Appreciate you carrying clean dressing.",
                    ["outcome"] = "accept_treatment",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.wellbeing.needs.checkin.reply.accept_treatment.say.1.default",
                    ["variantID"] = "default",
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
                    ["fallback"] = "Quit fussing over me. Keep your hands on your weapon.",
                    ["outcome"] = "dismissed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.wellbeing.needs.checkin.reply.dismissed.say.1.default",
                    ["variantID"] = "default",
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
                    ["fallback"] = "Tired to the bone, sure, but still standing and ready to move.",
                    ["outcome"] = "holding_up",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.wellbeing.needs.checkin.reply.holding_up.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Keep your roll for someone bleeding out—I'll stitch myself later.",
                    ["outcome"] = "refuse_treatment",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.wellbeing.needs.checkin.reply.refuse_treatment.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Fine, take one look, then get back on watch before anything hears us.",
                    ["outcome"] = "reluctant",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.wellbeing.needs.checkin.reply.reluctant.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Running dry without tap water's wearing everyone thin, not just me.",
                    ["outcome"] = "strained",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.wellbeing.needs.checkin.reply.strained.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Appreciate that, {addressee.name}. Knowing someone's got an eye out helps more than you'd think.",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/ThematicInteractive/TravelExcursionPlanExchangeToWellbeingNeedsCheckin",
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
                                    ["intent"] = "OFFER",
                                    ["speechAct"] = "OFFER",
                                    ["subject"] = "NEEDS",
                                },
                                {
                                    ["intent"] = "ACCEPT",
                                    ["speechAct"] = "ACCEPT",
                                    ["stateValue"] = "accept_treatment",
                                    ["subject"] = "WELLBEING",
                                },
                                {
                                    ["intent"] = "DEFER",
                                    ["speechAct"] = "DEFER",
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
                                        ["intent"] = "OFFER",
                                        ["speechAct"] = "OFFER",
                                        ["subject"] = "NEEDS",
                                    },
                                    ["id"] = "wellbeing.checkin.offer_help",
                                    ["labelFallback"] = "Share water or spare supplies",
                                    ["labelKey"] = "UI_PNC_Wellbeing_OfferHelp_Label",
                                    ["utteranceFallback"] = "Take a bottle from my pack; we'll replace it once we check the kitchen.",
                                    ["utteranceKey"] = "UI_PNC_Wellbeing_OfferHelp_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "eq",
                                        ["path"] = "inventory.hasMedicalItem",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "ACCEPT",
                                        ["speechAct"] = "ACCEPT",
                                        ["stateValue"] = "accept_treatment",
                                        ["subject"] = "WELLBEING",
                                    },
                                    ["id"] = "wellbeing.checkin.accept_aid",
                                    ["labelFallback"] = "Accept care and rest",
                                    ["labelKey"] = "UI_PNC_Wellbeing_AcceptAid_Label",
                                    ["utteranceFallback"] = "Alright, patch it up and let me sit five minutes off my boots.",
                                    ["utteranceKey"] = "UI_PNC_Wellbeing_AcceptAid_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "DEFER",
                                        ["speechAct"] = "DEFER",
                                        ["subject"] = "WELLBEING",
                                    },
                                    ["id"] = "wellbeing.checkin.defer_rest",
                                    ["labelFallback"] = "Hold until we find cover",
                                    ["labelKey"] = "UI_PNC_Wellbeing_DeferRest_Label",
                                    ["utteranceFallback"] = "Hold on to it—we unpack properly once the doors are bolted.",
                                    ["utteranceKey"] = "UI_PNC_Wellbeing_DeferRest_Utterance",
                                },
                            },
                            ["onClarify"] = "resolve_checkin",
                            ["onMatch"] = "follow_up_recovery",
                            ["onRefuse"] = "declined_help",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.wellbeing.needs.checkin.assess",
                            ["slots"] = {
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
                                    ["selfDirected"] = true,
                                    ["speechAct"] = "INFORM",
                                    ["stateType"] = "WELLBEING",
                                    ["stateValue"] = "positive",
                                },
                                {
                                    ["intent"] = "CLARIFY",
                                    ["speechAct"] = "CLARIFY",
                                    ["subject"] = "WELLBEING",
                                },
                                {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["stateValue"] = "water",
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
                                        ["intent"] = "QUESTION",
                                        ["speechAct"] = "QUESTION",
                                        ["subject"] = "NEEDS",
                                    },
                                    ["id"] = "wellbeing.checkin.admit_need",
                                    ["labelFallback"] = "Ask what is running low",
                                    ["labelKey"] = "UI_PNC_Wellbeing_AdmitNeed_Label",
                                    ["utteranceFallback"] = "Don't sugarcoat it—clean water, rations, bandages, what are you short on?",
                                    ["utteranceKey"] = "UI_PNC_Wellbeing_AdmitNeed_Utterance",
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
                                    ["labelFallback"] = "Say you are holding up",
                                    ["labelKey"] = "UI_PNC_Wellbeing_HoldingSteady_Label",
                                    ["utteranceFallback"] = "Still on my feet. Sore, sure, but I can pull my weight tonight.",
                                    ["utteranceKey"] = "UI_PNC_Wellbeing_HoldingSteady_Utterance",
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
                                    ["labelFallback"] = "Check if wounded or exhausted",
                                    ["labelKey"] = "UI_PNC_Wellbeing_ClarifyCond_Label",
                                    ["utteranceFallback"] = "You're favoring that shoulder—fresh cut, or just worn down?",
                                    ["utteranceKey"] = "UI_PNC_Wellbeing_ClarifyCond_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "eq",
                                        ["path"] = "worldKnowledge.waterCutoff",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "QUESTION",
                                        ["speechAct"] = "QUESTION",
                                        ["stateValue"] = "water",
                                        ["subject"] = "NEEDS",
                                    },
                                    ["id"] = "wellbeing.checkin.ask_water_ration",
                                    ["labelFallback"] = "Ask how water supply is holding",
                                    ["labelKey"] = "UI_PNC_Wellbeing_AskWater_Label",
                                    ["utteranceFallback"] = "With mains dead, do you still have clean bottles left or are you rationing?",
                                    ["utteranceKey"] = "UI_PNC_Wellbeing_AskWater_Utterance",
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
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["stateValue"] = "injured",
                                    ["subject"] = "WELLBEING",
                                },
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["stateValue"] = "strained",
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
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["subject"] = "NEEDS",
                                    },
                                    ["id"] = "wellbeing.checkin.name_need",
                                    ["labelFallback"] = "Name needed item",
                                    ["labelKey"] = "UI_PNC_Wellbeing_NameNeed_Label",
                                    ["utteranceFallback"] = "Could really use clean gauze or a bottle of purified water.",
                                    ["utteranceKey"] = "UI_PNC_Wellbeing_NameNeed_Utterance",
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
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["stateValue"] = "injured",
                                        ["subject"] = "WELLBEING",
                                    },
                                    ["id"] = "wellbeing.checkin.show_injury",
                                    ["labelFallback"] = "Point out bleeding wound",
                                    ["labelKey"] = "UI_PNC_Wellbeing_ShowInjury_Label",
                                    ["utteranceFallback"] = "Clipped glass climbing a frame earlier—needs wrapping before it turns foul.",
                                    ["utteranceKey"] = "UI_PNC_Wellbeing_ShowInjury_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "gte",
                                        ["path"] = "npcState.panic",
                                        ["value"] = 40,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["stateValue"] = "strained",
                                        ["subject"] = "WELLBEING",
                                    },
                                    ["id"] = "wellbeing.checkin.steady_nerves",
                                    ["labelFallback"] = "Acknowledge rattled nerves",
                                    ["labelKey"] = "UI_PNC_Wellbeing_SteadyNerves_Label",
                                    ["utteranceFallback"] = "Still catching my breath after that close call—give me half a minute.",
                                    ["utteranceKey"] = "UI_PNC_Wellbeing_SteadyNerves_Utterance",
                                },
                            },
                            ["onClarify"] = "assess_need",
                            ["onMatch"] = "triage_care",
                            ["onRefuse"] = "declined_help",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.wellbeing.needs.checkin.clarify",
                        },
                        ["complete"] = {
                            ["responsePool"] = "semantic.wellbeing.needs.checkin.complete",
                            ["terminal"] = true,
                        },
                        ["declined_help"] = {
                            ["responsePool"] = "semantic.wellbeing.needs.checkin.declined",
                            ["terminal"] = true,
                        },
                        ["follow_up_recovery"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "SUGGEST",
                                    ["speechAct"] = "SUGGEST",
                                    ["subject"] = "WELLBEING",
                                },
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["stateValue"] = "holding_up",
                                    ["subject"] = "WELLBEING",
                                },
                                {
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                    ["stateValue"] = "dismissed",
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
                                        ["intent"] = "SUGGEST",
                                        ["speechAct"] = "SUGGEST",
                                        ["subject"] = "WELLBEING",
                                    },
                                    ["id"] = "wellbeing.checkin.plan_light_duty",
                                    ["labelFallback"] = "Agree to light watch duty",
                                    ["labelKey"] = "UI_PNC_Wellbeing_LightDuty_Label",
                                    ["utteranceFallback"] = "Take the quiet inside post while your leg recovers.",
                                    ["utteranceKey"] = "UI_PNC_Wellbeing_LightDuty_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["stateValue"] = "holding_up",
                                        ["subject"] = "WELLBEING",
                                    },
                                    ["id"] = "wellbeing.checkin.insist_fit",
                                    ["labelFallback"] = "Insist you can keep moving",
                                    ["labelKey"] = "UI_PNC_Wellbeing_InsistFit_Label",
                                    ["utteranceFallback"] = "No benching—wrap holds tight enough to walk another mile.",
                                    ["utteranceKey"] = "UI_PNC_Wellbeing_InsistFit_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "REFUSE",
                                        ["speechAct"] = "REFUSE",
                                        ["stateValue"] = "dismissed",
                                    },
                                    ["id"] = "wellbeing.checkin.cut_short",
                                    ["labelFallback"] = "Shut down further checking",
                                    ["labelKey"] = "UI_PNC_Wellbeing_CutShort_Label",
                                    ["utteranceFallback"] = "Enough fussing over me. Get back on point.",
                                    ["utteranceKey"] = "UI_PNC_Wellbeing_CutShort_Utterance",
                                },
                            },
                            ["onMatch"] = "resolve_checkin",
                            ["onRefuse"] = "declined_help",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.wellbeing.needs.checkin.resolve",
                        },
                        ["resolve_checkin"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "AGREE",
                                    ["speechAct"] = "AGREE",
                                },
                                {
                                    ["intent"] = "ACKNOWLEDGE",
                                    ["speechAct"] = "ACKNOWLEDGE",
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
                                    },
                                    ["id"] = "wellbeing.checkin.confirm_support",
                                    ["labelFallback"] = "Agree to cover each other",
                                    ["labelKey"] = "UI_PNC_Wellbeing_ConfirmSupport_Label",
                                    ["utteranceFallback"] = "Appreciate it—sing out the second anything swells up or fades.",
                                    ["utteranceKey"] = "UI_PNC_Wellbeing_ConfirmSupport_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "ACKNOWLEDGE",
                                        ["speechAct"] = "ACKNOWLEDGE",
                                    },
                                    ["id"] = "wellbeing.checkin.agree_steady",
                                    ["labelFallback"] = "Confirm good to continue",
                                    ["labelKey"] = "UI_PNC_Wellbeing_AgreeSteady_Label",
                                    ["utteranceFallback"] = "Glad to hear it. Keep moving steady.",
                                    ["utteranceKey"] = "UI_PNC_Wellbeing_AgreeSteady_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "REFUSE",
                                        ["speechAct"] = "REFUSE",
                                    },
                                    ["id"] = "wellbeing.checkin.withdraw_care",
                                    ["labelFallback"] = "Step back from checkin",
                                    ["labelKey"] = "UI_PNC_Wellbeing_Withdraw_Label",
                                    ["utteranceFallback"] = "Save your breath—we've got perimeter checks waiting.",
                                    ["utteranceKey"] = "UI_PNC_Wellbeing_Withdraw_Utterance",
                                },
                            },
                            ["onMatch"] = "complete",
                            ["onRefuse"] = "declined_help",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.wellbeing.needs.checkin.resolve",
                        },
                        ["triage_care"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "OFFER",
                                    ["speechAct"] = "OFFER",
                                    ["stateValue"] = "accept_treatment",
                                    ["subject"] = "NEEDS",
                                },
                                {
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                    ["stateValue"] = "refuse_treatment",
                                    ["subject"] = "NEEDS",
                                },
                                {
                                    ["intent"] = "ACCEPT",
                                    ["speechAct"] = "ACCEPT",
                                    ["stateValue"] = "reluctant",
                                    ["subject"] = "WELLBEING",
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
                                        ["path"] = "inventory.hasMedicalItem",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "OFFER",
                                        ["speechAct"] = "OFFER",
                                        ["stateValue"] = "accept_treatment",
                                        ["subject"] = "NEEDS",
                                    },
                                    ["id"] = "wellbeing.checkin.offer_med_kit",
                                    ["labelFallback"] = "Offer clean bandage or antiseptic",
                                    ["labelKey"] = "UI_PNC_Wellbeing_OfferMeds_Label",
                                    ["utteranceFallback"] = "Hold still—I've got sterile wrap right in my pouch.",
                                    ["utteranceKey"] = "UI_PNC_Wellbeing_OfferMeds_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "REFUSE",
                                        ["speechAct"] = "REFUSE",
                                        ["stateValue"] = "refuse_treatment",
                                        ["subject"] = "NEEDS",
                                    },
                                    ["id"] = "wellbeing.checkin.decline_dressing",
                                    ["labelFallback"] = "Decline dressing for now",
                                    ["labelKey"] = "UI_PNC_Wellbeing_DeclineMeds_Label",
                                    ["utteranceFallback"] = "Save the sterile cloth—just a scratch, bind me with rags later.",
                                    ["utteranceKey"] = "UI_PNC_Wellbeing_DeclineMeds_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "gte",
                                        ["path"] = "relationship.approval",
                                        ["value"] = -10,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "ACCEPT",
                                        ["speechAct"] = "ACCEPT",
                                        ["stateValue"] = "reluctant",
                                        ["subject"] = "WELLBEING",
                                    },
                                    ["id"] = "wellbeing.checkin.reluctant_check",
                                    ["labelFallback"] = "Allow quick look only",
                                    ["labelKey"] = "UI_PNC_Wellbeing_ReluctantCheck_Label",
                                    ["utteranceFallback"] = "Make it fast—keep eyes on the stairwell while you check.",
                                    ["utteranceKey"] = "UI_PNC_Wellbeing_ReluctantCheck_Utterance",
                                },
                            },
                            ["onMatch"] = "assess_need",
                            ["onRefuse"] = "declined_help",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.wellbeing.needs.checkin.assess",
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
                    "accept_treatment",
                    "refuse_treatment",
                    "reluctant",
                    "holding_up",
                    "strained",
                    "dismissed",
                },
                ["replySemantics"] = {
                    ["accept_treatment"] = {
                        ["outcome"] = "accept_treatment",
                        ["stance"] = "positive",
                    },
                    ["blocked"] = {
                        ["outcome"] = "blocked",
                        ["stance"] = "negative",
                    },
                    ["declined"] = {
                        ["outcome"] = "declined",
                        ["stance"] = "negative",
                    },
                    ["deferred"] = {
                        ["outcome"] = "deferred",
                        ["stance"] = "contextual",
                    },
                    ["dismissed"] = {
                        ["outcome"] = "dismissed",
                        ["stance"] = "negative",
                    },
                    ["evasive"] = {
                        ["outcome"] = "evasive",
                        ["stance"] = "neutral",
                    },
                    ["holding_up"] = {
                        ["outcome"] = "holding_up",
                        ["stance"] = "positive",
                    },
                    ["refuse_treatment"] = {
                        ["outcome"] = "refuse_treatment",
                        ["stance"] = "negative",
                    },
                    ["reluctant"] = {
                        ["outcome"] = "reluctant",
                        ["stance"] = "contextual",
                    },
                    ["strained"] = {
                        ["outcome"] = "strained",
                        ["stance"] = "contextual",
                    },
                    ["supported"] = {
                        ["outcome"] = "supported",
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
                ["accept_treatment"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "colony.work.status_exchange",
                        },
                    },
                    ["outcome"] = "accept_treatment",
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
                                        ["fallback"] = "Alright—wrap it tight before it dirties. Appreciate you carrying clean dressing.",
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
                ["dismissed"] = {
                    ["outcome"] = "dismissed",
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
                                        ["fallback"] = "Quit fussing over me. Keep your hands on your weapon.",
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
                ["holding_up"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "travel.excursion.plan_exchange",
                        },
                    },
                    ["outcome"] = "holding_up",
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
                                        ["fallback"] = "Tired to the bone, sure, but still standing and ready to move.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["refuse_treatment"] = {
                    ["outcome"] = "refuse_treatment",
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
                                        ["fallback"] = "Keep your roll for someone bleeding out—I'll stitch myself later.",
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
                                        ["fallback"] = "Fine, take one look, then get back on watch before anything hears us.",
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
                                        ["fallback"] = "Running dry without tap water's wearing everyone thin, not just me.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["supported"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "colony.work.status_exchange",
                        },
                    },
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
                                        ["fallback"] = "Appreciate that, {addressee.name}. Knowing someone's got an eye out helps more than you'd think.",
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
                                ["fallback"] = "Glad to see you still on your feet, {addressee.name}. Need anything while we've got a quiet moment?",
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
                ["fallback"] = "Glad to see you still on your feet, {addressee.name}. Need anything while we've got a quiet moment?",
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
                ["fallback"] = "Alright—wrap it tight before it dirties. Appreciate you carrying clean dressing.",
                ["outcome"] = "accept_treatment",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.wellbeing.needs.checkin.reply.accept_treatment.say.1.default",
                ["variantID"] = "default",
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
                ["fallback"] = "Quit fussing over me. Keep your hands on your weapon.",
                ["outcome"] = "dismissed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.wellbeing.needs.checkin.reply.dismissed.say.1.default",
                ["variantID"] = "default",
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
                ["fallback"] = "Tired to the bone, sure, but still standing and ready to move.",
                ["outcome"] = "holding_up",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.wellbeing.needs.checkin.reply.holding_up.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Keep your roll for someone bleeding out—I'll stitch myself later.",
                ["outcome"] = "refuse_treatment",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.wellbeing.needs.checkin.reply.refuse_treatment.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Fine, take one look, then get back on watch before anything hears us.",
                ["outcome"] = "reluctant",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.wellbeing.needs.checkin.reply.reluctant.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Running dry without tap water's wearing everyone thin, not just me.",
                ["outcome"] = "strained",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.wellbeing.needs.checkin.reply.strained.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Appreciate that, {addressee.name}. Knowing someone's got an eye out helps more than you'd think.",
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
