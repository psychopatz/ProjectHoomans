-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_ally_warning",
        ["domainPath"] = "combat_ally_warning",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.ally_warn.callout",
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
                                ["fallback"] = "Heads up, dead ones closing in!",
                                ["id"] = "zombie_neutral",
                                ["templateID"] = "convo.combat.ally_warn.callout.say.1.zombie_neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Visual on infected! Weapons up!",
                                ["id"] = "zombie_tactical",
                                ["templateID"] = "convo.combat.ally_warn.callout.say.1.zombie_tactical",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Dead meat wandering into our turf! Drop them!",
                                ["id"] = "zombie_hostile",
                                ["templateID"] = "convo.combat.ally_warn.callout.say.1.zombie_hostile",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Watch out, hostile target spotted!",
                                ["id"] = "hostile_neutral",
                                ["templateID"] = "convo.combat.ally_warn.callout.say.1.hostile_neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Hostile contact spotted! Weapons ready!",
                                ["id"] = "hostile_tactical",
                                ["templateID"] = "convo.combat.ally_warn.callout.say.1.hostile_tactical",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Got an intruder! Flush them out!",
                                ["id"] = "hostile_hostile",
                                ["templateID"] = "convo.combat.ally_warn.callout.say.1.hostile_hostile",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.ally_warn",
            ["textRoles"] = {
                {
                    ["fallback"] = "Heads up, dead ones closing in!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.ally_warn.callout.say.1.zombie_neutral",
                    ["variantID"] = "zombie_neutral",
                },
                {
                    ["fallback"] = "Visual on infected! Weapons up!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.ally_warn.callout.say.1.zombie_tactical",
                    ["variantID"] = "zombie_tactical",
                },
                {
                    ["fallback"] = "Dead meat wandering into our turf! Drop them!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.ally_warn.callout.say.1.zombie_hostile",
                    ["variantID"] = "zombie_hostile",
                },
                {
                    ["fallback"] = "Watch out, hostile target spotted!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.ally_warn.callout.say.1.hostile_neutral",
                    ["variantID"] = "hostile_neutral",
                },
                {
                    ["fallback"] = "Hostile contact spotted! Weapons ready!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.ally_warn.callout.say.1.hostile_tactical",
                    ["variantID"] = "hostile_tactical",
                },
                {
                    ["fallback"] = "Got an intruder! Flush them out!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.ally_warn.callout.say.1.hostile_hostile",
                    ["variantID"] = "hostile_hostile",
                },
            },
        },
        ["id"] = "combat.ally_warn.callout",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "callout",
            ["sourceId"] = "combat.ally_warn.callout",
            ["sourcePath"] = "dialogue/combat_ally_warning/combat_ally_warn_callout.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatAllyWarning",
        ["namespace"] = "combat.ally_warn",
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
            ["domains"] = {
                {
                    ["domain"] = "combat",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["events"] = {
                {
                    ["id"] = "combat_event",
                    ["kind"] = "combat_event",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:event_reactions",
                ["contentOwner"] = "projecthoomans.dialogue_content.events",
                ["responseAct"] = "WARN",
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
                                ["fallback"] = "Heads up, dead ones closing in!",
                                ["id"] = "zombie_neutral",
                            },
                            {
                                ["fallback"] = "Visual on infected! Weapons up!",
                                ["id"] = "zombie_tactical",
                            },
                            {
                                ["fallback"] = "Dead meat wandering into our turf! Drop them!",
                                ["id"] = "zombie_hostile",
                            },
                            {
                                ["fallback"] = "Watch out, hostile target spotted!",
                                ["id"] = "hostile_neutral",
                            },
                            {
                                ["fallback"] = "Hostile contact spotted! Weapons ready!",
                                ["id"] = "hostile_tactical",
                            },
                            {
                                ["fallback"] = "Got an intruder! Flush them out!",
                                ["id"] = "hostile_hostile",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "combat",
                    ["id"] = "combat_reaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "WARN",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "combat.ally_warn.callout",
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
                            ["fallback"] = "Heads up, dead ones closing in!",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.ally_warn.callout.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/combat_ally_warning/combat_ally_warn_callout.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Heads up, dead ones closing in!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.ally_warn.callout.say.1.zombie_neutral",
                ["variantID"] = "zombie_neutral",
            },
            {
                ["fallback"] = "Visual on infected! Weapons up!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.ally_warn.callout.say.1.zombie_tactical",
                ["variantID"] = "zombie_tactical",
            },
            {
                ["fallback"] = "Dead meat wandering into our turf! Drop them!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.ally_warn.callout.say.1.zombie_hostile",
                ["variantID"] = "zombie_hostile",
            },
            {
                ["fallback"] = "Watch out, hostile target spotted!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.ally_warn.callout.say.1.hostile_neutral",
                ["variantID"] = "hostile_neutral",
            },
            {
                ["fallback"] = "Hostile contact spotted! Weapons ready!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.ally_warn.callout.say.1.hostile_tactical",
                ["variantID"] = "hostile_tactical",
            },
            {
                ["fallback"] = "Got an intruder! Flush them out!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.ally_warn.callout.say.1.hostile_hostile",
                ["variantID"] = "hostile_hostile",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_ally_warning",
        ["domainPath"] = "combat_ally_warning",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.ally_warn.reply",
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
                                ["fallback"] = "I see them! Moving in!",
                                ["id"] = "engaging_neutral",
                                ["templateID"] = "convo.combat.ally_warn.reply.say.1.engaging_neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Visual confirmed, engaging target!",
                                ["id"] = "engaging_tactical",
                                ["templateID"] = "convo.combat.ally_warn.reply.say.1.engaging_tactical",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Got 'em in my sights! Moving to finish it!",
                                ["id"] = "engaging_hostile",
                                ["templateID"] = "convo.combat.ally_warn.reply.say.1.engaging_hostile",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Heard you! Looking around now!",
                                ["id"] = "alerted_neutral",
                                ["templateID"] = "convo.combat.ally_warn.reply.say.1.alerted_neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Copy contact, scanning your sector!",
                                ["id"] = "alerted_tactical",
                                ["templateID"] = "convo.combat.ally_warn.reply.say.1.alerted_tactical",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Where are they?! Coming to back you up!",
                                ["id"] = "alerted_hostile",
                                ["templateID"] = "convo.combat.ally_warn.reply.say.1.alerted_hostile",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Whoa, staying clear! Watch out!",
                                ["id"] = "defensive_neutral",
                                ["templateID"] = "convo.combat.ally_warn.reply.say.1.defensive_neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Oh no—watching out, stay safe!",
                                ["id"] = "defensive_shaken",
                                ["templateID"] = "convo.combat.ally_warn.reply.say.1.defensive_shaken",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.ally_warn",
            ["textRoles"] = {
                {
                    ["fallback"] = "I see them! Moving in!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.ally_warn.reply.say.1.engaging_neutral",
                    ["variantID"] = "engaging_neutral",
                },
                {
                    ["fallback"] = "Visual confirmed, engaging target!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.ally_warn.reply.say.1.engaging_tactical",
                    ["variantID"] = "engaging_tactical",
                },
                {
                    ["fallback"] = "Got 'em in my sights! Moving to finish it!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.ally_warn.reply.say.1.engaging_hostile",
                    ["variantID"] = "engaging_hostile",
                },
                {
                    ["fallback"] = "Heard you! Looking around now!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.ally_warn.reply.say.1.alerted_neutral",
                    ["variantID"] = "alerted_neutral",
                },
                {
                    ["fallback"] = "Copy contact, scanning your sector!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.ally_warn.reply.say.1.alerted_tactical",
                    ["variantID"] = "alerted_tactical",
                },
                {
                    ["fallback"] = "Where are they?! Coming to back you up!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.ally_warn.reply.say.1.alerted_hostile",
                    ["variantID"] = "alerted_hostile",
                },
                {
                    ["fallback"] = "Whoa, staying clear! Watch out!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.ally_warn.reply.say.1.defensive_neutral",
                    ["variantID"] = "defensive_neutral",
                },
                {
                    ["fallback"] = "Oh no—watching out, stay safe!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.ally_warn.reply.say.1.defensive_shaken",
                    ["variantID"] = "defensive_shaken",
                },
            },
        },
        ["id"] = "combat.ally_warn.reply",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "reply",
            ["sourceId"] = "combat.ally_warn.reply",
            ["sourcePath"] = "dialogue/combat_ally_warning/combat_ally_warn_reply.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatAllyWarning",
        ["namespace"] = "combat.ally_warn",
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
            ["domains"] = {
                {
                    ["domain"] = "combat",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["events"] = {
                {
                    ["id"] = "combat_event",
                    ["kind"] = "combat_event",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:event_reactions",
                ["contentOwner"] = "projecthoomans.dialogue_content.events",
                ["responseAct"] = "ACK",
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
                                ["fallback"] = "I see them! Moving in!",
                                ["id"] = "engaging_neutral",
                            },
                            {
                                ["fallback"] = "Visual confirmed, engaging target!",
                                ["id"] = "engaging_tactical",
                            },
                            {
                                ["fallback"] = "Got 'em in my sights! Moving to finish it!",
                                ["id"] = "engaging_hostile",
                            },
                            {
                                ["fallback"] = "Heard you! Looking around now!",
                                ["id"] = "alerted_neutral",
                            },
                            {
                                ["fallback"] = "Copy contact, scanning your sector!",
                                ["id"] = "alerted_tactical",
                            },
                            {
                                ["fallback"] = "Where are they?! Coming to back you up!",
                                ["id"] = "alerted_hostile",
                            },
                            {
                                ["fallback"] = "Whoa, staying clear! Watch out!",
                                ["id"] = "defensive_neutral",
                            },
                            {
                                ["fallback"] = "Oh no—watching out, stay safe!",
                                ["id"] = "defensive_shaken",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "combat",
                    ["id"] = "combat_reaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "ACK",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "combat.ally_warn.reply",
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
                            ["fallback"] = "I see them! Moving in!",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.ally_warn.reply.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/combat_ally_warning/combat_ally_warn_reply.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I see them! Moving in!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.ally_warn.reply.say.1.engaging_neutral",
                ["variantID"] = "engaging_neutral",
            },
            {
                ["fallback"] = "Visual confirmed, engaging target!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.ally_warn.reply.say.1.engaging_tactical",
                ["variantID"] = "engaging_tactical",
            },
            {
                ["fallback"] = "Got 'em in my sights! Moving to finish it!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.ally_warn.reply.say.1.engaging_hostile",
                ["variantID"] = "engaging_hostile",
            },
            {
                ["fallback"] = "Heard you! Looking around now!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.ally_warn.reply.say.1.alerted_neutral",
                ["variantID"] = "alerted_neutral",
            },
            {
                ["fallback"] = "Copy contact, scanning your sector!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.ally_warn.reply.say.1.alerted_tactical",
                ["variantID"] = "alerted_tactical",
            },
            {
                ["fallback"] = "Where are they?! Coming to back you up!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.ally_warn.reply.say.1.alerted_hostile",
                ["variantID"] = "alerted_hostile",
            },
            {
                ["fallback"] = "Whoa, staying clear! Watch out!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.ally_warn.reply.say.1.defensive_neutral",
                ["variantID"] = "defensive_neutral",
            },
            {
                ["fallback"] = "Oh no—watching out, stay safe!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.ally_warn.reply.say.1.defensive_shaken",
                ["variantID"] = "defensive_shaken",
            },
        },
        ["when"] = nil,
    },
}
