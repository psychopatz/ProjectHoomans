-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "event_reactions_farewell",
        ["id"] = "semantic.flow.farewell.friendly",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.flow.farewell.friendly",
            ["sourcePath"] = "psdl/dialogue/event_reactions_farewell.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_flow_farewell_friendly",
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
                ["responseTemplateID"] = "semantic.flow.farewell.friendly",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/reactions/farewell.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "FAREWELL",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Take care. I will see you soon.",
                            },
                            ["TL"] = {
                                "Mag-ingat ka. Magkikita tayo sa lalong madaling panahon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Stay safe, my friend. Come back in one piece.",
                            },
                            ["TL"] = {
                                "Mag-ingat ka, kaibigan. Bumalik kang buo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Look after yourself. Don't be a stranger.",
                            },
                            ["TL"] = {
                                "Alagaan mo sarili mo. Huwag kang mawawala.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Good luck out there. See you soon.",
                            },
                            ["TL"] = {
                                "Magandang kapalaran sa labas. Hanggang sa muli.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your head down and stay safe. Talk soon.",
                            },
                            ["TL"] = {
                                "Yumuko sa panganib at mag-ingat. Usap tayo ulit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "It was good seeing you. Safe travels.",
                            },
                            ["TL"] = {
                                "Mabuti at nagkita tayo. Ligtas na paglalakbay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Take care of yourself. I'll be waiting.",
                            },
                            ["TL"] = {
                                "Alagaan mo sarili mo. Hihintayin kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Watch your back out there, friend.",
                            },
                            ["TL"] = {
                                "Bantayan ang likod mo sa labas, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Stay alive. We'll share a drink next time.",
                            },
                            ["TL"] = {
                                "Manatiling buhay. Mag-inuman tayo sa susunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Be careful out there. See you shortly.",
                            },
                            ["TL"] = {
                                "Mag-ingat ka sa labas. Magkikita tayo sa lalong madaling panahon.",
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
        ["sourceShard"] = "psdl/dialogue/event_reactions_farewell.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
