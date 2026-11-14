-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_banter_weapon_kill_shaken",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.kill.killer.shaken.blade_head",
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
                                ["fallback"] = "Oh God... there's blood everywhere.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.kill.killer.shaken.blade_head.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Oh God... there's blood everywhere.",
                                        "It's in pieces... I need a second.",
                                        "The smell... God, I think I'm gonna be sick.",
                                        "I can still feel the crunch...",
                                        "It came right at me... had to cut it.",
                                        "Hands won't stop trembling...",
                                        "Is it really dead? Look at it...",
                                        "That was horrible... but it's over.",
                                        "God, I hate doing this...",
                                        "Head's gone... let's just step back.",
                                    },
                                    ["TL"] = {
                                        "Diyos ko... may dugo kahit saan.",
                                        "Pira-piraso na... kailangan ko ng saglit.",
                                        "Ang amoy... Diyos ko, masusuka yata ako.",
                                        "Ramdam ko pa rin ang lagutok...",
                                        "Diretso sa akin... kailangan kong hiwain.",
                                        "Ayaw tumigil ng panginginig ng mga kamay ko...",
                                        "Patay na ba talaga? Tingnan mo...",
                                        "Kakila-kilabot 'yon... pero tapos na.",
                                        "Diyos ko, ayaw na ayaw kong ginagawa 'to...",
                                        "Wala nang ulo... umatras muna tayo.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.kill.killer.shaken",
            ["textRoles"] = {
                {
                    ["fallback"] = "Oh God... there's blood everywhere.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.killer.shaken.blade_head.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Oh God... there's blood everywhere.",
                            "It's in pieces... I need a second.",
                            "The smell... God, I think I'm gonna be sick.",
                            "I can still feel the crunch...",
                            "It came right at me... had to cut it.",
                            "Hands won't stop trembling...",
                            "Is it really dead? Look at it...",
                            "That was horrible... but it's over.",
                            "God, I hate doing this...",
                            "Head's gone... let's just step back.",
                        },
                        ["TL"] = {
                            "Diyos ko... may dugo kahit saan.",
                            "Pira-piraso na... kailangan ko ng saglit.",
                            "Ang amoy... Diyos ko, masusuka yata ako.",
                            "Ramdam ko pa rin ang lagutok...",
                            "Diretso sa akin... kailangan kong hiwain.",
                            "Ayaw tumigil ng panginginig ng mga kamay ko...",
                            "Patay na ba talaga? Tingnan mo...",
                            "Kakila-kilabot 'yon... pero tapos na.",
                            "Diyos ko, ayaw na ayaw kong ginagawa 'to...",
                            "Wala nang ulo... umatras muna tayo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.kill.killer.shaken.blade_head",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "blade_head",
            ["sourceId"] = "combat.kill.killer.shaken.blade_head",
            ["sourcePath"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_shaken/combat_kill_killer_shaken_blade_head.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatBanterWeaponKillShaken",
        ["namespace"] = "combat.kill.killer.shaken",
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
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/combat_banter/weapon_kill/shaken.json",
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
                                        "Oh God... there's blood everywhere.",
                                        "It's in pieces... I need a second.",
                                        "The smell... God, I think I'm gonna be sick.",
                                        "I can still feel the crunch...",
                                        "It came right at me... had to cut it.",
                                        "Hands won't stop trembling...",
                                        "Is it really dead? Look at it...",
                                        "That was horrible... but it's over.",
                                        "God, I hate doing this...",
                                        "Head's gone... let's just step back.",
                                    },
                                    ["TL"] = {
                                        "Diyos ko... may dugo kahit saan.",
                                        "Pira-piraso na... kailangan ko ng saglit.",
                                        "Ang amoy... Diyos ko, masusuka yata ako.",
                                        "Ramdam ko pa rin ang lagutok...",
                                        "Diretso sa akin... kailangan kong hiwain.",
                                        "Ayaw tumigil ng panginginig ng mga kamay ko...",
                                        "Patay na ba talaga? Tingnan mo...",
                                        "Kakila-kilabot 'yon... pero tapos na.",
                                        "Diyos ko, ayaw na ayaw kong ginagawa 'to...",
                                        "Wala nang ulo... umatras muna tayo.",
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
            ["responsePlanID"] = "combat.kill.killer.shaken.blade_head",
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
                            ["fallback"] = "Oh God... there's blood everywhere.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.kill.killer.shaken.blade_head.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_shaken/combat_kill_killer_shaken_blade_head.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Oh God... there's blood everywhere.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.killer.shaken.blade_head.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Oh God... there's blood everywhere.",
                        "It's in pieces... I need a second.",
                        "The smell... God, I think I'm gonna be sick.",
                        "I can still feel the crunch...",
                        "It came right at me... had to cut it.",
                        "Hands won't stop trembling...",
                        "Is it really dead? Look at it...",
                        "That was horrible... but it's over.",
                        "God, I hate doing this...",
                        "Head's gone... let's just step back.",
                    },
                    ["TL"] = {
                        "Diyos ko... may dugo kahit saan.",
                        "Pira-piraso na... kailangan ko ng saglit.",
                        "Ang amoy... Diyos ko, masusuka yata ako.",
                        "Ramdam ko pa rin ang lagutok...",
                        "Diretso sa akin... kailangan kong hiwain.",
                        "Ayaw tumigil ng panginginig ng mga kamay ko...",
                        "Patay na ba talaga? Tingnan mo...",
                        "Kakila-kilabot 'yon... pero tapos na.",
                        "Diyos ko, ayaw na ayaw kong ginagawa 'to...",
                        "Wala nang ulo... umatras muna tayo.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_banter_weapon_kill_shaken",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.kill.killer.shaken.firearm_low",
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
                                ["fallback"] = "Jesus... I actually hit it.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.kill.killer.shaken.firearm_low.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Jesus... I actually hit it.",
                                        "My hands are shaking... but it's down.",
                                        "Did I get it? God, I think it's dead.",
                                        "That was way too close...",
                                        "I panicked and fired... thank God.",
                                        "Is it dead? Please tell me it's dead.",
                                        "Heart's beating out of my chest...",
                                        "I didn't think that shot would land.",
                                        "It's down... don't let another one get close.",
                                        "God... that sound... it's finally quiet.",
                                    },
                                    ["TL"] = {
                                        "Diyos ko... tinamaan ko talaga.",
                                        "Nanginginig ang mga kamay ko... pero bagsak na.",
                                        "Napatay ko ba? Diyos ko, sa tingin ko patay na.",
                                        "Masyadong malapit 'yon...",
                                        "Nag-panic ako at bumaril... salamat sa Diyos.",
                                        "Patay na ba? Sabihin mo sa akin kung patay na.",
                                        "Lulukso ang puso ko sa kaba...",
                                        "Hindi ko akalaing tatama ang putok na 'yon.",
                                        "Bagsak na... huwag mong hayaang may makalapit pang iba.",
                                        "Diyos ko... ang tunog na 'yon... tahimik na rin sa wakas.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.kill.killer.shaken",
            ["textRoles"] = {
                {
                    ["fallback"] = "Jesus... I actually hit it.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.killer.shaken.firearm_low.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Jesus... I actually hit it.",
                            "My hands are shaking... but it's down.",
                            "Did I get it? God, I think it's dead.",
                            "That was way too close...",
                            "I panicked and fired... thank God.",
                            "Is it dead? Please tell me it's dead.",
                            "Heart's beating out of my chest...",
                            "I didn't think that shot would land.",
                            "It's down... don't let another one get close.",
                            "God... that sound... it's finally quiet.",
                        },
                        ["TL"] = {
                            "Diyos ko... tinamaan ko talaga.",
                            "Nanginginig ang mga kamay ko... pero bagsak na.",
                            "Napatay ko ba? Diyos ko, sa tingin ko patay na.",
                            "Masyadong malapit 'yon...",
                            "Nag-panic ako at bumaril... salamat sa Diyos.",
                            "Patay na ba? Sabihin mo sa akin kung patay na.",
                            "Lulukso ang puso ko sa kaba...",
                            "Hindi ko akalaing tatama ang putok na 'yon.",
                            "Bagsak na... huwag mong hayaang may makalapit pang iba.",
                            "Diyos ko... ang tunog na 'yon... tahimik na rin sa wakas.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.kill.killer.shaken.firearm_low",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "firearm_low",
            ["sourceId"] = "combat.kill.killer.shaken.firearm_low",
            ["sourcePath"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_shaken/combat_kill_killer_shaken_firearm_low.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatBanterWeaponKillShaken",
        ["namespace"] = "combat.kill.killer.shaken",
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
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/combat_banter/weapon_kill/shaken.json",
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
                                        "Jesus... I actually hit it.",
                                        "My hands are shaking... but it's down.",
                                        "Did I get it? God, I think it's dead.",
                                        "That was way too close...",
                                        "I panicked and fired... thank God.",
                                        "Is it dead? Please tell me it's dead.",
                                        "Heart's beating out of my chest...",
                                        "I didn't think that shot would land.",
                                        "It's down... don't let another one get close.",
                                        "God... that sound... it's finally quiet.",
                                    },
                                    ["TL"] = {
                                        "Diyos ko... tinamaan ko talaga.",
                                        "Nanginginig ang mga kamay ko... pero bagsak na.",
                                        "Napatay ko ba? Diyos ko, sa tingin ko patay na.",
                                        "Masyadong malapit 'yon...",
                                        "Nag-panic ako at bumaril... salamat sa Diyos.",
                                        "Patay na ba? Sabihin mo sa akin kung patay na.",
                                        "Lulukso ang puso ko sa kaba...",
                                        "Hindi ko akalaing tatama ang putok na 'yon.",
                                        "Bagsak na... huwag mong hayaang may makalapit pang iba.",
                                        "Diyos ko... ang tunog na 'yon... tahimik na rin sa wakas.",
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
            ["responsePlanID"] = "combat.kill.killer.shaken.firearm_low",
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
                            ["fallback"] = "Jesus... I actually hit it.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.kill.killer.shaken.firearm_low.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_shaken/combat_kill_killer_shaken_firearm_low.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Jesus... I actually hit it.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.killer.shaken.firearm_low.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Jesus... I actually hit it.",
                        "My hands are shaking... but it's down.",
                        "Did I get it? God, I think it's dead.",
                        "That was way too close...",
                        "I panicked and fired... thank God.",
                        "Is it dead? Please tell me it's dead.",
                        "Heart's beating out of my chest...",
                        "I didn't think that shot would land.",
                        "It's down... don't let another one get close.",
                        "God... that sound... it's finally quiet.",
                    },
                    ["TL"] = {
                        "Diyos ko... tinamaan ko talaga.",
                        "Nanginginig ang mga kamay ko... pero bagsak na.",
                        "Napatay ko ba? Diyos ko, sa tingin ko patay na.",
                        "Masyadong malapit 'yon...",
                        "Nag-panic ako at bumaril... salamat sa Diyos.",
                        "Patay na ba? Sabihin mo sa akin kung patay na.",
                        "Lulukso ang puso ko sa kaba...",
                        "Hindi ko akalaing tatama ang putok na 'yon.",
                        "Bagsak na... huwag mong hayaang may makalapit pang iba.",
                        "Diyos ko... ang tunog na 'yon... tahimik na rin sa wakas.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_banter_weapon_kill_shaken",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.kill.killer.shaken.unarmed",
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
                                ["fallback"] = "Oh God. I did that with my hands.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.kill.killer.shaken.unarmed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Oh God. I did that with my hands.",
                                        "I had to shove it down... my bare hands.",
                                        "It almost bit me. Look at my arms shaking.",
                                        "I need a weapon. I can't do that again.",
                                        "I felt its teeth scrape near my jacket.",
                                        "Stomped on its head... God forgive me.",
                                        "That was pure desperation.",
                                        "My hands are bruised... but I'm alive.",
                                        "Never want to be that close again.",
                                        "It's dead... I pushed it off and stomped.",
                                    },
                                    ["TL"] = {
                                        "Diyos ko. Kamay ko lang ang ginamit ko.",
                                        "Kinailangan kong itulak pabagsak... mga kamay ko lang.",
                                        "Halos makagat ako. Tingnan mo ang nanginginig kong braso.",
                                        "Kailangan ko ng sandata. Hindi ko na mauulit 'yon.",
                                        "Naramdaman ko ang ngipin nito malapit sa jacket ko.",
                                        "Tinapakan ko ang ulo... patawarin ako ng Diyos.",
                                        "Dala lang 'yon ng matinding takot.",
                                        "Pasa-pasa ang mga kamay ko... pero buhay pa ako.",
                                        "Ayoko nang mapalapit nang gano'n kailanman.",
                                        "Patay na... itinulak ko at tinapakan.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.kill.killer.shaken",
            ["textRoles"] = {
                {
                    ["fallback"] = "Oh God. I did that with my hands.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.killer.shaken.unarmed.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Oh God. I did that with my hands.",
                            "I had to shove it down... my bare hands.",
                            "It almost bit me. Look at my arms shaking.",
                            "I need a weapon. I can't do that again.",
                            "I felt its teeth scrape near my jacket.",
                            "Stomped on its head... God forgive me.",
                            "That was pure desperation.",
                            "My hands are bruised... but I'm alive.",
                            "Never want to be that close again.",
                            "It's dead... I pushed it off and stomped.",
                        },
                        ["TL"] = {
                            "Diyos ko. Kamay ko lang ang ginamit ko.",
                            "Kinailangan kong itulak pabagsak... mga kamay ko lang.",
                            "Halos makagat ako. Tingnan mo ang nanginginig kong braso.",
                            "Kailangan ko ng sandata. Hindi ko na mauulit 'yon.",
                            "Naramdaman ko ang ngipin nito malapit sa jacket ko.",
                            "Tinapakan ko ang ulo... patawarin ako ng Diyos.",
                            "Dala lang 'yon ng matinding takot.",
                            "Pasa-pasa ang mga kamay ko... pero buhay pa ako.",
                            "Ayoko nang mapalapit nang gano'n kailanman.",
                            "Patay na... itinulak ko at tinapakan.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.kill.killer.shaken.unarmed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "unarmed",
            ["sourceId"] = "combat.kill.killer.shaken.unarmed",
            ["sourcePath"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_shaken/combat_kill_killer_shaken_unarmed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatBanterWeaponKillShaken",
        ["namespace"] = "combat.kill.killer.shaken",
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
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/combat_banter/weapon_kill/shaken.json",
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
                                        "Oh God. I did that with my hands.",
                                        "I had to shove it down... my bare hands.",
                                        "It almost bit me. Look at my arms shaking.",
                                        "I need a weapon. I can't do that again.",
                                        "I felt its teeth scrape near my jacket.",
                                        "Stomped on its head... God forgive me.",
                                        "That was pure desperation.",
                                        "My hands are bruised... but I'm alive.",
                                        "Never want to be that close again.",
                                        "It's dead... I pushed it off and stomped.",
                                    },
                                    ["TL"] = {
                                        "Diyos ko. Kamay ko lang ang ginamit ko.",
                                        "Kinailangan kong itulak pabagsak... mga kamay ko lang.",
                                        "Halos makagat ako. Tingnan mo ang nanginginig kong braso.",
                                        "Kailangan ko ng sandata. Hindi ko na mauulit 'yon.",
                                        "Naramdaman ko ang ngipin nito malapit sa jacket ko.",
                                        "Tinapakan ko ang ulo... patawarin ako ng Diyos.",
                                        "Dala lang 'yon ng matinding takot.",
                                        "Pasa-pasa ang mga kamay ko... pero buhay pa ako.",
                                        "Ayoko nang mapalapit nang gano'n kailanman.",
                                        "Patay na... itinulak ko at tinapakan.",
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
            ["responsePlanID"] = "combat.kill.killer.shaken.unarmed",
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
                            ["fallback"] = "Oh God. I did that with my hands.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.kill.killer.shaken.unarmed.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_shaken/combat_kill_killer_shaken_unarmed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Oh God. I did that with my hands.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.killer.shaken.unarmed.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Oh God. I did that with my hands.",
                        "I had to shove it down... my bare hands.",
                        "It almost bit me. Look at my arms shaking.",
                        "I need a weapon. I can't do that again.",
                        "I felt its teeth scrape near my jacket.",
                        "Stomped on its head... God forgive me.",
                        "That was pure desperation.",
                        "My hands are bruised... but I'm alive.",
                        "Never want to be that close again.",
                        "It's dead... I pushed it off and stomped.",
                    },
                    ["TL"] = {
                        "Diyos ko. Kamay ko lang ang ginamit ko.",
                        "Kinailangan kong itulak pabagsak... mga kamay ko lang.",
                        "Halos makagat ako. Tingnan mo ang nanginginig kong braso.",
                        "Kailangan ko ng sandata. Hindi ko na mauulit 'yon.",
                        "Naramdaman ko ang ngipin nito malapit sa jacket ko.",
                        "Tinapakan ko ang ulo... patawarin ako ng Diyos.",
                        "Dala lang 'yon ng matinding takot.",
                        "Pasa-pasa ang mga kamay ko... pero buhay pa ako.",
                        "Ayoko nang mapalapit nang gano'n kailanman.",
                        "Patay na... itinulak ko at tinapakan.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
