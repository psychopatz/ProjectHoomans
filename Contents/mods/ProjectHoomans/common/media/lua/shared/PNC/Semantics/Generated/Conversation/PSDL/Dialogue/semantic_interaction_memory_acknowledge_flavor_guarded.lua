-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_memory",
        ["id"] = "semantic.interaction.memory.acknowledge_flavor.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.memory.acknowledge_flavor.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_memory.json#records[7]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_memory_acknowledge_flavor_guarded",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "The listener gives a guarded nod.",
                            },
                            ["TL"] = {
                                "Maingat na tumango ang nakikinig.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "The listener watches closely without revealing their thoughts.",
                            },
                            ["TL"] = {
                                "Masusing nagmasid ang nakikinig nang walang inilalantad na iniisip.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "A cautious look crosses the listener's eyes.",
                            },
                            ["TL"] = {
                                "Isang maingat na tingin ang dumaan sa mga mata ng nakikinig.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "The listener stiffens slightly as the past is mentioned.",
                            },
                            ["TL"] = {
                                "Bahagyang nanigas ang nakikinig nang mabanggit ang nakaraan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "A slow, guarded nod shows the words were registered.",
                            },
                            ["TL"] = {
                                "Isang mabagal at maingat na tango ang nagpahiwatig na narinig ang sinabi.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "The listener's hand rests near their belt during the pause.",
                            },
                            ["TL"] = {
                                "Nakalapag ang kamay ng nakikinig malapit sa sinturon sa sandaling iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "The listener narrows their eyes, weighing the intent behind the words.",
                            },
                            ["TL"] = {
                                "Nanliit ang mga mata ng nakikinig, tinitimbang ang layunin sa likod ng salita.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "A tight, reserved expression settles on the listener's face.",
                            },
                            ["TL"] = {
                                "Isang mahigpit at maramdamang ekspresyon ang namutawi sa mukha ng nakikinig.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "The listener gives nothing away, nodding once carefully.",
                            },
                            ["TL"] = {
                                "Walang ipinakitang emosyon ang nakikinig, isang maingat na tango lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "The listener keeps their guard up while acknowledging the memory.",
                            },
                            ["TL"] = {
                                "Nanatiling alerto ang nakikinig habang kinikilala ang alaala.",
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
