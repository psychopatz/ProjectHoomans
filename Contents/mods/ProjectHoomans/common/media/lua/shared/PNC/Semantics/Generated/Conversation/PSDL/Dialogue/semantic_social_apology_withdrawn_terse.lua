-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_apology",
        ["id"] = "semantic.social.apology.withdrawn.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.apology.withdrawn.terse",
            ["sourcePath"] = "psdl/dialogue/social_apology.json#records[14]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_apology_withdrawn_terse",
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
                ["responseTemplateID"] = "semantic.social.apology.withdrawn",
                ["sourceSurface"] = "content/social_apology.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "APOLOGY_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.social.apology.withdrawn.terse.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Leave it.",
                            },
                            ["TL"] = {
                                "Tama na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.social.apology.withdrawn.terse.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Drop it.",
                            },
                            ["TL"] = {
                                "Hayaan mo na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.social.apology.withdrawn.terse.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Enough.",
                            },
                            ["TL"] = {
                                "Sapat na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.social.apology.withdrawn.terse.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Done.",
                            },
                            ["TL"] = {
                                "Tapos na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.social.apology.withdrawn.terse.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Subject closed.",
                            },
                            ["TL"] = {
                                "Sarado na ang usapan.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.social.apology.withdrawn.terse.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No more.",
                            },
                            ["TL"] = {
                                "Wala nang kasunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.social.apology.withdrawn.terse.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Let it be.",
                            },
                            ["TL"] = {
                                "Hayaan mo na 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.social.apology.withdrawn.terse.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Finished.",
                            },
                            ["TL"] = {
                                "Tapos.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.social.apology.withdrawn.terse.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Moving on.",
                            },
                            ["TL"] = {
                                "Tuloy na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.social.apology.withdrawn.terse.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "End of discussion.",
                            },
                            ["TL"] = {
                                "Tapos na ang diskusyon.",
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
