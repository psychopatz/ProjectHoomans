-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.reply.thankyou.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.reply.thankyou.neutral",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[19]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_emote_reply_thankyou_neutral",
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
                ["responseTemplateID"] = "semantic.emote.reply.thankyou",
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
                                "You're welcome.",
                            },
                            ["TL"] = {
                                "Walang anuman.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "No problem.",
                            },
                            ["TL"] = {
                                "Walang problema.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Don't mention it.",
                            },
                            ["TL"] = {
                                "Huwag mo nang alalahanin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Glad to help.",
                            },
                            ["TL"] = {
                                "Masayang tumulong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Anytime.",
                            },
                            ["TL"] = {
                                "Kahit kailan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Just doing my part.",
                            },
                            ["TL"] = {
                                "Ginagawa ko lang ang bahagi ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Happy to assist.",
                            },
                            ["TL"] = {
                                "Mabuti at nakatulong ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "No trouble at all.",
                            },
                            ["TL"] = {
                                "Walang anuman talaga.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "All part of surviving together.",
                            },
                            ["TL"] = {
                                "Bahagi lang 'yan ng sabay na pamumuhay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "You'd do the same for me.",
                            },
                            ["TL"] = {
                                "Gagawin mo rin 'yan para sa akin.",
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
