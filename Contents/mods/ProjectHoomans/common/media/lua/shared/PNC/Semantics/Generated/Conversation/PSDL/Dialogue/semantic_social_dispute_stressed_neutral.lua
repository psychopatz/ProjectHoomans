-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_stressed.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_stressed.neutral",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[13]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_dispute_stressed_neutral",
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
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Tensions are high. Let's table this for later.",
                            },
                            ["TL"] = {
                                "Mataas ang tensiyon. Ipagpaliban muna natin mamaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "We're both stressed. Let's not make bad calls right now.",
                            },
                            ["TL"] = {
                                "Pareho tayong pagod. Huwag tayong gumawa ng maling desisyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Now isn't the moment to hash this out.",
                            },
                            ["TL"] = {
                                "Hindi ngayon ang oras para pagtalunan ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Let's catch our breath before we argue further.",
                            },
                            ["TL"] = {
                                "Huminga muna tayo bago magpatuloy sa pagtatalo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "We need clear heads right now, not arguments.",
                            },
                            ["TL"] = {
                                "Kailangan natin ng malinaw na isip, hindi bangayan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I understand you're upset, but we need to survive first.",
                            },
                            ["TL"] = {
                                "Naiintindihan kong galit ka, pero kaligtasan muna.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Let's put a pin in this until we're safe.",
                            },
                            ["TL"] = {
                                "Iwan muna natin ito hanggang sa maging ligtas tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Arguing right now only helps the dead.",
                            },
                            ["TL"] = {
                                "Ang pagtatalo ngayon ay pabor lang sa mga patay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I hear the frustration. Let's focus on the threat.",
                            },
                            ["TL"] = {
                                "Naririnig ko ang inis mo. Magpokus tayo sa banta.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "We can settle this once we're behind walls.",
                            },
                            ["TL"] = {
                                "Maaayos natin ito kapag nasa loob na tayo ng pader.",
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
