-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_stressed.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_stressed.warm",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[15]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_dispute_stressed_warm",
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
                ["responseTemplateID"] = "semantic.social.dispute_stressed",
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
                                "Hey, we're both frayed right now. Let's take a breath.",
                            },
                            ["TL"] = {
                                "Huy, pagod tayong pareho ngayon. Huminga muna tayo nang malalim.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "I know you're hurting and tense. I'm right here. Let's pause.",
                            },
                            ["TL"] = {
                                "Alam kong nahihirapan ka at tensiyonado. Narito lang ako. Huminto muna tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Don't let the stress tear us apart. We're partners.",
                            },
                            ["TL"] = {
                                "Huwag nating hayaang paglayuin tayo ng pagod. Magkasama tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "I hear your worry, but let's get somewhere safe first.",
                            },
                            ["TL"] = {
                                "Naririnig ko ang kaba mo, pero lumipat muna tayo sa ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "I care about what you think, just not while we're in danger.",
                            },
                            ["TL"] = {
                                "Mahalaga sa akin ang opinyon mo, pero huwag habang nasa panganib.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Let's take a second to reset. We're on the same side.",
                            },
                            ["TL"] = {
                                "Maglaan tayo ng sandali para kumalma. Magkakampi tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Breathe with me. We'll work through this disagreement later.",
                            },
                            ["TL"] = {
                                "Sumabay kang huminga sa akin. Aayusin natin ito mamaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not fighting you. Let's keep each other alive.",
                            },
                            ["TL"] = {
                                "Hindi kita kalaban. Panatilihin nating buhay ang isa't isa.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Stress is talking right now. Let's be gentle on each other.",
                            },
                            ["TL"] = {
                                "Pagod lang ang nagsasalita ngayon. Maging mahinahon tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "We'll talk this through when the dust settles, I promise.",
                            },
                            ["TL"] = {
                                "Pag-uusapan natin ito kapag humupa na ang gulo, pangako.",
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
