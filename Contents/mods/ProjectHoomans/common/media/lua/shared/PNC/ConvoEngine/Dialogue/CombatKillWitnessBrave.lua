-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_kill_witness_brave",
        ["domainPath"] = "combat_kill_witness_brave",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.reaction.kill_witness_brave",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Clean kill. Check the flanks.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.reaction.kill_witness_brave.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "One down. Keep your head up.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.reaction.kill_witness_brave.say.2.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Good. Keep moving before they bunch up.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.reaction.kill_witness_brave.say.3.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.reaction",
            ["textRoles"] = {
                {
                    ["fallback"] = "Clean kill. Check the flanks.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.reaction.kill_witness_brave.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "One down. Keep your head up.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.reaction.kill_witness_brave.say.2.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Good. Keep moving before they bunch up.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.reaction.kill_witness_brave.say.3.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.reaction.kill_witness_brave",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "kill_witness_brave",
            ["sourceId"] = "combat.reaction.kill_witness_brave",
            ["sourcePath"] = "dialogue/combat_kill_witness_brave/combat_reaction_kill_witness_brave.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatKillWitnessBrave",
        ["namespace"] = "combat.reaction",
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
                    ["domain"] = "combat",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["events"] = {
                {
                    ["id"] = "combat_event",
                    ["kind"] = "combat_event",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:combat_kill",
                ["contentOwner"] = "projecthoomans.dialogue_content.events",
                ["responseAct"] = "REACT",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Clean kill. Check the flanks.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "One down. Keep your head up.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Good. Keep moving before they bunch up.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "combat",
                    ["id"] = "combat_reaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "combat.reaction.kill_witness_brave",
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
                            ["fallback"] = "Clean kill. Check the flanks.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.reaction.kill_witness_brave.say_1",
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
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/combat_kill_witness_brave/combat_reaction_kill_witness_brave.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Clean kill. Check the flanks.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.reaction.kill_witness_brave.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "One down. Keep your head up.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.reaction.kill_witness_brave.say.2.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Good. Keep moving before they bunch up.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.reaction.kill_witness_brave.say.3.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
