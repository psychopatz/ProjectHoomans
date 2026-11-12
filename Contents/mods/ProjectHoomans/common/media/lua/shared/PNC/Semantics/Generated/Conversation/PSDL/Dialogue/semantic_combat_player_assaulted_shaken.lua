-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_player_assault_reactions",
        ["id"] = "semantic.combat.player_assaulted.shaken",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.player_assaulted.shaken",
            ["sourcePath"] = "psdl/dialogue/combat_player_assault_reactions.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_player_assaulted_shaken",
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
                ["responseTemplateID"] = "semantic.combat.player_assaulted.shaken",
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
                                "What the hell?! Stay back!",
                            },
                            ["TL"] = {
                                "Ano ba?! Lumayo ka!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Why are you attacking me?! Get back!",
                            },
                            ["TL"] = {
                                "Bakit mo ako inaatake?! Lumayo ka!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Stop! What are you doing?!",
                            },
                            ["TL"] = {
                                "Tigil! Ano bang ginagawa mo?!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Don't touch me! Are you crazy?!",
                            },
                            ["TL"] = {
                                "Huwag mo akong hawakan! Nababaliw ka na ba?!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Get away from me right now!",
                            },
                            ["TL"] = {
                                "Umalis ka sa harap ko ngayon din!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Jesus, back off! Put that away!",
                            },
                            ["TL"] = {
                                "Diyos ko, atras! Ibaba mo 'yan!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Why would you hit me?! Get back!",
                            },
                            ["TL"] = {
                                "Bakit mo ako sinaktan?! Lumayo ka!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Stay away from me! Don't do this!",
                            },
                            ["TL"] = {
                                "Lumayo ka sa akin! Huwag mong gawin 'to!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Are you out of your mind?! Stop!",
                            },
                            ["TL"] = {
                                "Nawawala ka na ba sa sarili mo?! Tigil!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Back off! Don't come any closer!",
                            },
                            ["TL"] = {
                                "Atras! Huwag kang lalapit pa!",
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
