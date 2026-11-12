-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_banter_weapon_kill_aggressive",
        ["id"] = "semantic.combat.kill.killer.aggressive.firearm_high_named_01",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.kill.killer.aggressive.firearm_high_named_01",
            ["sourcePath"] = "psdl/dialogue/combat_banter_weapon_kill_aggressive.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_kill_killer_aggressive_firearm_high_named_01",
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
                ["responseTemplateID"] = "semantic.combat.kill.killer.aggressive.firearm_high_named_01",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/combat_banter/weapon_kill/aggressive.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "This {slot.weapon.name} still shoots straight.",
                            },
                            ["TL"] = {
                                "Tuwid pa ring bumaril itong {slot.weapon.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Nothing beats this {slot.weapon.name} when it counts.",
                            },
                            ["TL"] = {
                                "Walang tatalo sa {slot.weapon.name} na 'to kapag kailangan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Good old {slot.weapon.name}. Never lets me down.",
                            },
                            ["TL"] = {
                                "Maaasahang {slot.weapon.name}. Hindi ako binibigo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Told you this {slot.weapon.name} has stopping power.",
                            },
                            ["TL"] = {
                                "Sabi ko sa'yo may lakas pumigil itong {slot.weapon.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "That {slot.weapon.name} put it right in the dirt.",
                            },
                            ["TL"] = {
                                "Ibinagsak agad ng {slot.weapon.name} sa lupa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Clean work with the {slot.weapon.name}.",
                            },
                            ["TL"] = {
                                "Malinis na trabaho gamit ang {slot.weapon.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "This {slot.weapon.name} punched right through.",
                            },
                            ["TL"] = {
                                "Tumagos agad itong {slot.weapon.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Glad I had this {slot.weapon.name} ready.",
                            },
                            ["TL"] = {
                                "Mabuti na lang at handa itong {slot.weapon.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "One round from this {slot.weapon.name} is all it takes.",
                            },
                            ["TL"] = {
                                "Isang bala lang mula sa {slot.weapon.name} na 'to, sapat na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "The {slot.weapon.name} tore right through its skull.",
                            },
                            ["TL"] = {
                                "Winasak ng {slot.weapon.name} ang bungo nito.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
            ["weapon"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.item",
            },
        },
        ["sourceShard"] = "psdl/dialogue/combat_banter_weapon_kill_aggressive.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
