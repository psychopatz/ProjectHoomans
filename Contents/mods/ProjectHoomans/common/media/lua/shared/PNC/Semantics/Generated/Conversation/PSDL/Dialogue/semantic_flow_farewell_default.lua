-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "event_reactions_farewell",
        ["id"] = "semantic.flow.farewell.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.flow.farewell.default",
            ["sourcePath"] = "psdl/dialogue/event_reactions_farewell.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_flow_farewell_default",
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
                ["responseTemplateID"] = "semantic.flow.farewell.default",
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
                                "Take care.",
                            },
                            ["TL"] = {
                                "Mag-ingat ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Stay safe out there.",
                            },
                            ["TL"] = {
                                "Maging ligtas ka sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Watch yourself.",
                            },
                            ["TL"] = {
                                "Ingatan mo sarili mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Until next time.",
                            },
                            ["TL"] = {
                                "Hanggang sa muli.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your guard up.",
                            },
                            ["TL"] = {
                                "Panatilihing mataas ang depensa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Stay sharp on the road.",
                            },
                            ["TL"] = {
                                "Magmatyag sa kalsada.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Catch you later.",
                            },
                            ["TL"] = {
                                "Mamaya ulit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Safe travels.",
                            },
                            ["TL"] = {
                                "Ligtas na paglalakbay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Keep breathing out there.",
                            },
                            ["TL"] = {
                                "Manatiling buhay sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "See you around.",
                            },
                            ["TL"] = {
                                "Magkita na lang tayo.",
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
