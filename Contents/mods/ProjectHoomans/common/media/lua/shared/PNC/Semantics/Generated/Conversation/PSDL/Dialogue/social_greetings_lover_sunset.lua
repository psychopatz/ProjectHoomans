-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_greetings",
        ["id"] = "social.greetings.lover.sunset",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "social.greetings.lover.sunset",
            ["sourcePath"] = "psdl/dialogue/social_greetings.json#records[18]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/social_greetings_lover_sunset",
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
                ["audience"] = "special",
                ["category"] = "projecthoomans:greetings",
                ["portraitAnimation"] = "greeting.wavehi",
                ["priority"] = 10,
                ["runtimeBlockID"] = "projecthoomans:greeting_lover_sunset",
                ["textDomain"] = "pnc.psdl.social.greetings.special.lover.sunset",
                ["textTarget"] = "psdl/social/greetings/special/lover/sunset",
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
                                "There you are. I worried when you were gone so long.",
                            },
                            ["TL"] = {
                                "Narito ka pala. Nag-alala ako nang matagal kang wala.",
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
                                "Come sit with me before the light goes.",
                            },
                            ["TL"] = {
                                "Halika maupo ka sa akin bago mamatay ang ilaw.",
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
                                "Long day. I'm glad you're here at the end of it.",
                            },
                            ["TL"] = {
                                "Mahabang araw. Natutuwa akong narito ka sa dulo nito.",
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
                                "You made it back. That's all I needed to see.",
                            },
                            ["TL"] = {
                                "Nakabalik ka. Iyon lang ang kailangan kong makita.",
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
                                "The sunset almost makes this place look peaceful.",
                            },
                            ["TL"] = {
                                "Halos nagmumukhang payapa ang lugar na ito sa dapit-hapon.",
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
                    ["value"] = "Lover",
                },
                {
                    ["all"] = {
                        {
                            ["op"] = "gte",
                            ["path"] = "world.time.hour",
                            ["value"] = 12,
                        },
                        {
                            ["op"] = "lt",
                            ["path"] = "world.time.hour",
                            ["value"] = 18,
                        },
                    },
                },
            },
        },
    },
}
