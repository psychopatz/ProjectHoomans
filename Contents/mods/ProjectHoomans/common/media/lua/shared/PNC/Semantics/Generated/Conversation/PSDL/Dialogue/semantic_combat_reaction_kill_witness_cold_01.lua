-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_kill_witness_cold",
        ["id"] = "semantic.combat.reaction.kill_witness_cold_01",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.reaction.kill_witness_cold_01",
            ["sourcePath"] = "psdl/dialogue/combat_kill_witness_cold.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_reaction_kill_witness_cold_01",
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
                ["responseTemplateID"] = "semantic.combat.reaction.kill_witness_cold_01",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/combat_kill/witness/cold.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Don't expect applause.",
                            },
                            ["TL"] = {
                                "Huwag kang umasa ng palakpak.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Basic survival. Nothing to celebrate.",
                            },
                            ["TL"] = {
                                "Pangkaraniwang kaligtasan. Walang ipagdiriwang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "You did what was expected. Move.",
                            },
                            ["TL"] = {
                                "Ginawa mo ang inaasahan. Kilos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "One kill doesn't earn a trophy.",
                            },
                            ["TL"] = {
                                "Ang isang patay ay hindi para ipagmalaki.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "A child could swing that weapon. Walk.",
                            },
                            ["TL"] = {
                                "Kahit bata kayang ihataw ang sandatang 'yan. Lakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Don't smirk. Keep walking.",
                            },
                            ["TL"] = {
                                "Huwag kang ngumisi. Magpatuloy sa paglalakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "That was the minimum requirement.",
                            },
                            ["TL"] = {
                                "Iyon ang pinakamababang kailangan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "You hit it. Congratulations on living.",
                            },
                            ["TL"] = {
                                "Tinamaan mo. Binabati kita sa pananatiling buhay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Save the pride for when we're safe.",
                            },
                            ["TL"] = {
                                "Itago ang yabang kapag ligtas na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Routine takedown. Move on.",
                            },
                            ["TL"] = {
                                "Pangkaraniwang patay. Tuloy.",
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
        ["sourceShard"] = "psdl/dialogue/combat_kill_witness_cold.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
