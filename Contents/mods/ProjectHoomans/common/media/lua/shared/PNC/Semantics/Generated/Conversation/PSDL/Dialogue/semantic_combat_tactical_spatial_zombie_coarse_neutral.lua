-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_combat",
        ["id"] = "semantic.combat.tactical_spatial.zombie.coarse.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.tactical_spatial.zombie.coarse.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_combat.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_tactical_spatial_zombie_coarse_neutral",
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
                ["responseTemplateID"] = "semantic.combat.tactical_spatial.zombie.coarse",
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
                                "Zombies {scene.relative}!",
                            },
                            ["TL"] = {
                                "Mga zombie {scene.relative}!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Watch out, dead heads {scene.relative}!",
                            },
                            ["TL"] = {
                                "Mag-ingat, may mga patay {scene.relative}!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Walkers approaching {scene.relative}!",
                            },
                            ["TL"] = {
                                "May mga walker na papalapit {scene.relative}!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Look {scene.relative}! Zombies!",
                            },
                            ["TL"] = {
                                "Tumingin {scene.relative}! Mga zombie!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Incoming dead {scene.relative}!",
                            },
                            ["TL"] = {
                                "Paparating na mga patay {scene.relative}!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Zombies closing in {scene.relative}!",
                            },
                            ["TL"] = {
                                "Lumalapit ang mga zombie {scene.relative}!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Eyes {scene.relative}, we've got walkers!",
                            },
                            ["TL"] = {
                                "Tumingin {scene.relative}, may mga walker tayo!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Dead heads spotted {scene.relative}!",
                            },
                            ["TL"] = {
                                "May nakitang mga zombie {scene.relative}!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Check {scene.relative}! Swarm incoming!",
                            },
                            ["TL"] = {
                                "Suriin {scene.relative}! May paparating na kawan!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Danger {scene.relative}! Zombies!",
                            },
                            ["TL"] = {
                                "Panganib {scene.relative}! Mga zombie!",
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
