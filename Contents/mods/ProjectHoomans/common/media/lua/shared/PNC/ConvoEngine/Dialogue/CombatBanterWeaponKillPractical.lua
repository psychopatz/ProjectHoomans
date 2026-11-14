-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_banter_weapon_kill_practical",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.kill.killer.practical.axe_spear",
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
                                ["fallback"] = "Good reach. Keep the line.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.kill.killer.practical.axe_spear.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Good reach. Keep the line.",
                                        "Kept our distance. That worked.",
                                        "Leverage did the work. Push ahead.",
                                        "Safe distance maintained. Next.",
                                        "Good weapon range. Watch the side.",
                                        "Clean penetration. Check haft condition.",
                                        "Hit before it closed in. Form up.",
                                        "Distance kept us safe. Continue.",
                                        "Controlled engagement. Move forward.",
                                        "Reach kept teeth off us. Proceed.",
                                    },
                                    ["TL"] = {
                                        "Maganda ang abot. Panatilihin ang linya.",
                                        "Nanatili sa ligtas na layo. Epektibo 'yon.",
                                        "Lakas at abot ang tumapos. Sulong.",
                                        "Ligtas na distansya napanatili. Sunod.",
                                        "Magandang distansya ng sandata. Bantayan ang gilid.",
                                        "Malinis na bumaon. Tignan ang hawakan.",
                                        "Tinamaan bago makalapit. Ayusin ang hanay.",
                                        "Ligtas tayo dahil sa distansya. Magpatuloy.",
                                        "Kontroladong engkwentro. Pasulong.",
                                        "Nailayo ang mga ngipin dahil sa abot. Tuloy.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.kill.killer.practical",
            ["textRoles"] = {
                {
                    ["fallback"] = "Good reach. Keep the line.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.killer.practical.axe_spear.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Good reach. Keep the line.",
                            "Kept our distance. That worked.",
                            "Leverage did the work. Push ahead.",
                            "Safe distance maintained. Next.",
                            "Good weapon range. Watch the side.",
                            "Clean penetration. Check haft condition.",
                            "Hit before it closed in. Form up.",
                            "Distance kept us safe. Continue.",
                            "Controlled engagement. Move forward.",
                            "Reach kept teeth off us. Proceed.",
                        },
                        ["TL"] = {
                            "Maganda ang abot. Panatilihin ang linya.",
                            "Nanatili sa ligtas na layo. Epektibo 'yon.",
                            "Lakas at abot ang tumapos. Sulong.",
                            "Ligtas na distansya napanatili. Sunod.",
                            "Magandang distansya ng sandata. Bantayan ang gilid.",
                            "Malinis na bumaon. Tignan ang hawakan.",
                            "Tinamaan bago makalapit. Ayusin ang hanay.",
                            "Ligtas tayo dahil sa distansya. Magpatuloy.",
                            "Kontroladong engkwentro. Pasulong.",
                            "Nailayo ang mga ngipin dahil sa abot. Tuloy.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.kill.killer.practical.axe_spear",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "axe_spear",
            ["sourceId"] = "combat.kill.killer.practical.axe_spear",
            ["sourcePath"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_practical/combat_kill_killer_practical_axe_spear.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatBanterWeaponKillPractical",
        ["namespace"] = "combat.kill.killer.practical",
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
                                        "Good reach. Keep the line.",
                                        "Kept our distance. That worked.",
                                        "Leverage did the work. Push ahead.",
                                        "Safe distance maintained. Next.",
                                        "Good weapon range. Watch the side.",
                                        "Clean penetration. Check haft condition.",
                                        "Hit before it closed in. Form up.",
                                        "Distance kept us safe. Continue.",
                                        "Controlled engagement. Move forward.",
                                        "Reach kept teeth off us. Proceed.",
                                    },
                                    ["TL"] = {
                                        "Maganda ang abot. Panatilihin ang linya.",
                                        "Nanatili sa ligtas na layo. Epektibo 'yon.",
                                        "Lakas at abot ang tumapos. Sulong.",
                                        "Ligtas na distansya napanatili. Sunod.",
                                        "Magandang distansya ng sandata. Bantayan ang gilid.",
                                        "Malinis na bumaon. Tignan ang hawakan.",
                                        "Tinamaan bago makalapit. Ayusin ang hanay.",
                                        "Ligtas tayo dahil sa distansya. Magpatuloy.",
                                        "Kontroladong engkwentro. Pasulong.",
                                        "Nailayo ang mga ngipin dahil sa abot. Tuloy.",
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
            ["responsePlanID"] = "combat.kill.killer.practical.axe_spear",
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
                            ["fallback"] = "Good reach. Keep the line.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.kill.killer.practical.axe_spear.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_practical/combat_kill_killer_practical_axe_spear.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Good reach. Keep the line.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.killer.practical.axe_spear.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Good reach. Keep the line.",
                        "Kept our distance. That worked.",
                        "Leverage did the work. Push ahead.",
                        "Safe distance maintained. Next.",
                        "Good weapon range. Watch the side.",
                        "Clean penetration. Check haft condition.",
                        "Hit before it closed in. Form up.",
                        "Distance kept us safe. Continue.",
                        "Controlled engagement. Move forward.",
                        "Reach kept teeth off us. Proceed.",
                    },
                    ["TL"] = {
                        "Maganda ang abot. Panatilihin ang linya.",
                        "Nanatili sa ligtas na layo. Epektibo 'yon.",
                        "Lakas at abot ang tumapos. Sulong.",
                        "Ligtas na distansya napanatili. Sunod.",
                        "Magandang distansya ng sandata. Bantayan ang gilid.",
                        "Malinis na bumaon. Tignan ang hawakan.",
                        "Tinamaan bago makalapit. Ayusin ang hanay.",
                        "Ligtas tayo dahil sa distansya. Magpatuloy.",
                        "Kontroladong engkwentro. Pasulong.",
                        "Nailayo ang mga ngipin dahil sa abot. Tuloy.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_banter_weapon_kill_practical",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.kill.killer.practical.blade",
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
                                ["fallback"] = "Blade did its job. Keep moving.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.kill.killer.practical.blade.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Blade did its job. Keep moving.",
                                        "Clean cut. Check blade edge.",
                                        "Down without wasting noise.",
                                        "Quiet kill. Keep your eyes sharp.",
                                        "Severed cleanly. Don't let your guard down.",
                                        "One silent drop. Keep the pace.",
                                        "Edge held up fine. Move ahead.",
                                        "Target down quietly. Scan the hall.",
                                        "No ammo burned. Good.",
                                        "Dropped it silently. Watch the rear.",
                                    },
                                    ["TL"] = {
                                        "Ginawa ng talim ang trabaho nito. Tuloy.",
                                        "Malinis na hiwa. Tignan ang talim.",
                                        "Bagsak nang hindi gumagawa ng ingay.",
                                        "Tahimik na patay. Panatilihing matalas ang mata.",
                                        "Hiwa nang malinis. Huwag ibaba ang depensa.",
                                        "Isang tahimik na pagbagsak. Tuloy ang hakbang.",
                                        "Maayos pa ang talim. Pasulong.",
                                        "Tahimik na naitumba ang target. Suriin ang pasilyo.",
                                        "Walang balang nasayang. Maganda.",
                                        "Tahimik na ibinagsak. Bantayan ang likuran.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.kill.killer.practical",
            ["textRoles"] = {
                {
                    ["fallback"] = "Blade did its job. Keep moving.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.killer.practical.blade.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Blade did its job. Keep moving.",
                            "Clean cut. Check blade edge.",
                            "Down without wasting noise.",
                            "Quiet kill. Keep your eyes sharp.",
                            "Severed cleanly. Don't let your guard down.",
                            "One silent drop. Keep the pace.",
                            "Edge held up fine. Move ahead.",
                            "Target down quietly. Scan the hall.",
                            "No ammo burned. Good.",
                            "Dropped it silently. Watch the rear.",
                        },
                        ["TL"] = {
                            "Ginawa ng talim ang trabaho nito. Tuloy.",
                            "Malinis na hiwa. Tignan ang talim.",
                            "Bagsak nang hindi gumagawa ng ingay.",
                            "Tahimik na patay. Panatilihing matalas ang mata.",
                            "Hiwa nang malinis. Huwag ibaba ang depensa.",
                            "Isang tahimik na pagbagsak. Tuloy ang hakbang.",
                            "Maayos pa ang talim. Pasulong.",
                            "Tahimik na naitumba ang target. Suriin ang pasilyo.",
                            "Walang balang nasayang. Maganda.",
                            "Tahimik na ibinagsak. Bantayan ang likuran.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.kill.killer.practical.blade",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "blade",
            ["sourceId"] = "combat.kill.killer.practical.blade",
            ["sourcePath"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_practical/combat_kill_killer_practical_blade.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatBanterWeaponKillPractical",
        ["namespace"] = "combat.kill.killer.practical",
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
                                        "Blade did its job. Keep moving.",
                                        "Clean cut. Check blade edge.",
                                        "Down without wasting noise.",
                                        "Quiet kill. Keep your eyes sharp.",
                                        "Severed cleanly. Don't let your guard down.",
                                        "One silent drop. Keep the pace.",
                                        "Edge held up fine. Move ahead.",
                                        "Target down quietly. Scan the hall.",
                                        "No ammo burned. Good.",
                                        "Dropped it silently. Watch the rear.",
                                    },
                                    ["TL"] = {
                                        "Ginawa ng talim ang trabaho nito. Tuloy.",
                                        "Malinis na hiwa. Tignan ang talim.",
                                        "Bagsak nang hindi gumagawa ng ingay.",
                                        "Tahimik na patay. Panatilihing matalas ang mata.",
                                        "Hiwa nang malinis. Huwag ibaba ang depensa.",
                                        "Isang tahimik na pagbagsak. Tuloy ang hakbang.",
                                        "Maayos pa ang talim. Pasulong.",
                                        "Tahimik na naitumba ang target. Suriin ang pasilyo.",
                                        "Walang balang nasayang. Maganda.",
                                        "Tahimik na ibinagsak. Bantayan ang likuran.",
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
            ["responsePlanID"] = "combat.kill.killer.practical.blade",
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
                            ["fallback"] = "Blade did its job. Keep moving.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.kill.killer.practical.blade.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_practical/combat_kill_killer_practical_blade.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Blade did its job. Keep moving.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.killer.practical.blade.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Blade did its job. Keep moving.",
                        "Clean cut. Check blade edge.",
                        "Down without wasting noise.",
                        "Quiet kill. Keep your eyes sharp.",
                        "Severed cleanly. Don't let your guard down.",
                        "One silent drop. Keep the pace.",
                        "Edge held up fine. Move ahead.",
                        "Target down quietly. Scan the hall.",
                        "No ammo burned. Good.",
                        "Dropped it silently. Watch the rear.",
                    },
                    ["TL"] = {
                        "Ginawa ng talim ang trabaho nito. Tuloy.",
                        "Malinis na hiwa. Tignan ang talim.",
                        "Bagsak nang hindi gumagawa ng ingay.",
                        "Tahimik na patay. Panatilihing matalas ang mata.",
                        "Hiwa nang malinis. Huwag ibaba ang depensa.",
                        "Isang tahimik na pagbagsak. Tuloy ang hakbang.",
                        "Maayos pa ang talim. Pasulong.",
                        "Tahimik na naitumba ang target. Suriin ang pasilyo.",
                        "Walang balang nasayang. Maganda.",
                        "Tahimik na ibinagsak. Bantayan ang likuran.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_banter_weapon_kill_practical",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.kill.killer.practical.blunt",
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
                                ["fallback"] = "Crushed it. Watch the next one.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.kill.killer.practical.blunt.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Crushed it. Watch the next one.",
                                        "Broke the skull. Check weapon wear.",
                                        "Solid blunt trauma. Move ahead.",
                                        "Effective hit. Keep your footing solid.",
                                        "Downed. Don't exhaust yourself swinging.",
                                        "Cracked through. Scan the surroundings.",
                                        "Heavy strike finished it. Advance.",
                                        "Impact neutralized the threat. Check corners.",
                                        "Good hit. Conserve stamina.",
                                        "Done. Step over and keep scanning.",
                                    },
                                    ["TL"] = {
                                        "Dinurog. Bantayan ang susunod.",
                                        "Basag ang bungo. Tignan ang gasgas ng sandata.",
                                        "Mabigat na hampas. Sulong sa unahan.",
                                        "Mabisang palo. Patatagin ang tindig.",
                                        "Bagsak. Huwag magpakapagod sa paghataw.",
                                        "Bumasag nang tuluyan. Suriin ang paligid.",
                                        "Mabigat na palo ang tumapos. Abante.",
                                        "Naitumba ng lakas ang banta. Tignan ang mga sulok.",
                                        "Magandang tama. Tipirin ang lakas.",
                                        "Tapos. Hakbangan at magpatuloy sa pagmamasid.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.kill.killer.practical",
            ["textRoles"] = {
                {
                    ["fallback"] = "Crushed it. Watch the next one.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.killer.practical.blunt.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Crushed it. Watch the next one.",
                            "Broke the skull. Check weapon wear.",
                            "Solid blunt trauma. Move ahead.",
                            "Effective hit. Keep your footing solid.",
                            "Downed. Don't exhaust yourself swinging.",
                            "Cracked through. Scan the surroundings.",
                            "Heavy strike finished it. Advance.",
                            "Impact neutralized the threat. Check corners.",
                            "Good hit. Conserve stamina.",
                            "Done. Step over and keep scanning.",
                        },
                        ["TL"] = {
                            "Dinurog. Bantayan ang susunod.",
                            "Basag ang bungo. Tignan ang gasgas ng sandata.",
                            "Mabigat na hampas. Sulong sa unahan.",
                            "Mabisang palo. Patatagin ang tindig.",
                            "Bagsak. Huwag magpakapagod sa paghataw.",
                            "Bumasag nang tuluyan. Suriin ang paligid.",
                            "Mabigat na palo ang tumapos. Abante.",
                            "Naitumba ng lakas ang banta. Tignan ang mga sulok.",
                            "Magandang tama. Tipirin ang lakas.",
                            "Tapos. Hakbangan at magpatuloy sa pagmamasid.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.kill.killer.practical.blunt",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "blunt",
            ["sourceId"] = "combat.kill.killer.practical.blunt",
            ["sourcePath"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_practical/combat_kill_killer_practical_blunt.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatBanterWeaponKillPractical",
        ["namespace"] = "combat.kill.killer.practical",
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
                                        "Crushed it. Watch the next one.",
                                        "Broke the skull. Check weapon wear.",
                                        "Solid blunt trauma. Move ahead.",
                                        "Effective hit. Keep your footing solid.",
                                        "Downed. Don't exhaust yourself swinging.",
                                        "Cracked through. Scan the surroundings.",
                                        "Heavy strike finished it. Advance.",
                                        "Impact neutralized the threat. Check corners.",
                                        "Good hit. Conserve stamina.",
                                        "Done. Step over and keep scanning.",
                                    },
                                    ["TL"] = {
                                        "Dinurog. Bantayan ang susunod.",
                                        "Basag ang bungo. Tignan ang gasgas ng sandata.",
                                        "Mabigat na hampas. Sulong sa unahan.",
                                        "Mabisang palo. Patatagin ang tindig.",
                                        "Bagsak. Huwag magpakapagod sa paghataw.",
                                        "Bumasag nang tuluyan. Suriin ang paligid.",
                                        "Mabigat na palo ang tumapos. Abante.",
                                        "Naitumba ng lakas ang banta. Tignan ang mga sulok.",
                                        "Magandang tama. Tipirin ang lakas.",
                                        "Tapos. Hakbangan at magpatuloy sa pagmamasid.",
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
            ["responsePlanID"] = "combat.kill.killer.practical.blunt",
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
                            ["fallback"] = "Crushed it. Watch the next one.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.kill.killer.practical.blunt.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_practical/combat_kill_killer_practical_blunt.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Crushed it. Watch the next one.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.killer.practical.blunt.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Crushed it. Watch the next one.",
                        "Broke the skull. Check weapon wear.",
                        "Solid blunt trauma. Move ahead.",
                        "Effective hit. Keep your footing solid.",
                        "Downed. Don't exhaust yourself swinging.",
                        "Cracked through. Scan the surroundings.",
                        "Heavy strike finished it. Advance.",
                        "Impact neutralized the threat. Check corners.",
                        "Good hit. Conserve stamina.",
                        "Done. Step over and keep scanning.",
                    },
                    ["TL"] = {
                        "Dinurog. Bantayan ang susunod.",
                        "Basag ang bungo. Tignan ang gasgas ng sandata.",
                        "Mabigat na hampas. Sulong sa unahan.",
                        "Mabisang palo. Patatagin ang tindig.",
                        "Bagsak. Huwag magpakapagod sa paghataw.",
                        "Bumasag nang tuluyan. Suriin ang paligid.",
                        "Mabigat na palo ang tumapos. Abante.",
                        "Naitumba ng lakas ang banta. Tignan ang mga sulok.",
                        "Magandang tama. Tipirin ang lakas.",
                        "Tapos. Hakbangan at magpatuloy sa pagmamasid.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_banter_weapon_kill_practical",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.kill.killer.practical.firearm_high",
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
                                ["fallback"] = "Good shot placement. Check the lane.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.kill.killer.practical.firearm_high.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Good shot placement. Check the lane.",
                                        "One round spent. Check your corners.",
                                        "Target down. Scan before advancing.",
                                        "Clean shot. Keep ammunition in mind.",
                                        "Dropped it cleanly. Watch for flankers.",
                                        "Down. Keep your weapon raised.",
                                        "Threat eliminated. Count your rounds.",
                                        "Solid hit. Keep moving methodically.",
                                        "Target neutralized. Check the perimeter.",
                                        "Shot connected well. Don't rush ahead.",
                                    },
                                    ["TL"] = {
                                        "Maganda ang tama. Suriin ang linya.",
                                        "Isang bala ang nagamit. Tignan ang mga sulok.",
                                        "Bagsak ang target. Magmasid bago sumulong.",
                                        "Malinis na putok. Tandaan ang natitirang bala.",
                                        "Bumagsak nang maayos. Mag-ingat sa mga nasa gilid.",
                                        "Bagsak. Panatilihing nakataas ang sandata.",
                                        "Banta naalis. Bilangin ang bala.",
                                        "Solido ang tama. Tuloy sa maingat na pagkilos.",
                                        "Bagsak ang target. Suriin ang paligid.",
                                        "Tumama nang maayos ang putok. Huwag magmadali.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.kill.killer.practical",
            ["textRoles"] = {
                {
                    ["fallback"] = "Good shot placement. Check the lane.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.killer.practical.firearm_high.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Good shot placement. Check the lane.",
                            "One round spent. Check your corners.",
                            "Target down. Scan before advancing.",
                            "Clean shot. Keep ammunition in mind.",
                            "Dropped it cleanly. Watch for flankers.",
                            "Down. Keep your weapon raised.",
                            "Threat eliminated. Count your rounds.",
                            "Solid hit. Keep moving methodically.",
                            "Target neutralized. Check the perimeter.",
                            "Shot connected well. Don't rush ahead.",
                        },
                        ["TL"] = {
                            "Maganda ang tama. Suriin ang linya.",
                            "Isang bala ang nagamit. Tignan ang mga sulok.",
                            "Bagsak ang target. Magmasid bago sumulong.",
                            "Malinis na putok. Tandaan ang natitirang bala.",
                            "Bumagsak nang maayos. Mag-ingat sa mga nasa gilid.",
                            "Bagsak. Panatilihing nakataas ang sandata.",
                            "Banta naalis. Bilangin ang bala.",
                            "Solido ang tama. Tuloy sa maingat na pagkilos.",
                            "Bagsak ang target. Suriin ang paligid.",
                            "Tumama nang maayos ang putok. Huwag magmadali.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.kill.killer.practical.firearm_high",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "firearm_high",
            ["sourceId"] = "combat.kill.killer.practical.firearm_high",
            ["sourcePath"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_practical/combat_kill_killer_practical_firearm_high.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatBanterWeaponKillPractical",
        ["namespace"] = "combat.kill.killer.practical",
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
                                        "Good shot placement. Check the lane.",
                                        "One round spent. Check your corners.",
                                        "Target down. Scan before advancing.",
                                        "Clean shot. Keep ammunition in mind.",
                                        "Dropped it cleanly. Watch for flankers.",
                                        "Down. Keep your weapon raised.",
                                        "Threat eliminated. Count your rounds.",
                                        "Solid hit. Keep moving methodically.",
                                        "Target neutralized. Check the perimeter.",
                                        "Shot connected well. Don't rush ahead.",
                                    },
                                    ["TL"] = {
                                        "Maganda ang tama. Suriin ang linya.",
                                        "Isang bala ang nagamit. Tignan ang mga sulok.",
                                        "Bagsak ang target. Magmasid bago sumulong.",
                                        "Malinis na putok. Tandaan ang natitirang bala.",
                                        "Bumagsak nang maayos. Mag-ingat sa mga nasa gilid.",
                                        "Bagsak. Panatilihing nakataas ang sandata.",
                                        "Banta naalis. Bilangin ang bala.",
                                        "Solido ang tama. Tuloy sa maingat na pagkilos.",
                                        "Bagsak ang target. Suriin ang paligid.",
                                        "Tumama nang maayos ang putok. Huwag magmadali.",
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
            ["responsePlanID"] = "combat.kill.killer.practical.firearm_high",
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
                            ["fallback"] = "Good shot placement. Check the lane.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.kill.killer.practical.firearm_high.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_practical/combat_kill_killer_practical_firearm_high.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Good shot placement. Check the lane.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.killer.practical.firearm_high.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Good shot placement. Check the lane.",
                        "One round spent. Check your corners.",
                        "Target down. Scan before advancing.",
                        "Clean shot. Keep ammunition in mind.",
                        "Dropped it cleanly. Watch for flankers.",
                        "Down. Keep your weapon raised.",
                        "Threat eliminated. Count your rounds.",
                        "Solid hit. Keep moving methodically.",
                        "Target neutralized. Check the perimeter.",
                        "Shot connected well. Don't rush ahead.",
                    },
                    ["TL"] = {
                        "Maganda ang tama. Suriin ang linya.",
                        "Isang bala ang nagamit. Tignan ang mga sulok.",
                        "Bagsak ang target. Magmasid bago sumulong.",
                        "Malinis na putok. Tandaan ang natitirang bala.",
                        "Bumagsak nang maayos. Mag-ingat sa mga nasa gilid.",
                        "Bagsak. Panatilihing nakataas ang sandata.",
                        "Banta naalis. Bilangin ang bala.",
                        "Solido ang tama. Tuloy sa maingat na pagkilos.",
                        "Bagsak ang target. Suriin ang paligid.",
                        "Tumama nang maayos ang putok. Huwag magmadali.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_banter_weapon_kill_practical",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.kill.killer.practical.firearm_low",
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
                                ["fallback"] = "Hit it. Don't count on luck twice.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.kill.killer.practical.firearm_low.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Hit it. Don't count on luck twice.",
                                        "Took two shots, but it's down.",
                                        "Messy hit, but it did the job.",
                                        "Downed. Check remaining ammo now.",
                                        "Wasted a round there. Settle your aim.",
                                        "It's on the floor. Reload if needed.",
                                        "Hit the mark eventually. Stay focused.",
                                        "Threat down. Don't get sloppy.",
                                        "Barely got that in time. Reset.",
                                        "Downed. Watch the noise level.",
                                    },
                                    ["TL"] = {
                                        "Tinamaan. Huwag umasa sa swerte nang dalawang beses.",
                                        "Dalawang putok ang kinailangan, pero bagsak na.",
                                        "Magulo ang tama, pero nagawa ang trabaho.",
                                        "Bagsak. Tignan ang natitirang bala ngayon.",
                                        "Nakaaksaya ng bala roon. Pakalmahin ang asinta.",
                                        "Nasa sahig na. Mag-reload kung kailangan.",
                                        "Tumama rin sa wakas. Manatiling nakatutok.",
                                        "Bagsak ang banta. Huwag magpabaya.",
                                        "Muntik na 'yon. Ayusin ulit ang pwesto.",
                                        "Bagsak. Bantayan ang ingay.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.kill.killer.practical",
            ["textRoles"] = {
                {
                    ["fallback"] = "Hit it. Don't count on luck twice.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.killer.practical.firearm_low.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Hit it. Don't count on luck twice.",
                            "Took two shots, but it's down.",
                            "Messy hit, but it did the job.",
                            "Downed. Check remaining ammo now.",
                            "Wasted a round there. Settle your aim.",
                            "It's on the floor. Reload if needed.",
                            "Hit the mark eventually. Stay focused.",
                            "Threat down. Don't get sloppy.",
                            "Barely got that in time. Reset.",
                            "Downed. Watch the noise level.",
                        },
                        ["TL"] = {
                            "Tinamaan. Huwag umasa sa swerte nang dalawang beses.",
                            "Dalawang putok ang kinailangan, pero bagsak na.",
                            "Magulo ang tama, pero nagawa ang trabaho.",
                            "Bagsak. Tignan ang natitirang bala ngayon.",
                            "Nakaaksaya ng bala roon. Pakalmahin ang asinta.",
                            "Nasa sahig na. Mag-reload kung kailangan.",
                            "Tumama rin sa wakas. Manatiling nakatutok.",
                            "Bagsak ang banta. Huwag magpabaya.",
                            "Muntik na 'yon. Ayusin ulit ang pwesto.",
                            "Bagsak. Bantayan ang ingay.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.kill.killer.practical.firearm_low",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "firearm_low",
            ["sourceId"] = "combat.kill.killer.practical.firearm_low",
            ["sourcePath"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_practical/combat_kill_killer_practical_firearm_low.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatBanterWeaponKillPractical",
        ["namespace"] = "combat.kill.killer.practical",
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
                                        "Hit it. Don't count on luck twice.",
                                        "Took two shots, but it's down.",
                                        "Messy hit, but it did the job.",
                                        "Downed. Check remaining ammo now.",
                                        "Wasted a round there. Settle your aim.",
                                        "It's on the floor. Reload if needed.",
                                        "Hit the mark eventually. Stay focused.",
                                        "Threat down. Don't get sloppy.",
                                        "Barely got that in time. Reset.",
                                        "Downed. Watch the noise level.",
                                    },
                                    ["TL"] = {
                                        "Tinamaan. Huwag umasa sa swerte nang dalawang beses.",
                                        "Dalawang putok ang kinailangan, pero bagsak na.",
                                        "Magulo ang tama, pero nagawa ang trabaho.",
                                        "Bagsak. Tignan ang natitirang bala ngayon.",
                                        "Nakaaksaya ng bala roon. Pakalmahin ang asinta.",
                                        "Nasa sahig na. Mag-reload kung kailangan.",
                                        "Tumama rin sa wakas. Manatiling nakatutok.",
                                        "Bagsak ang banta. Huwag magpabaya.",
                                        "Muntik na 'yon. Ayusin ulit ang pwesto.",
                                        "Bagsak. Bantayan ang ingay.",
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
            ["responsePlanID"] = "combat.kill.killer.practical.firearm_low",
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
                            ["fallback"] = "Hit it. Don't count on luck twice.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.kill.killer.practical.firearm_low.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_practical/combat_kill_killer_practical_firearm_low.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Hit it. Don't count on luck twice.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.killer.practical.firearm_low.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Hit it. Don't count on luck twice.",
                        "Took two shots, but it's down.",
                        "Messy hit, but it did the job.",
                        "Downed. Check remaining ammo now.",
                        "Wasted a round there. Settle your aim.",
                        "It's on the floor. Reload if needed.",
                        "Hit the mark eventually. Stay focused.",
                        "Threat down. Don't get sloppy.",
                        "Barely got that in time. Reset.",
                        "Downed. Watch the noise level.",
                    },
                    ["TL"] = {
                        "Tinamaan. Huwag umasa sa swerte nang dalawang beses.",
                        "Dalawang putok ang kinailangan, pero bagsak na.",
                        "Magulo ang tama, pero nagawa ang trabaho.",
                        "Bagsak. Tignan ang natitirang bala ngayon.",
                        "Nakaaksaya ng bala roon. Pakalmahin ang asinta.",
                        "Nasa sahig na. Mag-reload kung kailangan.",
                        "Tumama rin sa wakas. Manatiling nakatutok.",
                        "Bagsak ang banta. Huwag magpabaya.",
                        "Muntik na 'yon. Ayusin ulit ang pwesto.",
                        "Bagsak. Bantayan ang ingay.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_banter_weapon_kill_practical",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.kill.killer.practical.unarmed",
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
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.kill.killer.practical.unarmed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "It's down. I need a weapon.",
                                        "Managed that barehanded, but find me something to swing.",
                                        "Too close for comfort. We need gear.",
                                        "Took it down, but I can't keep doing that.",
                                        "It's dead. Look around for any weapon.",
                                        "Shoved and stomped. Get me something sharp.",
                                        "Risky move. Need proper tools.",
                                        "Downed it without gear. Won't get lucky twice.",
                                        "Bare hands worked once. Find weapons now.",
                                        "Bruised knuckles, but it's dead. Gear up.",
                                    },
                                    ["TL"] = {
                                        "Bagsak na. Kailangan ko ng sandata.",
                                        "Nakaraos nang walang gamit, pero hanapan mo ako ng mahahawakan.",
                                        "Masyadong delikado. Kailangan natin ng gamit.",
                                        "Naibagsak ko, pero hindi ko kayang ulit-ulitin 'yon.",
                                        "Patay na. Maghanap ka ng anumang pamalo sa paligid.",
                                        "Tinulak at tinapakan. Bigyan mo ako ng kahit matalim.",
                                        "Masyadong delikado. Kailangan ng maayos na gamit.",
                                        "Naitumba nang walang armas. Huwag umasang mauulit ang swerte.",
                                        "Gumabana ang mga kamay nang minsan. Maghanap ng sandata ngayon.",
                                        "Pasa ang kamao ko, pero patay na. Mag-armas tayo.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.kill.killer.practical",
            ["textRoles"] = {
                {
                    ["fallback"] = "It's down. I need a weapon.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.killer.practical.unarmed.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "It's down. I need a weapon.",
                            "Managed that barehanded, but find me something to swing.",
                            "Too close for comfort. We need gear.",
                            "Took it down, but I can't keep doing that.",
                            "It's dead. Look around for any weapon.",
                            "Shoved and stomped. Get me something sharp.",
                            "Risky move. Need proper tools.",
                            "Downed it without gear. Won't get lucky twice.",
                            "Bare hands worked once. Find weapons now.",
                            "Bruised knuckles, but it's dead. Gear up.",
                        },
                        ["TL"] = {
                            "Bagsak na. Kailangan ko ng sandata.",
                            "Nakaraos nang walang gamit, pero hanapan mo ako ng mahahawakan.",
                            "Masyadong delikado. Kailangan natin ng gamit.",
                            "Naibagsak ko, pero hindi ko kayang ulit-ulitin 'yon.",
                            "Patay na. Maghanap ka ng anumang pamalo sa paligid.",
                            "Tinulak at tinapakan. Bigyan mo ako ng kahit matalim.",
                            "Masyadong delikado. Kailangan ng maayos na gamit.",
                            "Naitumba nang walang armas. Huwag umasang mauulit ang swerte.",
                            "Gumabana ang mga kamay nang minsan. Maghanap ng sandata ngayon.",
                            "Pasa ang kamao ko, pero patay na. Mag-armas tayo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.kill.killer.practical.unarmed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "unarmed",
            ["sourceId"] = "combat.kill.killer.practical.unarmed",
            ["sourcePath"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_practical/combat_kill_killer_practical_unarmed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatBanterWeaponKillPractical",
        ["namespace"] = "combat.kill.killer.practical",
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
                                        "It's down. I need a weapon.",
                                        "Managed that barehanded, but find me something to swing.",
                                        "Too close for comfort. We need gear.",
                                        "Took it down, but I can't keep doing that.",
                                        "It's dead. Look around for any weapon.",
                                        "Shoved and stomped. Get me something sharp.",
                                        "Risky move. Need proper tools.",
                                        "Downed it without gear. Won't get lucky twice.",
                                        "Bare hands worked once. Find weapons now.",
                                        "Bruised knuckles, but it's dead. Gear up.",
                                    },
                                    ["TL"] = {
                                        "Bagsak na. Kailangan ko ng sandata.",
                                        "Nakaraos nang walang gamit, pero hanapan mo ako ng mahahawakan.",
                                        "Masyadong delikado. Kailangan natin ng gamit.",
                                        "Naibagsak ko, pero hindi ko kayang ulit-ulitin 'yon.",
                                        "Patay na. Maghanap ka ng anumang pamalo sa paligid.",
                                        "Tinulak at tinapakan. Bigyan mo ako ng kahit matalim.",
                                        "Masyadong delikado. Kailangan ng maayos na gamit.",
                                        "Naitumba nang walang armas. Huwag umasang mauulit ang swerte.",
                                        "Gumabana ang mga kamay nang minsan. Maghanap ng sandata ngayon.",
                                        "Pasa ang kamao ko, pero patay na. Mag-armas tayo.",
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
            ["responsePlanID"] = "combat.kill.killer.practical.unarmed",
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
                            ["templateID"] = "psdl.combat.kill.killer.practical.unarmed.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_practical/combat_kill_killer_practical_unarmed.json",
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
                ["templateID"] = "convo.combat.kill.killer.practical.unarmed.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "It's down. I need a weapon.",
                        "Managed that barehanded, but find me something to swing.",
                        "Too close for comfort. We need gear.",
                        "Took it down, but I can't keep doing that.",
                        "It's dead. Look around for any weapon.",
                        "Shoved and stomped. Get me something sharp.",
                        "Risky move. Need proper tools.",
                        "Downed it without gear. Won't get lucky twice.",
                        "Bare hands worked once. Find weapons now.",
                        "Bruised knuckles, but it's dead. Gear up.",
                    },
                    ["TL"] = {
                        "Bagsak na. Kailangan ko ng sandata.",
                        "Nakaraos nang walang gamit, pero hanapan mo ako ng mahahawakan.",
                        "Masyadong delikado. Kailangan natin ng gamit.",
                        "Naibagsak ko, pero hindi ko kayang ulit-ulitin 'yon.",
                        "Patay na. Maghanap ka ng anumang pamalo sa paligid.",
                        "Tinulak at tinapakan. Bigyan mo ako ng kahit matalim.",
                        "Masyadong delikado. Kailangan ng maayos na gamit.",
                        "Naitumba nang walang armas. Huwag umasang mauulit ang swerte.",
                        "Gumabana ang mga kamay nang minsan. Maghanap ng sandata ngayon.",
                        "Pasa ang kamao ko, pero patay na. Mag-armas tayo.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
