-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_memory",
        ["id"] = "semantic.interaction.memory.acknowledge.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.memory.acknowledge.terse",
            ["sourcePath"] = "psdl/dialogue/social_interaction_memory.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_memory_acknowledge_terse",
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
                ["responseTemplateID"] = "semantic.interaction.memory.acknowledge",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/memory/acknowledge.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Mm.",
                            },
                            ["TL"] = {
                                "Mm.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Remember.",
                            },
                            ["TL"] = {
                                "Tanda ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Recall it.",
                            },
                            ["TL"] = {
                                "Naalala ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Yeah.",
                            },
                            ["TL"] = {
                                "Oo.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Heard.",
                            },
                            ["TL"] = {
                                "Narinig.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Right.",
                            },
                            ["TL"] = {
                                "Tama.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Got it.",
                            },
                            ["TL"] = {
                                "Nakuha ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "True.",
                            },
                            ["TL"] = {
                                "Totoo.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Yep.",
                            },
                            ["TL"] = {
                                "Oo nga.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Understood.",
                            },
                            ["TL"] = {
                                "Naintindihan.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_memory.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
