-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_player_assault_reactions",
        ["id"] = "semantic.combat.player_assaulted.brave",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.player_assaulted.brave",
            ["sourcePath"] = "psdl/dialogue/combat_player_assault_reactions.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_player_assaulted_brave",
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
                ["responseTemplateID"] = "semantic.combat.player_assaulted.brave",
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
                                "That's it. You're done.",
                            },
                            ["TL"] = {
                                "Tama na. Tapos ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Bad choice. Defend yourself.",
                            },
                            ["TL"] = {
                                "Maling desisyon. Ipagtanggol mo ang sarili mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "You shouldn't have done that.",
                            },
                            ["TL"] = {
                                "Hindi mo dapat ginawa 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I gave you space. Now defend yourself.",
                            },
                            ["TL"] = {
                                "Binigyan kita ng puwang. Ipagtanggol mo sarili mo ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "That's where this ends.",
                            },
                            ["TL"] = {
                                "Diyan na nagtatapos 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "You made your choice.",
                            },
                            ["TL"] = {
                                "Pumili ka na ng kahihinatnan mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I won't let you hurt me. Stand down or fight.",
                            },
                            ["TL"] = {
                                "Hindi kita hahayaang saktan ako. Sumuko ka o lumaban.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Unacceptable. Drop your weapon.",
                            },
                            ["TL"] = {
                                "Hindi katanggap-tanggap. Ibaba mo ang sandata mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "You crossed the line.",
                            },
                            ["TL"] = {
                                "Lumagpas ka sa linya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Stand down right now, or I finish this.",
                            },
                            ["TL"] = {
                                "Tumigil ka ngayon din, o tatapusin ko 'to.",
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
