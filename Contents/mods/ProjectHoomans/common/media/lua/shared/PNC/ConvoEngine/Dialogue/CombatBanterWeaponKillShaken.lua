-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_banter_weapon_kill_shaken",
        ["id"] = "semantic.combat.kill.killer.shaken.blade_head_01",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.combat.kill.killer.shaken.blade_head_01",
            ["sourcePath"] = "psdl/dialogue/combat_banter_weapon_kill_shaken.json#records[1]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatBanterWeaponKillShaken",
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
                ["responseTemplateID"] = "semantic.combat.kill.killer.shaken.blade_head_01",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/combat_banter/weapon_kill/shaken.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Oh God... there's blood everywhere.",
                            },
                            ["TL"] = {
                                "Diyos ko... may dugo kahit saan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "It's in pieces... I need a second.",
                            },
                            ["TL"] = {
                                "Pira-piraso na... kailangan ko ng saglit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "The smell... God, I think I'm gonna be sick.",
                            },
                            ["TL"] = {
                                "Ang amoy... Diyos ko, masusuka yata ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I can still feel the crunch...",
                            },
                            ["TL"] = {
                                "Ramdam ko pa rin ang lagutok...",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "It came right at me... had to cut it.",
                            },
                            ["TL"] = {
                                "Diretso sa akin... kailangan kong hiwain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Hands won't stop trembling...",
                            },
                            ["TL"] = {
                                "Ayaw tumigil ng panginginig ng mga kamay ko...",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Is it really dead? Look at it...",
                            },
                            ["TL"] = {
                                "Patay na ba talaga? Tingnan mo...",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "That was horrible... but it's over.",
                            },
                            ["TL"] = {
                                "Kakila-kilabot 'yon... pero tapos na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "God, I hate doing this...",
                            },
                            ["TL"] = {
                                "Diyos ko, ayaw na ayaw kong ginagawa 'to...",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Head's gone... let's just step back.",
                            },
                            ["TL"] = {
                                "Wala nang ulo... umatras muna tayo.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/combat_banter_weapon_kill_shaken.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_banter_weapon_kill_shaken",
        ["id"] = "semantic.combat.kill.killer.shaken.firearm_low_01",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.combat.kill.killer.shaken.firearm_low_01",
            ["sourcePath"] = "psdl/dialogue/combat_banter_weapon_kill_shaken.json#records[0]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatBanterWeaponKillShaken",
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
                ["responseTemplateID"] = "semantic.combat.kill.killer.shaken.firearm_low_01",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/combat_banter/weapon_kill/shaken.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Jesus... I actually hit it.",
                            },
                            ["TL"] = {
                                "Diyos ko... tinamaan ko talaga.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "My hands are shaking... but it's down.",
                            },
                            ["TL"] = {
                                "Nanginginig ang mga kamay ko... pero bagsak na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Did I get it? God, I think it's dead.",
                            },
                            ["TL"] = {
                                "Napatay ko ba? Diyos ko, sa tingin ko patay na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "That was way too close...",
                            },
                            ["TL"] = {
                                "Masyadong malapit 'yon...",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I panicked and fired... thank God.",
                            },
                            ["TL"] = {
                                "Nag-panic ako at bumaril... salamat sa Diyos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Is it dead? Please tell me it's dead.",
                            },
                            ["TL"] = {
                                "Patay na ba? Sabihin mo sa akin kung patay na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Heart's beating out of my chest...",
                            },
                            ["TL"] = {
                                "Lulukso ang puso ko sa kaba...",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I didn't think that shot would land.",
                            },
                            ["TL"] = {
                                "Hindi ko akalaing tatama ang putok na 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "It's down... don't let another one get close.",
                            },
                            ["TL"] = {
                                "Bagsak na... huwag mong hayaang may makalapit pang iba.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "God... that sound... it's finally quiet.",
                            },
                            ["TL"] = {
                                "Diyos ko... ang tunog na 'yon... tahimik na rin sa wakas.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/combat_banter_weapon_kill_shaken.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_banter_weapon_kill_shaken",
        ["id"] = "semantic.combat.kill.killer.shaken.unarmed_01",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.combat.kill.killer.shaken.unarmed_01",
            ["sourcePath"] = "psdl/dialogue/combat_banter_weapon_kill_shaken.json#records[2]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatBanterWeaponKillShaken",
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
                ["responseTemplateID"] = "semantic.combat.kill.killer.shaken.unarmed_01",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/combat_banter/weapon_kill/shaken.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Oh God. I did that with my hands.",
                            },
                            ["TL"] = {
                                "Diyos ko. Kamay ko lang ang ginamit ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I had to shove it down... my bare hands.",
                            },
                            ["TL"] = {
                                "Kinailangan kong itulak pabagsak... mga kamay ko lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "It almost bit me. Look at my arms shaking.",
                            },
                            ["TL"] = {
                                "Halos makagat ako. Tingnan mo ang nanginginig kong braso.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I need a weapon. I can't do that again.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng sandata. Hindi ko na mauulit 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I felt its teeth scrape near my jacket.",
                            },
                            ["TL"] = {
                                "Naramdaman ko ang ngipin nito malapit sa jacket ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Stomped on its head... God forgive me.",
                            },
                            ["TL"] = {
                                "Tinapakan ko ang ulo... patawarin ako ng Diyos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "That was pure desperation.",
                            },
                            ["TL"] = {
                                "Dala lang 'yon ng matinding takot.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "My hands are bruised... but I'm alive.",
                            },
                            ["TL"] = {
                                "Pasa-pasa ang mga kamay ko... pero buhay pa ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Never want to be that close again.",
                            },
                            ["TL"] = {
                                "Ayoko nang mapalapit nang gano'n kailanman.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "It's dead... I pushed it off and stomped.",
                            },
                            ["TL"] = {
                                "Patay na... itinulak ko at tinapakan.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/combat_banter_weapon_kill_shaken.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
