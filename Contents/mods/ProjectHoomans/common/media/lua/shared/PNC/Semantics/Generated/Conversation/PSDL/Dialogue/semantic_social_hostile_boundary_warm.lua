-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.hostile_boundary.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.hostile_boundary.warm",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[27]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_hostile_boundary_warm",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.social.hostile_boundary",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/hostile.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "Hey, where is this hostility coming from? We're allies.",
                            },
                            ["TL"] = {
                                "Huy, saan nanggagaling ang galit na 'yan? Magkakampi tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Don't snap at me like that. I've only ever helped you.",
                            },
                            ["TL"] = {
                                "Huwag mo akong sigawan nang ganyan. Tumulong lang ako sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "I care about you, but that doesn't mean you can disrespect me.",
                            },
                            ["TL"] = {
                                "Nagmamalasakit ako sa 'yo, pero di ibig sabihing pwede mo akong bastusin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Please, let's treat each other better than this.",
                            },
                            ["TL"] = {
                                "Pakiusap, magtrato tayo nang mas maayos kaysa rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "That hurt, coming from you. Let's dial it back.",
                            },
                            ["TL"] = {
                                "Masakit marinig galing sa 'yo. Bawiin mo 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "We've got enough enemies out there without turning on each other.",
                            },
                            ["TL"] = {
                                "Marami na tayong kaaway sa labas, huwag na tayong mag-away.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Take a breath. I'm not your enemy.",
                            },
                            ["TL"] = {
                                "Huminga ka muna. Hindi mo ako kalaban.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "I don't deserve that kind of anger from you.",
                            },
                            ["TL"] = {
                                "Hindi ako karapat-dapat sa ganyang galit mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Let's remember who we are to each other.",
                            },
                            ["TL"] = {
                                "Tandaan natin kung sino tayo sa isa't isa.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Don't burn this bridge over a bad temper.",
                            },
                            ["TL"] = {
                                "Huwag mong sirain ang samahan natin dahil sa init ng ulo.",
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
        ["sourceShard"] = "psdl/dialogue/social_reactions_ack_dispute.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
