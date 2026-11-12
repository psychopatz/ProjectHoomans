-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.post_combat_clear.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.post_combat_clear.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_horde_work.json#records[19]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_scene_post_combat_clear_guarded",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Don't relax yet. Scan for stragglers.",
                            },
                            ["TL"] = {
                                "Huwag munang magpakampante. Maghanap ng mga naiwan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Down, but keep your weapon ready. More could be coming.",
                            },
                            ["TL"] = {
                                "Tumba na, pero ihanda ang armas. Baka may paparating pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Check your perimeter before you start celebrating.",
                            },
                            ["TL"] = {
                                "Suriin ang paligid bago magdiwang.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Check every corpse. Make sure they stay down.",
                            },
                            ["TL"] = {
                                "Tingnan ang bawat bangkay. Tiyaking hindi na gagalaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Gunfire brings more of them. We need to be ready to move.",
                            },
                            ["TL"] = {
                                "Nakahahatak ng iba ang putok. Maging handa tayong umalis.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Wipe your blade and reload immediately.",
                            },
                            ["TL"] = {
                                "Punasan ang talim at magkarga agad ng bala.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Are you bitten? Answer me right now.",
                            },
                            ["TL"] = {
                                "Kinagat ka ba? Sagutin mo ako ngayon din.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Threat is dead, but noise travels fast out here.",
                            },
                            ["TL"] = {
                                "Patay ang banta, pero mabilis kumalat ang ingay dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Keep low. Don't silhouette yourself in the doorway.",
                            },
                            ["TL"] = {
                                "Yumuko ka. Huwag mong i-expose ang sarili mo sa pinto.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Clear for now. Expect a second wave.",
                            },
                            ["TL"] = {
                                "Malinis sa ngayon. Maghanda sa pangalawang bugso.",
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
