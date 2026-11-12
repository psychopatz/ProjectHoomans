-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_stressed.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_stressed.guarded",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[12]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_dispute_stressed_guarded",
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
                ["responseTemplateID"] = "semantic.social.dispute_stressed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/disputes.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "I hear you. Not now.",
                            },
                            ["TL"] = {
                                "Naririnig kita. Hindi ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "We don't have time to fight. Stand down.",
                            },
                            ["TL"] = {
                                "Wala tayong oras para mag-away. Tumigil ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Too much on the line to argue. Shut it down.",
                            },
                            ["TL"] = {
                                "Masyadong malaki ang nakataya para magtalo. Itigil mo na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'm stressed, you're stressed. Drop it.",
                            },
                            ["TL"] = {
                                "Pagod ako, pagod ka. Hayaan mo na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Don't push an argument while we're in danger.",
                            },
                            ["TL"] = {
                                "Huwag kang magpumilit makipagtalo habang delikado.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "One more word about this and I walk away.",
                            },
                            ["TL"] = {
                                "Isa pang salita tungkol dito at aalis ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Save the bickering before it gets us killed.",
                            },
                            ["TL"] = {
                                "Itabi ang bangayan bago tayo mapatay nito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Not the time. Eyes forward.",
                            },
                            ["TL"] = {
                                "Hindi ito ang tamang oras. Tumingin sa unahan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'm done debating under pressure.",
                            },
                            ["TL"] = {
                                "Tapos na akong makipagtalo sa gitna ng tensiyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Cut the argument right now.",
                            },
                            ["TL"] = {
                                "Putulin mo ang pagtatalo ngayon din.",
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
        ["sourceShard"] = "psdl/dialogue/social_reactions_ack_dispute.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
