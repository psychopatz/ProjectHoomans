-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_memory",
        ["id"] = "semantic.interaction.memory.acknowledge_flavor.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.memory.acknowledge_flavor.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_memory.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_memory_acknowledge_flavor_neutral",
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
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "The listener gives a small acknowledging nod.",
                            },
                            ["TL"] = {
                                "Bahagyang tumango ang nakikinig bilang pagkilala.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "The listener listens thoughtfully and nods.",
                            },
                            ["TL"] = {
                                "Matiyagang nakikinig ang kausap at tumatango.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "A steady nod shows the listener remembers.",
                            },
                            ["TL"] = {
                                "Isang matatag na tango ang nagpapakitang naaalala niya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "The listener absorbs the words and dips their head.",
                            },
                            ["TL"] = {
                                "Inintindi ng nakikinig ang mga salita at bahagyang yumukod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "The listener acknowledges the shared recollection quietly.",
                            },
                            ["TL"] = {
                                "Tahimik na kinilala ng nakikinig ang pinagsaluhang alaala.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "A quiet look of recognition passes over the listener's face.",
                            },
                            ["TL"] = {
                                "Isang tahimik na anyo ng pagkilala ang dumaan sa mukha ng nakikinig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "The listener blinks slowly, recalling the moment.",
                            },
                            ["TL"] = {
                                "Mabagal na kumurap ang nakikinig, inaalala ang sandali.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "The listener gives a calm, measured gesture of understanding.",
                            },
                            ["TL"] = {
                                "Nagbigay ang nakikinig ng kalmado at maingat na senyas ng pagkaunawa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "A brief pause precedes an acknowledging nod.",
                            },
                            ["TL"] = {
                                "Isang maikling paghinto ang nauna bago tumango bilang pagkilala.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "The listener tilts their head in silent agreement.",
                            },
                            ["TL"] = {
                                "Itinagilid ng nakikinig ang ulo bilang tahimik na pagsang-ayon.",
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
