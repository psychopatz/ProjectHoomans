-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_combat",
        ["id"] = "semantic.combat.tactical_spatial.zombie.clock.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.tactical_spatial.zombie.clock.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_combat.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_tactical_spatial_zombie_clock_neutral",
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
                ["responseTemplateID"] = "semantic.combat.tactical_spatial.zombie.clock",
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
                                "Zombies, {scene.clock}!",
                            },
                            ["TL"] = {
                                "Mga zombie, {scene.clock}!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Dead coming in from {scene.clock}!",
                            },
                            ["TL"] = {
                                "May mga patay na parating mula sa {scene.clock}!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Watch {scene.clock}, walkers spotted!",
                            },
                            ["TL"] = {
                                "Bantayan ang {scene.clock}, may mga walker!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Zombies at {scene.clock}! Get ready!",
                            },
                            ["TL"] = {
                                "Mga zombie sa {scene.clock}! Humanda!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Movement at {scene.clock}, it's dead heads!",
                            },
                            ["TL"] = {
                                "May galaw sa {scene.clock}, mga zombie 'yan!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Incoming zombies from {scene.clock}!",
                            },
                            ["TL"] = {
                                "Paparating na mga zombie galing sa {scene.clock}!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Eyes on {scene.clock}! Walkers approaching!",
                            },
                            ["TL"] = {
                                "Tumingin sa {scene.clock}! May lumalapit na mga walker!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Check {scene.clock}, we've got zombies!",
                            },
                            ["TL"] = {
                                "Tingnan ang {scene.clock}, may mga zombie tayo!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Zombies moving in fast at {scene.clock}!",
                            },
                            ["TL"] = {
                                "Mabilis na lumalapit ang mga zombie sa {scene.clock}!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Target at {scene.clock}! Zombies!",
                            },
                            ["TL"] = {
                                "Puntirya sa {scene.clock}! Mga zombie!",
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
