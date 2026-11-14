-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_banter_weapon_kill_supportive",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.kill.killer.supportive.firearm",
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
                                ["fallback"] = "Got it. You good?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.kill.killer.supportive.firearm.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Got it. You good?",
                                        "Threat's down. Check yourself.",
                                        "Downed that one. I've got your back.",
                                        "Clear! You hurt anywhere?",
                                        "Got him off us. Stay close.",
                                        "Dropped that one. Keep your eyes open.",
                                        "Took care of it. Are you alright?",
                                        "Shot landed. You safe?",
                                        "Target down. Covering you.",
                                        "That one's finished. Watch the flanks.",
                                    },
                                    ["TL"] = {
                                        "Nakuha ko. Ayos ka?",
                                        "Bagsak ang banta. Tignan mo sarili mo.",
                                        "Ibinagsak ko ang isa. Hawak ko ang likod mo.",
                                        "Malinis! May tama ka ba kahit saan?",
                                        "Nailayo ko sa atin. Dumikit ka.",
                                        "Bagsak na 'yon. Manatiling gising ang mata.",
                                        "Inasikaso ko na. Ayos ka lang?",
                                        "Tumama ang putok. Ligtas ka?",
                                        "Bagsak ang target. Sinasalag kita.",
                                        "Tapos na ang isang 'yon. Bantayan ang gilid.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.kill.killer.supportive",
            ["textRoles"] = {
                {
                    ["fallback"] = "Got it. You good?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.killer.supportive.firearm.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Got it. You good?",
                            "Threat's down. Check yourself.",
                            "Downed that one. I've got your back.",
                            "Clear! You hurt anywhere?",
                            "Got him off us. Stay close.",
                            "Dropped that one. Keep your eyes open.",
                            "Took care of it. Are you alright?",
                            "Shot landed. You safe?",
                            "Target down. Covering you.",
                            "That one's finished. Watch the flanks.",
                        },
                        ["TL"] = {
                            "Nakuha ko. Ayos ka?",
                            "Bagsak ang banta. Tignan mo sarili mo.",
                            "Ibinagsak ko ang isa. Hawak ko ang likod mo.",
                            "Malinis! May tama ka ba kahit saan?",
                            "Nailayo ko sa atin. Dumikit ka.",
                            "Bagsak na 'yon. Manatiling gising ang mata.",
                            "Inasikaso ko na. Ayos ka lang?",
                            "Tumama ang putok. Ligtas ka?",
                            "Bagsak ang target. Sinasalag kita.",
                            "Tapos na ang isang 'yon. Bantayan ang gilid.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.kill.killer.supportive.firearm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "firearm",
            ["sourceId"] = "combat.kill.killer.supportive.firearm",
            ["sourcePath"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_supportive/combat_kill_killer_supportive_firearm.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatBanterWeaponKillSupportive",
        ["namespace"] = "combat.kill.killer.supportive",
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
                                        "Got it. You good?",
                                        "Threat's down. Check yourself.",
                                        "Downed that one. I've got your back.",
                                        "Clear! You hurt anywhere?",
                                        "Got him off us. Stay close.",
                                        "Dropped that one. Keep your eyes open.",
                                        "Took care of it. Are you alright?",
                                        "Shot landed. You safe?",
                                        "Target down. Covering you.",
                                        "That one's finished. Watch the flanks.",
                                    },
                                    ["TL"] = {
                                        "Nakuha ko. Ayos ka?",
                                        "Bagsak ang banta. Tignan mo sarili mo.",
                                        "Ibinagsak ko ang isa. Hawak ko ang likod mo.",
                                        "Malinis! May tama ka ba kahit saan?",
                                        "Nailayo ko sa atin. Dumikit ka.",
                                        "Bagsak na 'yon. Manatiling gising ang mata.",
                                        "Inasikaso ko na. Ayos ka lang?",
                                        "Tumama ang putok. Ligtas ka?",
                                        "Bagsak ang target. Sinasalag kita.",
                                        "Tapos na ang isang 'yon. Bantayan ang gilid.",
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
            ["responsePlanID"] = "combat.kill.killer.supportive.firearm",
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
                            ["fallback"] = "Got it. You good?",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.kill.killer.supportive.firearm.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_supportive/combat_kill_killer_supportive_firearm.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Got it. You good?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.killer.supportive.firearm.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Got it. You good?",
                        "Threat's down. Check yourself.",
                        "Downed that one. I've got your back.",
                        "Clear! You hurt anywhere?",
                        "Got him off us. Stay close.",
                        "Dropped that one. Keep your eyes open.",
                        "Took care of it. Are you alright?",
                        "Shot landed. You safe?",
                        "Target down. Covering you.",
                        "That one's finished. Watch the flanks.",
                    },
                    ["TL"] = {
                        "Nakuha ko. Ayos ka?",
                        "Bagsak ang banta. Tignan mo sarili mo.",
                        "Ibinagsak ko ang isa. Hawak ko ang likod mo.",
                        "Malinis! May tama ka ba kahit saan?",
                        "Nailayo ko sa atin. Dumikit ka.",
                        "Bagsak na 'yon. Manatiling gising ang mata.",
                        "Inasikaso ko na. Ayos ka lang?",
                        "Tumama ang putok. Ligtas ka?",
                        "Bagsak ang target. Sinasalag kita.",
                        "Tapos na ang isang 'yon. Bantayan ang gilid.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_banter_weapon_kill_supportive",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.kill.killer.supportive.melee",
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
                                ["fallback"] = "It's down. Keep close.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.kill.killer.supportive.melee.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "It's down. Keep close.",
                                        "Got it off you. You alright?",
                                        "Downed it. Check your corners.",
                                        "I'm right here with you. It's dead.",
                                        "Crushed it before it got close.",
                                        "Stay behind me. That one's done.",
                                        "Took it down. Catch your breath.",
                                        "Dead on the floor. You holding up?",
                                        "I've got this line. Watch behind us.",
                                        "It's over for that one. We're okay.",
                                    },
                                    ["TL"] = {
                                        "Bagsak na. Dumikit ka lang.",
                                        "Nailayo ko sa'yo. Ayos ka lang?",
                                        "Ibinagsak ko na. Tignan ang sulok mo.",
                                        "Nandito lang ako kasama mo. Patay na.",
                                        "Dinurog bago pa makalapit.",
                                        "Manatili sa likod ko. Tapos na 'yon.",
                                        "Ibinagsak ko na. Huminga ka muna.",
                                        "Patay sa sahig. Nakakayanan mo pa?",
                                        "Hawak ko ang linyang 'to. Bantayan ang likod.",
                                        "Tapos na ang isang 'yon. Ayos lang tayo.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.kill.killer.supportive",
            ["textRoles"] = {
                {
                    ["fallback"] = "It's down. Keep close.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.kill.killer.supportive.melee.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "It's down. Keep close.",
                            "Got it off you. You alright?",
                            "Downed it. Check your corners.",
                            "I'm right here with you. It's dead.",
                            "Crushed it before it got close.",
                            "Stay behind me. That one's done.",
                            "Took it down. Catch your breath.",
                            "Dead on the floor. You holding up?",
                            "I've got this line. Watch behind us.",
                            "It's over for that one. We're okay.",
                        },
                        ["TL"] = {
                            "Bagsak na. Dumikit ka lang.",
                            "Nailayo ko sa'yo. Ayos ka lang?",
                            "Ibinagsak ko na. Tignan ang sulok mo.",
                            "Nandito lang ako kasama mo. Patay na.",
                            "Dinurog bago pa makalapit.",
                            "Manatili sa likod ko. Tapos na 'yon.",
                            "Ibinagsak ko na. Huminga ka muna.",
                            "Patay sa sahig. Nakakayanan mo pa?",
                            "Hawak ko ang linyang 'to. Bantayan ang likod.",
                            "Tapos na ang isang 'yon. Ayos lang tayo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.kill.killer.supportive.melee",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "melee",
            ["sourceId"] = "combat.kill.killer.supportive.melee",
            ["sourcePath"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_supportive/combat_kill_killer_supportive_melee.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatBanterWeaponKillSupportive",
        ["namespace"] = "combat.kill.killer.supportive",
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
                                        "It's down. Keep close.",
                                        "Got it off you. You alright?",
                                        "Downed it. Check your corners.",
                                        "I'm right here with you. It's dead.",
                                        "Crushed it before it got close.",
                                        "Stay behind me. That one's done.",
                                        "Took it down. Catch your breath.",
                                        "Dead on the floor. You holding up?",
                                        "I've got this line. Watch behind us.",
                                        "It's over for that one. We're okay.",
                                    },
                                    ["TL"] = {
                                        "Bagsak na. Dumikit ka lang.",
                                        "Nailayo ko sa'yo. Ayos ka lang?",
                                        "Ibinagsak ko na. Tignan ang sulok mo.",
                                        "Nandito lang ako kasama mo. Patay na.",
                                        "Dinurog bago pa makalapit.",
                                        "Manatili sa likod ko. Tapos na 'yon.",
                                        "Ibinagsak ko na. Huminga ka muna.",
                                        "Patay sa sahig. Nakakayanan mo pa?",
                                        "Hawak ko ang linyang 'to. Bantayan ang likod.",
                                        "Tapos na ang isang 'yon. Ayos lang tayo.",
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
            ["responsePlanID"] = "combat.kill.killer.supportive.melee",
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
                            ["fallback"] = "It's down. Keep close.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.kill.killer.supportive.melee.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/combat_banter_weapon_kill_supportive/combat_kill_killer_supportive_melee.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "It's down. Keep close.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.kill.killer.supportive.melee.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "It's down. Keep close.",
                        "Got it off you. You alright?",
                        "Downed it. Check your corners.",
                        "I'm right here with you. It's dead.",
                        "Crushed it before it got close.",
                        "Stay behind me. That one's done.",
                        "Took it down. Catch your breath.",
                        "Dead on the floor. You holding up?",
                        "I've got this line. Watch behind us.",
                        "It's over for that one. We're okay.",
                    },
                    ["TL"] = {
                        "Bagsak na. Dumikit ka lang.",
                        "Nailayo ko sa'yo. Ayos ka lang?",
                        "Ibinagsak ko na. Tignan ang sulok mo.",
                        "Nandito lang ako kasama mo. Patay na.",
                        "Dinurog bago pa makalapit.",
                        "Manatili sa likod ko. Tapos na 'yon.",
                        "Ibinagsak ko na. Huminga ka muna.",
                        "Patay sa sahig. Nakakayanan mo pa?",
                        "Hawak ko ang linyang 'to. Bantayan ang likod.",
                        "Tapos na ang isang 'yon. Ayos lang tayo.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
