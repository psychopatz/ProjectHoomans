-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_withdrawn.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_withdrawn.guarded",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[20]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_dispute_withdrawn_guarded",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Let's leave it there.",
                            },
                            ["TL"] = {
                                "Tama na iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not arguing with you anymore.",
                            },
                            ["TL"] = {
                                "Hindi na ako makikipagtalo sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Done talking about this.",
                            },
                            ["TL"] = {
                                "Tapos na akong pag-usapan ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Subject is closed. Back off.",
                            },
                            ["TL"] = {
                                "Sarado na ang paksa. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "I've said my piece. Leave it alone.",
                            },
                            ["TL"] = {
                                "Nasabi ko na ang parte ko. Hayaan mo na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Drop it before I get angry.",
                            },
                            ["TL"] = {
                                "Itigil mo 'yan bago pa ako magalit.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Nothing more to say.",
                            },
                            ["TL"] = {
                                "Wala nang dapat sabihin pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "We're done here.",
                            },
                            ["TL"] = {
                                "Tapos na tayo rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Walk away.",
                            },
                            ["TL"] = {
                                "Umalis ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "I'm finished with this conversation.",
                            },
                            ["TL"] = {
                                "Tapos na ako sa usapang ito.",
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
