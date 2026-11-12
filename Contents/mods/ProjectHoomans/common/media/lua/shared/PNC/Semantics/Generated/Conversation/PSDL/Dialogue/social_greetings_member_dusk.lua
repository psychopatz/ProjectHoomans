-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_greetings",
        ["id"] = "social.greetings.member.dusk",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "social.greetings.member.dusk",
            ["sourcePath"] = "psdl/dialogue/social_greetings.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/social_greetings_member_dusk",
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
                ["audience"] = "member",
                ["category"] = "projecthoomans:greetings",
                ["portraitAnimation"] = "greeting.wavehi",
                ["priority"] = 10,
                ["runtimeBlockID"] = "projecthoomans:greeting_member_dusk",
                ["textDomain"] = "pnc.psdl.social.greetings.member.dusk",
                ["textTarget"] = "psdl/social/greetings/member/dusk",
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
                                "Evening. Perimeter looks clear.",
                            },
                            ["TL"] = {
                                "Gabi. Mukhang malinaw ang perimeter.",
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
                                "Need me for something before night watch?",
                            },
                            ["TL"] = {
                                "Kailangan mo ba ako bago ang pagbabantay sa gabi?",
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
                                "We're all still here. I'll call that a good day.",
                            },
                            ["TL"] = {
                                "Narito pa rin tayong lahat. Ituturing ko iyong magandang araw.",
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
                                "Keep it quiet. The others are settling down.",
                            },
                            ["TL"] = {
                                "Manahimik ka. Umayos na yung iba.",
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
                                "I can take first watch if you need the rest.",
                            },
                            ["TL"] = {
                                "Maaari akong kumuha ng unang panonood kung kailangan mo ang iba pa.",
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
                    ["value"] = "Member",
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
