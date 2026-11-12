-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.reply.clap.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.reply.clap.neutral",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[12]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_emote_reply_clap_neutral",
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
                ["responseTemplateID"] = "semantic.emote.reply.clap",
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
                                "Thanks.",
                            },
                            ["TL"] = {
                                "Salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Appreciate the applause.",
                            },
                            ["TL"] = {
                                "Salamat sa palakpak.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Just doing what had to be done.",
                            },
                            ["TL"] = {
                                "Ginawa lang ang kailangang gawin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Glad you liked it.",
                            },
                            ["TL"] = {
                                "Mabuti at nagustuhan mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Much appreciated.",
                            },
                            ["TL"] = {
                                "Maraming salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "All in a day's work.",
                            },
                            ["TL"] = {
                                "Bahagi lang 'yan ng araw-araw na trabaho.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks. Good to know it landed well.",
                            },
                            ["TL"] = {
                                "Salamat. Mabuting malaman na maayos ang dating.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Appreciate it.",
                            },
                            ["TL"] = {
                                "Salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks. Let's keep the momentum going.",
                            },
                            ["TL"] = {
                                "Salamat. Tuloy lang natin ang sigla.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Thank you for the encouragement.",
                            },
                            ["TL"] = {
                                "Salamat sa pampalakas ng loob.",
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
