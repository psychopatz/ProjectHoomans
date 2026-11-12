-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_combat",
        ["id"] = "semantic.combat.horde.choice.avoid",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.horde.choice.avoid",
            ["sourcePath"] = "psdl/dialogue/companion_commands_combat.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_horde_choice_avoid",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.combat.horde.choice.avoid",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/combat_horde_reactions.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Go around.",
                            },
                            ["TL"] = {
                                "Umikot tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Bypass them. Stay quiet.",
                            },
                            ["TL"] = {
                                "Lalagpasan natin sila. Huwag mag-ingay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Find another route. Don't draw them.",
                            },
                            ["TL"] = {
                                "Maghanap ng ibang ruta. Huwag silang akitin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Circle wide. Keep in the shadows.",
                            },
                            ["TL"] = {
                                "Umikot nang malayo. Manatili sa dilim.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Not worth the ammo. Move around.",
                            },
                            ["TL"] = {
                                "Sayang ang bala. Umiwas na lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Detour through the alley. Quietly.",
                            },
                            ["TL"] = {
                                "Daan tayo sa eskinita. Nang tahimik.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "We sneak past. Crouch and move.",
                            },
                            ["TL"] = {
                                "Lulusot tayo nang lihim. Yumuko at lumakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Leave them be. Take the back way.",
                            },
                            ["TL"] = {
                                "Hayaan sila roon. Daan tayo sa likod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Avoid contact. Step carefully.",
                            },
                            ["TL"] = {
                                "Iwasan ang engkwentro. Mag-ingat sa bawat hakbang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Back out and take the alternate street.",
                            },
                            ["TL"] = {
                                "Atras muna at dumaan sa kabilang kalsada.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_combat.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
