-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_memory",
        ["id"] = "semantic.interaction.memory.acknowledge_flavor.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.memory.acknowledge_flavor.terse",
            ["sourcePath"] = "psdl/dialogue/social_interaction_memory.json#records[6]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_memory_acknowledge_flavor_terse",
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
                ["responseTemplateID"] = "semantic.interaction.memory.acknowledge_flavor",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/memory/acknowledge_flavor.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "A brief nod follows.",
                            },
                            ["TL"] = {
                                "Isang maikling tango ang sumunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "A curt dip of the chin confirms it.",
                            },
                            ["TL"] = {
                                "Maikling pagyuko ng baba ang kumumpirma.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "The listener grunts in assent.",
                            },
                            ["TL"] = {
                                "Umungol ang nakikinig bilang pagsang-ayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "A sharp single nod.",
                            },
                            ["TL"] = {
                                "Isang mabilis at iisang tango.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "The listener barely shifts.",
                            },
                            ["TL"] = {
                                "Halos hindi gumalaw ang nakikinig.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Eyes narrow briefly in recognition.",
                            },
                            ["TL"] = {
                                "Sandaling nanliit ang mga mata sa pagkilala.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "A quick jerk of the head acknowledges it.",
                            },
                            ["TL"] = {
                                "Mabilis na paggalaw ng ulo ang kumilala roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "The listener's jaw sets firmly.",
                            },
                            ["TL"] = {
                                "Nadiin ang panga ng nakikinig.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "A momentary pause, nothing more.",
                            },
                            ["TL"] = {
                                "Isang saglit na paghinto, wala nang iba.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "A flat nod ends the topic.",
                            },
                            ["TL"] = {
                                "Isang malamig na tango ang nagtapos sa paksa.",
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
