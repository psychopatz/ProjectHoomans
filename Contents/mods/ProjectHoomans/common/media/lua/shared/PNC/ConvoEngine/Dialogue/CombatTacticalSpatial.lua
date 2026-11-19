-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_tactical_spatial",
        ["domainPath"] = "combat_tactical_spatial",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.tactical_spatial.hostile",
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
                                ["fallback"] = "Hostiles at {scene.clock}!",
                                ["id"] = "clock",
                                ["templateID"] = "convo.combat.tactical_spatial.hostile.say.1.clock",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Hostiles {scene.relative}!",
                                ["id"] = "coarse",
                                ["templateID"] = "convo.combat.tactical_spatial.hostile.say.1.coarse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.tactical_spatial",
            ["textRoles"] = {
                {
                    ["fallback"] = "Hostiles at {scene.clock}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.tactical_spatial.hostile.say.1.clock",
                    ["variantID"] = "clock",
                },
                {
                    ["fallback"] = "Hostiles {scene.relative}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.tactical_spatial.hostile.say.1.coarse",
                    ["variantID"] = "coarse",
                },
            },
        },
        ["id"] = "combat.tactical_spatial.hostile",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "hostile",
            ["sourceId"] = "combat.tactical_spatial.hostile",
            ["sourcePath"] = "dialogue/combat_tactical_spatial/combat_tactical_spatial_hostile.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatTacticalSpatial",
        ["namespace"] = "combat.tactical_spatial",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseAct"] = "REACT",
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
                                ["fallback"] = "Hostiles at {scene.clock}!",
                                ["id"] = "clock",
                            },
                            {
                                ["fallback"] = "Hostiles {scene.relative}!",
                                ["id"] = "coarse",
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
            ["responsePlanID"] = "combat.tactical_spatial.hostile",
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
                            ["fallback"] = "Hostiles at {scene.clock}!",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.tactical_spatial.hostile.say_1",
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
        ["sourceShard"] = "dialogue/combat_tactical_spatial/combat_tactical_spatial_hostile.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Hostiles at {scene.clock}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.tactical_spatial.hostile.say.1.clock",
                ["variantID"] = "clock",
            },
            {
                ["fallback"] = "Hostiles {scene.relative}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.tactical_spatial.hostile.say.1.coarse",
                ["variantID"] = "coarse",
            },
        },
        ["when"] = nil,
    },
}
