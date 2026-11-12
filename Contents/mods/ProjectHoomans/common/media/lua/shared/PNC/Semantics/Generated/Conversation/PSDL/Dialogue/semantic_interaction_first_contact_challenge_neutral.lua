-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_first_contact",
        ["id"] = "semantic.interaction.first_contact.challenge.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.first_contact.challenge.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_first_contact.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_first_contact_challenge_neutral",
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
                ["responseTemplateID"] = "semantic.interaction.first_contact.challenge",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/first_contact/challenge.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Hold it. Who are you?",
                            },
                            ["TL"] = {
                                "Sandali. Sino ka?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Hold up a second. What's your name?",
                            },
                            ["TL"] = {
                                "Teka sandali. Anong pangalan mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Who goes there? Speak up.",
                            },
                            ["TL"] = {
                                "Sino 'yan? Magsalita ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Stop there for a moment. Are you friendly?",
                            },
                            ["TL"] = {
                                "Tigil muna diyan. Kaibigan ka ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Hold on. What brings you to this area?",
                            },
                            ["TL"] = {
                                "Teka muna. Anong ginagawa mo sa lugar na 'to?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "State who you are and what you're doing here.",
                            },
                            ["TL"] = {
                                "Sabihin kung sino ka at anong ginagawa mo rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Hold it right there. Let's talk before you come closer.",
                            },
                            ["TL"] = {
                                "Diyan ka muna. Mag-usap tayo bago ka lumapit pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Who are you and who are you with?",
                            },
                            ["TL"] = {
                                "Sino ka at sinong kasama mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Stop there. Just want to make sure you're not a threat.",
                            },
                            ["TL"] = {
                                "Tigil diyan. Nais ko lang tiyakin na di ka banta.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Hold up. Give me a name and a reason you're here.",
                            },
                            ["TL"] = {
                                "Teka lang. Bigyan mo ako ng pangalan at dahilan kung bakit ka narito.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_first_contact.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
