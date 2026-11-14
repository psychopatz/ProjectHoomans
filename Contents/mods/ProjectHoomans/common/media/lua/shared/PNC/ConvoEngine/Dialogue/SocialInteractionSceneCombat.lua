-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_combat",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.tactical_spatial.hostile.clock",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "Hostiles at {scene.clock}!",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.tactical_spatial.hostile.clock.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Hostiles at {scene.clock}!",
                                        "Shooters at {scene.clock}! Take cover!",
                                        "Enemy fighters spotted at {scene.clock}!",
                                        "Gunmen at {scene.clock}! Watch your head!",
                                        "Hostiles moving in from {scene.clock}!",
                                        "Armed enemies at {scene.clock}!",
                                        "Contact! Hostiles at {scene.clock}!",
                                        "Check {scene.clock}! Armed hostiles!",
                                        "Enemy squad at {scene.clock}!",
                                        "Threat at {scene.clock}! Hostiles!",
                                    },
                                    ["TL"] = {
                                        "Mga kalaban sa {scene.clock}!",
                                        "May mga baril sa {scene.clock}! Magtago!",
                                        "May mga kalabang manlalaban sa {scene.clock}!",
                                        "May mga armadong tao sa {scene.clock}! Yumuko ka!",
                                        "Mga kalaban lumalapit mula sa {scene.clock}!",
                                        "May armadong mga kalaban sa {scene.clock}!",
                                        "May engkuwentro! Mga kalaban sa {scene.clock}!",
                                        "Tingnan ang {scene.clock}! May armadong kalaban!",
                                        "Grupo ng kalaban sa {scene.clock}!",
                                        "Banta sa {scene.clock}! Mga kalaban!",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.tactical_spatial.hostile",
            ["textRoles"] = {
                {
                    ["fallback"] = "Hostiles at {scene.clock}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.tactical_spatial.hostile.clock.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Hostiles at {scene.clock}!",
                            "Shooters at {scene.clock}! Take cover!",
                            "Enemy fighters spotted at {scene.clock}!",
                            "Gunmen at {scene.clock}! Watch your head!",
                            "Hostiles moving in from {scene.clock}!",
                            "Armed enemies at {scene.clock}!",
                            "Contact! Hostiles at {scene.clock}!",
                            "Check {scene.clock}! Armed hostiles!",
                            "Enemy squad at {scene.clock}!",
                            "Threat at {scene.clock}! Hostiles!",
                        },
                        ["TL"] = {
                            "Mga kalaban sa {scene.clock}!",
                            "May mga baril sa {scene.clock}! Magtago!",
                            "May mga kalabang manlalaban sa {scene.clock}!",
                            "May mga armadong tao sa {scene.clock}! Yumuko ka!",
                            "Mga kalaban lumalapit mula sa {scene.clock}!",
                            "May armadong mga kalaban sa {scene.clock}!",
                            "May engkuwentro! Mga kalaban sa {scene.clock}!",
                            "Tingnan ang {scene.clock}! May armadong kalaban!",
                            "Grupo ng kalaban sa {scene.clock}!",
                            "Banta sa {scene.clock}! Mga kalaban!",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.tactical_spatial.hostile.clock",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "clock",
            ["sourceId"] = "combat.tactical_spatial.hostile.clock",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_combat/combat_tactical_spatial_hostile_clock.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneCombat",
        ["namespace"] = "combat.tactical_spatial.hostile",
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
                ["responseAct"] = "REACT",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Hostiles at {scene.clock}!",
                                        "Shooters at {scene.clock}! Take cover!",
                                        "Enemy fighters spotted at {scene.clock}!",
                                        "Gunmen at {scene.clock}! Watch your head!",
                                        "Hostiles moving in from {scene.clock}!",
                                        "Armed enemies at {scene.clock}!",
                                        "Contact! Hostiles at {scene.clock}!",
                                        "Check {scene.clock}! Armed hostiles!",
                                        "Enemy squad at {scene.clock}!",
                                        "Threat at {scene.clock}! Hostiles!",
                                    },
                                    ["TL"] = {
                                        "Mga kalaban sa {scene.clock}!",
                                        "May mga baril sa {scene.clock}! Magtago!",
                                        "May mga kalabang manlalaban sa {scene.clock}!",
                                        "May mga armadong tao sa {scene.clock}! Yumuko ka!",
                                        "Mga kalaban lumalapit mula sa {scene.clock}!",
                                        "May armadong mga kalaban sa {scene.clock}!",
                                        "May engkuwentro! Mga kalaban sa {scene.clock}!",
                                        "Tingnan ang {scene.clock}! May armadong kalaban!",
                                        "Grupo ng kalaban sa {scene.clock}!",
                                        "Banta sa {scene.clock}! Mga kalaban!",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "combat.tactical_spatial.hostile.clock",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Hostiles at {scene.clock}!",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.tactical_spatial.hostile.clock.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_combat/combat_tactical_spatial_hostile_clock.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Hostiles at {scene.clock}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.tactical_spatial.hostile.clock.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Hostiles at {scene.clock}!",
                        "Shooters at {scene.clock}! Take cover!",
                        "Enemy fighters spotted at {scene.clock}!",
                        "Gunmen at {scene.clock}! Watch your head!",
                        "Hostiles moving in from {scene.clock}!",
                        "Armed enemies at {scene.clock}!",
                        "Contact! Hostiles at {scene.clock}!",
                        "Check {scene.clock}! Armed hostiles!",
                        "Enemy squad at {scene.clock}!",
                        "Threat at {scene.clock}! Hostiles!",
                    },
                    ["TL"] = {
                        "Mga kalaban sa {scene.clock}!",
                        "May mga baril sa {scene.clock}! Magtago!",
                        "May mga kalabang manlalaban sa {scene.clock}!",
                        "May mga armadong tao sa {scene.clock}! Yumuko ka!",
                        "Mga kalaban lumalapit mula sa {scene.clock}!",
                        "May armadong mga kalaban sa {scene.clock}!",
                        "May engkuwentro! Mga kalaban sa {scene.clock}!",
                        "Tingnan ang {scene.clock}! May armadong kalaban!",
                        "Grupo ng kalaban sa {scene.clock}!",
                        "Banta sa {scene.clock}! Mga kalaban!",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_combat",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.tactical_spatial.hostile.coarse",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "Hostiles {scene.relative}!",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.tactical_spatial.hostile.coarse.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Hostiles {scene.relative}!",
                                        "Armed fighters {scene.relative}!",
                                        "Enemy movement {scene.relative}!",
                                        "Take cover, hostiles {scene.relative}!",
                                        "Gunfire expected {scene.relative}! Hostiles!",
                                        "Watch out {scene.relative}, armed hostiles!",
                                        "Enemy survivors spotted {scene.relative}!",
                                        "Contact {scene.relative}! Keep low!",
                                        "Check {scene.relative}! Hostiles advancing!",
                                        "Incoming attack {scene.relative}!",
                                    },
                                    ["TL"] = {
                                        "Mga kalaban {scene.relative}!",
                                        "May armadong mga tao {scene.relative}!",
                                        "Galaw ng kalaban {scene.relative}!",
                                        "Magtago, may mga kalaban {scene.relative}!",
                                        "Maghanda sa putukan {scene.relative}! Mga kalaban!",
                                        "Mag-ingat {scene.relative}, may mga armadong kalaban!",
                                        "May kalabang nakaligtas {scene.relative}!",
                                        "May kalaban {scene.relative}! Yumuko!",
                                        "Tingnan {scene.relative}! Sumusulong ang kalaban!",
                                        "Paparating na atake {scene.relative}!",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.tactical_spatial.hostile",
            ["textRoles"] = {
                {
                    ["fallback"] = "Hostiles {scene.relative}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.tactical_spatial.hostile.coarse.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Hostiles {scene.relative}!",
                            "Armed fighters {scene.relative}!",
                            "Enemy movement {scene.relative}!",
                            "Take cover, hostiles {scene.relative}!",
                            "Gunfire expected {scene.relative}! Hostiles!",
                            "Watch out {scene.relative}, armed hostiles!",
                            "Enemy survivors spotted {scene.relative}!",
                            "Contact {scene.relative}! Keep low!",
                            "Check {scene.relative}! Hostiles advancing!",
                            "Incoming attack {scene.relative}!",
                        },
                        ["TL"] = {
                            "Mga kalaban {scene.relative}!",
                            "May armadong mga tao {scene.relative}!",
                            "Galaw ng kalaban {scene.relative}!",
                            "Magtago, may mga kalaban {scene.relative}!",
                            "Maghanda sa putukan {scene.relative}! Mga kalaban!",
                            "Mag-ingat {scene.relative}, may mga armadong kalaban!",
                            "May kalabang nakaligtas {scene.relative}!",
                            "May kalaban {scene.relative}! Yumuko!",
                            "Tingnan {scene.relative}! Sumusulong ang kalaban!",
                            "Paparating na atake {scene.relative}!",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.tactical_spatial.hostile.coarse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "coarse",
            ["sourceId"] = "combat.tactical_spatial.hostile.coarse",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_combat/combat_tactical_spatial_hostile_coarse.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneCombat",
        ["namespace"] = "combat.tactical_spatial.hostile",
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
                ["responseAct"] = "REACT",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Hostiles {scene.relative}!",
                                        "Armed fighters {scene.relative}!",
                                        "Enemy movement {scene.relative}!",
                                        "Take cover, hostiles {scene.relative}!",
                                        "Gunfire expected {scene.relative}! Hostiles!",
                                        "Watch out {scene.relative}, armed hostiles!",
                                        "Enemy survivors spotted {scene.relative}!",
                                        "Contact {scene.relative}! Keep low!",
                                        "Check {scene.relative}! Hostiles advancing!",
                                        "Incoming attack {scene.relative}!",
                                    },
                                    ["TL"] = {
                                        "Mga kalaban {scene.relative}!",
                                        "May armadong mga tao {scene.relative}!",
                                        "Galaw ng kalaban {scene.relative}!",
                                        "Magtago, may mga kalaban {scene.relative}!",
                                        "Maghanda sa putukan {scene.relative}! Mga kalaban!",
                                        "Mag-ingat {scene.relative}, may mga armadong kalaban!",
                                        "May kalabang nakaligtas {scene.relative}!",
                                        "May kalaban {scene.relative}! Yumuko!",
                                        "Tingnan {scene.relative}! Sumusulong ang kalaban!",
                                        "Paparating na atake {scene.relative}!",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "combat.tactical_spatial.hostile.coarse",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Hostiles {scene.relative}!",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.tactical_spatial.hostile.coarse.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_combat/combat_tactical_spatial_hostile_coarse.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Hostiles {scene.relative}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.tactical_spatial.hostile.coarse.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Hostiles {scene.relative}!",
                        "Armed fighters {scene.relative}!",
                        "Enemy movement {scene.relative}!",
                        "Take cover, hostiles {scene.relative}!",
                        "Gunfire expected {scene.relative}! Hostiles!",
                        "Watch out {scene.relative}, armed hostiles!",
                        "Enemy survivors spotted {scene.relative}!",
                        "Contact {scene.relative}! Keep low!",
                        "Check {scene.relative}! Hostiles advancing!",
                        "Incoming attack {scene.relative}!",
                    },
                    ["TL"] = {
                        "Mga kalaban {scene.relative}!",
                        "May armadong mga tao {scene.relative}!",
                        "Galaw ng kalaban {scene.relative}!",
                        "Magtago, may mga kalaban {scene.relative}!",
                        "Maghanda sa putukan {scene.relative}! Mga kalaban!",
                        "Mag-ingat {scene.relative}, may mga armadong kalaban!",
                        "May kalabang nakaligtas {scene.relative}!",
                        "May kalaban {scene.relative}! Yumuko!",
                        "Tingnan {scene.relative}! Sumusulong ang kalaban!",
                        "Paparating na atake {scene.relative}!",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_combat",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.tactical_spatial.zombie.clock",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "Zombies, {scene.clock}!",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.tactical_spatial.zombie.clock.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Zombies, {scene.clock}!",
                                        "Dead coming in from {scene.clock}!",
                                        "Watch {scene.clock}, walkers spotted!",
                                        "Zombies at {scene.clock}! Get ready!",
                                        "Movement at {scene.clock}, it's dead heads!",
                                        "Incoming zombies from {scene.clock}!",
                                        "Eyes on {scene.clock}! Walkers approaching!",
                                        "Check {scene.clock}, we've got zombies!",
                                        "Zombies moving in fast at {scene.clock}!",
                                        "Target at {scene.clock}! Zombies!",
                                    },
                                    ["TL"] = {
                                        "Mga zombie, {scene.clock}!",
                                        "May mga patay na parating mula sa {scene.clock}!",
                                        "Bantayan ang {scene.clock}, may mga walker!",
                                        "Mga zombie sa {scene.clock}! Humanda!",
                                        "May galaw sa {scene.clock}, mga zombie 'yan!",
                                        "Paparating na mga zombie galing sa {scene.clock}!",
                                        "Tumingin sa {scene.clock}! May lumalapit na mga walker!",
                                        "Tingnan ang {scene.clock}, may mga zombie tayo!",
                                        "Mabilis na lumalapit ang mga zombie sa {scene.clock}!",
                                        "Puntirya sa {scene.clock}! Mga zombie!",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.tactical_spatial.zombie",
            ["textRoles"] = {
                {
                    ["fallback"] = "Zombies, {scene.clock}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.tactical_spatial.zombie.clock.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Zombies, {scene.clock}!",
                            "Dead coming in from {scene.clock}!",
                            "Watch {scene.clock}, walkers spotted!",
                            "Zombies at {scene.clock}! Get ready!",
                            "Movement at {scene.clock}, it's dead heads!",
                            "Incoming zombies from {scene.clock}!",
                            "Eyes on {scene.clock}! Walkers approaching!",
                            "Check {scene.clock}, we've got zombies!",
                            "Zombies moving in fast at {scene.clock}!",
                            "Target at {scene.clock}! Zombies!",
                        },
                        ["TL"] = {
                            "Mga zombie, {scene.clock}!",
                            "May mga patay na parating mula sa {scene.clock}!",
                            "Bantayan ang {scene.clock}, may mga walker!",
                            "Mga zombie sa {scene.clock}! Humanda!",
                            "May galaw sa {scene.clock}, mga zombie 'yan!",
                            "Paparating na mga zombie galing sa {scene.clock}!",
                            "Tumingin sa {scene.clock}! May lumalapit na mga walker!",
                            "Tingnan ang {scene.clock}, may mga zombie tayo!",
                            "Mabilis na lumalapit ang mga zombie sa {scene.clock}!",
                            "Puntirya sa {scene.clock}! Mga zombie!",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.tactical_spatial.zombie.clock",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "clock",
            ["sourceId"] = "combat.tactical_spatial.zombie.clock",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_combat/combat_tactical_spatial_zombie_clock.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneCombat",
        ["namespace"] = "combat.tactical_spatial.zombie",
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
                ["responseAct"] = "REACT",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Zombies, {scene.clock}!",
                                        "Dead coming in from {scene.clock}!",
                                        "Watch {scene.clock}, walkers spotted!",
                                        "Zombies at {scene.clock}! Get ready!",
                                        "Movement at {scene.clock}, it's dead heads!",
                                        "Incoming zombies from {scene.clock}!",
                                        "Eyes on {scene.clock}! Walkers approaching!",
                                        "Check {scene.clock}, we've got zombies!",
                                        "Zombies moving in fast at {scene.clock}!",
                                        "Target at {scene.clock}! Zombies!",
                                    },
                                    ["TL"] = {
                                        "Mga zombie, {scene.clock}!",
                                        "May mga patay na parating mula sa {scene.clock}!",
                                        "Bantayan ang {scene.clock}, may mga walker!",
                                        "Mga zombie sa {scene.clock}! Humanda!",
                                        "May galaw sa {scene.clock}, mga zombie 'yan!",
                                        "Paparating na mga zombie galing sa {scene.clock}!",
                                        "Tumingin sa {scene.clock}! May lumalapit na mga walker!",
                                        "Tingnan ang {scene.clock}, may mga zombie tayo!",
                                        "Mabilis na lumalapit ang mga zombie sa {scene.clock}!",
                                        "Puntirya sa {scene.clock}! Mga zombie!",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "combat.tactical_spatial.zombie.clock",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Zombies, {scene.clock}!",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.tactical_spatial.zombie.clock.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_combat/combat_tactical_spatial_zombie_clock.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Zombies, {scene.clock}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.tactical_spatial.zombie.clock.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Zombies, {scene.clock}!",
                        "Dead coming in from {scene.clock}!",
                        "Watch {scene.clock}, walkers spotted!",
                        "Zombies at {scene.clock}! Get ready!",
                        "Movement at {scene.clock}, it's dead heads!",
                        "Incoming zombies from {scene.clock}!",
                        "Eyes on {scene.clock}! Walkers approaching!",
                        "Check {scene.clock}, we've got zombies!",
                        "Zombies moving in fast at {scene.clock}!",
                        "Target at {scene.clock}! Zombies!",
                    },
                    ["TL"] = {
                        "Mga zombie, {scene.clock}!",
                        "May mga patay na parating mula sa {scene.clock}!",
                        "Bantayan ang {scene.clock}, may mga walker!",
                        "Mga zombie sa {scene.clock}! Humanda!",
                        "May galaw sa {scene.clock}, mga zombie 'yan!",
                        "Paparating na mga zombie galing sa {scene.clock}!",
                        "Tumingin sa {scene.clock}! May lumalapit na mga walker!",
                        "Tingnan ang {scene.clock}, may mga zombie tayo!",
                        "Mabilis na lumalapit ang mga zombie sa {scene.clock}!",
                        "Puntirya sa {scene.clock}! Mga zombie!",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_combat",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.tactical_spatial.zombie.coarse",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "Zombies {scene.relative}!",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.tactical_spatial.zombie.coarse.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Zombies {scene.relative}!",
                                        "Watch out, dead heads {scene.relative}!",
                                        "Walkers approaching {scene.relative}!",
                                        "Look {scene.relative}! Zombies!",
                                        "Incoming dead {scene.relative}!",
                                        "Zombies closing in {scene.relative}!",
                                        "Eyes {scene.relative}, we've got walkers!",
                                        "Dead heads spotted {scene.relative}!",
                                        "Check {scene.relative}! Swarm incoming!",
                                        "Danger {scene.relative}! Zombies!",
                                    },
                                    ["TL"] = {
                                        "Mga zombie {scene.relative}!",
                                        "Mag-ingat, may mga patay {scene.relative}!",
                                        "May mga walker na papalapit {scene.relative}!",
                                        "Tumingin {scene.relative}! Mga zombie!",
                                        "Paparating na mga patay {scene.relative}!",
                                        "Lumalapit ang mga zombie {scene.relative}!",
                                        "Tumingin {scene.relative}, may mga walker tayo!",
                                        "May nakitang mga zombie {scene.relative}!",
                                        "Suriin {scene.relative}! May paparating na kawan!",
                                        "Panganib {scene.relative}! Mga zombie!",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.tactical_spatial.zombie",
            ["textRoles"] = {
                {
                    ["fallback"] = "Zombies {scene.relative}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.tactical_spatial.zombie.coarse.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Zombies {scene.relative}!",
                            "Watch out, dead heads {scene.relative}!",
                            "Walkers approaching {scene.relative}!",
                            "Look {scene.relative}! Zombies!",
                            "Incoming dead {scene.relative}!",
                            "Zombies closing in {scene.relative}!",
                            "Eyes {scene.relative}, we've got walkers!",
                            "Dead heads spotted {scene.relative}!",
                            "Check {scene.relative}! Swarm incoming!",
                            "Danger {scene.relative}! Zombies!",
                        },
                        ["TL"] = {
                            "Mga zombie {scene.relative}!",
                            "Mag-ingat, may mga patay {scene.relative}!",
                            "May mga walker na papalapit {scene.relative}!",
                            "Tumingin {scene.relative}! Mga zombie!",
                            "Paparating na mga patay {scene.relative}!",
                            "Lumalapit ang mga zombie {scene.relative}!",
                            "Tumingin {scene.relative}, may mga walker tayo!",
                            "May nakitang mga zombie {scene.relative}!",
                            "Suriin {scene.relative}! May paparating na kawan!",
                            "Panganib {scene.relative}! Mga zombie!",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.tactical_spatial.zombie.coarse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "coarse",
            ["sourceId"] = "combat.tactical_spatial.zombie.coarse",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_combat/combat_tactical_spatial_zombie_coarse.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneCombat",
        ["namespace"] = "combat.tactical_spatial.zombie",
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
                ["responseAct"] = "REACT",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Zombies {scene.relative}!",
                                        "Watch out, dead heads {scene.relative}!",
                                        "Walkers approaching {scene.relative}!",
                                        "Look {scene.relative}! Zombies!",
                                        "Incoming dead {scene.relative}!",
                                        "Zombies closing in {scene.relative}!",
                                        "Eyes {scene.relative}, we've got walkers!",
                                        "Dead heads spotted {scene.relative}!",
                                        "Check {scene.relative}! Swarm incoming!",
                                        "Danger {scene.relative}! Zombies!",
                                    },
                                    ["TL"] = {
                                        "Mga zombie {scene.relative}!",
                                        "Mag-ingat, may mga patay {scene.relative}!",
                                        "May mga walker na papalapit {scene.relative}!",
                                        "Tumingin {scene.relative}! Mga zombie!",
                                        "Paparating na mga patay {scene.relative}!",
                                        "Lumalapit ang mga zombie {scene.relative}!",
                                        "Tumingin {scene.relative}, may mga walker tayo!",
                                        "May nakitang mga zombie {scene.relative}!",
                                        "Suriin {scene.relative}! May paparating na kawan!",
                                        "Panganib {scene.relative}! Mga zombie!",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "combat.tactical_spatial.zombie.coarse",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Zombies {scene.relative}!",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.tactical_spatial.zombie.coarse.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_combat/combat_tactical_spatial_zombie_coarse.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Zombies {scene.relative}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.tactical_spatial.zombie.coarse.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Zombies {scene.relative}!",
                        "Watch out, dead heads {scene.relative}!",
                        "Walkers approaching {scene.relative}!",
                        "Look {scene.relative}! Zombies!",
                        "Incoming dead {scene.relative}!",
                        "Zombies closing in {scene.relative}!",
                        "Eyes {scene.relative}, we've got walkers!",
                        "Dead heads spotted {scene.relative}!",
                        "Check {scene.relative}! Swarm incoming!",
                        "Danger {scene.relative}! Zombies!",
                    },
                    ["TL"] = {
                        "Mga zombie {scene.relative}!",
                        "Mag-ingat, may mga patay {scene.relative}!",
                        "May mga walker na papalapit {scene.relative}!",
                        "Tumingin {scene.relative}! Mga zombie!",
                        "Paparating na mga patay {scene.relative}!",
                        "Lumalapit ang mga zombie {scene.relative}!",
                        "Tumingin {scene.relative}, may mga walker tayo!",
                        "May nakitang mga zombie {scene.relative}!",
                        "Suriin {scene.relative}! May paparating na kawan!",
                        "Panganib {scene.relative}! Mga zombie!",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
