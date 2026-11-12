-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_greetings",
        ["id"] = "social.greetings.firstmeet.dawn",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "social.greetings.firstmeet.dawn",
            ["sourcePath"] = "psdl/dialogue/social_greetings.json#records[11]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/social_greetings_firstmeet_dawn",
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
                ["runtimeBlockID"] = "projecthoomans:greeting_firstmeet_dawn",
                ["textDomain"] = "pnc.psdl.social.greetings.neutral.first_meet.dawn",
                ["textTarget"] = "psdl/social/greetings/neutral/first_meet/dawn",
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
                                "Hold there. I don't know you, and dawn is a strange time for introductions.",
                            },
                            ["TL"] = {
                                "Humawak ka dyan. Hindi kita kilala, at ang bukang-liwayway ay isang kakaibang oras para sa pagpapakilala.",
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
                                "You're up before the dead settle down. Who are you?",
                            },
                            ["TL"] = {
                                "Gising ka bago pa manahimik ang mga patay. Sino ka?",
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
                                "Easy. The light is barely up, and I wasn't expecting company.",
                            },
                            ["TL"] = {
                                "Madali. Bahagyang nakapatay ang ilaw, at hindi ko inaasahan ang makakasama ko.",
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
                                "Morning, I suppose. Keep your hands where I can see them.",
                            },
                            ["TL"] = {
                                "Umaga, kumbaga. Itago ang iyong mga kamay kung saan ko sila makikita.",
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
                                "First light and a new face. Tell me what you need.",
                            },
                            ["TL"] = {
                                "Unang liwanag at bagong mukha. Sabihin mo sa akin kung ano ang kailangan mo.",
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
                    ["value"] = "FirstMeet",
                },
                {
                    ["all"] = {
                        {
                            ["op"] = "gte",
                            ["path"] = "world.time.hour",
                            ["value"] = 5,
                        },
                        {
                            ["op"] = "lt",
                            ["path"] = "world.time.hour",
                            ["value"] = 6.5,
                        },
                    },
                },
            },
        },
    },
}
