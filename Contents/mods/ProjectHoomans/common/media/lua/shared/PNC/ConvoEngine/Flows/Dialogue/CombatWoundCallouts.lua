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
                {
                    ["op"] = "neq",
                    ["path"] = "roles.hostile",
                    ["value"] = true,
                },
            },
        },
        ["domain"] = "semantic",
        ["id"] = "combat.injury.triage_exchange",
        ["initial"] = "injury_entry",
        ["nodes"] = {
            ["assess_wound_location"] = {
                ["accepts"] = {
                    {
                        ["intent"] = "INFORM",
                        ["speechAct"] = "INFORM",
                        ["subject"] = "COMBAT_INJURY",
                    },
                    {
                        ["intent"] = "AGREE",
                        ["speechAct"] = "AGREE",
                        ["subject"] = "COMBAT_INJURY",
                    },
                    {
                        ["intent"] = "CLARIFY",
                        ["speechAct"] = "CLARIFY",
                        ["stateValue"] = "squad_check",
                        ["subject"] = "COMBAT_INJURY",
                    },
                    {
                        ["intent"] = "QUESTION",
                        ["speechAct"] = "QUESTION",
                        ["stateValue"] = "bite_check",
                        ["subject"] = "COMBAT_INJURY",
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
                            ["path"] = "npcState.hasOpenWounds",
                            ["value"] = true,
                        },
                        ["consumers"] = {
                            "participant",
                        },
                        ["frame"] = {
                            ["intent"] = "INFORM",
                            ["speechAct"] = "INFORM",
                            ["stateValue"] = "covered_for_treatment",
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.patch_with_wounds",
                        ["labelFallback"] = "Press them to bandage open wounds",
                        ["labelKey"] = "UI_PNC_CombatInjury_PatchOpen_Label",
                        ["utteranceFallback"] = "It's still soaked with fresh blood. Step back two paces and wrap it!",
                        ["utteranceKey"] = "UI_PNC_CombatInjury_PatchOpen_Utterance",
                    },
                    {
                        ["consumers"] = {
                            "participant",
                        },
                        ["frame"] = {
                            ["intent"] = "AGREE",
                            ["speechAct"] = "AGREE",
                            ["stateValue"] = "patched_push_on",
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.hold_patched_line",
                        ["labelFallback"] = "Check if the bandage is holding",
                        ["labelKey"] = "UI_PNC_CombatInjury_HoldPatched_Label",
                        ["utteranceFallback"] = "If that dressing holds, swing steady and let me take the point.",
                        ["utteranceKey"] = "UI_PNC_CombatInjury_HoldPatched_Utterance",
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
                            ["stateValue"] = "squad_check",
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.pull_squad_opinion",
                        ["labelFallback"] = "Look to nearby squadmates",
                        ["labelKey"] = "UI_PNC_CombatInjury_SquadCheck_Label",
                        ["utteranceFallback"] = "Hey, keep eyes on their flank while we sort this injury out!",
                        ["utteranceKey"] = "UI_PNC_CombatInjury_SquadCheck_Utterance",
                    },
                    {
                        ["constraints"] = {
                            ["op"] = "eq",
                            ["path"] = "npcState.isBitten",
                            ["value"] = true,
                        },
                        ["consumers"] = {
                            "participant",
                        },
                        ["frame"] = {
                            ["intent"] = "QUESTION",
                            ["speechAct"] = "QUESTION",
                            ["stateValue"] = "bite_check",
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.inspect_bite_depth",
                        ["labelFallback"] = "Verify bite transmission risk",
                        ["labelKey"] = "UI_PNC_CombatInjury_InspectBite_Label",
                        ["utteranceFallback"] = "Hold still so I can see whether that bite broke deep.",
                        ["utteranceKey"] = "UI_PNC_CombatInjury_InspectBite_Utterance",
                    },
                },
                ["onClarify"] = "squad_reaction_interjection",
                ["onMatch"] = "tactical_fallback_or_push",
                ["onRefuse"] = "bite_transmission_check",
                ["onUnrelated"] = "suspend",
                ["responsePool"] = "semantic.flow.combat.injury.triage.assess",
            },
            ["bite_transmission_check"] = {
                ["accepts"] = {
                    {
                        ["intent"] = "INFORM",
                        ["speechAct"] = "INFORM",
                        ["stateValue"] = "bite_non_lethal_stabilized",
                        ["subject"] = "COMBAT_INJURY",
                    },
                    {
                        ["intent"] = "WARN",
                        ["speechAct"] = "WARN",
                        ["stateValue"] = "bite_lethal",
                        ["subject"] = "COMBAT_INJURY",
                    },
                    {
                        ["intent"] = "CHALLENGE",
                        ["speechAct"] = "CHALLENGE",
                        ["stateValue"] = "bite_psychopath_threatened",
                        ["subject"] = "COMBAT_INJURY",
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
                            ["path"] = "worldKnowledge.salivaTransmissible",
                            ["value"] = false,
                        },
                        ["consumers"] = {
                            "participant",
                        },
                        ["frame"] = {
                            ["intent"] = "INFORM",
                            ["speechAct"] = "INFORM",
                            ["stateValue"] = "bite_non_lethal_stabilized",
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.bite_not_transmissible",
                        ["labelFallback"] = "Remind them bites do not turn people here",
                        ["labelKey"] = "UI_PNC_CombatInjury_BiteNoSaliva_Label",
                        ["utteranceFallback"] = "Breathe! The sickness does not spread by saliva here, just stop the bleeding!",
                        ["utteranceKey"] = "UI_PNC_CombatInjury_BiteNoSaliva_Utterance",
                    },
                    {
                        ["constraints"] = {
                            ["op"] = "eq",
                            ["path"] = "worldKnowledge.salivaTransmissible",
                            ["value"] = true,
                        },
                        ["consumers"] = {
                            "participant",
                        },
                        ["frame"] = {
                            ["intent"] = "WARN",
                            ["speechAct"] = "WARN",
                            ["stateValue"] = "bite_lethal",
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.bite_lethal_dread",
                        ["labelFallback"] = "Acknowledge lethal bite risk",
                        ["labelKey"] = "UI_PNC_CombatInjury_BiteLethal_Label",
                        ["utteranceFallback"] = "Stay calm. Wrap that bite tight and watch the squad while we clear a way out.",
                        ["utteranceKey"] = "UI_PNC_CombatInjury_BiteLethal_Utterance",
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
                            ["intent"] = "CHALLENGE",
                            ["speechAct"] = "CHALLENGE",
                            ["stateValue"] = "bite_psychopath_threatened",
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.psychopath_call_threat",
                        ["labelFallback"] = "Confront hostile squadmate over bitten ally",
                        ["labelKey"] = "UI_PNC_CombatInjury_PsychoThreat_Label",
                        ["utteranceFallback"] = "Nobody is pulling a trigger on them in the middle of my fight!",
                        ["utteranceKey"] = "UI_PNC_CombatInjury_PsychoThreat_Utterance",
                    },
                },
                ["onClarify"] = "squad_reaction_interjection",
                ["onMatch"] = "quarantine_or_mercy_standoff",
                ["onRefuse"] = "triage_resolution",
                ["onUnrelated"] = "suspend",
                ["responsePool"] = "semantic.flow.combat.injury.triage.bite_check",
            },
            ["injury_entry"] = {
                ["gate"] = {
                    ["type"] = "pnc:injury_observation",
                },
                ["onFail"] = "injury_report_open",
                ["onPass"] = "observation_reply",
                ["onUnknown"] = "injury_report_open",
            },
            ["injury_report_open"] = {
                ["accepts"] = {
                    {
                        ["intent"] = "QUESTION",
                        ["speechAct"] = "QUESTION",
                        ["subject"] = "COMBAT_INJURY",
                    },
                    {
                        ["intent"] = "INFORM",
                        ["speechAct"] = "INFORM",
                        ["subject"] = "COMBAT_INJURY",
                    },
                    {
                        ["intent"] = "ACCEPT",
                        ["speechAct"] = "ACCEPT",
                        ["stateValue"] = "covered_for_treatment",
                        ["subject"] = "COMBAT_INJURY",
                    },
                    {
                        ["intent"] = "CLARIFY",
                        ["speechAct"] = "CLARIFY",
                        ["stateValue"] = "ordered_fallback",
                        ["subject"] = "COMBAT_INJURY",
                    },
                    {
                        ["intent"] = "WARN",
                        ["speechAct"] = "WARN",
                        ["stateValue"] = "bitten",
                        ["subject"] = "COMBAT_INJURY",
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
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.check_where_hit",
                        ["labelFallback"] = "Ask where you're hit and how bad it is",
                        ["labelKey"] = "UI_PNC_CombatInjury_CheckWhere_Label",
                        ["utteranceFallback"] = "Where did they get you? Is that wrap still holding?",
                        ["utteranceKey"] = "UI_PNC_CombatInjury_CheckWhere_Utterance",
                    },
                    {
                        ["constraints"] = {
                            ["op"] = "eq",
                            ["path"] = "npcState.hasOpenWounds",
                            ["value"] = true,
                        },
                        ["consumers"] = {
                            "participant",
                        },
                        ["frame"] = {
                            ["intent"] = "ACCEPT",
                            ["speechAct"] = "ACCEPT",
                            ["stateValue"] = "covered_for_treatment",
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.offer_cover_wrap",
                        ["labelFallback"] = "Cover them while they patch up",
                        ["labelKey"] = "UI_PNC_CombatInjury_OfferCover_Label",
                        ["utteranceFallback"] = "I have eyes on the dead. Tie that wound off right now!",
                        ["utteranceKey"] = "UI_PNC_CombatInjury_OfferCover_Utterance",
                    },
                    {
                        ["consumers"] = {
                            "participant",
                        },
                        ["frame"] = {
                            ["intent"] = "CLARIFY",
                            ["speechAct"] = "CLARIFY",
                            ["stateValue"] = "ordered_fallback",
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.order_fallback",
                        ["labelFallback"] = "Order them behind the line",
                        ["labelKey"] = "UI_PNC_CombatInjury_OrderFallback_Label",
                        ["utteranceFallback"] = "You're bleeding too hard to trade swings! Pull back behind me!",
                        ["utteranceKey"] = "UI_PNC_CombatInjury_OrderFallback_Utterance",
                    },
                    {
                        ["consumers"] = {
                            "participant",
                        },
                        ["frame"] = {
                            ["intent"] = "INFORM",
                            ["speechAct"] = "INFORM",
                            ["stateValue"] = "reassured_bond",
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.reassure_keep_fighting",
                        ["labelFallback"] = "Keep them focused and fighting",
                        ["labelKey"] = "UI_PNC_CombatInjury_Reassure_Label",
                        ["utteranceFallback"] = "Stay on my shoulder and watch your wrap. We are not losing you today.",
                        ["utteranceKey"] = "UI_PNC_CombatInjury_Reassure_Utterance",
                    },
                    {
                        ["constraints"] = {
                            ["op"] = "eq",
                            ["path"] = "npcState.isBitten",
                            ["value"] = true,
                        },
                        ["consumers"] = {
                            "participant",
                        },
                        ["frame"] = {
                            ["intent"] = "WARN",
                            ["speechAct"] = "WARN",
                            ["stateValue"] = "bitten",
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.check_bite_exposure",
                        ["labelFallback"] = "Check the bite mark immediately",
                        ["labelKey"] = "UI_PNC_CombatInjury_CheckBite_Label",
                        ["utteranceFallback"] = "Wait, was that teeth? Let me see that bite right now!",
                        ["utteranceKey"] = "UI_PNC_CombatInjury_CheckBite_Utterance",
                    },
                },
                ["onClarify"] = "tactical_fallback_or_push",
                ["onMatch"] = "assess_wound_location",
                ["onRefuse"] = "bite_transmission_check",
                ["onUnrelated"] = "suspend",
                ["responsePool"] = "semantic.flow.combat.injury.triage.open",
                ["slots"] = {
                    ["woundPart"] = {
                        ["owner"] = "combat.injury.triage_exchange",
                        ["source"] = "slots.woundPart.value",
                        ["type"] = "string",
                    },
                    ["woundType"] = {
                        ["owner"] = "combat.injury.triage_exchange",
                        ["source"] = "slots.woundType.value",
                        ["type"] = "string",
                    },
                },
            },
            ["observation_followup"] = {
                ["accepts"] = {
                    {
                        ["intent"] = "ACKNOWLEDGE",
                        ["speechAct"] = "ACKNOWLEDGE",
                        ["stateValue"] = "observation_thanks",
                        ["subject"] = "COMBAT_INJURY",
                    },
                    {
                        ["intent"] = "INFORM",
                        ["speechAct"] = "INFORM",
                        ["stateValue"] = "observation_owe",
                        ["subject"] = "COMBAT_INJURY",
                    },
                    {
                        ["intent"] = "QUESTION",
                        ["speechAct"] = "QUESTION",
                        ["stateValue"] = "observation_sure",
                        ["subject"] = "COMBAT_INJURY",
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
                            ["stateValue"] = "observation_thanks",
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.observation_thanks",
                        ["labelFallback"] = "Thanks.",
                        ["labelKey"] = "UI_PNC_InjuryObservation_observation_thanks_Label",
                        ["utteranceFallback"] = "Thanks.",
                        ["utteranceKey"] = "UI_PNC_InjuryObservation_observation_thanks_Utterance",
                    },
                    {
                        ["consumers"] = {
                            "participant",
                        },
                        ["frame"] = {
                            ["intent"] = "INFORM",
                            ["speechAct"] = "INFORM",
                            ["stateValue"] = "observation_owe",
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.observation_owe",
                        ["labelFallback"] = "I owe you.",
                        ["labelKey"] = "UI_PNC_InjuryObservation_observation_owe_Label",
                        ["utteranceFallback"] = "I owe you.",
                        ["utteranceKey"] = "UI_PNC_InjuryObservation_observation_owe_Utterance",
                    },
                    {
                        ["consumers"] = {
                            "participant",
                        },
                        ["frame"] = {
                            ["intent"] = "QUESTION",
                            ["speechAct"] = "QUESTION",
                            ["stateValue"] = "observation_sure",
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.observation_sure",
                        ["labelFallback"] = "You're sure?",
                        ["labelKey"] = "UI_PNC_InjuryObservation_observation_sure_Label",
                        ["utteranceFallback"] = "You're sure?",
                        ["utteranceKey"] = "UI_PNC_InjuryObservation_observation_sure_Utterance",
                    },
                },
                ["onMatch"] = "triage_resolution",
                ["onUnrelated"] = "suspend",
                ["responsePool"] = "semantic.flow.combat.injury.triage.observation_followup",
            },
            ["observation_reply"] = {
                ["accepts"] = {
                    {
                        ["intent"] = "ACKNOWLEDGE",
                        ["speechAct"] = "ACKNOWLEDGE",
                        ["stateValue"] = "observation_known",
                        ["subject"] = "COMBAT_INJURY",
                    },
                    {
                        ["intent"] = "INFORM",
                        ["speechAct"] = "INFORM",
                        ["stateValue"] = "observation_no_dressing",
                        ["subject"] = "COMBAT_INJURY",
                    },
                    {
                        ["intent"] = "QUESTION",
                        ["speechAct"] = "QUESTION",
                        ["stateValue"] = "observation_help",
                        ["subject"] = "COMBAT_INJURY",
                    },
                    {
                        ["intent"] = "DISAGREE",
                        ["speechAct"] = "DISAGREE",
                        ["stateValue"] = "observation_minimize",
                        ["subject"] = "COMBAT_INJURY",
                    },
                    {
                        ["intent"] = "REFUSE",
                        ["speechAct"] = "REFUSE",
                        ["stateValue"] = "observation_dismiss",
                        ["subject"] = "COMBAT_INJURY",
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
                            ["stateValue"] = "observation_known",
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.observation_known",
                        ["labelFallback"] = "I know.",
                        ["labelKey"] = "UI_PNC_InjuryObservation_observation_known_Label",
                        ["utteranceFallback"] = "I know.",
                        ["utteranceKey"] = "UI_PNC_InjuryObservation_observation_known_Utterance",
                    },
                    {
                        ["consumers"] = {
                            "participant",
                        },
                        ["frame"] = {
                            ["intent"] = "INFORM",
                            ["speechAct"] = "INFORM",
                            ["stateValue"] = "observation_no_dressing",
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.observation_no_dressing",
                        ["labelFallback"] = "I don't have a bandage.",
                        ["labelKey"] = "UI_PNC_InjuryObservation_observation_no_dressing_Label",
                        ["utteranceFallback"] = "I don't have a bandage.",
                        ["utteranceKey"] = "UI_PNC_InjuryObservation_observation_no_dressing_Utterance",
                    },
                    {
                        ["consumers"] = {
                            "participant",
                        },
                        ["frame"] = {
                            ["intent"] = "QUESTION",
                            ["speechAct"] = "QUESTION",
                            ["stateValue"] = "observation_help",
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.observation_help",
                        ["labelFallback"] = "Can you help me?",
                        ["labelKey"] = "UI_PNC_InjuryObservation_observation_help_Label",
                        ["utteranceFallback"] = "Can you help me?",
                        ["utteranceKey"] = "UI_PNC_InjuryObservation_observation_help_Utterance",
                    },
                    {
                        ["consumers"] = {
                            "participant",
                        },
                        ["frame"] = {
                            ["intent"] = "DISAGREE",
                            ["speechAct"] = "DISAGREE",
                            ["stateValue"] = "observation_minimize",
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.observation_minimize",
                        ["labelFallback"] = "It's not that bad.",
                        ["labelKey"] = "UI_PNC_InjuryObservation_observation_minimize_Label",
                        ["utteranceFallback"] = "It's not that bad.",
                        ["utteranceKey"] = "UI_PNC_InjuryObservation_observation_minimize_Utterance",
                    },
                    {
                        ["consumers"] = {
                            "participant",
                        },
                        ["frame"] = {
                            ["intent"] = "REFUSE",
                            ["speechAct"] = "REFUSE",
                            ["stateValue"] = "observation_dismiss",
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.observation_dismiss",
                        ["labelFallback"] = "Mind your own business.",
                        ["labelKey"] = "UI_PNC_InjuryObservation_observation_dismiss_Label",
                        ["utteranceFallback"] = "Mind your own business.",
                        ["utteranceKey"] = "UI_PNC_InjuryObservation_observation_dismiss_Utterance",
                    },
                },
                ["onMatch"] = "observation_supply",
                ["onRefuse"] = "triage_resolution",
                ["onUnrelated"] = "suspend",
                ["responsePool"] = "semantic.flow.combat.injury.triage.observation_reply",
            },
            ["observation_supply"] = {
                ["accepts"] = {
                    {
                        ["intent"] = "ACCEPT",
                        ["speechAct"] = "ACCEPT",
                        ["stateValue"] = "observation_accept_aid",
                        ["subject"] = "COMBAT_INJURY",
                    },
                    {
                        ["intent"] = "REFUSE",
                        ["speechAct"] = "REFUSE",
                        ["stateValue"] = "observation_decline_aid",
                        ["subject"] = "COMBAT_INJURY",
                    },
                    {
                        ["intent"] = "REFUSE",
                        ["speechAct"] = "REFUSE",
                        ["stateValue"] = "observation_decline_costly",
                        ["subject"] = "COMBAT_INJURY",
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
                            ["stateValue"] = "observation_accept_aid",
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.observation_accept_aid",
                        ["labelFallback"] = "Yes, I could use it.",
                        ["labelKey"] = "UI_PNC_InjuryObservation_observation_accept_aid_Label",
                        ["utteranceFallback"] = "Yes, I could use it.",
                        ["utteranceKey"] = "UI_PNC_InjuryObservation_observation_accept_aid_Utterance",
                    },
                    {
                        ["consumers"] = {
                            "participant",
                        },
                        ["frame"] = {
                            ["intent"] = "REFUSE",
                            ["speechAct"] = "REFUSE",
                            ["stateValue"] = "observation_decline_aid",
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.observation_decline_aid",
                        ["labelFallback"] = "Keep it. I'll manage.",
                        ["labelKey"] = "UI_PNC_InjuryObservation_observation_decline_aid_Label",
                        ["utteranceFallback"] = "Keep it. I'll manage.",
                        ["utteranceKey"] = "UI_PNC_InjuryObservation_observation_decline_aid_Utterance",
                    },
                    {
                        ["consumers"] = {
                            "participant",
                        },
                        ["frame"] = {
                            ["intent"] = "REFUSE",
                            ["speechAct"] = "REFUSE",
                            ["stateValue"] = "observation_decline_costly",
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.observation_decline_costly",
                        ["labelFallback"] = "Don't waste it on me.",
                        ["labelKey"] = "UI_PNC_InjuryObservation_observation_decline_costly_Label",
                        ["utteranceFallback"] = "Don't waste it on me.",
                        ["utteranceKey"] = "UI_PNC_InjuryObservation_observation_decline_costly_Utterance",
                    },
                },
                ["onMatch"] = "observation_followup",
                ["onRefuse"] = "triage_resolution",
                ["onUnrelated"] = "suspend",
                ["responsePool"] = "semantic.flow.combat.injury.triage.observation_supply",
            },
            ["quarantine_or_mercy_standoff"] = {
                ["accepts"] = {
                    {
                        ["intent"] = "ACCEPT",
                        ["speechAct"] = "ACCEPT",
                        ["subject"] = "COMBAT_INJURY",
                    },
                    {
                        ["intent"] = "CHALLENGE",
                        ["speechAct"] = "CHALLENGE",
                        ["subject"] = "COMBAT_INJURY",
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
                            ["stateValue"] = "bite_quarantined",
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.standoff_stabilize",
                        ["labelFallback"] = "Order immediate bandage and watch",
                        ["labelKey"] = "UI_PNC_CombatInjury_StandoffStabilize_Label",
                        ["utteranceFallback"] = "Stay on your feet, wrap the bite, and we sort out the rest back at camp.",
                        ["utteranceKey"] = "UI_PNC_CombatInjury_StandoffStabilize_Utterance",
                    },
                    {
                        ["consumers"] = {
                            "participant",
                        },
                        ["frame"] = {
                            ["intent"] = "CHALLENGE",
                            ["speechAct"] = "CHALLENGE",
                            ["stateValue"] = "bite_psychopath_threatened",
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.standoff_hostile_warning",
                        ["labelFallback"] = "Warn aggressive squadmate to stand down",
                        ["labelKey"] = "UI_PNC_CombatInjury_StandoffHostile_Label",
                        ["utteranceFallback"] = "Try shooting my teammate and you answer to me next.",
                        ["utteranceKey"] = "UI_PNC_CombatInjury_StandoffHostile_Utterance",
                    },
                },
                ["onMatch"] = "triage_resolution",
                ["onRefuse"] = "triage_resolution",
                ["onUnrelated"] = "suspend",
                ["responsePool"] = "semantic.flow.combat.injury.triage.bite_standoff",
            },
            ["squad_reaction_interjection"] = {
                ["accepts"] = {
                    {
                        ["intent"] = "MEDIATE",
                        ["speechAct"] = "MEDIATE",
                        ["subject"] = "COMBAT_INJURY",
                    },
                    {
                        ["intent"] = "DISAGREE",
                        ["speechAct"] = "DISAGREE",
                        ["subject"] = "COMBAT_INJURY",
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
                            ["intent"] = "MEDIATE",
                            ["speechAct"] = "MEDIATE",
                            ["stateValue"] = "reassured_bond",
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.defend_injured_ally",
                        ["labelFallback"] = "Keep the squad together and protect them",
                        ["labelKey"] = "UI_PNC_CombatInjury_DefendAlly_Label",
                        ["utteranceFallback"] = "Lower that barrel right now! We patch our own first and fight together.",
                        ["utteranceKey"] = "UI_PNC_CombatInjury_DefendAlly_Utterance",
                    },
                    {
                        ["constraints"] = {
                            ["op"] = "eq",
                            ["path"] = "worldKnowledge.salivaTransmissible",
                            ["value"] = true,
                        },
                        ["consumers"] = {
                            "participant",
                        },
                        ["frame"] = {
                            ["intent"] = "DISAGREE",
                            ["speechAct"] = "DISAGREE",
                            ["stateValue"] = "bite_quarantined",
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.quarantine_after_fight",
                        ["labelFallback"] = "Set quarantine perimeter after contact",
                        ["labelKey"] = "UI_PNC_CombatInjury_Quarantine_Label",
                        ["utteranceFallback"] = "Keep twenty paces back once these walkers drop, we will watch the fever safely.",
                        ["utteranceKey"] = "UI_PNC_CombatInjury_Quarantine_Utterance",
                    },
                },
                ["onClarify"] = "quarantine_or_mercy_standoff",
                ["onMatch"] = "triage_resolution",
                ["onRefuse"] = "triage_resolution",
                ["onUnrelated"] = "suspend",
                ["responsePool"] = "semantic.flow.combat.injury.triage.squad_interject",
            },
            ["tactical_fallback_or_push"] = {
                ["accepts"] = {
                    {
                        ["intent"] = "AGREE",
                        ["speechAct"] = "AGREE",
                        ["subject"] = "COMBAT_INJURY",
                    },
                    {
                        ["intent"] = "ACCEPT",
                        ["speechAct"] = "ACCEPT",
                        ["subject"] = "COMBAT_INJURY",
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
                            ["stateValue"] = "ordered_fallback",
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.rotate_rear_guard",
                        ["labelFallback"] = "Rotate them to rear guard",
                        ["labelKey"] = "UI_PNC_CombatInjury_RotateRear_Label",
                        ["utteranceFallback"] = "Switch spots with me now! Watch the rear while I clear the front.",
                        ["utteranceKey"] = "UI_PNC_CombatInjury_RotateRear_Utterance",
                    },
                    {
                        ["consumers"] = {
                            "participant",
                        },
                        ["frame"] = {
                            ["intent"] = "ACCEPT",
                            ["speechAct"] = "ACCEPT",
                            ["stateValue"] = "patched_push_on",
                            ["subject"] = "COMBAT_INJURY",
                        },
                        ["id"] = "combat.injury.confirm_hold_patched",
                        ["labelFallback"] = "Hold formation patched up",
                        ["labelKey"] = "UI_PNC_CombatInjury_ConfirmHold_Label",
                        ["utteranceFallback"] = "Good wrap. Stick close so nothing hits that limb again.",
                        ["utteranceKey"] = "UI_PNC_CombatInjury_ConfirmHold_Utterance",
                    },
                },
                ["onMatch"] = "triage_resolution",
                ["onRefuse"] = "triage_resolution",
                ["onUnrelated"] = "suspend",
                ["responsePool"] = "semantic.flow.combat.injury.triage.tactical_order",
            },
            ["triage_resolution"] = {
                ["responsePool"] = "semantic.flow.combat.injury.triage.resolved",
                ["terminal"] = true,
            },
        },
        ["owner"] = "ProjectHoomans",
        ["triggers"] = {
            {
                ["intent"] = "QUESTION",
                ["subject"] = "COMBAT_INJURY",
            },
            {
                ["intent"] = "CHECK",
                ["subject"] = "COMBAT_INJURY",
            },
            {
                ["intent"] = "OFFER",
                ["subject"] = "COMBAT_INJURY",
            },
            {
                ["intent"] = "ACCEPT",
                ["subject"] = "COMBAT_INJURY",
            },
            {
                ["intent"] = "CLARIFY",
                ["subject"] = "COMBAT_INJURY",
            },
            {
                ["intent"] = "WARN",
                ["subject"] = "COMBAT_INJURY",
            },
            {
                ["intent"] = "INFORM",
                ["subject"] = "COMBAT_INJURY",
            },
        },
        ["version"] = 1,
    },
}
