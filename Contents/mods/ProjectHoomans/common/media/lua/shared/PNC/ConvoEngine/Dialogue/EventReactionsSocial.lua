-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "event_reactions_social",
        ["exchangeFamily"] = {
            ["familyID"] = "social.reaction.default",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "I hear you.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.reaction.default.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I hear you.",
                                        "Understood.",
                                        "Got it.",
                                        "I'm listening.",
                                        "Fair enough.",
                                        "Sounds good.",
                                        "Copy that.",
                                        "Noted.",
                                        "Makes sense.",
                                        "I agree.",
                                    },
                                    ["TL"] = {
                                        "Narinig kita.",
                                        "Naiintindihan ko.",
                                        "Nakuha ko.",
                                        "Nakikinig ako.",
                                        "Makatarungan 'yan.",
                                        "Mabuti 'yan.",
                                        "Kopya.",
                                        "Tandaan ko 'yan.",
                                        "May punto ka.",
                                        "Sumasang-ayon ako.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.reaction",
            ["textRoles"] = {
                {
                    ["fallback"] = "I hear you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.reaction.default.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I hear you.",
                            "Understood.",
                            "Got it.",
                            "I'm listening.",
                            "Fair enough.",
                            "Sounds good.",
                            "Copy that.",
                            "Noted.",
                            "Makes sense.",
                            "I agree.",
                        },
                        ["TL"] = {
                            "Narinig kita.",
                            "Naiintindihan ko.",
                            "Nakuha ko.",
                            "Nakikinig ako.",
                            "Makatarungan 'yan.",
                            "Mabuti 'yan.",
                            "Kopya.",
                            "Tandaan ko 'yan.",
                            "May punto ka.",
                            "Sumasang-ayon ako.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.reaction.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "default",
            ["sourceId"] = "social.reaction.default",
            ["sourcePath"] = "adopters/hoomans/dialogue/event_reactions_social/social_reaction_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsSocial",
        ["namespace"] = "social.reaction",
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
                ["category"] = "projecthoomans:event_reactions",
                ["contentOwner"] = "projecthoomans.dialogue_content.events",
                ["responseAct"] = "REACT",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "I hear you.",
                                        "Understood.",
                                        "Got it.",
                                        "I'm listening.",
                                        "Fair enough.",
                                        "Sounds good.",
                                        "Copy that.",
                                        "Noted.",
                                        "Makes sense.",
                                        "I agree.",
                                    },
                                    ["TL"] = {
                                        "Narinig kita.",
                                        "Naiintindihan ko.",
                                        "Nakuha ko.",
                                        "Nakikinig ako.",
                                        "Makatarungan 'yan.",
                                        "Mabuti 'yan.",
                                        "Kopya.",
                                        "Tandaan ko 'yan.",
                                        "May punto ka.",
                                        "Sumasang-ayon ako.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.reaction.default",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I hear you.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.reaction.default.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/event_reactions_social/social_reaction_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I hear you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.reaction.default.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I hear you.",
                        "Understood.",
                        "Got it.",
                        "I'm listening.",
                        "Fair enough.",
                        "Sounds good.",
                        "Copy that.",
                        "Noted.",
                        "Makes sense.",
                        "I agree.",
                    },
                    ["TL"] = {
                        "Narinig kita.",
                        "Naiintindihan ko.",
                        "Nakuha ko.",
                        "Nakikinig ako.",
                        "Makatarungan 'yan.",
                        "Mabuti 'yan.",
                        "Kopya.",
                        "Tandaan ko 'yan.",
                        "May punto ka.",
                        "Sumasang-ayon ako.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
