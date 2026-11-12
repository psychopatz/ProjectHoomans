-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_trusted.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_trusted.guarded",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[16]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_dispute_trusted_guarded",
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
                ["responseTemplateID"] = "semantic.social.dispute_trusted",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/disputes.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "I still don't agree. Leave it there.",
                            },
                            ["TL"] = {
                                "Hindi pa rin ako sang-ayon. Tama na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Even between us, I draw the line here.",
                            },
                            ["TL"] = {
                                "Kahit sa ating dalawa, may hangganan ako rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "I trust you, but I won't back this decision.",
                            },
                            ["TL"] = {
                                "Tiwala ako sa 'yo, pero di ko susuportahan ang desisyong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "We've been through a lot, but I disagree on this.",
                            },
                            ["TL"] = {
                                "Marami na tayong pinagdaanan, pero di ako sang-ayon dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Don't lean on our history to push a bad idea.",
                            },
                            ["TL"] = {
                                "Huwag mong gamitin ang samahan natin para ipilit ang maling plano.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "I trust your survival skills, not this specific take.",
                            },
                            ["TL"] = {
                                "Tiwala ako sa galing mo, pero hindi sa opinyong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Stand down on this. I won't follow blindly.",
                            },
                            ["TL"] = {
                                "Bumitiw ka rito. Hindi ako susunod nang pikit-mata.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Trust goes both ways. Hear my disagreement.",
                            },
                            ["TL"] = {
                                "May dalawang panig ang tiwala. Pakinggan mo ang pagtutol ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "I won't let friendship blind me to a bad risk.",
                            },
                            ["TL"] = {
                                "Hindi ko hahayaang bulagin ng samahan ang maling sugal.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "We're close, but on this, you're dead wrong.",
                            },
                            ["TL"] = {
                                "Malapit tayo, pero rito, maling-mali ka.",
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
