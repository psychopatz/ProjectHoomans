-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.hostile_boundary.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.hostile_boundary.neutral",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[25]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_hostile_boundary_neutral",
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
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "That tone isn't acceptable.",
                            },
                            ["TL"] = {
                                "Hindi katanggap-tanggap ang ganyang tono.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Speak to me with respect or don't speak to me at all.",
                            },
                            ["TL"] = {
                                "Kausapin mo ako nang may galang o huwag na lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "We need to keep this professional and decent.",
                            },
                            ["TL"] = {
                                "Kailangan nating panatilihing maayos at magalang ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "There's no call for hostility here.",
                            },
                            ["TL"] = {
                                "Walang dahilan para maging marahas dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I won't be spoken to that way.",
                            },
                            ["TL"] = {
                                "Hindi ako papayag na ganyanin ang pananalita sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your hostility out of this conversation.",
                            },
                            ["TL"] = {
                                "Alisin mo ang galit sa usapang ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "We have boundaries here. Respect them.",
                            },
                            ["TL"] = {
                                "May mga hangganan tayo rito. Igalang mo ang mga 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "That kind of talk isn't going to get you anywhere.",
                            },
                            ["TL"] = {
                                "Walang patutunguhan ang ganyang pananalita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Lower your voice and adjust your attitude.",
                            },
                            ["TL"] = {
                                "Hinaan mo ang boses mo at ayusin ang asal mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I expect basic decency from the people around me.",
                            },
                            ["TL"] = {
                                "Umaasa ako sa simpleng respeto mula sa mga kasama ko.",
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
