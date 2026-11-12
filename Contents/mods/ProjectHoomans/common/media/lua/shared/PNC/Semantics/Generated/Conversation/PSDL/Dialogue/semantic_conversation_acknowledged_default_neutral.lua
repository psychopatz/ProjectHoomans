-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.conversation.acknowledged.default.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.conversation.acknowledged.default.neutral",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_conversation_acknowledged_default_neutral",
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
                ["responseTemplateID"] = "semantic.conversation.acknowledged.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/emotes_conversation.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "All right. Ask if you want to talk more.",
                            },
                            ["TL"] = {
                                "Sige. Magtanong ka kung gusto mo pang mag-usap.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Let me know if you need anything else.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Sabihan mo ako kung may kailangan ka pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Sounds good. We can pick this up later.",
                            },
                            ["TL"] = {
                                "Mabuti. Pwede nating ipagpatuloy ito mamaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Got it. Let's get back to what we were doing.",
                            },
                            ["TL"] = {
                                "Nakuha ko. Balik na tayo sa ginagawa natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Fair enough. Holler if something comes up.",
                            },
                            ["TL"] = {
                                "Makatwiran. Tawagin mo ako kapag may nangyari.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "All right. We're on the same page.",
                            },
                            ["TL"] = {
                                "Sige. Pareho tayo ng iniisip.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Take care.",
                            },
                            ["TL"] = {
                                "Naintindihan. Mag-ingat ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Clear. We'll talk again soon.",
                            },
                            ["TL"] = {
                                "Malinaw. Mag-uusap tayong muli mamaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Got it. I'm around if you need to talk.",
                            },
                            ["TL"] = {
                                "Nakuha ko. Narito lang ako kung kailangan mong makipag-usap.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Right. We'll leave it there for now.",
                            },
                            ["TL"] = {
                                "Sige. Dito muna tayo magtapos sa ngayon.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
