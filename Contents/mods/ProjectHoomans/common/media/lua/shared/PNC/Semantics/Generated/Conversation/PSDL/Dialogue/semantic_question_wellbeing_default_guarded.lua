-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.default.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.default.guarded",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[10]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_wellbeing_default_guarded",
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
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseTemplateID"] = "semantic.question.wellbeing.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/general.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm managing. Don't press me.",
                            },
                            ["TL"] = {
                                "Kinakaya ko. Huwag mo nang ipilit.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "I'm fine. Keep your focus on your own work.",
                            },
                            ["TL"] = {
                                "Ayos lang ako. Ituon mo ang pansin sa sarili mong gawain.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "No problems here. That's all you get.",
                            },
                            ["TL"] = {
                                "Walang problema rito. Iyon lang ang masasabi ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "I can look after myself. No need to inquire.",
                            },
                            ["TL"] = {
                                "Kaya kong alagaan ang sarili ko. Huwag nang magtanong.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Doing what needs doing. Back off a bit.",
                            },
                            ["TL"] = {
                                "Ginagawa ang kailangang gawin. Lumayo ka nang kaunti.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "I don't discuss personal matters easily.",
                            },
                            ["TL"] = {
                                "Hindi ako basta-basta nagkukuwento tungkol sa sarili ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Healthy enough to defend myself. That's enough.",
                            },
                            ["TL"] = {
                                "Kaya ko pang ipagtanggol ang sarili ko. Sapat na 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Nothing to complain about to strangers.",
                            },
                            ["TL"] = {
                                "Walang dapat ireklamo sa mga hindi ko kakilala.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'm alright. Mind your own perimeter.",
                            },
                            ["TL"] = {
                                "Ayos lang ako. Bantayan mo ang sarili mong parte.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Alive and alert. Leave it at that.",
                            },
                            ["TL"] = {
                                "Buhay at alerto. Hanggang doon na lang.",
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
        ["sourceShard"] = "psdl/dialogue/wellbeing_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
