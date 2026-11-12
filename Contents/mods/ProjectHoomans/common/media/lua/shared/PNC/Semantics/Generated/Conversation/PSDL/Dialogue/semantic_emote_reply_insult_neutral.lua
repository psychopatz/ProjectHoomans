-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.reply.insult.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.reply.insult.neutral",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[15]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_emote_reply_insult_neutral",
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
                ["responseTemplateID"] = "semantic.emote.reply.insult",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/reply.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Keep it respectful.",
                            },
                            ["TL"] = {
                                "Maging magalang ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Save that attitude for the dead.",
                            },
                            ["TL"] = {
                                "Itabi mo ang ugaling 'yan para sa mga patay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Not in the mood for that.",
                            },
                            ["TL"] = {
                                "Wala ako sa mood para diyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Watch yourself.",
                            },
                            ["TL"] = {
                                "Mag-ingat ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your hands and words to yourself.",
                            },
                            ["TL"] = {
                                "Itago mo sa sarili mo ang mga salita mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Don't start something out here.",
                            },
                            ["TL"] = {
                                "Huwag kang magsimula ng gulo rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Grow up. We have real threats to worry about.",
                            },
                            ["TL"] = {
                                "Magpakatanda ka. May mga totoong panganib tayong kinakaharap.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Not amused.",
                            },
                            ["TL"] = {
                                "Hindi nakatutuwa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Check yourself before you cause trouble.",
                            },
                            ["TL"] = {
                                "Pagsabihan mo ang sarili mo bago ka makagawa ng gulo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I'm ignoring that for now. Don't push it.",
                            },
                            ["TL"] = {
                                "Pinalalampas ko muna 'yan. Huwag mong sagarin.",
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
