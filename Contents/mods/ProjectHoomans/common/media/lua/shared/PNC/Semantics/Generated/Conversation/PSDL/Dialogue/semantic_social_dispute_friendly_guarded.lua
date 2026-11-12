-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_friendly.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_friendly.guarded",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[8]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_dispute_friendly_guarded",
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
                ["responseTemplateID"] = "semantic.social.dispute_friendly",
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
                                "I disagree. Leave it there.",
                            },
                            ["TL"] = {
                                "Hindi ako sang-ayon. Tama na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "I see it differently. Don't push it.",
                            },
                            ["TL"] = {
                                "Iba ang tingin ko. Huwag mo nang ipilit.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "We don't agree on this. Drop it.",
                            },
                            ["TL"] = {
                                "Hindi tayo nagtutugma rito. Iwan mo na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Not buying that. Let's move on.",
                            },
                            ["TL"] = {
                                "Hindi ako kumbinsido. Lumipat na tayo ng usapan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not on board with that idea.",
                            },
                            ["TL"] = {
                                "Hindi ako sang-ayon sa kaisipang 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "I disagree, and I'm not budging.",
                            },
                            ["TL"] = {
                                "Hindi ako sang-ayon, at hindi ako uusad.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "That won't work for me. End of story.",
                            },
                            ["TL"] = {
                                "Hindi uubra sa akin 'yan. Diyan nagtatapos 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "You have your view, I have mine. Back off.",
                            },
                            ["TL"] = {
                                "May pananaw ka, mayroon din ako. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "I dispute that. We leave it alone.",
                            },
                            ["TL"] = {
                                "Pinasisinungalingan ko 'yan. Hayaan na natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "No. I don't see it that way at all.",
                            },
                            ["TL"] = {
                                "Hindi. Hindi ko talaga tinitingnan nang ganyan.",
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
