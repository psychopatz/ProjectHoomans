-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.health_state.healthy.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.health_state.healthy.neutral",
            ["sourcePath"] = "psdl/dialogue/health_content.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_health_state_healthy_neutral",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseTemplateID"] = "semantic.question.health_state.healthy",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/health_state.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm doing okay.",
                            },
                            ["TL"] = {
                                "Ayos lang ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Healthy as can be expected out here.",
                            },
                            ["TL"] = {
                                "Malusog naman ayon sa inaasahan dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "No wounds or sickness bothering me right now.",
                            },
                            ["TL"] = {
                                "Walang sugat o sakit na gumugulo sa akin ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Feeling solid. No injuries to speak of.",
                            },
                            ["TL"] = {
                                "Maayos ang pakiramdam ko. Walang iniindang sugat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I'm in good health today, all things considered.",
                            },
                            ["TL"] = {
                                "Mabuti ang kalusugan ko ngayon, sa kabila ng lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Everything's working the way it should.",
                            },
                            ["TL"] = {
                                "Gumagana ang lahat nang maayos sa katawan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "No complaints on the physical side today.",
                            },
                            ["TL"] = {
                                "Walang reklamo sa pisikal kong kalagayan ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Feeling intact and steady. No wounds on me.",
                            },
                            ["TL"] = {
                                "Buo at matatag ang pakiramdam ko. Walang sugat sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Health is holding up fine. Ready for work.",
                            },
                            ["TL"] = {
                                "Maayos ang kalusugan ko. Handa na para sa gawain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Not carrying any injuries right now.",
                            },
                            ["TL"] = {
                                "Wala akong iniindang anumang sugat ngayon.",
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
        ["sourceShard"] = "psdl/dialogue/health_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
