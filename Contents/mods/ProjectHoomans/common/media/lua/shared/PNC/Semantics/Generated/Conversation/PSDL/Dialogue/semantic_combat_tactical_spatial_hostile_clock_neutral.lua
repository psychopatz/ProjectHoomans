-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_combat",
        ["id"] = "semantic.combat.tactical_spatial.hostile.clock.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.tactical_spatial.hostile.clock.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_combat.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_tactical_spatial_hostile_clock_neutral",
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
                ["responseTemplateID"] = "semantic.combat.tactical_spatial.hostile.clock",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/combat/tactical_spatial.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Hostiles at {scene.clock}!",
                            },
                            ["TL"] = {
                                "Mga kalaban sa {scene.clock}!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Shooters at {scene.clock}! Take cover!",
                            },
                            ["TL"] = {
                                "May mga baril sa {scene.clock}! Magtago!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Enemy fighters spotted at {scene.clock}!",
                            },
                            ["TL"] = {
                                "May mga kalabang manlalaban sa {scene.clock}!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Gunmen at {scene.clock}! Watch your head!",
                            },
                            ["TL"] = {
                                "May mga armadong tao sa {scene.clock}! Yumuko ka!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Hostiles moving in from {scene.clock}!",
                            },
                            ["TL"] = {
                                "Mga kalaban lumalapit mula sa {scene.clock}!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Armed enemies at {scene.clock}!",
                            },
                            ["TL"] = {
                                "May armadong mga kalaban sa {scene.clock}!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Contact! Hostiles at {scene.clock}!",
                            },
                            ["TL"] = {
                                "May engkuwentro! Mga kalaban sa {scene.clock}!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Check {scene.clock}! Armed hostiles!",
                            },
                            ["TL"] = {
                                "Tingnan ang {scene.clock}! May armadong kalaban!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Enemy squad at {scene.clock}!",
                            },
                            ["TL"] = {
                                "Grupo ng kalaban sa {scene.clock}!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Threat at {scene.clock}! Hostiles!",
                            },
                            ["TL"] = {
                                "Banta sa {scene.clock}! Mga kalaban!",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_combat.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
