-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "event_reactions_safety",
        ["id"] = "semantic.conversation.safety.danger",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.conversation.safety.danger",
            ["sourcePath"] = "psdl/dialogue/event_reactions_safety.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_conversation_safety_danger",
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
                ["category"] = "projecthoomans:event_reactions",
                ["contentOwner"] = "projecthoomans.dialogue_content.events",
                ["responseTemplateID"] = "semantic.conversation.safety.danger",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/reactions/safety.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "WARN",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Watch out. We need to move now.",
                            },
                            ["TL"] = {
                                "Mag-ingat. Kailangan nating kumilos ngayon din.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Danger close! Move, move!",
                            },
                            ["TL"] = {
                                "Malapit ang panganib! Kilos, kilos!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Not safe here. Clear out now.",
                            },
                            ["TL"] = {
                                "Hindi ligtas dito. Lumikas na ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Look around! We need to leave this spot.",
                            },
                            ["TL"] = {
                                "Tumingin ka sa paligid! Kailangan nating umalis dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Infected coming! Get into cover right now.",
                            },
                            ["TL"] = {
                                "Paparating ang mga infected! Magtago na ngayon din.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Trouble's right on us. Relocate immediately.",
                            },
                            ["TL"] = {
                                "Nandito na ang gulo. Lumipat agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Heads up! We're in the open and exposed.",
                            },
                            ["TL"] = {
                                "Ulo niyo! Lantad tayo sa bukas na lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Drop what you're doing, we have to move.",
                            },
                            ["TL"] = {
                                "Bitawan ang ginagawa mo, kailangan nating tumakbo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Danger! Don't freeze up, run!",
                            },
                            ["TL"] = {
                                "Panganib! Huwag kang matulala, takbo!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Move now! We're getting cornered.",
                            },
                            ["TL"] = {
                                "Kilos na! Naiipit na tayo.",
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
        ["sourceShard"] = "psdl/dialogue/event_reactions_safety.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
