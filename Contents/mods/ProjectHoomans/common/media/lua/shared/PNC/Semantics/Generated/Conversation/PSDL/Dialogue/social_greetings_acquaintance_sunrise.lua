-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_greetings",
        ["id"] = "social.greetings.acquaintance.sunrise",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "social.greetings.acquaintance.sunrise",
            ["sourcePath"] = "psdl/dialogue/social_greetings.json#records[7]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/social_greetings_acquaintance_sunrise",
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
                ["audience"] = "neutral",
                ["category"] = "projecthoomans:greetings",
                ["portraitAnimation"] = "greeting.wavehi",
                ["priority"] = 10,
                ["runtimeBlockID"] = "projecthoomans:greeting_acquaintance_sunrise",
                ["textDomain"] = "pnc.psdl.social.greetings.neutral.acquaintance.sunrise",
                ["textTarget"] = "psdl/social/greetings/neutral/acquaintance/sunrise",
                ["weight"] = 100,
            },
            ["response"] = {
                ["act"] = "GREETING",
                ["variants"] = {
                    {
                        ["id"] = "greeting.001",
                        ["metadata"] = {
                            ["textKey"] = "greeting.001",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Morning. Good to see a familiar face.",
                            },
                            ["TL"] = {
                                "Umaga. Ang sarap makakita ng pamilyar na mukha.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.002",
                        ["metadata"] = {
                            ["textKey"] = "greeting.002",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hey. How's the day treating you?",
                            },
                            ["TL"] = {
                                "Hey. Kumusta ang pagtrato sa iyo ng araw?",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.003",
                        ["metadata"] = {
                            ["textKey"] = "greeting.003",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "There you are. Need a minute?",
                            },
                            ["TL"] = {
                                "Narito ka pala. Kailangan mo ba ng sandali?",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.004",
                        ["metadata"] = {
                            ["textKey"] = "greeting.004",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Morning. You look like you have something on your mind.",
                            },
                            ["TL"] = {
                                "Umaga. Parang may iniisip ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.005",
                        ["metadata"] = {
                            ["textKey"] = "greeting.005",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Nice to see you made it through another night.",
                            },
                            ["TL"] = {
                                "Natutuwa akong makita kang nagtagumpay sa isa pang gabi.",
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
        ["sourceShard"] = "psdl/dialogue/social_greetings.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["all"] = {
                {
                    ["op"] = "eq",
                    ["path"] = "relationship.speakerToAddressee.state",
                    ["value"] = "Acquaintance",
                },
                {
                    ["all"] = {
                        {
                            ["op"] = "gte",
                            ["path"] = "world.time.hour",
                            ["value"] = 6.5,
                        },
                        {
                            ["op"] = "lt",
                            ["path"] = "world.time.hour",
                            ["value"] = 12,
                        },
                    },
                },
            },
        },
    },
}
