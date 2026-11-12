-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_friendly.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_friendly.warm",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[11]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_dispute_friendly_warm",
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
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "I disagree, friend, but I respect your perspective.",
                            },
                            ["TL"] = {
                                "Hindi ako sang-ayon, kaibigan, pero iginagalang ko ang opinyon mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "We don't see eye to eye on this, but we're still good.",
                            },
                            ["TL"] = {
                                "Hindi tayo pareho ng paningin dito, pero maayos pa rin tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "I see where you're coming from, but I look at it differently.",
                            },
                            ["TL"] = {
                                "Nauunawaan ko ang pinanggagalingan mo, pero iba ang tingin ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "No hard feelings, but I'd handle it another way.",
                            },
                            ["TL"] = {
                                "Walang samaan ng loob, pero iba ang gagawin kong paraan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "I value your thoughts, even when we don't agree.",
                            },
                            ["TL"] = {
                                "Pinahahalagahan ko ang isip mo, kahit di tayo magkasundo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "We're allowed to differ. We still have each other's backs.",
                            },
                            ["TL"] = {
                                "Pwede tayong magkaiba. Hawak pa rin natin ang likod ng bawat isa.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "I don't agree with the plan, but I trust you as a comrade.",
                            },
                            ["TL"] = {
                                "Di ako sang-ayon sa plano, pero may tiwala ako sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Let's talk through it without getting worked up.",
                            },
                            ["TL"] = {
                                "Pag-usapan natin ito nang hindi nagkakainitan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "I disagree, but I'm glad you felt comfortable saying it.",
                            },
                            ["TL"] = {
                                "Hindi ako sang-ayon, pero mabuti't malaya mong nasabi.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "We can disagree and still keep each other alive.",
                            },
                            ["TL"] = {
                                "Pwede tayong magkaiba at manatili pa ring buhay magkasama.",
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
