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
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneCombat/Catalog",
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
    {
        ["domain"] = "social_interaction_scene_combat",
        ["id"] = "semantic.combat.tactical_spatial.hostile.coarse.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.tactical_spatial.hostile.coarse.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_combat.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneCombat/Catalog",
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
    {
        ["domain"] = "social_interaction_scene_combat",
        ["id"] = "semantic.combat.tactical_spatial.zombie.clock.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.tactical_spatial.zombie.clock.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_combat.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneCombat/Catalog",
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
    {
        ["domain"] = "social_interaction_scene_combat",
        ["id"] = "semantic.combat.tactical_spatial.zombie.coarse.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.tactical_spatial.zombie.coarse.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_combat.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneCombat/Catalog",
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
