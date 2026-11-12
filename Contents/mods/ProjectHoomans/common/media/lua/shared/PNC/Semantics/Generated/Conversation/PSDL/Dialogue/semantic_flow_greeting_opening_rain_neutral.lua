-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_greeting",
        ["id"] = "semantic.flow.greeting.opening.rain.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.flow.greeting.opening.rain.neutral",
            ["sourcePath"] = "psdl/dialogue/conversation_greeting.json#records[12]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_flow_greeting_opening_rain_neutral",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.flow.greeting.opening.rain",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/greeting.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Hey there. Wet one today.",
                            },
                            ["TL"] = {
                                "Uy, maulan ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Rain's not letting up anytime soon.",
                            },
                            ["TL"] = {
                                "Mukhang hindi titigil ang ulan agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Keep dry if you can out there.",
                            },
                            ["TL"] = {
                                "Magpatuyo ka kung kaya mo sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Miserable weather, but we're still kicking.",
                            },
                            ["TL"] = {
                                "Masamang panahon, pero buhay pa rin tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Ground's completely soaked out there.",
                            },
                            ["TL"] = {
                                "Babad na babad ang lupa sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Cold rain like this makes everything harder.",
                            },
                            ["TL"] = {
                                "Ang malamig na ulan na ito ang nagpapahirap sa lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Watch your footing in this mud.",
                            },
                            ["TL"] = {
                                "Mag-ingat sa paghakbang sa putikan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Rain makes it hard to hear them coming. Stay alert.",
                            },
                            ["TL"] = {
                                "Mahirap silang marinig dahil sa ulan. Maging alerto ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Good day to stay under a solid roof if you've got one.",
                            },
                            ["TL"] = {
                                "Magandang araw para sumilong sa maayos na bubong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "At least the rain washes away the tracks. Stay dry.",
                            },
                            ["TL"] = {
                                "Kahit papaano nabubura ng ulan ang mga bakas. Manatiling tuyo.",
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
        ["sourceShard"] = "psdl/dialogue/conversation_greeting.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
