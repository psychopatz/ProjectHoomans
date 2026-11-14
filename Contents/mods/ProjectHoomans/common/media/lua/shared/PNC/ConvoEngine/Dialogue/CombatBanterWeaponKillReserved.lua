-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_banter_weapon_kill_reserved",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.kill.killer.reserved.blade",
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
                                ["fallback"] = "Cut down.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.kill.killer.reserved.blade.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Cut down.",
                                        "Head severed.",
                                        "Down.",
                                        "Done.",
                                        "Clear.",
                                        "Finished.",
                                        "Eliminated.",
                                        "Fell.",
                                        "Clean strike.",
                                        "Moving.",
                                    },
                                    ["TL"] = {
                                        "Nahati.",
                                        "Pugot.",
                                        "Bagsak.",
                                        "Tapos.",
                                        "Malinis.",
                                        "Yari.",
                                        "Tanggal.",
                                        "Bumagsak.",
                                        "Malinis na tama.",
                                        "Lalakad na.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.kill.killer.reserved",
            ["textRoles"] = {
                {
                    ["fallback"] = "Cut down.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.killer.reserved.blade.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Cut down.",
                            "Head severed.",
                            "Down.",
                            "Done.",
                            "Clear.",
                            "Finished.",
                            "Eliminated.",
                            "Fell.",
                            "Clean strike.",
                            "Moving.",
                        },
                        ["TL"] = {
                            "Nahati.",
                            "Pugot.",
                            "Bagsak.",
                            "Tapos.",
                            "Malinis.",
                            "Yari.",
                            "Tanggal.",
                            "Bumagsak.",
                            "Malinis na tama.",
                            "Lalakad na.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.kill.killer.reserved.blade",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "blade",
            ["sourceId"] = "combat.kill.killer.reserved.blade",
            ["sourcePath"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_reserved/combat_kill_killer_reserved_blade.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatBanterWeaponKillReserved",
        ["namespace"] = "combat.kill.killer.reserved",
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
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/combat_banter/weapon_kill/reserved.json",
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
                                        "Cut down.",
                                        "Head severed.",
                                        "Down.",
                                        "Done.",
                                        "Clear.",
                                        "Finished.",
                                        "Eliminated.",
                                        "Fell.",
                                        "Clean strike.",
                                        "Moving.",
                                    },
                                    ["TL"] = {
                                        "Nahati.",
                                        "Pugot.",
                                        "Bagsak.",
                                        "Tapos.",
                                        "Malinis.",
                                        "Yari.",
                                        "Tanggal.",
                                        "Bumagsak.",
                                        "Malinis na tama.",
                                        "Lalakad na.",
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
            ["responsePlanID"] = "combat.kill.killer.reserved.blade",
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
                            ["fallback"] = "Cut down.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.kill.killer.reserved.blade.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_reserved/combat_kill_killer_reserved_blade.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Cut down.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.killer.reserved.blade.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Cut down.",
                        "Head severed.",
                        "Down.",
                        "Done.",
                        "Clear.",
                        "Finished.",
                        "Eliminated.",
                        "Fell.",
                        "Clean strike.",
                        "Moving.",
                    },
                    ["TL"] = {
                        "Nahati.",
                        "Pugot.",
                        "Bagsak.",
                        "Tapos.",
                        "Malinis.",
                        "Yari.",
                        "Tanggal.",
                        "Bumagsak.",
                        "Malinis na tama.",
                        "Lalakad na.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_banter_weapon_kill_reserved",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.kill.killer.reserved.firearm",
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
                                ["fallback"] = "Hit.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.kill.killer.reserved.firearm.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Hit.",
                                        "Down.",
                                        "Target neutral.",
                                        "One round.",
                                        "Clear.",
                                        "Eliminated.",
                                        "Dropped.",
                                        "Shot connected.",
                                        "Neutralized.",
                                        "Done.",
                                    },
                                    ["TL"] = {
                                        "Tinamaan.",
                                        "Bagsak.",
                                        "Target bagsak.",
                                        "Isang bala.",
                                        "Malinis.",
                                        "Tanggal.",
                                        "Naitumba.",
                                        "Tumama ang putok.",
                                        "Naalis.",
                                        "Tapos.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.kill.killer.reserved",
            ["textRoles"] = {
                {
                    ["fallback"] = "Hit.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.killer.reserved.firearm.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Hit.",
                            "Down.",
                            "Target neutral.",
                            "One round.",
                            "Clear.",
                            "Eliminated.",
                            "Dropped.",
                            "Shot connected.",
                            "Neutralized.",
                            "Done.",
                        },
                        ["TL"] = {
                            "Tinamaan.",
                            "Bagsak.",
                            "Target bagsak.",
                            "Isang bala.",
                            "Malinis.",
                            "Tanggal.",
                            "Naitumba.",
                            "Tumama ang putok.",
                            "Naalis.",
                            "Tapos.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.kill.killer.reserved.firearm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "firearm",
            ["sourceId"] = "combat.kill.killer.reserved.firearm",
            ["sourcePath"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_reserved/combat_kill_killer_reserved_firearm.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatBanterWeaponKillReserved",
        ["namespace"] = "combat.kill.killer.reserved",
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
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/combat_banter/weapon_kill/reserved.json",
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
                                        "Hit.",
                                        "Down.",
                                        "Target neutral.",
                                        "One round.",
                                        "Clear.",
                                        "Eliminated.",
                                        "Dropped.",
                                        "Shot connected.",
                                        "Neutralized.",
                                        "Done.",
                                    },
                                    ["TL"] = {
                                        "Tinamaan.",
                                        "Bagsak.",
                                        "Target bagsak.",
                                        "Isang bala.",
                                        "Malinis.",
                                        "Tanggal.",
                                        "Naitumba.",
                                        "Tumama ang putok.",
                                        "Naalis.",
                                        "Tapos.",
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
            ["responsePlanID"] = "combat.kill.killer.reserved.firearm",
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
                            ["fallback"] = "Hit.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.kill.killer.reserved.firearm.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_reserved/combat_kill_killer_reserved_firearm.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Hit.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.killer.reserved.firearm.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Hit.",
                        "Down.",
                        "Target neutral.",
                        "One round.",
                        "Clear.",
                        "Eliminated.",
                        "Dropped.",
                        "Shot connected.",
                        "Neutralized.",
                        "Done.",
                    },
                    ["TL"] = {
                        "Tinamaan.",
                        "Bagsak.",
                        "Target bagsak.",
                        "Isang bala.",
                        "Malinis.",
                        "Tanggal.",
                        "Naitumba.",
                        "Tumama ang putok.",
                        "Naalis.",
                        "Tapos.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
