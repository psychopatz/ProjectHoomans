-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_apology",
        ["id"] = "semantic.social.apology.withdrawn.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.apology.withdrawn.guarded",
            ["sourcePath"] = "psdl/dialogue/social_apology.json#records[15]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_apology_withdrawn_guarded",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "APOLOGY_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.withdrawn.guarded.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "All right. Leave it there.",
                            },
                            ["TL"] = {
                                "Sige. Tama na iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.withdrawn.guarded.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't bring it up again.",
                            },
                            ["TL"] = {
                                "Huwag mo nang bubuksan muli 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.withdrawn.guarded.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Drop it while you're ahead.",
                            },
                            ["TL"] = {
                                "Itigil mo na habang maaga pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.withdrawn.guarded.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm done hearing about it.",
                            },
                            ["TL"] = {
                                "Ayoko nang marinig ang tungkol diyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.withdrawn.guarded.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Leave it where it lies.",
                            },
                            ["TL"] = {
                                "Hayaan mo kung saan 'yan naroroon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.withdrawn.guarded.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "We're not reopening this. Ever.",
                            },
                            ["TL"] = {
                                "Hindi na natin bubuksan muli ito. Kailanman.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.withdrawn.guarded.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "That's enough out of you.",
                            },
                            ["TL"] = {
                                "Sapat na ang narinig ko sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.withdrawn.guarded.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Keep your distance from that subject.",
                            },
                            ["TL"] = {
                                "Lumayo ka sa paksang 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.withdrawn.guarded.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Consider this matter closed.",
                            },
                            ["TL"] = {
                                "Ituring mong sarado na ang usaping ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.withdrawn.guarded.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Leave it there and don't test me.",
                            },
                            ["TL"] = {
                                "Iwan mo na diyan at huwag mo akong subukan.",
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
