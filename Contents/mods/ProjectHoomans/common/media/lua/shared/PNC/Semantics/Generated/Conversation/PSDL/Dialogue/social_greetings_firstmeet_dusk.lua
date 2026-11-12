-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_greetings",
        ["id"] = "social.greetings.firstmeet.dusk",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "social.greetings.firstmeet.dusk",
            ["sourcePath"] = "psdl/dialogue/social_greetings.json#records[14]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/social_greetings_firstmeet_dusk",
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
                ["runtimeBlockID"] = "projecthoomans:greeting_firstmeet_dusk",
                ["textDomain"] = "pnc.psdl.social.greetings.neutral.first_meet.dusk",
                ["textTarget"] = "psdl/social/greetings/neutral/first_meet/dusk",
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
                                "Stop there. Dusk makes strangers hard to read.",
                            },
                            ["TL"] = {
                                "Tumigil ka dyan. Dahil sa takipsilim, mahirap basahin ang mga estranghero.",
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
                                "Not much light left. Introduce yourself.",
                            },
                            ["TL"] = {
                                "Wala nang gaanong ilaw. Magpakilala ka.",
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
                                "You surprised me. What do you want?",
                            },
                            ["TL"] = {
                                "Nagulat mo ako. Ano ang kailangan mo?",
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
                                "Keep your voice down and tell me why you're here.",
                            },
                            ["TL"] = {
                                "Hinaan mo ang boses mo at sabihin sa akin kung bakit ka nandito.",
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
                                "I can't make out your face. Come no closer.",
                            },
                            ["TL"] = {
                                "Hindi ko maaninag ang mukha mo. Huwag kang lalapit.",
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
                            ["value"] = 18,
                        },
                        {
                            ["op"] = "lt",
                            ["path"] = "world.time.hour",
                            ["value"] = 21,
                        },
                    },
                },
            },
        },
    },
}
