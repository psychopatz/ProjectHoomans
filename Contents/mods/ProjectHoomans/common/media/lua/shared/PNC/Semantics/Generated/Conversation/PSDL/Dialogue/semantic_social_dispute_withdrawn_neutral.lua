-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_withdrawn.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_withdrawn.neutral",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[21]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_dispute_withdrawn_neutral",
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
                ["responseTemplateID"] = "semantic.social.dispute_withdrawn",
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
                                "All right. Let's step back from this.",
                            },
                            ["TL"] = {
                                "Sige. Umatras muna tayo sa usapang ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "We're not getting anywhere. Let's move on.",
                            },
                            ["TL"] = {
                                "Wala tayong mararating. Magpatuloy na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I think we've said enough on the matter.",
                            },
                            ["TL"] = {
                                "Sa tingin ko sapat na ang nasabi natin sa usapin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Let's take a break from this topic.",
                            },
                            ["TL"] = {
                                "Magpahinga muna tayo sa paksang ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Fair enough. Let's focus on other priorities.",
                            },
                            ["TL"] = {
                                "Makatwiran. Magpokus na lang tayo sa ibang gawain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "No point spinning our wheels. Let's work.",
                            },
                            ["TL"] = {
                                "Walang silbing magpaulit-ulit. Magtrabaho na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. We'll leave it at that.",
                            },
                            ["TL"] = {
                                "Naintindihan. Diyan na muna natin iiwan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Agreed. Moving past it now.",
                            },
                            ["TL"] = {
                                "Sang-ayon. Lumilipas na tayo roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "We can revisit this when things settle down.",
                            },
                            ["TL"] = {
                                "Mababalikan natin ito kapag maayos na ang lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "All right. Let's put our energy elsewhere.",
                            },
                            ["TL"] = {
                                "Sige. Dalhin na lang natin ang lakas sa iba.",
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
