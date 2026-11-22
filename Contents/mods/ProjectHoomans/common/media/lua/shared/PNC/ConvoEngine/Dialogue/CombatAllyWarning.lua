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
                                ["fallback"] = "Heads up—{target.name} closing in {scene.location}!",
                                ["id"] = "zombie_neutral",
                                ["templateID"] = "convo.combat.ally_warn.callout.say.1.zombie_neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Contact dead—{target.name} {scene.location}! Weapons up!",
                                ["id"] = "zombie_tactical",
                                ["templateID"] = "convo.combat.ally_warn.callout.say.1.zombie_tactical",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Drop them! {target.name} wandering {scene.location}!",
                                ["id"] = "zombie_hostile",
                                ["templateID"] = "convo.combat.ally_warn.callout.say.1.zombie_hostile",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Watch out—{target.name} spotted {scene.location}!",
                                ["id"] = "hostile_neutral",
                                ["templateID"] = "convo.combat.ally_warn.callout.say.1.hostile_neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Hostile contact! {target.name} {scene.location}, weapons ready!",
                                ["id"] = "hostile_tactical",
                                ["templateID"] = "convo.combat.ally_warn.callout.say.1.hostile_tactical",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Flush them out! Got {target.name} {scene.location}!",
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
                    ["fallback"] = "Heads up—{target.name} closing in {scene.location}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.ally_warn.callout.say.1.zombie_neutral",
                    ["variantID"] = "zombie_neutral",
                },
                {
                    ["fallback"] = "Contact dead—{target.name} {scene.location}! Weapons up!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.ally_warn.callout.say.1.zombie_tactical",
                    ["variantID"] = "zombie_tactical",
                },
                {
                    ["fallback"] = "Drop them! {target.name} wandering {scene.location}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.ally_warn.callout.say.1.zombie_hostile",
                    ["variantID"] = "zombie_hostile",
                },
                {
                    ["fallback"] = "Watch out—{target.name} spotted {scene.location}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.ally_warn.callout.say.1.hostile_neutral",
                    ["variantID"] = "hostile_neutral",
                },
                {
                    ["fallback"] = "Hostile contact! {target.name} {scene.location}, weapons ready!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.ally_warn.callout.say.1.hostile_tactical",
                    ["variantID"] = "hostile_tactical",
                },
                {
                    ["fallback"] = "Flush them out! Got {target.name} {scene.location}!",
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
                                ["fallback"] = "Heads up—{target.name} closing in {scene.location}!",
                                ["id"] = "zombie_neutral",
                            },
                            {
                                ["fallback"] = "Contact dead—{target.name} {scene.location}! Weapons up!",
                                ["id"] = "zombie_tactical",
                            },
                            {
                                ["fallback"] = "Drop them! {target.name} wandering {scene.location}!",
                                ["id"] = "zombie_hostile",
                            },
                            {
                                ["fallback"] = "Watch out—{target.name} spotted {scene.location}!",
                                ["id"] = "hostile_neutral",
                            },
                            {
                                ["fallback"] = "Hostile contact! {target.name} {scene.location}, weapons ready!",
                                ["id"] = "hostile_tactical",
                            },
                            {
                                ["fallback"] = "Flush them out! Got {target.name} {scene.location}!",
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
                            ["fallback"] = "Heads up—{target.name} closing in {scene.location}!",
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
                ["fallback"] = "Heads up—{target.name} closing in {scene.location}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.ally_warn.callout.say.1.zombie_neutral",
                ["variantID"] = "zombie_neutral",
            },
            {
                ["fallback"] = "Contact dead—{target.name} {scene.location}! Weapons up!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.ally_warn.callout.say.1.zombie_tactical",
                ["variantID"] = "zombie_tactical",
            },
            {
                ["fallback"] = "Drop them! {target.name} wandering {scene.location}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.ally_warn.callout.say.1.zombie_hostile",
                ["variantID"] = "zombie_hostile",
            },
            {
                ["fallback"] = "Watch out—{target.name} spotted {scene.location}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.ally_warn.callout.say.1.hostile_neutral",
                ["variantID"] = "hostile_neutral",
            },
            {
                ["fallback"] = "Hostile contact! {target.name} {scene.location}, weapons ready!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.ally_warn.callout.say.1.hostile_tactical",
                ["variantID"] = "hostile_tactical",
            },
            {
                ["fallback"] = "Flush them out! Got {target.name} {scene.location}!",
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
                                ["fallback"] = "I see {target.name} {scene.location}, {addressee.name}! Moving in!",
                                ["id"] = "engaging_neutral",
                                ["templateID"] = "convo.combat.ally_warn.reply.say.1.engaging_neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Visual confirmed on {target.name} {scene.location}, {addressee.name}—engaging!",
                                ["id"] = "engaging_tactical",
                                ["templateID"] = "convo.combat.ally_warn.reply.say.1.engaging_tactical",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Got {target.name} in my sights {scene.location}, {addressee.name}! Finishing this!",
                                ["id"] = "engaging_hostile",
                                ["templateID"] = "convo.combat.ally_warn.reply.say.1.engaging_hostile",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Heard you, {addressee.name}! Looking for {target.name} {scene.location} now!",
                                ["id"] = "alerted_neutral",
                                ["templateID"] = "convo.combat.ally_warn.reply.say.1.alerted_neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Copy contact, {addressee.name}! Scanning {scene.location} for {target.name}!",
                                ["id"] = "alerted_tactical",
                                ["templateID"] = "convo.combat.ally_warn.reply.say.1.alerted_tactical",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Keep {target.name} busy, {addressee.name}! Coming {scene.location} now!",
                                ["id"] = "alerted_hostile",
                                ["templateID"] = "convo.combat.ally_warn.reply.say.1.alerted_hostile",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Whoa, {addressee.name}, keeping clear of {target.name} {scene.location}!",
                                ["id"] = "defensive_neutral",
                                ["templateID"] = "convo.combat.ally_warn.reply.say.1.defensive_neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Be careful with {target.name} {scene.location}, {addressee.name}—I'm staying back!",
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
                    ["fallback"] = "I see {target.name} {scene.location}, {addressee.name}! Moving in!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.ally_warn.reply.say.1.engaging_neutral",
                    ["variantID"] = "engaging_neutral",
                },
                {
                    ["fallback"] = "Visual confirmed on {target.name} {scene.location}, {addressee.name}—engaging!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.ally_warn.reply.say.1.engaging_tactical",
                    ["variantID"] = "engaging_tactical",
                },
                {
                    ["fallback"] = "Got {target.name} in my sights {scene.location}, {addressee.name}! Finishing this!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.ally_warn.reply.say.1.engaging_hostile",
                    ["variantID"] = "engaging_hostile",
                },
                {
                    ["fallback"] = "Heard you, {addressee.name}! Looking for {target.name} {scene.location} now!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.ally_warn.reply.say.1.alerted_neutral",
                    ["variantID"] = "alerted_neutral",
                },
                {
                    ["fallback"] = "Copy contact, {addressee.name}! Scanning {scene.location} for {target.name}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.ally_warn.reply.say.1.alerted_tactical",
                    ["variantID"] = "alerted_tactical",
                },
                {
                    ["fallback"] = "Keep {target.name} busy, {addressee.name}! Coming {scene.location} now!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.ally_warn.reply.say.1.alerted_hostile",
                    ["variantID"] = "alerted_hostile",
                },
                {
                    ["fallback"] = "Whoa, {addressee.name}, keeping clear of {target.name} {scene.location}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.ally_warn.reply.say.1.defensive_neutral",
                    ["variantID"] = "defensive_neutral",
                },
                {
                    ["fallback"] = "Be careful with {target.name} {scene.location}, {addressee.name}—I'm staying back!",
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
                                ["fallback"] = "I see {target.name} {scene.location}, {addressee.name}! Moving in!",
                                ["id"] = "engaging_neutral",
                            },
                            {
                                ["fallback"] = "Visual confirmed on {target.name} {scene.location}, {addressee.name}—engaging!",
                                ["id"] = "engaging_tactical",
                            },
                            {
                                ["fallback"] = "Got {target.name} in my sights {scene.location}, {addressee.name}! Finishing this!",
                                ["id"] = "engaging_hostile",
                            },
                            {
                                ["fallback"] = "Heard you, {addressee.name}! Looking for {target.name} {scene.location} now!",
                                ["id"] = "alerted_neutral",
                            },
                            {
                                ["fallback"] = "Copy contact, {addressee.name}! Scanning {scene.location} for {target.name}!",
                                ["id"] = "alerted_tactical",
                            },
                            {
                                ["fallback"] = "Keep {target.name} busy, {addressee.name}! Coming {scene.location} now!",
                                ["id"] = "alerted_hostile",
                            },
                            {
                                ["fallback"] = "Whoa, {addressee.name}, keeping clear of {target.name} {scene.location}!",
                                ["id"] = "defensive_neutral",
                            },
                            {
                                ["fallback"] = "Be careful with {target.name} {scene.location}, {addressee.name}—I'm staying back!",
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
                            ["fallback"] = "I see {target.name} {scene.location}, {addressee.name}! Moving in!",
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
                ["fallback"] = "I see {target.name} {scene.location}, {addressee.name}! Moving in!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.ally_warn.reply.say.1.engaging_neutral",
                ["variantID"] = "engaging_neutral",
            },
            {
                ["fallback"] = "Visual confirmed on {target.name} {scene.location}, {addressee.name}—engaging!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.ally_warn.reply.say.1.engaging_tactical",
                ["variantID"] = "engaging_tactical",
            },
            {
                ["fallback"] = "Got {target.name} in my sights {scene.location}, {addressee.name}! Finishing this!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.ally_warn.reply.say.1.engaging_hostile",
                ["variantID"] = "engaging_hostile",
            },
            {
                ["fallback"] = "Heard you, {addressee.name}! Looking for {target.name} {scene.location} now!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.ally_warn.reply.say.1.alerted_neutral",
                ["variantID"] = "alerted_neutral",
            },
            {
                ["fallback"] = "Copy contact, {addressee.name}! Scanning {scene.location} for {target.name}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.ally_warn.reply.say.1.alerted_tactical",
                ["variantID"] = "alerted_tactical",
            },
            {
                ["fallback"] = "Keep {target.name} busy, {addressee.name}! Coming {scene.location} now!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.ally_warn.reply.say.1.alerted_hostile",
                ["variantID"] = "alerted_hostile",
            },
            {
                ["fallback"] = "Whoa, {addressee.name}, keeping clear of {target.name} {scene.location}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.ally_warn.reply.say.1.defensive_neutral",
                ["variantID"] = "defensive_neutral",
            },
            {
                ["fallback"] = "Be careful with {target.name} {scene.location}, {addressee.name}—I'm staying back!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.ally_warn.reply.say.1.defensive_shaken",
                ["variantID"] = "defensive_shaken",
            },
        },
        ["when"] = nil,
    },
}
