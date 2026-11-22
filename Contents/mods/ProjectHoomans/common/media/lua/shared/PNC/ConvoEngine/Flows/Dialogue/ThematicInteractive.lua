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
