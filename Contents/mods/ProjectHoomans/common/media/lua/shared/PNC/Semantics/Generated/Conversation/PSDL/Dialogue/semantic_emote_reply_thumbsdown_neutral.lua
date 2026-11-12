-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.reply.thumbsdown.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.reply.thumbsdown.neutral",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[21]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_emote_reply_thumbsdown_neutral",
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
                ["responseTemplateID"] = "semantic.emote.reply.thumbsdown",
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
                                "I got the message. Tell me what's wrong.",
                            },
                            ["TL"] = {
                                "Nakuha ko ang mensahe. Sabihin mo kung anong problema.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Not happy with that? What's your take?",
                            },
                            ["TL"] = {
                                "Hindi ka sang-ayon? Ano ang opinyon mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. You disagree.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Hindi ka sang-ayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Message received. We can rethink it.",
                            },
                            ["TL"] = {
                                "Nakuha ko ang pahiwatig. Pwede nating pag-isipan ulit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Got it. You don't like the look of this.",
                            },
                            ["TL"] = {
                                "Naintindihan. Hindi maganda ang kutob mo rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Fair enough. What's the alternative?",
                            },
                            ["TL"] = {
                                "Makatwiran. Ano ang alternatibo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I hear the disapproval. Let's adjust.",
                            },
                            ["TL"] = {
                                "Naririnig ko ang pagtutol mo. Mag-ayos tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Noted. We won't go that route then.",
                            },
                            ["TL"] = {
                                "Tala ko na. Hindi na natin dadaanan ang rutang 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Point taken.",
                            },
                            ["TL"] = {
                                "Naintindihan. Nakuha ko ang punto mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "All right, let's look for a better option.",
                            },
                            ["TL"] = {
                                "Sige, maghanap tayo ng mas magandang paraan.",
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
