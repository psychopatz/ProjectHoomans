-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_argument",
        ["id"] = "semantic.interaction.argument.retaliate.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.argument.retaliate.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_argument.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_argument_retaliate_neutral",
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
                ["responseTemplateID"] = "semantic.interaction.argument.retaliate",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/argument/retaliate.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "You're really testing me right now.",
                            },
                            ["TL"] = {
                                "Talagang sinusubok mo ang pasensya ko ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Don't push your luck any further.",
                            },
                            ["TL"] = {
                                "Huwag mo nang isugal pa ang suwerte mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "You're out of line, and I won't stand for it.",
                            },
                            ["TL"] = {
                                "Sumusobra ka na, at hindi ako papayag diyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "You started this, but I'll finish it if I have to.",
                            },
                            ["TL"] = {
                                "Ikaw ang nagsimula, pero tatapusin ko kung kailangan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "You're making a massive mistake talking to me like that.",
                            },
                            ["TL"] = {
                                "Napakalaking pagkakamali ang kausapin ako nang ganyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Think very carefully about what you say next.",
                            },
                            ["TL"] = {
                                "Pag-isipan mong mabuti ang susunod mong sasabihin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I've had about enough of your disrespect.",
                            },
                            ["TL"] = {
                                "Sapat na ang pambabastos mo sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "You're crossing a boundary you can't walk back.",
                            },
                            ["TL"] = {
                                "Tumatawid ka sa hangganang hindi mo na mababawi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Back down before this escalates completely.",
                            },
                            ["TL"] = {
                                "Umatras ka bago pa tuluyang magkagulo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I'm answering in kind: knock it off.",
                            },
                            ["TL"] = {
                                "Sasagutin kita nang patas: itigil mo na 'yan.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_argument.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
