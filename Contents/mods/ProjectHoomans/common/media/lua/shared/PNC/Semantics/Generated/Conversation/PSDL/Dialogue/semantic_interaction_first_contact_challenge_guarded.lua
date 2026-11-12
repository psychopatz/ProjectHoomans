-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_first_contact",
        ["id"] = "semantic.interaction.first_contact.challenge.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.first_contact.challenge.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_first_contact.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_first_contact_challenge_guarded",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "That's close enough. What do you want?",
                            },
                            ["TL"] = {
                                "Hanggang diyan ka lang. Ano ang gusto mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Hands where I can see them. Who are you?",
                            },
                            ["TL"] = {
                                "Kamay kung saan ko nakikita. Sino ka?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Stop right there. State your business.",
                            },
                            ["TL"] = {
                                "Tigil diyan. Sabihin mo ang pakay mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your distance. What brings you over here?",
                            },
                            ["TL"] = {
                                "Panatilihin ang distansya. Anong nagdala sa 'yo rito?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Don't take another step. Who sent you?",
                            },
                            ["TL"] = {
                                "Huwag ka nang humakbang pa. Sinong nagpadala sa 'yo?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Hold it. Are you armed?",
                            },
                            ["TL"] = {
                                "Sandali. May armas ka ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Stay where you are. Why are you approaching me?",
                            },
                            ["TL"] = {
                                "Diyan ka lang. Bakit ka lumalapit sa akin?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Hold ground. What are you after?",
                            },
                            ["TL"] = {
                                "Diyan ka lang. Anong hinahabol mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your hands clear of your waist. Who are you?",
                            },
                            ["TL"] = {
                                "Ilayo ang kamay sa baywang. Sino ka?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "One wrong twitch and we have a problem. Speak up.",
                            },
                            ["TL"] = {
                                "Isang maling galaw at magkakaproblema tayo. Magsalita ka.",
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
