-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "event_reactions_safety",
        ["id"] = "semantic.conversation.safety.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.conversation.safety.default",
            ["sourcePath"] = "psdl/dialogue/event_reactions_safety.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_conversation_safety_default",
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
                ["responseTemplateID"] = "semantic.conversation.safety.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/reactions/safety.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "WARN",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Stay alert.",
                            },
                            ["TL"] = {
                                "Manatiling alerto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your eyes peeled.",
                            },
                            ["TL"] = {
                                "Buksan ang mga mata.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Watch our surroundings.",
                            },
                            ["TL"] = {
                                "Bantayan ang paligid natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Don't let your guard down.",
                            },
                            ["TL"] = {
                                "Huwag ibaba ang depensa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Stay sharp out here.",
                            },
                            ["TL"] = {
                                "Maging handa rito sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Keep quiet and listen.",
                            },
                            ["TL"] = {
                                "Tumahimik at makinig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Keep checking the corners.",
                            },
                            ["TL"] = {
                                "Tignan palagi ang mga sulok.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Stay cautious.",
                            },
                            ["TL"] = {
                                "Mag-ingat palagi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Eyes front and back.",
                            },
                            ["TL"] = {
                                "Tumingin sa harap at likod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Stay focused.",
                            },
                            ["TL"] = {
                                "Manatiling nakapokus.",
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
        ["sourceShard"] = "psdl/dialogue/event_reactions_safety.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
