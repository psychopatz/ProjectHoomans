-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_teammate",
        ["id"] = "semantic.medical.distress.teammate.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.teammate.default",
            ["sourcePath"] = "psdl/dialogue/medical_event_teammate.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_medical_distress_teammate_default",
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
                ["category"] = "projecthoomans:medical_event",
                ["responseTemplateID"] = "semantic.medical.distress.teammate.default",
                ["sourceSurface"] = "content/event/medical/teammate.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.default.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "They are hurt! Stay with them while I cover you.",
                            },
                            ["TL"] = {
                                "Nasaktan sila! Samahan mo sila habang binabantayan ko kayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.default.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Our companion is down! Tend to them, I've got guard.",
                            },
                            ["TL"] = {
                                "Bagsak ang kasama natin! Gamutin mo, babantayan ko kayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.default.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "They're injured! Get them patched up while I watch.",
                            },
                            ["TL"] = {
                                "Sugatan sila! Bendahan mo habang nagmamasid ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.default.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Check on them right now! I'll hold off the threats.",
                            },
                            ["TL"] = {
                                "Tignan mo sila ngayon din! Haharangin ko ang mga kalaban.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.default.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "They took a hit! See to their wounds, I'm watching.",
                            },
                            ["TL"] = {
                                "Tinamaan sila! Tingnan mo ang sugat nila, nakabantay ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.default.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Partner is wounded! Apply first aid, I've got your back.",
                            },
                            ["TL"] = {
                                "Sugatan ang kasama! Maglapat ng first aid, hawak ko likod niyo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.default.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "They're bleeding! Patch them while I keep perimeter.",
                            },
                            ["TL"] = {
                                "Dumurugo sila! Gamutin mo habang binabantayan ko ang paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.default.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Help them up! I'll keep the lane clear.",
                            },
                            ["TL"] = {
                                "Tulungan mo silang tumayo! Lilinisin ko ang daanan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.default.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "They need attention! Administer aid, I'll protect you both.",
                            },
                            ["TL"] = {
                                "Kailangan nila ng lunas! Gamutin mo, poprotektahan ko kayong dalawa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.default.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Our friend is hurt! Help them, I'm standing sentry.",
                            },
                            ["TL"] = {
                                "Nasaktan ang kaibigan natin! Tulungan mo sila, nakabantay ako.",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_teammate.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
