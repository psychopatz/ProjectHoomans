-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_hostile_offer_threat",
        ["id"] = "semantic.social.hostile_withdrawn.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.hostile_withdrawn.neutral",
            ["sourcePath"] = "psdl/dialogue/social_reactions_hostile_offer_threat.json#records[9]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_hostile_withdrawn_neutral",
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
                ["responseTemplateID"] = "semantic.social.hostile_withdrawn",
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
                                "Please leave me alone.",
                            },
                            ["TL"] = {
                                "Pakiusap iwan mo akong mag-isa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I need to be on my own right now.",
                            },
                            ["TL"] = {
                                "Kailangan kong mapag-isa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'm asking for privacy. Please respect it.",
                            },
                            ["TL"] = {
                                "Hinihiling ko ang katahimikan. Pakiusap igalang mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Go on. I'll be fine by myself.",
                            },
                            ["TL"] = {
                                "Sige na. Ayos lang ako nang mag-isa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Let's not interact for the rest of today.",
                            },
                            ["TL"] = {
                                "Huwag muna tayong mag-usap sa buong araw na ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'd prefer not to speak to anyone right now.",
                            },
                            ["TL"] = {
                                "Mas gusto kong walang makausap ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Please walk away.",
                            },
                            ["TL"] = {
                                "Pakiusap lumayo ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Give me time to myself.",
                            },
                            ["TL"] = {
                                "Bigyan mo ako ng oras para sa sarili ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I need some quiet. Leave me be.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng katahimikan. Hayaan mo ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "We're done talking for now.",
                            },
                            ["TL"] = {
                                "Tapos na tayong mag-usap sa ngayon.",
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
        ["sourceShard"] = "psdl/dialogue/social_reactions_hostile_offer_threat.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
