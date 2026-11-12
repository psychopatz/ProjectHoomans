-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_banter_weapon_kill_practical",
        ["id"] = "semantic.combat.kill.killer.practical.firearm_low_01",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.kill.killer.practical.firearm_low_01",
            ["sourcePath"] = "psdl/dialogue/combat_banter_weapon_kill_practical.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_kill_killer_practical_firearm_low_01",
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
                ["responseTemplateID"] = "semantic.combat.kill.killer.practical.firearm_low_01",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/combat_banter/weapon_kill/practical.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Hit it. Don't count on luck twice.",
                            },
                            ["TL"] = {
                                "Tinamaan. Huwag umasa sa swerte nang dalawang beses.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Took two shots, but it's down.",
                            },
                            ["TL"] = {
                                "Dalawang putok ang kinailangan, pero bagsak na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Messy hit, but it did the job.",
                            },
                            ["TL"] = {
                                "Magulo ang tama, pero nagawa ang trabaho.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Downed. Check remaining ammo now.",
                            },
                            ["TL"] = {
                                "Bagsak. Tignan ang natitirang bala ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Wasted a round there. Settle your aim.",
                            },
                            ["TL"] = {
                                "Nakaaksaya ng bala roon. Pakalmahin ang asinta.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "It's on the floor. Reload if needed.",
                            },
                            ["TL"] = {
                                "Nasa sahig na. Mag-reload kung kailangan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Hit the mark eventually. Stay focused.",
                            },
                            ["TL"] = {
                                "Tumama rin sa wakas. Manatiling nakatutok.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Threat down. Don't get sloppy.",
                            },
                            ["TL"] = {
                                "Bagsak ang banta. Huwag magpabaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Barely got that in time. Reset.",
                            },
                            ["TL"] = {
                                "Muntik na 'yon. Ayusin ulit ang pwesto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Downed. Watch the noise level.",
                            },
                            ["TL"] = {
                                "Bagsak. Bantayan ang ingay.",
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
        ["sourceShard"] = "psdl/dialogue/combat_banter_weapon_kill_practical.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
