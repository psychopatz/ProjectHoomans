-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_greetings",
        ["id"] = "social.greetings.firstmeet.twilight",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "social.greetings.firstmeet.twilight",
            ["sourcePath"] = "psdl/dialogue/social_greetings.json#records[15]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/social_greetings_firstmeet_twilight",
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
                ["runtimeBlockID"] = "projecthoomans:greeting_firstmeet_twilight",
                ["textDomain"] = "pnc.psdl.social.greetings.neutral.first_meet.twilight",
                ["textTarget"] = "psdl/social/greetings/neutral/first_meet/twilight",
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
                                "It's dark out. Stay where I can see you.",
                            },
                            ["TL"] = {
                                "Madilim sa labas. Manatili ka kung saan kita makikita.",
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
                                "A stranger walking up at night usually means trouble.",
                            },
                            ["TL"] = {
                                "Ang isang estranghero na naglalakad sa gabi ay karaniwang nangangahulugan ng problema.",
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
                                "Keep your voice low. Who are you?",
                            },
                            ["TL"] = {
                                "Panatilihing mahina ang iyong boses. sino ka ba",
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
                                "You chose a bad time to sneak up on someone.",
                            },
                            ["TL"] = {
                                "You chose a bad time to sneak up buhay someone.",
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
                                "Don't move any closer. We can talk from there.",
                            },
                            ["TL"] = {
                                "Huwag kang lalapit. Maaari tayong mag-usap mula doon.",
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
                    ["any"] = {
                        {
                            ["op"] = "gte",
                            ["path"] = "world.time.hour",
                            ["value"] = 21,
                        },
                        {
                            ["op"] = "lt",
                            ["path"] = "world.time.hour",
                            ["value"] = 5,
                        },
                    },
                },
            },
        },
    },
}
