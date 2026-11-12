-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.post_combat_clear.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.post_combat_clear.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_horde_work.json#records[16]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_scene_post_combat_clear_neutral",
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
                ["responseTemplateID"] = "semantic.interaction.scene.post_combat_clear",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/post_combat.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Looks clear now. That got rough for a minute.",
                            },
                            ["TL"] = {
                                "Mukhang malinaw na. Naging delikado sandali.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Area is secure. Check yourselves for injuries.",
                            },
                            ["TL"] = {
                                "Ligtas na ang lugar. Tingnan niyo kung may mga sugat kayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "They're all down. Take a breath and reload.",
                            },
                            ["TL"] = {
                                "Tumba na silang lahat. Huminga at magkarga ng bala.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Fight's over. Good work holding the line.",
                            },
                            ["TL"] = {
                                "Tapos na ang laban. Magandang pagpigil sa linya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Looks like the immediate threat is dealt with.",
                            },
                            ["TL"] = {
                                "Mukhang naasikaso na ang agarang banta.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Clear. Everyone still in one piece?",
                            },
                            ["TL"] = {
                                "Malinaw. Buo pa ba ang lahat?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Threat neutralized. Let's recover our stamina.",
                            },
                            ["TL"] = {
                                "Nalipol ang banta. Bawiin natin ang lakas natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "It's quiet again. Stay alert for stragglers.",
                            },
                            ["TL"] = {
                                "Tahimik na ulit. Magbantay sa mga naiwan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Combat is finished. Reload and bandage up.",
                            },
                            ["TL"] = {
                                "Tapos na ang bakbakan. Magkarga at magbenda.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "We held them off. Area appears clear.",
                            },
                            ["TL"] = {
                                "Naitaboy natin sila. Mukhang malinis na ang lugar.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_horde_work.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
