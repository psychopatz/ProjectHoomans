-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.conversation.acknowledged.default.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.conversation.acknowledged.default.guarded",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_conversation_acknowledged_default_guarded",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. We'll leave it there.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Tama na iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Heard. That's enough talk for now.",
                            },
                            ["TL"] = {
                                "Narinig ko. Sapat na ang usapan sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Message received. Keep your distance.",
                            },
                            ["TL"] = {
                                "Nakuha ko. Manatili ka sa puwesto mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Got it. Let's keep our heads on our shoulders.",
                            },
                            ["TL"] = {
                                "Naintindihan. Mag-ingat na lang tayo sa paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "I heard what you said. Leaving it at that.",
                            },
                            ["TL"] = {
                                "Narinig ko ang sinabi mo. Iiwan ko na roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "All right. Eyes open.",
                            },
                            ["TL"] = {
                                "Sige. Buksan ang mga mata.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "I take your point. Let's stay alert.",
                            },
                            ["TL"] = {
                                "Nakuha ko ang punto mo. Manatiling alisto.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Clear enough. No more discussion needed.",
                            },
                            ["TL"] = {
                                "Malinaw na. Hindi na kailangan ng karagdagang usapan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Keep sharp.",
                            },
                            ["TL"] = {
                                "Naintindihan. Maging alerto.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Noted. Back to watching the perimeter.",
                            },
                            ["TL"] = {
                                "Tala ko na. Balik sa pagbabantay.",
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
