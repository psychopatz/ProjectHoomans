-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_banter_weapon_kill_brave",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.kill.killer.brave.axe",
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
                                ["fallback"] = "One chop. Done.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.kill.killer.brave.axe.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "One chop. Done.",
                                        "Heavy cleave. Push forward.",
                                        "Broke the spine in one stroke. Move.",
                                        "Split the skull. Threat eliminated.",
                                        "Solid strike. Next target.",
                                        "Downed instantly. Keep moving.",
                                        "Axe did its work. Advance.",
                                        "Clean breach through bone. Proceed.",
                                        "That one's finished. Step forward.",
                                        "Decisive hit. Don't stop now.",
                                    },
                                    ["TL"] = {
                                        "Isang taga. Tapos.",
                                        "Mabigat na taga. Sulong sa unahan.",
                                        "Nabasag ang gulugod sa isang palo. Kilos.",
                                        "Biyak ang bungo. Banta nawala na.",
                                        "Solido ang tama. Susunod na target.",
                                        "Bagsak agad. Tuloy ang lakad.",
                                        "Nagawa ng palakol ang trabaho. Abante.",
                                        "Malinis na bumaon sa buto. Tuloy.",
                                        "Tapos na ang isang 'yon. Hakbang pasulong.",
                                        "Tiyak na tama. Huwag hihinto ngayon.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.kill.killer.brave",
            ["textRoles"] = {
                {
                    ["fallback"] = "One chop. Done.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.killer.brave.axe.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "One chop. Done.",
                            "Heavy cleave. Push forward.",
                            "Broke the spine in one stroke. Move.",
                            "Split the skull. Threat eliminated.",
                            "Solid strike. Next target.",
                            "Downed instantly. Keep moving.",
                            "Axe did its work. Advance.",
                            "Clean breach through bone. Proceed.",
                            "That one's finished. Step forward.",
                            "Decisive hit. Don't stop now.",
                        },
                        ["TL"] = {
                            "Isang taga. Tapos.",
                            "Mabigat na taga. Sulong sa unahan.",
                            "Nabasag ang gulugod sa isang palo. Kilos.",
                            "Biyak ang bungo. Banta nawala na.",
                            "Solido ang tama. Susunod na target.",
                            "Bagsak agad. Tuloy ang lakad.",
                            "Nagawa ng palakol ang trabaho. Abante.",
                            "Malinis na bumaon sa buto. Tuloy.",
                            "Tapos na ang isang 'yon. Hakbang pasulong.",
                            "Tiyak na tama. Huwag hihinto ngayon.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.kill.killer.brave.axe",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "axe",
            ["sourceId"] = "combat.kill.killer.brave.axe",
            ["sourcePath"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_brave/combat_kill_killer_brave_axe.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatBanterWeaponKillBrave",
        ["namespace"] = "combat.kill.killer.brave",
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
                                        "One chop. Done.",
                                        "Heavy cleave. Push forward.",
                                        "Broke the spine in one stroke. Move.",
                                        "Split the skull. Threat eliminated.",
                                        "Solid strike. Next target.",
                                        "Downed instantly. Keep moving.",
                                        "Axe did its work. Advance.",
                                        "Clean breach through bone. Proceed.",
                                        "That one's finished. Step forward.",
                                        "Decisive hit. Don't stop now.",
                                    },
                                    ["TL"] = {
                                        "Isang taga. Tapos.",
                                        "Mabigat na taga. Sulong sa unahan.",
                                        "Nabasag ang gulugod sa isang palo. Kilos.",
                                        "Biyak ang bungo. Banta nawala na.",
                                        "Solido ang tama. Susunod na target.",
                                        "Bagsak agad. Tuloy ang lakad.",
                                        "Nagawa ng palakol ang trabaho. Abante.",
                                        "Malinis na bumaon sa buto. Tuloy.",
                                        "Tapos na ang isang 'yon. Hakbang pasulong.",
                                        "Tiyak na tama. Huwag hihinto ngayon.",
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
            ["responsePlanID"] = "combat.kill.killer.brave.axe",
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
                            ["fallback"] = "One chop. Done.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.kill.killer.brave.axe.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_brave/combat_kill_killer_brave_axe.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "One chop. Done.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.killer.brave.axe.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "One chop. Done.",
                        "Heavy cleave. Push forward.",
                        "Broke the spine in one stroke. Move.",
                        "Split the skull. Threat eliminated.",
                        "Solid strike. Next target.",
                        "Downed instantly. Keep moving.",
                        "Axe did its work. Advance.",
                        "Clean breach through bone. Proceed.",
                        "That one's finished. Step forward.",
                        "Decisive hit. Don't stop now.",
                    },
                    ["TL"] = {
                        "Isang taga. Tapos.",
                        "Mabigat na taga. Sulong sa unahan.",
                        "Nabasag ang gulugod sa isang palo. Kilos.",
                        "Biyak ang bungo. Banta nawala na.",
                        "Solido ang tama. Susunod na target.",
                        "Bagsak agad. Tuloy ang lakad.",
                        "Nagawa ng palakol ang trabaho. Abante.",
                        "Malinis na bumaon sa buto. Tuloy.",
                        "Tapos na ang isang 'yon. Hakbang pasulong.",
                        "Tiyak na tama. Huwag hihinto ngayon.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_banter_weapon_kill_brave",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.kill.killer.brave.blade_head",
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
                                ["fallback"] = "Clean cut. Next.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.kill.killer.brave.blade_head.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Clean cut. Next.",
                                        "Head severed. Move up.",
                                        "Blade struck true. Keep the line.",
                                        "One strike. Proceed.",
                                        "Downed without breaking stride.",
                                        "Decapitated. Clear the path.",
                                        "Threat down. Maintain vigilance.",
                                        "Firm strike. Moving ahead.",
                                        "Head neutralized. Don't linger.",
                                        "Swift cut. Let's keep moving.",
                                    },
                                    ["TL"] = {
                                        "Malinis na hiwa. Sunod.",
                                        "Pugot ang ulo. Sulong.",
                                        "Tumama nang tumpak ang talim. Hawakan ang linya.",
                                        "Isang hampas. Tuloy.",
                                        "Bumagsak nang hindi nahihinto ang hakbang.",
                                        "Napugutan. Linisin ang daan.",
                                        "Banta bagsak na. Manatiling alerto.",
                                        "Matatag na hampas. Pasulong.",
                                        "Ulo nawasak. Huwag magtagal.",
                                        "Mabilis na hiwa. Tuloy-tuloy tayo.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.kill.killer.brave",
            ["textRoles"] = {
                {
                    ["fallback"] = "Clean cut. Next.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.killer.brave.blade_head.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Clean cut. Next.",
                            "Head severed. Move up.",
                            "Blade struck true. Keep the line.",
                            "One strike. Proceed.",
                            "Downed without breaking stride.",
                            "Decapitated. Clear the path.",
                            "Threat down. Maintain vigilance.",
                            "Firm strike. Moving ahead.",
                            "Head neutralized. Don't linger.",
                            "Swift cut. Let's keep moving.",
                        },
                        ["TL"] = {
                            "Malinis na hiwa. Sunod.",
                            "Pugot ang ulo. Sulong.",
                            "Tumama nang tumpak ang talim. Hawakan ang linya.",
                            "Isang hampas. Tuloy.",
                            "Bumagsak nang hindi nahihinto ang hakbang.",
                            "Napugutan. Linisin ang daan.",
                            "Banta bagsak na. Manatiling alerto.",
                            "Matatag na hampas. Pasulong.",
                            "Ulo nawasak. Huwag magtagal.",
                            "Mabilis na hiwa. Tuloy-tuloy tayo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.kill.killer.brave.blade_head",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "blade_head",
            ["sourceId"] = "combat.kill.killer.brave.blade_head",
            ["sourcePath"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_brave/combat_kill_killer_brave_blade_head.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatBanterWeaponKillBrave",
        ["namespace"] = "combat.kill.killer.brave",
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
                                        "Clean cut. Next.",
                                        "Head severed. Move up.",
                                        "Blade struck true. Keep the line.",
                                        "One strike. Proceed.",
                                        "Downed without breaking stride.",
                                        "Decapitated. Clear the path.",
                                        "Threat down. Maintain vigilance.",
                                        "Firm strike. Moving ahead.",
                                        "Head neutralized. Don't linger.",
                                        "Swift cut. Let's keep moving.",
                                    },
                                    ["TL"] = {
                                        "Malinis na hiwa. Sunod.",
                                        "Pugot ang ulo. Sulong.",
                                        "Tumama nang tumpak ang talim. Hawakan ang linya.",
                                        "Isang hampas. Tuloy.",
                                        "Bumagsak nang hindi nahihinto ang hakbang.",
                                        "Napugutan. Linisin ang daan.",
                                        "Banta bagsak na. Manatiling alerto.",
                                        "Matatag na hampas. Pasulong.",
                                        "Ulo nawasak. Huwag magtagal.",
                                        "Mabilis na hiwa. Tuloy-tuloy tayo.",
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
            ["responsePlanID"] = "combat.kill.killer.brave.blade_head",
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
                            ["fallback"] = "Clean cut. Next.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.kill.killer.brave.blade_head.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_brave/combat_kill_killer_brave_blade_head.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Clean cut. Next.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.killer.brave.blade_head.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Clean cut. Next.",
                        "Head severed. Move up.",
                        "Blade struck true. Keep the line.",
                        "One strike. Proceed.",
                        "Downed without breaking stride.",
                        "Decapitated. Clear the path.",
                        "Threat down. Maintain vigilance.",
                        "Firm strike. Moving ahead.",
                        "Head neutralized. Don't linger.",
                        "Swift cut. Let's keep moving.",
                    },
                    ["TL"] = {
                        "Malinis na hiwa. Sunod.",
                        "Pugot ang ulo. Sulong.",
                        "Tumama nang tumpak ang talim. Hawakan ang linya.",
                        "Isang hampas. Tuloy.",
                        "Bumagsak nang hindi nahihinto ang hakbang.",
                        "Napugutan. Linisin ang daan.",
                        "Banta bagsak na. Manatiling alerto.",
                        "Matatag na hampas. Pasulong.",
                        "Ulo nawasak. Huwag magtagal.",
                        "Mabilis na hiwa. Tuloy-tuloy tayo.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_banter_weapon_kill_brave",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.kill.killer.brave.firearm_high",
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
                                ["fallback"] = "Dead center. Keep moving.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.kill.killer.brave.firearm_high.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Dead center. Keep moving.",
                                        "Clean hit. Advance.",
                                        "Downed. Scanning the next sector.",
                                        "One shot, one down. Keep pace.",
                                        "Target eliminated. Form up.",
                                        "Precise shot. Push through.",
                                        "Threat neutralized. Eyes ahead.",
                                        "Confirmed kill. Move forward.",
                                        "Handled. Watch your spacing.",
                                        "Center mass then head. Done.",
                                    },
                                    ["TL"] = {
                                        "Gitnang-gitna. Tuloy lang.",
                                        "Malinis na tama. Sulong.",
                                        "Bagsak. Sinusuri ang susunod na parte.",
                                        "Isang putok, isang bagsak. Panatilihin ang bilis.",
                                        "Target naalis. Ayusin ang pwesto.",
                                        "Eksaktong putok. Lusot tayo.",
                                        "Banta nawala na. Tumingin sa unahan.",
                                        "Kumpirmadong patay. Abante.",
                                        "Naasikaso na. Bantayan ang agwat.",
                                        "Gitna muna bago ulo. Tapos.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.kill.killer.brave",
            ["textRoles"] = {
                {
                    ["fallback"] = "Dead center. Keep moving.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.killer.brave.firearm_high.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Dead center. Keep moving.",
                            "Clean hit. Advance.",
                            "Downed. Scanning the next sector.",
                            "One shot, one down. Keep pace.",
                            "Target eliminated. Form up.",
                            "Precise shot. Push through.",
                            "Threat neutralized. Eyes ahead.",
                            "Confirmed kill. Move forward.",
                            "Handled. Watch your spacing.",
                            "Center mass then head. Done.",
                        },
                        ["TL"] = {
                            "Gitnang-gitna. Tuloy lang.",
                            "Malinis na tama. Sulong.",
                            "Bagsak. Sinusuri ang susunod na parte.",
                            "Isang putok, isang bagsak. Panatilihin ang bilis.",
                            "Target naalis. Ayusin ang pwesto.",
                            "Eksaktong putok. Lusot tayo.",
                            "Banta nawala na. Tumingin sa unahan.",
                            "Kumpirmadong patay. Abante.",
                            "Naasikaso na. Bantayan ang agwat.",
                            "Gitna muna bago ulo. Tapos.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.kill.killer.brave.firearm_high",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "firearm_high",
            ["sourceId"] = "combat.kill.killer.brave.firearm_high",
            ["sourcePath"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_brave/combat_kill_killer_brave_firearm_high.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatBanterWeaponKillBrave",
        ["namespace"] = "combat.kill.killer.brave",
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
                                        "Dead center. Keep moving.",
                                        "Clean hit. Advance.",
                                        "Downed. Scanning the next sector.",
                                        "One shot, one down. Keep pace.",
                                        "Target eliminated. Form up.",
                                        "Precise shot. Push through.",
                                        "Threat neutralized. Eyes ahead.",
                                        "Confirmed kill. Move forward.",
                                        "Handled. Watch your spacing.",
                                        "Center mass then head. Done.",
                                    },
                                    ["TL"] = {
                                        "Gitnang-gitna. Tuloy lang.",
                                        "Malinis na tama. Sulong.",
                                        "Bagsak. Sinusuri ang susunod na parte.",
                                        "Isang putok, isang bagsak. Panatilihin ang bilis.",
                                        "Target naalis. Ayusin ang pwesto.",
                                        "Eksaktong putok. Lusot tayo.",
                                        "Banta nawala na. Tumingin sa unahan.",
                                        "Kumpirmadong patay. Abante.",
                                        "Naasikaso na. Bantayan ang agwat.",
                                        "Gitna muna bago ulo. Tapos.",
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
            ["responsePlanID"] = "combat.kill.killer.brave.firearm_high",
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
                            ["fallback"] = "Dead center. Keep moving.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.kill.killer.brave.firearm_high.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_brave/combat_kill_killer_brave_firearm_high.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Dead center. Keep moving.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.killer.brave.firearm_high.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Dead center. Keep moving.",
                        "Clean hit. Advance.",
                        "Downed. Scanning the next sector.",
                        "One shot, one down. Keep pace.",
                        "Target eliminated. Form up.",
                        "Precise shot. Push through.",
                        "Threat neutralized. Eyes ahead.",
                        "Confirmed kill. Move forward.",
                        "Handled. Watch your spacing.",
                        "Center mass then head. Done.",
                    },
                    ["TL"] = {
                        "Gitnang-gitna. Tuloy lang.",
                        "Malinis na tama. Sulong.",
                        "Bagsak. Sinusuri ang susunod na parte.",
                        "Isang putok, isang bagsak. Panatilihin ang bilis.",
                        "Target naalis. Ayusin ang pwesto.",
                        "Eksaktong putok. Lusot tayo.",
                        "Banta nawala na. Tumingin sa unahan.",
                        "Kumpirmadong patay. Abante.",
                        "Naasikaso na. Bantayan ang agwat.",
                        "Gitna muna bago ulo. Tapos.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_banter_weapon_kill_brave",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.kill.killer.brave.spear",
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
                                ["fallback"] = "Kept it right where I wanted it.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.kill.killer.brave.spear.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Kept it right where I wanted it.",
                                        "Direct thrust. Target down.",
                                        "Distance held, kill confirmed.",
                                        "Spear struck true. Advance.",
                                        "Pinned down and finished. Move.",
                                        "Clean breach from outside reach.",
                                        "Neutralized at range. Proceed.",
                                        "No risk taken. Push through.",
                                        "Impaled. Path is clear.",
                                        "Firm thrust to the skull. Done.",
                                    },
                                    ["TL"] = {
                                        "Napanatili ko siya sa tamang distansya.",
                                        "Diretsong ulos. Bagsak ang target.",
                                        "Distansya nahawakan, patay kumpirmado.",
                                        "Tumagos ang sibat. Abante.",
                                        "Itinarak at tinapos. Kilos.",
                                        "Malinis na tama mula sa ligtas na layo.",
                                        "Naitumba mula sa malayo. Tuloy.",
                                        "Walang peligrong kinuha. Lusot.",
                                        "Tinuhog. Malinis ang daan.",
                                        "Matatag na saksak sa bungo. Tapos.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.kill.killer.brave",
            ["textRoles"] = {
                {
                    ["fallback"] = "Kept it right where I wanted it.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.killer.brave.spear.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Kept it right where I wanted it.",
                            "Direct thrust. Target down.",
                            "Distance held, kill confirmed.",
                            "Spear struck true. Advance.",
                            "Pinned down and finished. Move.",
                            "Clean breach from outside reach.",
                            "Neutralized at range. Proceed.",
                            "No risk taken. Push through.",
                            "Impaled. Path is clear.",
                            "Firm thrust to the skull. Done.",
                        },
                        ["TL"] = {
                            "Napanatili ko siya sa tamang distansya.",
                            "Diretsong ulos. Bagsak ang target.",
                            "Distansya nahawakan, patay kumpirmado.",
                            "Tumagos ang sibat. Abante.",
                            "Itinarak at tinapos. Kilos.",
                            "Malinis na tama mula sa ligtas na layo.",
                            "Naitumba mula sa malayo. Tuloy.",
                            "Walang peligrong kinuha. Lusot.",
                            "Tinuhog. Malinis ang daan.",
                            "Matatag na saksak sa bungo. Tapos.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.kill.killer.brave.spear",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "spear",
            ["sourceId"] = "combat.kill.killer.brave.spear",
            ["sourcePath"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_brave/combat_kill_killer_brave_spear.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatBanterWeaponKillBrave",
        ["namespace"] = "combat.kill.killer.brave",
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
                                        "Kept it right where I wanted it.",
                                        "Direct thrust. Target down.",
                                        "Distance held, kill confirmed.",
                                        "Spear struck true. Advance.",
                                        "Pinned down and finished. Move.",
                                        "Clean breach from outside reach.",
                                        "Neutralized at range. Proceed.",
                                        "No risk taken. Push through.",
                                        "Impaled. Path is clear.",
                                        "Firm thrust to the skull. Done.",
                                    },
                                    ["TL"] = {
                                        "Napanatili ko siya sa tamang distansya.",
                                        "Diretsong ulos. Bagsak ang target.",
                                        "Distansya nahawakan, patay kumpirmado.",
                                        "Tumagos ang sibat. Abante.",
                                        "Itinarak at tinapos. Kilos.",
                                        "Malinis na tama mula sa ligtas na layo.",
                                        "Naitumba mula sa malayo. Tuloy.",
                                        "Walang peligrong kinuha. Lusot.",
                                        "Tinuhog. Malinis ang daan.",
                                        "Matatag na saksak sa bungo. Tapos.",
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
            ["responsePlanID"] = "combat.kill.killer.brave.spear",
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
                            ["fallback"] = "Kept it right where I wanted it.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.kill.killer.brave.spear.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_brave/combat_kill_killer_brave_spear.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Kept it right where I wanted it.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.killer.brave.spear.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Kept it right where I wanted it.",
                        "Direct thrust. Target down.",
                        "Distance held, kill confirmed.",
                        "Spear struck true. Advance.",
                        "Pinned down and finished. Move.",
                        "Clean breach from outside reach.",
                        "Neutralized at range. Proceed.",
                        "No risk taken. Push through.",
                        "Impaled. Path is clear.",
                        "Firm thrust to the skull. Done.",
                    },
                    ["TL"] = {
                        "Napanatili ko siya sa tamang distansya.",
                        "Diretsong ulos. Bagsak ang target.",
                        "Distansya nahawakan, patay kumpirmado.",
                        "Tumagos ang sibat. Abante.",
                        "Itinarak at tinapos. Kilos.",
                        "Malinis na tama mula sa ligtas na layo.",
                        "Naitumba mula sa malayo. Tuloy.",
                        "Walang peligrong kinuha. Lusot.",
                        "Tinuhog. Malinis ang daan.",
                        "Matatag na saksak sa bungo. Tapos.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
