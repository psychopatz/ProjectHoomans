-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_withdrawn.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_withdrawn.warm",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[23]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_dispute_withdrawn_warm",
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
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "Let's leave it there for now, friend. We're still good.",
                            },
                            ["TL"] = {
                                "Tama na muna iyon, kaibigan. Maayos pa rin tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "I don't want this to come between us. Let's rest on it.",
                            },
                            ["TL"] = {
                                "Ayokong masira tayo dahil dito. Ipahinga na muna natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "We've said what we needed to say. All love here.",
                            },
                            ["TL"] = {
                                "Nasabi na natin ang kailangan. Maayos ang kalooban dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Let's pause this. You're more important to me than this argument.",
                            },
                            ["TL"] = {
                                "Tigil muna. Mas mahalaga ka sa akin kaysa sa pagtatalong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "All good. Let's go grab a drink and clear our heads.",
                            },
                            ["TL"] = {
                                "Ayos lang. Uminom muna tayo para mahimasmasan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "I hear you, and I respect you. Let's let the dust settle.",
                            },
                            ["TL"] = {
                                "Narinig kita, at iginagalang kita. Hayaang lumipas ang alikabok.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "We don't need to fight. We're on the same team.",
                            },
                            ["TL"] = {
                                "Di natin kailangang mag-away. Nasa iisang koponan tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "It's all right. We can let this one slide.",
                            },
                            ["TL"] = {
                                "Ayos lang. Pwede nating palampasin ang isang 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "I value our partnership too much to push this.",
                            },
                            ["TL"] = {
                                "Masyadong mahalaga ang samahan natin para ipagpilitan ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "We'll be okay. Let's take a breather.",
                            },
                            ["TL"] = {
                                "Magiging maayos tayo. Huminga muna tayo nang malalim.",
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
