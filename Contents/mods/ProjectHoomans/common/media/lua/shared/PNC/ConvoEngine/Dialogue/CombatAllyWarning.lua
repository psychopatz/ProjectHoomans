-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_ally_warning",
        ["domainPath"] = "combat_ally_warning",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.callout.reply_alerted",
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
                                ["fallback"] = "Heard you, {addressee.name}! Looking for {target.name} {scene.location} now!",
                                ["id"] = "alerted_neutral",
                                ["templateID"] = "convo.combat.callout.reply_alerted.say.1.alerted_neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Copy contact, {addressee.name}! Scanning for {target.name} {scene.location}!",
                                ["id"] = "alerted_tactical",
                                ["templateID"] = "convo.combat.callout.reply_alerted.say.1.alerted_tactical",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Keep {target.name} busy {scene.location}, {addressee.name}! Coming over now!",
                                ["id"] = "alerted_hostile",
                                ["templateID"] = "convo.combat.callout.reply_alerted.say.1.alerted_hostile",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Whoa, good catch, {addressee.name}! I'm on it!",
                                ["id"] = "blindside_reply",
                                ["templateID"] = "convo.combat.callout.reply_alerted.say.1.blindside_reply",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Finish it off, {addressee.name}, I've got your back!",
                                ["id"] = "last_one_reply",
                                ["templateID"] = "convo.combat.callout.reply_alerted.say.1.last_one_reply",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.callout",
            ["textRoles"] = {
                {
                    ["fallback"] = "Heard you, {addressee.name}! Looking for {target.name} {scene.location} now!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.reply_alerted.say.1.alerted_neutral",
                    ["variantID"] = "alerted_neutral",
                },
                {
                    ["fallback"] = "Copy contact, {addressee.name}! Scanning for {target.name} {scene.location}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.reply_alerted.say.1.alerted_tactical",
                    ["variantID"] = "alerted_tactical",
                },
                {
                    ["fallback"] = "Keep {target.name} busy {scene.location}, {addressee.name}! Coming over now!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.reply_alerted.say.1.alerted_hostile",
                    ["variantID"] = "alerted_hostile",
                },
                {
                    ["fallback"] = "Whoa, good catch, {addressee.name}! I'm on it!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.reply_alerted.say.1.blindside_reply",
                    ["variantID"] = "blindside_reply",
                },
                {
                    ["fallback"] = "Finish it off, {addressee.name}, I've got your back!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.reply_alerted.say.1.last_one_reply",
                    ["variantID"] = "last_one_reply",
                },
            },
        },
        ["id"] = "combat.callout.reply_alerted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "reply_alerted",
            ["sourceId"] = "combat.callout.reply_alerted",
            ["sourcePath"] = "dialogue/combat_ally_warning/combat_callout_reply_alerted.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatAllyWarning",
        ["namespace"] = "combat.callout",
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
                                ["fallback"] = "Heard you, {addressee.name}! Looking for {target.name} {scene.location} now!",
                                ["id"] = "alerted_neutral",
                            },
                            {
                                ["fallback"] = "Copy contact, {addressee.name}! Scanning for {target.name} {scene.location}!",
                                ["id"] = "alerted_tactical",
                            },
                            {
                                ["fallback"] = "Keep {target.name} busy {scene.location}, {addressee.name}! Coming over now!",
                                ["id"] = "alerted_hostile",
                            },
                            {
                                ["fallback"] = "Whoa, good catch, {addressee.name}! I'm on it!",
                                ["id"] = "blindside_reply",
                            },
                            {
                                ["fallback"] = "Finish it off, {addressee.name}, I've got your back!",
                                ["id"] = "last_one_reply",
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
            ["responsePlanID"] = "combat.callout.reply_alerted",
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
                            ["fallback"] = "Heard you, {addressee.name}! Looking for {target.name} {scene.location} now!",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.callout.reply_alerted.say_1",
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
        ["sourceShard"] = "dialogue/combat_ally_warning/combat_callout_reply_alerted.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Heard you, {addressee.name}! Looking for {target.name} {scene.location} now!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.reply_alerted.say.1.alerted_neutral",
                ["variantID"] = "alerted_neutral",
            },
            {
                ["fallback"] = "Copy contact, {addressee.name}! Scanning for {target.name} {scene.location}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.reply_alerted.say.1.alerted_tactical",
                ["variantID"] = "alerted_tactical",
            },
            {
                ["fallback"] = "Keep {target.name} busy {scene.location}, {addressee.name}! Coming over now!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.reply_alerted.say.1.alerted_hostile",
                ["variantID"] = "alerted_hostile",
            },
            {
                ["fallback"] = "Whoa, good catch, {addressee.name}! I'm on it!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.reply_alerted.say.1.blindside_reply",
                ["variantID"] = "blindside_reply",
            },
            {
                ["fallback"] = "Finish it off, {addressee.name}, I've got your back!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.reply_alerted.say.1.last_one_reply",
                ["variantID"] = "last_one_reply",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_ally_warning",
        ["domainPath"] = "combat_ally_warning",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.callout.reply_defensive",
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
                                ["fallback"] = "Whoa, {addressee.name}, keeping clear of {target.name} {scene.location}!",
                                ["id"] = "defensive_neutral",
                                ["templateID"] = "convo.combat.callout.reply_defensive.say.1.defensive_neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Be careful with {target.name} {scene.location}, {addressee.name}, I'm staying back!",
                                ["id"] = "defensive_shaken",
                                ["templateID"] = "convo.combat.callout.reply_defensive.say.1.defensive_shaken",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "You handle {target.name}, {addressee.name}! I'm staying clear!",
                                ["id"] = "wingman_defensive",
                                ["templateID"] = "convo.combat.callout.reply_defensive.say.1.wingman_defensive",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.callout",
            ["textRoles"] = {
                {
                    ["fallback"] = "Whoa, {addressee.name}, keeping clear of {target.name} {scene.location}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.reply_defensive.say.1.defensive_neutral",
                    ["variantID"] = "defensive_neutral",
                },
                {
                    ["fallback"] = "Be careful with {target.name} {scene.location}, {addressee.name}, I'm staying back!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.reply_defensive.say.1.defensive_shaken",
                    ["variantID"] = "defensive_shaken",
                },
                {
                    ["fallback"] = "You handle {target.name}, {addressee.name}! I'm staying clear!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.reply_defensive.say.1.wingman_defensive",
                    ["variantID"] = "wingman_defensive",
                },
            },
        },
        ["id"] = "combat.callout.reply_defensive",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "reply_defensive",
            ["sourceId"] = "combat.callout.reply_defensive",
            ["sourcePath"] = "dialogue/combat_ally_warning/combat_callout_reply_defensive.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatAllyWarning",
        ["namespace"] = "combat.callout",
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
                                ["fallback"] = "Whoa, {addressee.name}, keeping clear of {target.name} {scene.location}!",
                                ["id"] = "defensive_neutral",
                            },
                            {
                                ["fallback"] = "Be careful with {target.name} {scene.location}, {addressee.name}, I'm staying back!",
                                ["id"] = "defensive_shaken",
                            },
                            {
                                ["fallback"] = "You handle {target.name}, {addressee.name}! I'm staying clear!",
                                ["id"] = "wingman_defensive",
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
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "combat.callout.reply_defensive",
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
                            ["fallback"] = "Whoa, {addressee.name}, keeping clear of {target.name} {scene.location}!",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.callout.reply_defensive.say_1",
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
        ["sourceShard"] = "dialogue/combat_ally_warning/combat_callout_reply_defensive.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Whoa, {addressee.name}, keeping clear of {target.name} {scene.location}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.reply_defensive.say.1.defensive_neutral",
                ["variantID"] = "defensive_neutral",
            },
            {
                ["fallback"] = "Be careful with {target.name} {scene.location}, {addressee.name}, I'm staying back!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.reply_defensive.say.1.defensive_shaken",
                ["variantID"] = "defensive_shaken",
            },
            {
                ["fallback"] = "You handle {target.name}, {addressee.name}! I'm staying clear!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.reply_defensive.say.1.wingman_defensive",
                ["variantID"] = "wingman_defensive",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_ally_warning",
        ["domainPath"] = "combat_ally_warning",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.callout.reply_engage",
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
                                ["templateID"] = "convo.combat.callout.reply_engage.say.1.engaging_neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Visual confirmed on {target.name} {scene.location}, {addressee.name}, engaging!",
                                ["id"] = "engaging_tactical",
                                ["templateID"] = "convo.combat.callout.reply_engage.say.1.engaging_tactical",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Got {target.name} in my sights {scene.location}, {addressee.name}! Finishing this!",
                                ["id"] = "engaging_hostile",
                                ["templateID"] = "convo.combat.callout.reply_engage.say.1.engaging_hostile",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Oh shit, {addressee.name}, {target.name}?! Stay right by me!",
                                ["id"] = "engaging_shaken",
                                ["templateID"] = "convo.combat.callout.reply_engage.say.1.engaging_shaken",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 3,
                            },
                            {
                                ["fallback"] = "I'm ready, {addressee.name}. Let's drop {target.name}.",
                                ["id"] = "engaging_brave",
                                ["templateID"] = "convo.combat.callout.reply_engage.say.1.engaging_brave",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 3,
                            },
                            {
                                ["fallback"] = "Hell yeah, {addressee.name}, save {target.name} for me!",
                                ["id"] = "engaging_aggressive",
                                ["templateID"] = "convo.combat.callout.reply_engage.say.1.engaging_aggressive",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 3,
                            },
                            {
                                ["fallback"] = "Stay behind me if it gets ugly, {addressee.name}!",
                                ["id"] = "engaging_supportive",
                                ["templateID"] = "convo.combat.callout.reply_engage.say.1.engaging_supportive",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 3,
                            },
                            {
                                ["fallback"] = "I'm beat, {addressee.name}, but I'll still watch your flank.",
                                ["id"] = "engaging_exhausted",
                                ["templateID"] = "convo.combat.callout.reply_engage.say.1.engaging_exhausted",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 3,
                            },
                            {
                                ["fallback"] = "I've got the rear covered, {addressee.name}!",
                                ["id"] = "anchor_combat",
                                ["templateID"] = "convo.combat.callout.reply_engage.say.1.anchor_combat",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Rear guard set, {addressee.name}, push forward!",
                                ["id"] = "anchor_tactical",
                                ["templateID"] = "convo.combat.callout.reply_engage.say.1.anchor_tactical",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.callout",
            ["textRoles"] = {
                {
                    ["fallback"] = "I see {target.name} {scene.location}, {addressee.name}! Moving in!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.reply_engage.say.1.engaging_neutral",
                    ["variantID"] = "engaging_neutral",
                },
                {
                    ["fallback"] = "Visual confirmed on {target.name} {scene.location}, {addressee.name}, engaging!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.reply_engage.say.1.engaging_tactical",
                    ["variantID"] = "engaging_tactical",
                },
                {
                    ["fallback"] = "Got {target.name} in my sights {scene.location}, {addressee.name}! Finishing this!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.reply_engage.say.1.engaging_hostile",
                    ["variantID"] = "engaging_hostile",
                },
                {
                    ["fallback"] = "Oh shit, {addressee.name}, {target.name}?! Stay right by me!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.reply_engage.say.1.engaging_shaken",
                    ["variantID"] = "engaging_shaken",
                },
                {
                    ["fallback"] = "I'm ready, {addressee.name}. Let's drop {target.name}.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.reply_engage.say.1.engaging_brave",
                    ["variantID"] = "engaging_brave",
                },
                {
                    ["fallback"] = "Hell yeah, {addressee.name}, save {target.name} for me!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.reply_engage.say.1.engaging_aggressive",
                    ["variantID"] = "engaging_aggressive",
                },
                {
                    ["fallback"] = "Stay behind me if it gets ugly, {addressee.name}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.reply_engage.say.1.engaging_supportive",
                    ["variantID"] = "engaging_supportive",
                },
                {
                    ["fallback"] = "I'm beat, {addressee.name}, but I'll still watch your flank.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.reply_engage.say.1.engaging_exhausted",
                    ["variantID"] = "engaging_exhausted",
                },
                {
                    ["fallback"] = "I've got the rear covered, {addressee.name}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.reply_engage.say.1.anchor_combat",
                    ["variantID"] = "anchor_combat",
                },
                {
                    ["fallback"] = "Rear guard set, {addressee.name}, push forward!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.reply_engage.say.1.anchor_tactical",
                    ["variantID"] = "anchor_tactical",
                },
            },
        },
        ["id"] = "combat.callout.reply_engage",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "reply_engage",
            ["sourceId"] = "combat.callout.reply_engage",
            ["sourcePath"] = "dialogue/combat_ally_warning/combat_callout_reply_engage.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatAllyWarning",
        ["namespace"] = "combat.callout",
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
                                ["fallback"] = "Visual confirmed on {target.name} {scene.location}, {addressee.name}, engaging!",
                                ["id"] = "engaging_tactical",
                            },
                            {
                                ["fallback"] = "Got {target.name} in my sights {scene.location}, {addressee.name}! Finishing this!",
                                ["id"] = "engaging_hostile",
                            },
                            {
                                ["fallback"] = "Oh shit, {addressee.name}, {target.name}?! Stay right by me!",
                                ["id"] = "engaging_shaken",
                            },
                            {
                                ["fallback"] = "I'm ready, {addressee.name}. Let's drop {target.name}.",
                                ["id"] = "engaging_brave",
                            },
                            {
                                ["fallback"] = "Hell yeah, {addressee.name}, save {target.name} for me!",
                                ["id"] = "engaging_aggressive",
                            },
                            {
                                ["fallback"] = "Stay behind me if it gets ugly, {addressee.name}!",
                                ["id"] = "engaging_supportive",
                            },
                            {
                                ["fallback"] = "I'm beat, {addressee.name}, but I'll still watch your flank.",
                                ["id"] = "engaging_exhausted",
                            },
                            {
                                ["fallback"] = "I've got the rear covered, {addressee.name}!",
                                ["id"] = "anchor_combat",
                            },
                            {
                                ["fallback"] = "Rear guard set, {addressee.name}, push forward!",
                                ["id"] = "anchor_tactical",
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
            ["responsePlanID"] = "combat.callout.reply_engage",
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
                            ["templateID"] = "convo.combat.callout.reply_engage.say_1",
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
        ["sourceShard"] = "dialogue/combat_ally_warning/combat_callout_reply_engage.json",
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
                ["templateID"] = "convo.combat.callout.reply_engage.say.1.engaging_neutral",
                ["variantID"] = "engaging_neutral",
            },
            {
                ["fallback"] = "Visual confirmed on {target.name} {scene.location}, {addressee.name}, engaging!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.reply_engage.say.1.engaging_tactical",
                ["variantID"] = "engaging_tactical",
            },
            {
                ["fallback"] = "Got {target.name} in my sights {scene.location}, {addressee.name}! Finishing this!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.reply_engage.say.1.engaging_hostile",
                ["variantID"] = "engaging_hostile",
            },
            {
                ["fallback"] = "Oh shit, {addressee.name}, {target.name}?! Stay right by me!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.reply_engage.say.1.engaging_shaken",
                ["variantID"] = "engaging_shaken",
            },
            {
                ["fallback"] = "I'm ready, {addressee.name}. Let's drop {target.name}.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.reply_engage.say.1.engaging_brave",
                ["variantID"] = "engaging_brave",
            },
            {
                ["fallback"] = "Hell yeah, {addressee.name}, save {target.name} for me!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.reply_engage.say.1.engaging_aggressive",
                ["variantID"] = "engaging_aggressive",
            },
            {
                ["fallback"] = "Stay behind me if it gets ugly, {addressee.name}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.reply_engage.say.1.engaging_supportive",
                ["variantID"] = "engaging_supportive",
            },
            {
                ["fallback"] = "I'm beat, {addressee.name}, but I'll still watch your flank.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.reply_engage.say.1.engaging_exhausted",
                ["variantID"] = "engaging_exhausted",
            },
            {
                ["fallback"] = "I've got the rear covered, {addressee.name}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.reply_engage.say.1.anchor_combat",
                ["variantID"] = "anchor_combat",
            },
            {
                ["fallback"] = "Rear guard set, {addressee.name}, push forward!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.reply_engage.say.1.anchor_tactical",
                ["variantID"] = "anchor_tactical",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_ally_warning",
        ["domainPath"] = "combat_ally_warning",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.callout.reply_wingman",
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
                                ["fallback"] = "Right behind you, {addressee.name}! I'll flank {target.name}!",
                                ["id"] = "engaging_neutral",
                                ["templateID"] = "convo.combat.callout.reply_wingman.say.1.engaging_neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Flanking wide, {addressee.name}, keep {target.name} pinned!",
                                ["id"] = "engaging_tactical",
                                ["templateID"] = "convo.combat.callout.reply_wingman.say.1.engaging_tactical",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Save some of {target.name} for me, {addressee.name}! Going around!",
                                ["id"] = "engaging_hostile",
                                ["templateID"] = "convo.combat.callout.reply_wingman.say.1.engaging_hostile",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Oh shit, there's more? Stay close, {addressee.name}!",
                                ["id"] = "shaken",
                                ["templateID"] = "convo.combat.callout.reply_wingman.say.1.shaken",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "I'm ready too, {addressee.name}. Let's finish them.",
                                ["id"] = "brave",
                                ["templateID"] = "convo.combat.callout.reply_wingman.say.1.brave",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Save one for me, {addressee.name}!",
                                ["id"] = "aggressive",
                                ["templateID"] = "convo.combat.callout.reply_wingman.say.1.aggressive",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Moving up behind you, {addressee.name}! Watching for {target.name}!",
                                ["id"] = "alerted_neutral",
                                ["templateID"] = "convo.combat.callout.reply_wingman.say.1.alerted_neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Covering your six, {addressee.name}, scanning for {target.name}!",
                                ["id"] = "alerted_tactical",
                                ["templateID"] = "convo.combat.callout.reply_wingman.say.1.alerted_tactical",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.callout",
            ["textRoles"] = {
                {
                    ["fallback"] = "Right behind you, {addressee.name}! I'll flank {target.name}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.reply_wingman.say.1.engaging_neutral",
                    ["variantID"] = "engaging_neutral",
                },
                {
                    ["fallback"] = "Flanking wide, {addressee.name}, keep {target.name} pinned!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.reply_wingman.say.1.engaging_tactical",
                    ["variantID"] = "engaging_tactical",
                },
                {
                    ["fallback"] = "Save some of {target.name} for me, {addressee.name}! Going around!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.reply_wingman.say.1.engaging_hostile",
                    ["variantID"] = "engaging_hostile",
                },
                {
                    ["fallback"] = "Oh shit, there's more? Stay close, {addressee.name}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.reply_wingman.say.1.shaken",
                    ["variantID"] = "shaken",
                },
                {
                    ["fallback"] = "I'm ready too, {addressee.name}. Let's finish them.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.reply_wingman.say.1.brave",
                    ["variantID"] = "brave",
                },
                {
                    ["fallback"] = "Save one for me, {addressee.name}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.reply_wingman.say.1.aggressive",
                    ["variantID"] = "aggressive",
                },
                {
                    ["fallback"] = "Moving up behind you, {addressee.name}! Watching for {target.name}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.reply_wingman.say.1.alerted_neutral",
                    ["variantID"] = "alerted_neutral",
                },
                {
                    ["fallback"] = "Covering your six, {addressee.name}, scanning for {target.name}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.reply_wingman.say.1.alerted_tactical",
                    ["variantID"] = "alerted_tactical",
                },
            },
        },
        ["id"] = "combat.callout.reply_wingman",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "reply_wingman",
            ["sourceId"] = "combat.callout.reply_wingman",
            ["sourcePath"] = "dialogue/combat_ally_warning/combat_callout_reply_wingman.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatAllyWarning",
        ["namespace"] = "combat.callout",
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
                                ["fallback"] = "Right behind you, {addressee.name}! I'll flank {target.name}!",
                                ["id"] = "engaging_neutral",
                            },
                            {
                                ["fallback"] = "Flanking wide, {addressee.name}, keep {target.name} pinned!",
                                ["id"] = "engaging_tactical",
                            },
                            {
                                ["fallback"] = "Save some of {target.name} for me, {addressee.name}! Going around!",
                                ["id"] = "engaging_hostile",
                            },
                            {
                                ["fallback"] = "Oh shit, there's more? Stay close, {addressee.name}!",
                                ["id"] = "shaken",
                            },
                            {
                                ["fallback"] = "I'm ready too, {addressee.name}. Let's finish them.",
                                ["id"] = "brave",
                            },
                            {
                                ["fallback"] = "Save one for me, {addressee.name}!",
                                ["id"] = "aggressive",
                            },
                            {
                                ["fallback"] = "Moving up behind you, {addressee.name}! Watching for {target.name}!",
                                ["id"] = "alerted_neutral",
                            },
                            {
                                ["fallback"] = "Covering your six, {addressee.name}, scanning for {target.name}!",
                                ["id"] = "alerted_tactical",
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
            ["responsePlanID"] = "combat.callout.reply_wingman",
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
                            ["fallback"] = "Right behind you, {addressee.name}! I'll flank {target.name}!",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.callout.reply_wingman.say_1",
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
        ["sourceShard"] = "dialogue/combat_ally_warning/combat_callout_reply_wingman.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Right behind you, {addressee.name}! I'll flank {target.name}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.reply_wingman.say.1.engaging_neutral",
                ["variantID"] = "engaging_neutral",
            },
            {
                ["fallback"] = "Flanking wide, {addressee.name}, keep {target.name} pinned!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.reply_wingman.say.1.engaging_tactical",
                ["variantID"] = "engaging_tactical",
            },
            {
                ["fallback"] = "Save some of {target.name} for me, {addressee.name}! Going around!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.reply_wingman.say.1.engaging_hostile",
                ["variantID"] = "engaging_hostile",
            },
            {
                ["fallback"] = "Oh shit, there's more? Stay close, {addressee.name}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.reply_wingman.say.1.shaken",
                ["variantID"] = "shaken",
            },
            {
                ["fallback"] = "I'm ready too, {addressee.name}. Let's finish them.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.reply_wingman.say.1.brave",
                ["variantID"] = "brave",
            },
            {
                ["fallback"] = "Save one for me, {addressee.name}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.reply_wingman.say.1.aggressive",
                ["variantID"] = "aggressive",
            },
            {
                ["fallback"] = "Moving up behind you, {addressee.name}! Watching for {target.name}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.reply_wingman.say.1.alerted_neutral",
                ["variantID"] = "alerted_neutral",
            },
            {
                ["fallback"] = "Covering your six, {addressee.name}, scanning for {target.name}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.reply_wingman.say.1.alerted_tactical",
                ["variantID"] = "alerted_tactical",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_ally_warning",
        ["domainPath"] = "combat_ally_warning",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.callout.threat",
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
                                ["fallback"] = "Heads up, {addressee.name}, {target.name} moving {scene.location}!",
                                ["id"] = "zombie_neutral",
                                ["templateID"] = "convo.combat.callout.threat.say.1.zombie_neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Contact, {scene.location}! {target.name}, weapons up!",
                                ["id"] = "zombie_tactical",
                                ["templateID"] = "convo.combat.callout.threat.say.1.zombie_tactical",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Drop them! {target.name} prowling {scene.location}!",
                                ["id"] = "zombie_hostile",
                                ["templateID"] = "convo.combat.callout.threat.say.1.zombie_hostile",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Watch out, {target.name} spotted {scene.location}!",
                                ["id"] = "hostile_neutral",
                                ["templateID"] = "convo.combat.callout.threat.say.1.hostile_neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Hostile contact! {target.name} {scene.location}, weapons ready!",
                                ["id"] = "hostile_tactical",
                                ["templateID"] = "convo.combat.callout.threat.say.1.hostile_tactical",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Flush them out! Got {target.name} {scene.location}!",
                                ["id"] = "hostile_hostile",
                                ["templateID"] = "convo.combat.callout.threat.say.1.hostile_hostile",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Watch your feet! Got {target.name} dragging {scene.location}!",
                                ["id"] = "crawler",
                                ["templateID"] = "convo.combat.callout.threat.say.1.crawler",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Look out, {addressee.name}! Got {target.name} right behind you!",
                                ["id"] = "blindside",
                                ["templateID"] = "convo.combat.callout.threat.say.1.blindside",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Just this last one left! Put {target.name} down!",
                                ["id"] = "last_one",
                                ["templateID"] = "convo.combat.callout.threat.say.1.last_one",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.callout",
            ["textRoles"] = {
                {
                    ["fallback"] = "Heads up, {addressee.name}, {target.name} moving {scene.location}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.threat.say.1.zombie_neutral",
                    ["variantID"] = "zombie_neutral",
                },
                {
                    ["fallback"] = "Contact, {scene.location}! {target.name}, weapons up!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.threat.say.1.zombie_tactical",
                    ["variantID"] = "zombie_tactical",
                },
                {
                    ["fallback"] = "Drop them! {target.name} prowling {scene.location}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.threat.say.1.zombie_hostile",
                    ["variantID"] = "zombie_hostile",
                },
                {
                    ["fallback"] = "Watch out, {target.name} spotted {scene.location}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.threat.say.1.hostile_neutral",
                    ["variantID"] = "hostile_neutral",
                },
                {
                    ["fallback"] = "Hostile contact! {target.name} {scene.location}, weapons ready!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.threat.say.1.hostile_tactical",
                    ["variantID"] = "hostile_tactical",
                },
                {
                    ["fallback"] = "Flush them out! Got {target.name} {scene.location}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.threat.say.1.hostile_hostile",
                    ["variantID"] = "hostile_hostile",
                },
                {
                    ["fallback"] = "Watch your feet! Got {target.name} dragging {scene.location}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.threat.say.1.crawler",
                    ["variantID"] = "crawler",
                },
                {
                    ["fallback"] = "Look out, {addressee.name}! Got {target.name} right behind you!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.threat.say.1.blindside",
                    ["variantID"] = "blindside",
                },
                {
                    ["fallback"] = "Just this last one left! Put {target.name} down!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.callout.threat.say.1.last_one",
                    ["variantID"] = "last_one",
                },
            },
        },
        ["id"] = "combat.callout.threat",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "threat",
            ["sourceId"] = "combat.callout.threat",
            ["sourcePath"] = "dialogue/combat_ally_warning/combat_callout_threat.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatAllyWarning",
        ["namespace"] = "combat.callout",
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
                                ["fallback"] = "Heads up, {addressee.name}, {target.name} moving {scene.location}!",
                                ["id"] = "zombie_neutral",
                            },
                            {
                                ["fallback"] = "Contact, {scene.location}! {target.name}, weapons up!",
                                ["id"] = "zombie_tactical",
                            },
                            {
                                ["fallback"] = "Drop them! {target.name} prowling {scene.location}!",
                                ["id"] = "zombie_hostile",
                            },
                            {
                                ["fallback"] = "Watch out, {target.name} spotted {scene.location}!",
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
                            {
                                ["fallback"] = "Watch your feet! Got {target.name} dragging {scene.location}!",
                                ["id"] = "crawler",
                            },
                            {
                                ["fallback"] = "Look out, {addressee.name}! Got {target.name} right behind you!",
                                ["id"] = "blindside",
                            },
                            {
                                ["fallback"] = "Just this last one left! Put {target.name} down!",
                                ["id"] = "last_one",
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
            ["responsePlanID"] = "combat.callout.threat",
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
                            ["fallback"] = "Heads up, {addressee.name}, {target.name} moving {scene.location}!",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.callout.threat.say_1",
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
        ["sourceShard"] = "dialogue/combat_ally_warning/combat_callout_threat.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Heads up, {addressee.name}, {target.name} moving {scene.location}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.threat.say.1.zombie_neutral",
                ["variantID"] = "zombie_neutral",
            },
            {
                ["fallback"] = "Contact, {scene.location}! {target.name}, weapons up!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.threat.say.1.zombie_tactical",
                ["variantID"] = "zombie_tactical",
            },
            {
                ["fallback"] = "Drop them! {target.name} prowling {scene.location}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.threat.say.1.zombie_hostile",
                ["variantID"] = "zombie_hostile",
            },
            {
                ["fallback"] = "Watch out, {target.name} spotted {scene.location}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.threat.say.1.hostile_neutral",
                ["variantID"] = "hostile_neutral",
            },
            {
                ["fallback"] = "Hostile contact! {target.name} {scene.location}, weapons ready!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.threat.say.1.hostile_tactical",
                ["variantID"] = "hostile_tactical",
            },
            {
                ["fallback"] = "Flush them out! Got {target.name} {scene.location}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.threat.say.1.hostile_hostile",
                ["variantID"] = "hostile_hostile",
            },
            {
                ["fallback"] = "Watch your feet! Got {target.name} dragging {scene.location}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.threat.say.1.crawler",
                ["variantID"] = "crawler",
            },
            {
                ["fallback"] = "Look out, {addressee.name}! Got {target.name} right behind you!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.threat.say.1.blindside",
                ["variantID"] = "blindside",
            },
            {
                ["fallback"] = "Just this last one left! Put {target.name} down!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.callout.threat.say.1.last_one",
                ["variantID"] = "last_one",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_ally_warning",
        ["domainPath"] = "combat_ally_warning",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.checkin.reply",
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
                                ["fallback"] = "All good here, {addressee.name}, barely broke a sweat.",
                                ["id"] = "ok",
                                ["templateID"] = "convo.combat.checkin.reply.say.1.ok",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.checkin",
            ["textRoles"] = {
                {
                    ["fallback"] = "All good here, {addressee.name}, barely broke a sweat.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.checkin.reply.say.1.ok",
                    ["variantID"] = "ok",
                },
            },
        },
        ["id"] = "combat.checkin.reply",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "reply",
            ["sourceId"] = "combat.checkin.reply",
            ["sourcePath"] = "dialogue/combat_ally_warning/combat_checkin_reply.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatAllyWarning",
        ["namespace"] = "combat.checkin",
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
                                ["fallback"] = "All good here, {addressee.name}, barely broke a sweat.",
                                ["id"] = "ok",
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
            ["responsePlanID"] = "combat.checkin.reply",
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
                            ["fallback"] = "All good here, {addressee.name}, barely broke a sweat.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.checkin.reply.say_1",
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
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/combat_ally_warning/combat_checkin_reply.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "All good here, {addressee.name}, barely broke a sweat.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.checkin.reply.say.1.ok",
                ["variantID"] = "ok",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_ally_warning",
        ["domainPath"] = "combat_ally_warning",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.checkin.warn",
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
                                ["fallback"] = "All clear! Are you okay, {addressee.name}?",
                                ["id"] = "injured",
                                ["templateID"] = "convo.combat.checkin.warn.say.1.injured",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "That's the last of them, {addressee.name}. Everybody good?",
                                ["id"] = "clear",
                                ["templateID"] = "convo.combat.checkin.warn.say.1.clear",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.checkin",
            ["textRoles"] = {
                {
                    ["fallback"] = "All clear! Are you okay, {addressee.name}?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.checkin.warn.say.1.injured",
                    ["variantID"] = "injured",
                },
                {
                    ["fallback"] = "That's the last of them, {addressee.name}. Everybody good?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.checkin.warn.say.1.clear",
                    ["variantID"] = "clear",
                },
            },
        },
        ["id"] = "combat.checkin.warn",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "warn",
            ["sourceId"] = "combat.checkin.warn",
            ["sourcePath"] = "dialogue/combat_ally_warning/combat_checkin_warn.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatAllyWarning",
        ["namespace"] = "combat.checkin",
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
                                ["fallback"] = "All clear! Are you okay, {addressee.name}?",
                                ["id"] = "injured",
                            },
                            {
                                ["fallback"] = "That's the last of them, {addressee.name}. Everybody good?",
                                ["id"] = "clear",
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
            ["responsePlanID"] = "combat.checkin.warn",
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
                            ["fallback"] = "All clear! Are you okay, {addressee.name}?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.checkin.warn.say_1",
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
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/combat_ally_warning/combat_checkin_warn.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "All clear! Are you okay, {addressee.name}?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.checkin.warn.say.1.injured",
                ["variantID"] = "injured",
            },
            {
                ["fallback"] = "That's the last of them, {addressee.name}. Everybody good?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.checkin.warn.say.1.clear",
                ["variantID"] = "clear",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_ally_warning",
        ["domainPath"] = "combat_ally_warning",
        ["exchangeFamily"] = {
            ["familyID"] = "condition.stamina.reply",
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
                                ["fallback"] = "I've got you covered, {addressee.name}! Catch your breath!",
                                ["id"] = "cover_winded",
                                ["templateID"] = "convo.condition.stamina.reply.say.1.cover_winded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "condition.stamina",
            ["textRoles"] = {
                {
                    ["fallback"] = "I've got you covered, {addressee.name}! Catch your breath!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.condition.stamina.reply.say.1.cover_winded",
                    ["variantID"] = "cover_winded",
                },
            },
        },
        ["id"] = "condition.stamina.reply",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "reply",
            ["sourceId"] = "condition.stamina.reply",
            ["sourcePath"] = "dialogue/combat_ally_warning/condition_stamina_reply.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatAllyWarning",
        ["namespace"] = "condition.stamina",
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
                    ["domain"] = "condition",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["events"] = {
                {
                    ["id"] = "condition_event",
                    ["kind"] = "condition_event",
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
                                ["fallback"] = "I've got you covered, {addressee.name}! Catch your breath!",
                                ["id"] = "cover_winded",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "condition",
                    ["id"] = "stamina_status",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "ACK",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "condition.stamina.reply",
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
                            ["fallback"] = "I've got you covered, {addressee.name}! Catch your breath!",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.condition.stamina.reply.say_1",
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
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/combat_ally_warning/condition_stamina_reply.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I've got you covered, {addressee.name}! Catch your breath!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.condition.stamina.reply.say.1.cover_winded",
                ["variantID"] = "cover_winded",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_ally_warning",
        ["domainPath"] = "combat_ally_warning",
        ["exchangeFamily"] = {
            ["familyID"] = "condition.stamina.warn",
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
                                ["fallback"] = "Whoa, {addressee.name}, give me a second to catch my breath.",
                                ["id"] = "winded",
                                ["templateID"] = "convo.condition.stamina.warn.say.1.winded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "I'm completely gassed, {addressee.name}! Cover me while I catch my breath!",
                                ["id"] = "exhausted",
                                ["templateID"] = "convo.condition.stamina.warn.say.1.exhausted",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "condition.stamina",
            ["textRoles"] = {
                {
                    ["fallback"] = "Whoa, {addressee.name}, give me a second to catch my breath.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.condition.stamina.warn.say.1.winded",
                    ["variantID"] = "winded",
                },
                {
                    ["fallback"] = "I'm completely gassed, {addressee.name}! Cover me while I catch my breath!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.condition.stamina.warn.say.1.exhausted",
                    ["variantID"] = "exhausted",
                },
            },
        },
        ["id"] = "condition.stamina.warn",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "warn",
            ["sourceId"] = "condition.stamina.warn",
            ["sourcePath"] = "dialogue/combat_ally_warning/condition_stamina_warn.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatAllyWarning",
        ["namespace"] = "condition.stamina",
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
                    ["domain"] = "condition",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["events"] = {
                {
                    ["id"] = "condition_event",
                    ["kind"] = "condition_event",
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
                                ["fallback"] = "Whoa, {addressee.name}, give me a second to catch my breath.",
                                ["id"] = "winded",
                            },
                            {
                                ["fallback"] = "I'm completely gassed, {addressee.name}! Cover me while I catch my breath!",
                                ["id"] = "exhausted",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "condition",
                    ["id"] = "stamina_status",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "WARN",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "condition.stamina.warn",
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
                            ["fallback"] = "Whoa, {addressee.name}, give me a second to catch my breath.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.condition.stamina.warn.say_1",
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
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/combat_ally_warning/condition_stamina_warn.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Whoa, {addressee.name}, give me a second to catch my breath.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.condition.stamina.warn.say.1.winded",
                ["variantID"] = "winded",
            },
            {
                ["fallback"] = "I'm completely gassed, {addressee.name}! Cover me while I catch my breath!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.condition.stamina.warn.say.1.exhausted",
                ["variantID"] = "exhausted",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_ally_warning",
        ["domainPath"] = "combat_ally_warning",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.bandage.cover_reply",
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
                                ["fallback"] = "I've got you covered, {addressee.name}! Take your time!",
                                ["id"] = "cover_bandage",
                                ["templateID"] = "convo.medical.bandage.cover_reply.say.1.cover_bandage",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.bandage",
            ["textRoles"] = {
                {
                    ["fallback"] = "I've got you covered, {addressee.name}! Take your time!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.bandage.cover_reply.say.1.cover_bandage",
                    ["variantID"] = "cover_bandage",
                },
            },
        },
        ["id"] = "medical.bandage.cover_reply",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "cover_reply",
            ["sourceId"] = "medical.bandage.cover_reply",
            ["sourcePath"] = "dialogue/combat_ally_warning/medical_bandage_cover_reply.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatAllyWarning",
        ["namespace"] = "medical.bandage",
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
                    ["domain"] = "medical",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["events"] = {
                {
                    ["id"] = "medical_event",
                    ["kind"] = "medical_event",
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
                                ["fallback"] = "I've got you covered, {addressee.name}! Take your time!",
                                ["id"] = "cover_bandage",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "medical",
                    ["id"] = "medical_care",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "ACK",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "medical.bandage.cover_reply",
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
                            ["fallback"] = "I've got you covered, {addressee.name}! Take your time!",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.medical.bandage.cover_reply.say_1",
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
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/combat_ally_warning/medical_bandage_cover_reply.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I've got you covered, {addressee.name}! Take your time!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.bandage.cover_reply.say.1.cover_bandage",
                ["variantID"] = "cover_bandage",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_ally_warning",
        ["domainPath"] = "combat_ally_warning",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.bandage.cover_warn",
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
                                ["fallback"] = "Cover me, {addressee.name}, I'm bandaging up!",
                                ["id"] = "self",
                                ["templateID"] = "convo.medical.bandage.cover_warn.say.1.self",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Cover us {scene.location}, {addressee.name}, I'm bandaging {target.name}!",
                                ["id"] = "ally",
                                ["templateID"] = "convo.medical.bandage.cover_warn.say.1.ally",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.bandage",
            ["textRoles"] = {
                {
                    ["fallback"] = "Cover me, {addressee.name}, I'm bandaging up!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.bandage.cover_warn.say.1.self",
                    ["variantID"] = "self",
                },
                {
                    ["fallback"] = "Cover us {scene.location}, {addressee.name}, I'm bandaging {target.name}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.bandage.cover_warn.say.1.ally",
                    ["variantID"] = "ally",
                },
            },
        },
        ["id"] = "medical.bandage.cover_warn",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "cover_warn",
            ["sourceId"] = "medical.bandage.cover_warn",
            ["sourcePath"] = "dialogue/combat_ally_warning/medical_bandage_cover_warn.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatAllyWarning",
        ["namespace"] = "medical.bandage",
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
                    ["domain"] = "medical",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["events"] = {
                {
                    ["id"] = "medical_event",
                    ["kind"] = "medical_event",
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
                                ["fallback"] = "Cover me, {addressee.name}, I'm bandaging up!",
                                ["id"] = "self",
                            },
                            {
                                ["fallback"] = "Cover us {scene.location}, {addressee.name}, I'm bandaging {target.name}!",
                                ["id"] = "ally",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "medical",
                    ["id"] = "medical_care",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "WARN",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "medical.bandage.cover_warn",
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
                            ["fallback"] = "Cover me, {addressee.name}, I'm bandaging up!",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.medical.bandage.cover_warn.say_1",
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
        ["sourceShard"] = "dialogue/combat_ally_warning/medical_bandage_cover_warn.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Cover me, {addressee.name}, I'm bandaging up!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.bandage.cover_warn.say.1.self",
                ["variantID"] = "self",
            },
            {
                ["fallback"] = "Cover us {scene.location}, {addressee.name}, I'm bandaging {target.name}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.bandage.cover_warn.say.1.ally",
                ["variantID"] = "ally",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_ally_warning",
        ["domainPath"] = "combat_ally_warning",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.injury.status_reply",
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
                                ["fallback"] = "I'm bleeding a bit, {addressee.name}, got bandages on me so I'll patch it up.",
                                ["id"] = "injured_has_bandage",
                                ["templateID"] = "convo.medical.injury.status_reply.say.1.injured_has_bandage",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "I'm bleeding, {addressee.name}, and I'm out of bandages!",
                                ["id"] = "injured_no_bandage",
                                ["templateID"] = "convo.medical.injury.status_reply.say.1.injured_no_bandage",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Hang on, {addressee.name}, I've got a spare bandage! Hold still!",
                                ["id"] = "medic_has_bandage",
                                ["templateID"] = "convo.medical.injury.status_reply.say.1.medic_has_bandage",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "I'm out too, {addressee.name}! Keep pressure on it while we look for bandages!",
                                ["id"] = "medic_no_bandage",
                                ["templateID"] = "convo.medical.injury.status_reply.say.1.medic_no_bandage",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.injury",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm bleeding a bit, {addressee.name}, got bandages on me so I'll patch it up.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.injury.status_reply.say.1.injured_has_bandage",
                    ["variantID"] = "injured_has_bandage",
                },
                {
                    ["fallback"] = "I'm bleeding, {addressee.name}, and I'm out of bandages!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.injury.status_reply.say.1.injured_no_bandage",
                    ["variantID"] = "injured_no_bandage",
                },
                {
                    ["fallback"] = "Hang on, {addressee.name}, I've got a spare bandage! Hold still!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.injury.status_reply.say.1.medic_has_bandage",
                    ["variantID"] = "medic_has_bandage",
                },
                {
                    ["fallback"] = "I'm out too, {addressee.name}! Keep pressure on it while we look for bandages!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.injury.status_reply.say.1.medic_no_bandage",
                    ["variantID"] = "medic_no_bandage",
                },
            },
        },
        ["id"] = "medical.injury.status_reply",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "status_reply",
            ["sourceId"] = "medical.injury.status_reply",
            ["sourcePath"] = "dialogue/combat_ally_warning/medical_injury_status_reply.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatAllyWarning",
        ["namespace"] = "medical.injury",
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
                    ["domain"] = "medical",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["events"] = {
                {
                    ["id"] = "medical_event",
                    ["kind"] = "medical_event",
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
                                ["fallback"] = "I'm bleeding a bit, {addressee.name}, got bandages on me so I'll patch it up.",
                                ["id"] = "injured_has_bandage",
                            },
                            {
                                ["fallback"] = "I'm bleeding, {addressee.name}, and I'm out of bandages!",
                                ["id"] = "injured_no_bandage",
                            },
                            {
                                ["fallback"] = "Hang on, {addressee.name}, I've got a spare bandage! Hold still!",
                                ["id"] = "medic_has_bandage",
                            },
                            {
                                ["fallback"] = "I'm out too, {addressee.name}! Keep pressure on it while we look for bandages!",
                                ["id"] = "medic_no_bandage",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "medical",
                    ["id"] = "medical_care",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "ACK",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "medical.injury.status_reply",
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
                            ["fallback"] = "I'm bleeding a bit, {addressee.name}, got bandages on me so I'll patch it up.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.medical.injury.status_reply.say_1",
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
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/combat_ally_warning/medical_injury_status_reply.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm bleeding a bit, {addressee.name}, got bandages on me so I'll patch it up.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.injury.status_reply.say.1.injured_has_bandage",
                ["variantID"] = "injured_has_bandage",
            },
            {
                ["fallback"] = "I'm bleeding, {addressee.name}, and I'm out of bandages!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.injury.status_reply.say.1.injured_no_bandage",
                ["variantID"] = "injured_no_bandage",
            },
            {
                ["fallback"] = "Hang on, {addressee.name}, I've got a spare bandage! Hold still!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.injury.status_reply.say.1.medic_has_bandage",
                ["variantID"] = "medic_has_bandage",
            },
            {
                ["fallback"] = "I'm out too, {addressee.name}! Keep pressure on it while we look for bandages!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.injury.status_reply.say.1.medic_no_bandage",
                ["variantID"] = "medic_no_bandage",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_ally_warning",
        ["domainPath"] = "combat_ally_warning",
        ["exchangeFamily"] = {
            ["familyID"] = "world.weather.rain_reply",
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
                                ["fallback"] = "Tell me about it, {addressee.name}. Keep your eyes peeled, rain hides their footsteps.",
                                ["id"] = "rain_reply",
                                ["templateID"] = "convo.world.weather.rain_reply.say.1.rain_reply",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 3,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "world.weather",
            ["textRoles"] = {
                {
                    ["fallback"] = "Tell me about it, {addressee.name}. Keep your eyes peeled, rain hides their footsteps.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.world.weather.rain_reply.say.1.rain_reply",
                    ["variantID"] = "rain_reply",
                },
            },
        },
        ["id"] = "world.weather.rain_reply",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "rain_reply",
            ["sourceId"] = "world.weather.rain_reply",
            ["sourcePath"] = "dialogue/combat_ally_warning/world_weather_rain_reply.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatAllyWarning",
        ["namespace"] = "world.weather",
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
                    ["domain"] = "world",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["events"] = {
                {
                    ["id"] = "world_event",
                    ["kind"] = "world_event",
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
                                ["fallback"] = "Tell me about it, {addressee.name}. Keep your eyes peeled, rain hides their footsteps.",
                                ["id"] = "rain_reply",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "world",
                    ["id"] = "weather_reaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "ACK",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "world.weather.rain_reply",
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
                            ["fallback"] = "Tell me about it, {addressee.name}. Keep your eyes peeled, rain hides their footsteps.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.world.weather.rain_reply.say_1",
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
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/combat_ally_warning/world_weather_rain_reply.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Tell me about it, {addressee.name}. Keep your eyes peeled, rain hides their footsteps.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.world.weather.rain_reply.say.1.rain_reply",
                ["variantID"] = "rain_reply",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_ally_warning",
        ["domainPath"] = "combat_ally_warning",
        ["exchangeFamily"] = {
            ["familyID"] = "world.weather.rain_warn",
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
                                ["fallback"] = "Great, it's starting to pour, {addressee.name}. We might want some cover soon.",
                                ["id"] = "rain_open",
                                ["templateID"] = "convo.world.weather.rain_warn.say.1.rain_open",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 3,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "world.weather",
            ["textRoles"] = {
                {
                    ["fallback"] = "Great, it's starting to pour, {addressee.name}. We might want some cover soon.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.world.weather.rain_warn.say.1.rain_open",
                    ["variantID"] = "rain_open",
                },
            },
        },
        ["id"] = "world.weather.rain_warn",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "rain_warn",
            ["sourceId"] = "world.weather.rain_warn",
            ["sourcePath"] = "dialogue/combat_ally_warning/world_weather_rain_warn.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatAllyWarning",
        ["namespace"] = "world.weather",
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
                    ["domain"] = "world",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["events"] = {
                {
                    ["id"] = "world_event",
                    ["kind"] = "world_event",
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
                                ["fallback"] = "Great, it's starting to pour, {addressee.name}. We might want some cover soon.",
                                ["id"] = "rain_open",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "world",
                    ["id"] = "weather_reaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "WARN",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "world.weather.rain_warn",
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
                            ["fallback"] = "Great, it's starting to pour, {addressee.name}. We might want some cover soon.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.world.weather.rain_warn.say_1",
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
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/combat_ally_warning/world_weather_rain_warn.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Great, it's starting to pour, {addressee.name}. We might want some cover soon.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.world.weather.rain_warn.say.1.rain_open",
                ["variantID"] = "rain_open",
            },
        },
        ["when"] = nil,
    },
}
