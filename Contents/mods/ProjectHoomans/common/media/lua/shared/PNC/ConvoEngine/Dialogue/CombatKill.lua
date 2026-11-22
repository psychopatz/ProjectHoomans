-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_kill",
        ["domainPath"] = "combat_kill",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.kill.blade",
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
                                ["fallback"] = "Took its head clean off.",
                                ["id"] = "aggressive.blade_head",
                                ["templateID"] = "convo.combat.kill.blade.say.1.aggressive.blade_head",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                            {
                                ["fallback"] = "Clean cut. Next.",
                                ["id"] = "brave.blade_head",
                                ["templateID"] = "convo.combat.kill.blade.say.1.brave.blade_head",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                            {
                                ["fallback"] = "Head came apart. Moving on.",
                                ["id"] = "cold.blade_head",
                                ["templateID"] = "convo.combat.kill.blade.say.1.cold.blade_head",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                            {
                                ["fallback"] = "Blade did its job. Keep moving.",
                                ["id"] = "practical.blade",
                                ["templateID"] = "convo.combat.kill.blade.say.1.practical.blade",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                            {
                                ["fallback"] = "Cut down.",
                                ["id"] = "reserved.blade",
                                ["templateID"] = "convo.combat.kill.blade.say.1.reserved.blade",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                            {
                                ["fallback"] = "Oh God... there's blood everywhere.",
                                ["id"] = "shaken.blade_head",
                                ["templateID"] = "convo.combat.kill.blade.say.1.shaken.blade_head",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.kill",
            ["slots"] = {
                ["weapon"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.item",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "Took its head clean off.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.blade.say.1.aggressive.blade_head",
                    ["variantID"] = "aggressive.blade_head",
                },
                {
                    ["fallback"] = "Clean cut. Next.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.blade.say.1.brave.blade_head",
                    ["variantID"] = "brave.blade_head",
                },
                {
                    ["fallback"] = "Head came apart. Moving on.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.blade.say.1.cold.blade_head",
                    ["variantID"] = "cold.blade_head",
                },
                {
                    ["fallback"] = "Blade did its job. Keep moving.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.blade.say.1.practical.blade",
                    ["variantID"] = "practical.blade",
                },
                {
                    ["fallback"] = "Cut down.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.blade.say.1.reserved.blade",
                    ["variantID"] = "reserved.blade",
                },
                {
                    ["fallback"] = "Oh God... there's blood everywhere.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.blade.say.1.shaken.blade_head",
                    ["variantID"] = "shaken.blade_head",
                },
            },
        },
        ["id"] = "combat.kill.blade",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "blade",
            ["sourceId"] = "combat.kill.blade",
            ["sourcePath"] = "dialogue/combat_kill/combat_kill_blade.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatKill",
        ["namespace"] = "combat.kill",
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
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "Took its head clean off.",
                                ["id"] = "aggressive.blade_head",
                            },
                            {
                                ["fallback"] = "Clean cut. Next.",
                                ["id"] = "brave.blade_head",
                            },
                            {
                                ["fallback"] = "Head came apart. Moving on.",
                                ["id"] = "cold.blade_head",
                            },
                            {
                                ["fallback"] = "Blade did its job. Keep moving.",
                                ["id"] = "practical.blade",
                            },
                            {
                                ["fallback"] = "Cut down.",
                                ["id"] = "reserved.blade",
                            },
                            {
                                ["fallback"] = "Oh God... there's blood everywhere.",
                                ["id"] = "shaken.blade_head",
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
            ["responsePlanID"] = "combat.kill.blade",
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
                            ["fallback"] = "Took its head clean off.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.kill.blade.say_1",
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
            ["weapon"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.item",
            },
        },
        ["sourceShard"] = "dialogue/combat_kill/combat_kill_blade.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Took its head clean off.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.blade.say.1.aggressive.blade_head",
                ["variantID"] = "aggressive.blade_head",
            },
            {
                ["fallback"] = "Clean cut. Next.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.blade.say.1.brave.blade_head",
                ["variantID"] = "brave.blade_head",
            },
            {
                ["fallback"] = "Head came apart. Moving on.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.blade.say.1.cold.blade_head",
                ["variantID"] = "cold.blade_head",
            },
            {
                ["fallback"] = "Blade did its job. Keep moving.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.blade.say.1.practical.blade",
                ["variantID"] = "practical.blade",
            },
            {
                ["fallback"] = "Cut down.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.blade.say.1.reserved.blade",
                ["variantID"] = "reserved.blade",
            },
            {
                ["fallback"] = "Oh God... there's blood everywhere.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.blade.say.1.shaken.blade_head",
                ["variantID"] = "shaken.blade_head",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_kill",
        ["domainPath"] = "combat_kill",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.kill.firearm",
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
                                ["fallback"] = "This {slot.weapon.name} still shoots straight.",
                                ["id"] = "aggressive.firearm_high_named.say.1",
                                ["templateID"] = "convo.combat.kill.firearm.say.1.aggressive.firearm_high_named.say.1",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                            {
                                ["fallback"] = "Right where I wanted it. Down.",
                                ["id"] = "aggressive.firearm_high_named.say.2",
                                ["templateID"] = "convo.combat.kill.firearm.say.1.aggressive.firearm_high_named.say.2",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                            {
                                ["fallback"] = "Dead center. Keep moving.",
                                ["id"] = "brave.firearm_high",
                                ["templateID"] = "convo.combat.kill.firearm.say.1.brave.firearm_high",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                            {
                                ["fallback"] = "Clean shot.",
                                ["id"] = "cold.firearm_high",
                                ["templateID"] = "convo.combat.kill.firearm.say.1.cold.firearm_high",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                            {
                                ["fallback"] = "Good shot placement. Check the lane.",
                                ["id"] = "practical.firearm_high",
                                ["templateID"] = "convo.combat.kill.firearm.say.1.practical.firearm_high",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                            {
                                ["fallback"] = "Hit it. Don't count on luck twice.",
                                ["id"] = "practical.firearm_low",
                                ["templateID"] = "convo.combat.kill.firearm.say.1.practical.firearm_low",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                            {
                                ["fallback"] = "Hit.",
                                ["id"] = "reserved.firearm",
                                ["templateID"] = "convo.combat.kill.firearm.say.1.reserved.firearm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                            {
                                ["fallback"] = "Jesus... I actually hit it.",
                                ["id"] = "shaken.firearm_low",
                                ["templateID"] = "convo.combat.kill.firearm.say.1.shaken.firearm_low",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                            {
                                ["fallback"] = "Got it. You good?",
                                ["id"] = "supportive.firearm",
                                ["templateID"] = "convo.combat.kill.firearm.say.1.supportive.firearm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.kill",
            ["slots"] = {
                ["weapon"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.item",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "This {slot.weapon.name} still shoots straight.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.firearm.say.1.aggressive.firearm_high_named.say.1",
                    ["variantID"] = "aggressive.firearm_high_named.say.1",
                },
                {
                    ["fallback"] = "Right where I wanted it. Down.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.firearm.say.1.aggressive.firearm_high_named.say.2",
                    ["variantID"] = "aggressive.firearm_high_named.say.2",
                },
                {
                    ["fallback"] = "Dead center. Keep moving.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.firearm.say.1.brave.firearm_high",
                    ["variantID"] = "brave.firearm_high",
                },
                {
                    ["fallback"] = "Clean shot.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.firearm.say.1.cold.firearm_high",
                    ["variantID"] = "cold.firearm_high",
                },
                {
                    ["fallback"] = "Good shot placement. Check the lane.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.firearm.say.1.practical.firearm_high",
                    ["variantID"] = "practical.firearm_high",
                },
                {
                    ["fallback"] = "Hit it. Don't count on luck twice.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.firearm.say.1.practical.firearm_low",
                    ["variantID"] = "practical.firearm_low",
                },
                {
                    ["fallback"] = "Hit.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.firearm.say.1.reserved.firearm",
                    ["variantID"] = "reserved.firearm",
                },
                {
                    ["fallback"] = "Jesus... I actually hit it.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.firearm.say.1.shaken.firearm_low",
                    ["variantID"] = "shaken.firearm_low",
                },
                {
                    ["fallback"] = "Got it. You good?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.firearm.say.1.supportive.firearm",
                    ["variantID"] = "supportive.firearm",
                },
            },
        },
        ["id"] = "combat.kill.firearm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "firearm",
            ["sourceId"] = "combat.kill.firearm",
            ["sourcePath"] = "dialogue/combat_kill/combat_kill_firearm.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatKill",
        ["namespace"] = "combat.kill",
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
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "This {slot.weapon.name} still shoots straight.",
                                ["id"] = "aggressive.firearm_high_named.say.1",
                            },
                            {
                                ["fallback"] = "Right where I wanted it. Down.",
                                ["id"] = "aggressive.firearm_high_named.say.2",
                            },
                            {
                                ["fallback"] = "Dead center. Keep moving.",
                                ["id"] = "brave.firearm_high",
                            },
                            {
                                ["fallback"] = "Clean shot.",
                                ["id"] = "cold.firearm_high",
                            },
                            {
                                ["fallback"] = "Good shot placement. Check the lane.",
                                ["id"] = "practical.firearm_high",
                            },
                            {
                                ["fallback"] = "Hit it. Don't count on luck twice.",
                                ["id"] = "practical.firearm_low",
                            },
                            {
                                ["fallback"] = "Hit.",
                                ["id"] = "reserved.firearm",
                            },
                            {
                                ["fallback"] = "Jesus... I actually hit it.",
                                ["id"] = "shaken.firearm_low",
                            },
                            {
                                ["fallback"] = "Got it. You good?",
                                ["id"] = "supportive.firearm",
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
            ["responsePlanID"] = "combat.kill.firearm",
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
                            ["fallback"] = "This {slot.weapon.name} still shoots straight.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.kill.firearm.say_1",
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
            ["weapon"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.item",
            },
        },
        ["sourceShard"] = "dialogue/combat_kill/combat_kill_firearm.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "This {slot.weapon.name} still shoots straight.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.firearm.say.1.aggressive.firearm_high_named.say.1",
                ["variantID"] = "aggressive.firearm_high_named.say.1",
            },
            {
                ["fallback"] = "Right where I wanted it. Down.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.firearm.say.1.aggressive.firearm_high_named.say.2",
                ["variantID"] = "aggressive.firearm_high_named.say.2",
            },
            {
                ["fallback"] = "Dead center. Keep moving.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.firearm.say.1.brave.firearm_high",
                ["variantID"] = "brave.firearm_high",
            },
            {
                ["fallback"] = "Clean shot.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.firearm.say.1.cold.firearm_high",
                ["variantID"] = "cold.firearm_high",
            },
            {
                ["fallback"] = "Good shot placement. Check the lane.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.firearm.say.1.practical.firearm_high",
                ["variantID"] = "practical.firearm_high",
            },
            {
                ["fallback"] = "Hit it. Don't count on luck twice.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.firearm.say.1.practical.firearm_low",
                ["variantID"] = "practical.firearm_low",
            },
            {
                ["fallback"] = "Hit.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.firearm.say.1.reserved.firearm",
                ["variantID"] = "reserved.firearm",
            },
            {
                ["fallback"] = "Jesus... I actually hit it.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.firearm.say.1.shaken.firearm_low",
                ["variantID"] = "shaken.firearm_low",
            },
            {
                ["fallback"] = "Got it. You good?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.firearm.say.1.supportive.firearm",
                ["variantID"] = "supportive.firearm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_kill",
        ["domainPath"] = "combat_kill",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.kill.heavy_melee",
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
                                ["fallback"] = "Split that rotten head wide open.",
                                ["id"] = "aggressive.axe_head",
                                ["templateID"] = "convo.combat.kill.heavy_melee.say.1.aggressive.axe_head",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                            {
                                ["fallback"] = "Felt that one crack.",
                                ["id"] = "aggressive.blunt",
                                ["templateID"] = "convo.combat.kill.heavy_melee.say.1.aggressive.blunt",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                            {
                                ["fallback"] = "That's why I like the reach.",
                                ["id"] = "aggressive.spear",
                                ["templateID"] = "convo.combat.kill.heavy_melee.say.1.aggressive.spear",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                            {
                                ["fallback"] = "One chop. Done.",
                                ["id"] = "brave.axe",
                                ["templateID"] = "convo.combat.kill.heavy_melee.say.1.brave.axe",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                            {
                                ["fallback"] = "Kept it right where I wanted it.",
                                ["id"] = "brave.spear",
                                ["templateID"] = "convo.combat.kill.heavy_melee.say.1.brave.spear",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                            {
                                ["fallback"] = "Crushed it.",
                                ["id"] = "cold.heavy_melee",
                                ["templateID"] = "convo.combat.kill.heavy_melee.say.1.cold.heavy_melee",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                            {
                                ["fallback"] = "Good reach. Keep the line.",
                                ["id"] = "practical.axe_spear",
                                ["templateID"] = "convo.combat.kill.heavy_melee.say.1.practical.axe_spear",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                            {
                                ["fallback"] = "Crushed it. Watch the next one.",
                                ["id"] = "practical.blunt",
                                ["templateID"] = "convo.combat.kill.heavy_melee.say.1.practical.blunt",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                            {
                                ["fallback"] = "It's down. Keep close.",
                                ["id"] = "supportive.melee",
                                ["templateID"] = "convo.combat.kill.heavy_melee.say.1.supportive.melee",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.kill",
            ["slots"] = {
                ["weapon"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.item",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "Split that rotten head wide open.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.heavy_melee.say.1.aggressive.axe_head",
                    ["variantID"] = "aggressive.axe_head",
                },
                {
                    ["fallback"] = "Felt that one crack.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.heavy_melee.say.1.aggressive.blunt",
                    ["variantID"] = "aggressive.blunt",
                },
                {
                    ["fallback"] = "That's why I like the reach.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.heavy_melee.say.1.aggressive.spear",
                    ["variantID"] = "aggressive.spear",
                },
                {
                    ["fallback"] = "One chop. Done.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.heavy_melee.say.1.brave.axe",
                    ["variantID"] = "brave.axe",
                },
                {
                    ["fallback"] = "Kept it right where I wanted it.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.heavy_melee.say.1.brave.spear",
                    ["variantID"] = "brave.spear",
                },
                {
                    ["fallback"] = "Crushed it.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.heavy_melee.say.1.cold.heavy_melee",
                    ["variantID"] = "cold.heavy_melee",
                },
                {
                    ["fallback"] = "Good reach. Keep the line.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.heavy_melee.say.1.practical.axe_spear",
                    ["variantID"] = "practical.axe_spear",
                },
                {
                    ["fallback"] = "Crushed it. Watch the next one.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.heavy_melee.say.1.practical.blunt",
                    ["variantID"] = "practical.blunt",
                },
                {
                    ["fallback"] = "It's down. Keep close.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.heavy_melee.say.1.supportive.melee",
                    ["variantID"] = "supportive.melee",
                },
            },
        },
        ["id"] = "combat.kill.heavy_melee",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "heavy_melee",
            ["sourceId"] = "combat.kill.heavy_melee",
            ["sourcePath"] = "dialogue/combat_kill/combat_kill_heavy_melee.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatKill",
        ["namespace"] = "combat.kill",
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
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "Split that rotten head wide open.",
                                ["id"] = "aggressive.axe_head",
                            },
                            {
                                ["fallback"] = "Felt that one crack.",
                                ["id"] = "aggressive.blunt",
                            },
                            {
                                ["fallback"] = "That's why I like the reach.",
                                ["id"] = "aggressive.spear",
                            },
                            {
                                ["fallback"] = "One chop. Done.",
                                ["id"] = "brave.axe",
                            },
                            {
                                ["fallback"] = "Kept it right where I wanted it.",
                                ["id"] = "brave.spear",
                            },
                            {
                                ["fallback"] = "Crushed it.",
                                ["id"] = "cold.heavy_melee",
                            },
                            {
                                ["fallback"] = "Good reach. Keep the line.",
                                ["id"] = "practical.axe_spear",
                            },
                            {
                                ["fallback"] = "Crushed it. Watch the next one.",
                                ["id"] = "practical.blunt",
                            },
                            {
                                ["fallback"] = "It's down. Keep close.",
                                ["id"] = "supportive.melee",
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
            ["responsePlanID"] = "combat.kill.heavy_melee",
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
                            ["fallback"] = "Split that rotten head wide open.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.kill.heavy_melee.say_1",
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
            ["weapon"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.item",
            },
        },
        ["sourceShard"] = "dialogue/combat_kill/combat_kill_heavy_melee.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Split that rotten head wide open.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.heavy_melee.say.1.aggressive.axe_head",
                ["variantID"] = "aggressive.axe_head",
            },
            {
                ["fallback"] = "Felt that one crack.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.heavy_melee.say.1.aggressive.blunt",
                ["variantID"] = "aggressive.blunt",
            },
            {
                ["fallback"] = "That's why I like the reach.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.heavy_melee.say.1.aggressive.spear",
                ["variantID"] = "aggressive.spear",
            },
            {
                ["fallback"] = "One chop. Done.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.heavy_melee.say.1.brave.axe",
                ["variantID"] = "brave.axe",
            },
            {
                ["fallback"] = "Kept it right where I wanted it.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.heavy_melee.say.1.brave.spear",
                ["variantID"] = "brave.spear",
            },
            {
                ["fallback"] = "Crushed it.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.heavy_melee.say.1.cold.heavy_melee",
                ["variantID"] = "cold.heavy_melee",
            },
            {
                ["fallback"] = "Good reach. Keep the line.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.heavy_melee.say.1.practical.axe_spear",
                ["variantID"] = "practical.axe_spear",
            },
            {
                ["fallback"] = "Crushed it. Watch the next one.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.heavy_melee.say.1.practical.blunt",
                ["variantID"] = "practical.blunt",
            },
            {
                ["fallback"] = "It's down. Keep close.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.heavy_melee.say.1.supportive.melee",
                ["variantID"] = "supportive.melee",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_kill",
        ["domainPath"] = "combat_kill",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.kill.unarmed",
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
                                ["fallback"] = "It's down. I need a weapon.",
                                ["id"] = "practical.unarmed",
                                ["templateID"] = "convo.combat.kill.unarmed.say.1.practical.unarmed",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                            {
                                ["fallback"] = "Oh God. I did that with my hands.",
                                ["id"] = "shaken.unarmed",
                                ["templateID"] = "convo.combat.kill.unarmed.say.1.shaken.unarmed",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.kill",
            ["textRoles"] = {
                {
                    ["fallback"] = "It's down. I need a weapon.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.unarmed.say.1.practical.unarmed",
                    ["variantID"] = "practical.unarmed",
                },
                {
                    ["fallback"] = "Oh God. I did that with my hands.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.unarmed.say.1.shaken.unarmed",
                    ["variantID"] = "shaken.unarmed",
                },
            },
        },
        ["id"] = "combat.kill.unarmed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "unarmed",
            ["sourceId"] = "combat.kill.unarmed",
            ["sourcePath"] = "dialogue/combat_kill/combat_kill_unarmed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatKill",
        ["namespace"] = "combat.kill",
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
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "It's down. I need a weapon.",
                                ["id"] = "practical.unarmed",
                            },
                            {
                                ["fallback"] = "Oh God. I did that with my hands.",
                                ["id"] = "shaken.unarmed",
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
            ["responsePlanID"] = "combat.kill.unarmed",
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
                            ["fallback"] = "It's down. I need a weapon.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.kill.unarmed.say_1",
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
        ["sourceShard"] = "dialogue/combat_kill/combat_kill_unarmed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "It's down. I need a weapon.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.unarmed.say.1.practical.unarmed",
                ["variantID"] = "practical.unarmed",
            },
            {
                ["fallback"] = "Oh God. I did that with my hands.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.unarmed.say.1.shaken.unarmed",
                ["variantID"] = "shaken.unarmed",
            },
        },
        ["when"] = nil,
    },
}
