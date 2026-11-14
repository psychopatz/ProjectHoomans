-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_banter_weapon_kill_cold",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.kill.killer.cold.blade_head",
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
                                ["fallback"] = "Head came apart. Moving on.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.kill.killer.cold.blade_head.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Head came apart. Moving on.",
                                        "Severed at the neck. Proceed.",
                                        "Anatomical destruction complete.",
                                        "Ceased function. Next.",
                                        "Cranium broken. Moving forward.",
                                        "Irreversible damage. Clear.",
                                        "Neck cleaved. Done.",
                                        "No remaining reflex. Move.",
                                        "Head split. Continue.",
                                        "Decapitation verified.",
                                    },
                                    ["TL"] = {
                                        "Nawasak ang ulo. Tuloy.",
                                        "Nahiwa sa leeg. Tuloy.",
                                        "Winasak ang ulo nang buo.",
                                        "Tumigil ang galaw. Sunod.",
                                        "Basag ang bungo. Pasulong.",
                                        "Wala nang buhay. Malinis.",
                                        "Hiwa ang leeg. Tapos.",
                                        "Walang natitirang kilos. Abante.",
                                        "Biyak ang ulo. Magpatuloy.",
                                        "Kumpirmadong napugutan.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.kill.killer.cold",
            ["textRoles"] = {
                {
                    ["fallback"] = "Head came apart. Moving on.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.killer.cold.blade_head.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Head came apart. Moving on.",
                            "Severed at the neck. Proceed.",
                            "Anatomical destruction complete.",
                            "Ceased function. Next.",
                            "Cranium broken. Moving forward.",
                            "Irreversible damage. Clear.",
                            "Neck cleaved. Done.",
                            "No remaining reflex. Move.",
                            "Head split. Continue.",
                            "Decapitation verified.",
                        },
                        ["TL"] = {
                            "Nawasak ang ulo. Tuloy.",
                            "Nahiwa sa leeg. Tuloy.",
                            "Winasak ang ulo nang buo.",
                            "Tumigil ang galaw. Sunod.",
                            "Basag ang bungo. Pasulong.",
                            "Wala nang buhay. Malinis.",
                            "Hiwa ang leeg. Tapos.",
                            "Walang natitirang kilos. Abante.",
                            "Biyak ang ulo. Magpatuloy.",
                            "Kumpirmadong napugutan.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.kill.killer.cold.blade_head",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "blade_head",
            ["sourceId"] = "combat.kill.killer.cold.blade_head",
            ["sourcePath"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_cold/combat_kill_killer_cold_blade_head.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatBanterWeaponKillCold",
        ["namespace"] = "combat.kill.killer.cold",
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Head came apart. Moving on.",
                                        "Severed at the neck. Proceed.",
                                        "Anatomical destruction complete.",
                                        "Ceased function. Next.",
                                        "Cranium broken. Moving forward.",
                                        "Irreversible damage. Clear.",
                                        "Neck cleaved. Done.",
                                        "No remaining reflex. Move.",
                                        "Head split. Continue.",
                                        "Decapitation verified.",
                                    },
                                    ["TL"] = {
                                        "Nawasak ang ulo. Tuloy.",
                                        "Nahiwa sa leeg. Tuloy.",
                                        "Winasak ang ulo nang buo.",
                                        "Tumigil ang galaw. Sunod.",
                                        "Basag ang bungo. Pasulong.",
                                        "Wala nang buhay. Malinis.",
                                        "Hiwa ang leeg. Tapos.",
                                        "Walang natitirang kilos. Abante.",
                                        "Biyak ang ulo. Magpatuloy.",
                                        "Kumpirmadong napugutan.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "combat.kill.killer.cold.blade_head",
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
                            ["fallback"] = "Head came apart. Moving on.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.kill.killer.cold.blade_head.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_cold/combat_kill_killer_cold_blade_head.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Head came apart. Moving on.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.killer.cold.blade_head.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Head came apart. Moving on.",
                        "Severed at the neck. Proceed.",
                        "Anatomical destruction complete.",
                        "Ceased function. Next.",
                        "Cranium broken. Moving forward.",
                        "Irreversible damage. Clear.",
                        "Neck cleaved. Done.",
                        "No remaining reflex. Move.",
                        "Head split. Continue.",
                        "Decapitation verified.",
                    },
                    ["TL"] = {
                        "Nawasak ang ulo. Tuloy.",
                        "Nahiwa sa leeg. Tuloy.",
                        "Winasak ang ulo nang buo.",
                        "Tumigil ang galaw. Sunod.",
                        "Basag ang bungo. Pasulong.",
                        "Wala nang buhay. Malinis.",
                        "Hiwa ang leeg. Tapos.",
                        "Walang natitirang kilos. Abante.",
                        "Biyak ang ulo. Magpatuloy.",
                        "Kumpirmadong napugutan.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_banter_weapon_kill_cold",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.kill.killer.cold.firearm_high",
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
                                ["fallback"] = "Clean shot.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.kill.killer.cold.firearm_high.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Clean shot.",
                                        "Target expired. Moving.",
                                        "Zero waste. Proceed.",
                                        "Bullet found the brain. Next.",
                                        "Dropped efficiently.",
                                        "Threat terminated.",
                                        "Simple precision.",
                                        "One less obstacle.",
                                        "Expired instantly.",
                                        "Path opened.",
                                    },
                                    ["TL"] = {
                                        "Malinis na tira.",
                                        "Patay ang target. Kilos.",
                                        "Walang aksaya. Tuloy.",
                                        "Bumaon ang bala sa utak. Sunod.",
                                        "Bumagsak nang walang aberya.",
                                        "Banta tinapos na.",
                                        "Simpleng asinta.",
                                        "Nabawasan ng isang sagabal.",
                                        "Patay agad.",
                                        "Bukas na ang daan.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.kill.killer.cold",
            ["textRoles"] = {
                {
                    ["fallback"] = "Clean shot.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.killer.cold.firearm_high.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Clean shot.",
                            "Target expired. Moving.",
                            "Zero waste. Proceed.",
                            "Bullet found the brain. Next.",
                            "Dropped efficiently.",
                            "Threat terminated.",
                            "Simple precision.",
                            "One less obstacle.",
                            "Expired instantly.",
                            "Path opened.",
                        },
                        ["TL"] = {
                            "Malinis na tira.",
                            "Patay ang target. Kilos.",
                            "Walang aksaya. Tuloy.",
                            "Bumaon ang bala sa utak. Sunod.",
                            "Bumagsak nang walang aberya.",
                            "Banta tinapos na.",
                            "Simpleng asinta.",
                            "Nabawasan ng isang sagabal.",
                            "Patay agad.",
                            "Bukas na ang daan.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.kill.killer.cold.firearm_high",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "firearm_high",
            ["sourceId"] = "combat.kill.killer.cold.firearm_high",
            ["sourcePath"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_cold/combat_kill_killer_cold_firearm_high.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatBanterWeaponKillCold",
        ["namespace"] = "combat.kill.killer.cold",
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Clean shot.",
                                        "Target expired. Moving.",
                                        "Zero waste. Proceed.",
                                        "Bullet found the brain. Next.",
                                        "Dropped efficiently.",
                                        "Threat terminated.",
                                        "Simple precision.",
                                        "One less obstacle.",
                                        "Expired instantly.",
                                        "Path opened.",
                                    },
                                    ["TL"] = {
                                        "Malinis na tira.",
                                        "Patay ang target. Kilos.",
                                        "Walang aksaya. Tuloy.",
                                        "Bumaon ang bala sa utak. Sunod.",
                                        "Bumagsak nang walang aberya.",
                                        "Banta tinapos na.",
                                        "Simpleng asinta.",
                                        "Nabawasan ng isang sagabal.",
                                        "Patay agad.",
                                        "Bukas na ang daan.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "combat.kill.killer.cold.firearm_high",
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
                            ["fallback"] = "Clean shot.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.kill.killer.cold.firearm_high.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_cold/combat_kill_killer_cold_firearm_high.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Clean shot.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.killer.cold.firearm_high.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Clean shot.",
                        "Target expired. Moving.",
                        "Zero waste. Proceed.",
                        "Bullet found the brain. Next.",
                        "Dropped efficiently.",
                        "Threat terminated.",
                        "Simple precision.",
                        "One less obstacle.",
                        "Expired instantly.",
                        "Path opened.",
                    },
                    ["TL"] = {
                        "Malinis na tira.",
                        "Patay ang target. Kilos.",
                        "Walang aksaya. Tuloy.",
                        "Bumaon ang bala sa utak. Sunod.",
                        "Bumagsak nang walang aberya.",
                        "Banta tinapos na.",
                        "Simpleng asinta.",
                        "Nabawasan ng isang sagabal.",
                        "Patay agad.",
                        "Bukas na ang daan.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_banter_weapon_kill_cold",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.kill.killer.cold.heavy_melee",
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
                                ["fallback"] = "Crushed it.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.kill.killer.cold.heavy_melee.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Crushed it.",
                                        "Structural skull collapse. Done.",
                                        "Pulverized. Moving on.",
                                        "Impact sufficient. Next.",
                                        "Ceased all motor function.",
                                        "Crushed flat.",
                                        "Bones splintered. Clear.",
                                        "Force delivered. Finished.",
                                        "Obliterated. Advance.",
                                        "Skull collapsed inward.",
                                    },
                                    ["TL"] = {
                                        "Dinurog.",
                                        "Basag ang istruktura ng bungo. Tapos.",
                                        "Durog na. Tuloy.",
                                        "Sapat ang lakas ng tama. Sunod.",
                                        "Tumigil ang lahat ng galaw.",
                                        "Pinitpit.",
                                        "Nabasag ang mga buto. Malinis.",
                                        "Naitama ang bigat. Tapos.",
                                        "Winasak. Abante.",
                                        "Lumalubog ang bungo sa lakas.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.kill.killer.cold",
            ["textRoles"] = {
                {
                    ["fallback"] = "Crushed it.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.killer.cold.heavy_melee.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Crushed it.",
                            "Structural skull collapse. Done.",
                            "Pulverized. Moving on.",
                            "Impact sufficient. Next.",
                            "Ceased all motor function.",
                            "Crushed flat.",
                            "Bones splintered. Clear.",
                            "Force delivered. Finished.",
                            "Obliterated. Advance.",
                            "Skull collapsed inward.",
                        },
                        ["TL"] = {
                            "Dinurog.",
                            "Basag ang istruktura ng bungo. Tapos.",
                            "Durog na. Tuloy.",
                            "Sapat ang lakas ng tama. Sunod.",
                            "Tumigil ang lahat ng galaw.",
                            "Pinitpit.",
                            "Nabasag ang mga buto. Malinis.",
                            "Naitama ang bigat. Tapos.",
                            "Winasak. Abante.",
                            "Lumalubog ang bungo sa lakas.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.kill.killer.cold.heavy_melee",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "heavy_melee",
            ["sourceId"] = "combat.kill.killer.cold.heavy_melee",
            ["sourcePath"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_cold/combat_kill_killer_cold_heavy_melee.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatBanterWeaponKillCold",
        ["namespace"] = "combat.kill.killer.cold",
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Crushed it.",
                                        "Structural skull collapse. Done.",
                                        "Pulverized. Moving on.",
                                        "Impact sufficient. Next.",
                                        "Ceased all motor function.",
                                        "Crushed flat.",
                                        "Bones splintered. Clear.",
                                        "Force delivered. Finished.",
                                        "Obliterated. Advance.",
                                        "Skull collapsed inward.",
                                    },
                                    ["TL"] = {
                                        "Dinurog.",
                                        "Basag ang istruktura ng bungo. Tapos.",
                                        "Durog na. Tuloy.",
                                        "Sapat ang lakas ng tama. Sunod.",
                                        "Tumigil ang lahat ng galaw.",
                                        "Pinitpit.",
                                        "Nabasag ang mga buto. Malinis.",
                                        "Naitama ang bigat. Tapos.",
                                        "Winasak. Abante.",
                                        "Lumalubog ang bungo sa lakas.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "combat.kill.killer.cold.heavy_melee",
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
                            ["fallback"] = "Crushed it.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.kill.killer.cold.heavy_melee.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_cold/combat_kill_killer_cold_heavy_melee.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Crushed it.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.killer.cold.heavy_melee.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Crushed it.",
                        "Structural skull collapse. Done.",
                        "Pulverized. Moving on.",
                        "Impact sufficient. Next.",
                        "Ceased all motor function.",
                        "Crushed flat.",
                        "Bones splintered. Clear.",
                        "Force delivered. Finished.",
                        "Obliterated. Advance.",
                        "Skull collapsed inward.",
                    },
                    ["TL"] = {
                        "Dinurog.",
                        "Basag ang istruktura ng bungo. Tapos.",
                        "Durog na. Tuloy.",
                        "Sapat ang lakas ng tama. Sunod.",
                        "Tumigil ang lahat ng galaw.",
                        "Pinitpit.",
                        "Nabasag ang mga buto. Malinis.",
                        "Naitama ang bigat. Tapos.",
                        "Winasak. Abante.",
                        "Lumalubog ang bungo sa lakas.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
