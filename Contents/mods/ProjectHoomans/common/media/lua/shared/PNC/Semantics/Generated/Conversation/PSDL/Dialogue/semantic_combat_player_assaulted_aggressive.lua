-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_player_assault_reactions",
        ["id"] = "semantic.combat.player_assaulted.aggressive",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.player_assaulted.aggressive",
            ["sourcePath"] = "psdl/dialogue/combat_player_assault_reactions.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_player_assaulted_aggressive",
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
                ["responseTemplateID"] = "semantic.combat.player_assaulted.aggressive",
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
                                "You just made a big mistake.",
                            },
                            ["TL"] = {
                                "Malaking pagkakamali ang ginawa mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "All right. You want a fight, you've got one.",
                            },
                            ["TL"] = {
                                "Sige. Gusto mo ng laban, makukuha mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "You hit me? You're going to regret that.",
                            },
                            ["TL"] = {
                                "Sinaktan mo ako? Pagsisisihan mo 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Try that again and see what happens.",
                            },
                            ["TL"] = {
                                "Ulitin mo pa at tignan natin ang mangyayari.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Wrong person to mess with.",
                            },
                            ["TL"] = {
                                "Maling tao ang binangga mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "You want some of this?! Come on then!",
                            },
                            ["TL"] = {
                                "Gusto mo pala ng gulo?! Halika rito!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "That was your last free shot.",
                            },
                            ["TL"] = {
                                "Huling libreng tira mo na 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'll put you in the ground for that.",
                            },
                            ["TL"] = {
                                "Ililibing kita sa ginawa mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "You swung at me? Big mistake.",
                            },
                            ["TL"] = {
                                "Hinataw mo ako? Malaking mali.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "You really want to do this? Let's go.",
                            },
                            ["TL"] = {
                                "Gusto mo talagang gawin 'to? Tara.",
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
