-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "event_reactions_companion",
        ["id"] = "semantic.companion.reaction.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.companion.reaction.default",
            ["sourcePath"] = "psdl/dialogue/event_reactions_companion.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_companion_reaction_default",
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
                ["responseTemplateID"] = "semantic.companion.reaction.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/reactions/companion.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "ACK",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I heard you. We will handle it together.",
                            },
                            ["TL"] = {
                                "Narinig kita. Sabay natin 'yang haharapin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. I'm right here with you.",
                            },
                            ["TL"] = {
                                "Naintindihan ko. Nandito lang ako kasama mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Got your message. Let's get it done.",
                            },
                            ["TL"] = {
                                "Nakuha ko ang sabi mo. Tapusin na natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'm with you. Lead the way.",
                            },
                            ["TL"] = {
                                "Kasama mo ako. Ikaw ang manguna.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Heard. Whatever comes, we take it on.",
                            },
                            ["TL"] = {
                                "Narinig ko. Kahit ano'ng dumating, lalabanan natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Copy that. Staying right by your side.",
                            },
                            ["TL"] = {
                                "Kopya. Dito lang ako sa tabi mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I hear you loud and clear. Let's move.",
                            },
                            ["TL"] = {
                                "Malinaw kong narinig. Kilos na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Count on me. We're in this together.",
                            },
                            ["TL"] = {
                                "Maaasahan mo ako. Magkasama tayo rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Let's keep our heads clear.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Panatilihing malinaw ang isip natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Right behind you. Let's handle this.",
                            },
                            ["TL"] = {
                                "Nasa likod mo lang ako. Asikasuhin natin 'to.",
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
        ["sourceShard"] = "psdl/dialogue/event_reactions_companion.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
