-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_apology",
        ["id"] = "semantic.social.apology.friendly.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.apology.friendly.guarded",
            ["sourcePath"] = "psdl/dialogue/social_apology.json#records[7]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_apology_friendly_guarded",
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
                ["category"] = "projecthoomans:social.apology",
                ["responseTemplateID"] = "semantic.social.apology.friendly",
                ["sourceSurface"] = "content/social_apology.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "APOLOGY_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.friendly.guarded.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I heard you. Leave it there.",
                            },
                            ["TL"] = {
                                "Narinig kita. Tama na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.friendly.guarded.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Fine. Just don't let it happen again.",
                            },
                            ["TL"] = {
                                "Sige. Huwag mo lang hahayaang maulit.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.friendly.guarded.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Accepted. Watch your step next time.",
                            },
                            ["TL"] = {
                                "Tanggap ko. Mag-ingat ka na lang sa susunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.friendly.guarded.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "All right. But I'll be keeping an eye out.",
                            },
                            ["TL"] = {
                                "Sige. Pero magmamasid pa rin ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.friendly.guarded.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "We'll let it slide this time.",
                            },
                            ["TL"] = {
                                "Palalampasin natin sa pagkakataong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.friendly.guarded.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Do better going forward.",
                            },
                            ["TL"] = {
                                "Naintindihan. Ayusin mo sa mga susunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.friendly.guarded.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I accept it. Just remember what's at stake.",
                            },
                            ["TL"] = {
                                "Tinatanggap ko. Tandaan mo lang kung anong nakataya.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.friendly.guarded.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Fair enough. Let's not have a repeat.",
                            },
                            ["TL"] = {
                                "Makatwiran. Huwag nang uulitin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.friendly.guarded.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I hear the words. Make sure actions follow.",
                            },
                            ["TL"] = {
                                "Naririnig ko ang salita. Tiyakin mong susunod ang gawa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.friendly.guarded.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "We're even for now. Keep it that way.",
                            },
                            ["TL"] = {
                                "Pantay tayo sa ngayon. Panatilihin mong ganoon.",
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
        ["sourceShard"] = "psdl/dialogue/social_apology.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
