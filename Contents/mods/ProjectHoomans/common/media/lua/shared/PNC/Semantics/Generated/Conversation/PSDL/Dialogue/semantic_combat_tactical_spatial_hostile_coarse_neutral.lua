-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_combat",
        ["id"] = "semantic.combat.tactical_spatial.hostile.coarse.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.tactical_spatial.hostile.coarse.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_combat.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_tactical_spatial_hostile_coarse_neutral",
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
                ["responseTemplateID"] = "semantic.combat.tactical_spatial.hostile.coarse",
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
                                "Hostiles {scene.relative}!",
                            },
                            ["TL"] = {
                                "Mga kalaban {scene.relative}!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Armed fighters {scene.relative}!",
                            },
                            ["TL"] = {
                                "May armadong mga tao {scene.relative}!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Enemy movement {scene.relative}!",
                            },
                            ["TL"] = {
                                "Galaw ng kalaban {scene.relative}!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Take cover, hostiles {scene.relative}!",
                            },
                            ["TL"] = {
                                "Magtago, may mga kalaban {scene.relative}!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Gunfire expected {scene.relative}! Hostiles!",
                            },
                            ["TL"] = {
                                "Maghanda sa putukan {scene.relative}! Mga kalaban!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Watch out {scene.relative}, armed hostiles!",
                            },
                            ["TL"] = {
                                "Mag-ingat {scene.relative}, may mga armadong kalaban!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Enemy survivors spotted {scene.relative}!",
                            },
                            ["TL"] = {
                                "May kalabang nakaligtas {scene.relative}!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Contact {scene.relative}! Keep low!",
                            },
                            ["TL"] = {
                                "May kalaban {scene.relative}! Yumuko!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Check {scene.relative}! Hostiles advancing!",
                            },
                            ["TL"] = {
                                "Tingnan {scene.relative}! Sumusulong ang kalaban!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Incoming attack {scene.relative}!",
                            },
                            ["TL"] = {
                                "Paparating na atake {scene.relative}!",
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
