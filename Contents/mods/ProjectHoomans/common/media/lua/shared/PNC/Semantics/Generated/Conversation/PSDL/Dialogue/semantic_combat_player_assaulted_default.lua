-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_player_assault_reactions",
        ["id"] = "semantic.combat.player_assaulted.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.player_assaulted.default",
            ["sourcePath"] = "psdl/dialogue/combat_player_assault_reactions.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_player_assaulted_default",
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
                ["contentOwner"] = "projecthoomans.dialogue_content.combat",
                ["responseTemplateID"] = "semantic.combat.player_assaulted.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/combat/player_assault_reactions.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Why did you do that?!",
                            },
                            ["TL"] = {
                                "Bakit mo ginawa iyon?!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "What the hell is wrong with you?!",
                            },
                            ["TL"] = {
                                "Ano bang problema mo?!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Hey! Watch what you're doing!",
                            },
                            ["TL"] = {
                                "Hoy! Tingnan mo ang ginagawa mo!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Did you just swing at me?!",
                            },
                            ["TL"] = {
                                "Hinataw mo ba ako?!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Are you trying to kill me?!",
                            },
                            ["TL"] = {
                                "Gusto mo ba akong patayin?!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "What are you thinking?! Stop it!",
                            },
                            ["TL"] = {
                                "Ano bang iniisip mo?! Tigil!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Whoa! Back off!",
                            },
                            ["TL"] = {
                                "Teka! Atras!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Don't hit me! What's wrong with you?!",
                            },
                            ["TL"] = {
                                "Huwag mo akong saktan! Ano bang nangyayari sa'yo?!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Stop swinging at me!",
                            },
                            ["TL"] = {
                                "Huwag mo akong pagbantaan!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Back away from me!",
                            },
                            ["TL"] = {
                                "Umatras ka palayo sa akin!",
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
        ["sourceShard"] = "psdl/dialogue/combat_player_assault_reactions.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
