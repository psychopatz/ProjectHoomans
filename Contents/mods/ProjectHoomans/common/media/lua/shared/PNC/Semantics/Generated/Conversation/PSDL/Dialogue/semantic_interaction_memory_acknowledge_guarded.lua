-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_memory",
        ["id"] = "semantic.interaction.memory.acknowledge.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.memory.acknowledge.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_memory.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_memory_acknowledge_guarded",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "All right. I heard you.",
                            },
                            ["TL"] = {
                                "Sige. Narinig kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "I remember, but let's not dwell on the past.",
                            },
                            ["TL"] = {
                                "Naaalala ko, pero huwag na nating balik-balikan ang nakaraan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Past is past. Keep your focus here.",
                            },
                            ["TL"] = {
                                "Nakalipas na. Magpokus ka sa kasalukuyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "I know what happened. No need to rehash it.",
                            },
                            ["TL"] = {
                                "Alam ko ang nangyari. Di na kailangang ulitin pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Noted. But don't expect me to get sentimental.",
                            },
                            ["TL"] = {
                                "Tala ko na. Pero huwag kang umasang magiging madrama ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Yeah, I remember. Why bring it up now?",
                            },
                            ["TL"] = {
                                "Oo, tanda ko. Bakit mo binubuksan ngayon?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "I haven't forgotten. I never forget.",
                            },
                            ["TL"] = {
                                "Hindi ko kinalimutan. Hindi ako kailanman nakalilimot.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Heard. Let's move on.",
                            },
                            ["TL"] = {
                                "Narinig ko. Lumipat na tayo ng usapan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "I remember the lesson it taught us.",
                            },
                            ["TL"] = {
                                "Naaalala ko ang aral na itinuro niyan sa atin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "All right. Keep that to yourself moving forward.",
                            },
                            ["TL"] = {
                                "Sige. Itago mo na lang sa sarili mo sa susunod.",
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
