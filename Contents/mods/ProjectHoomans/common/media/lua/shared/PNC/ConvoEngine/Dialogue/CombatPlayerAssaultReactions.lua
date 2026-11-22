-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_player_assault_reactions",
        ["domainPath"] = "combat_player_assault_reactions",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.player_assaulted.aggressive",
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
                                ["fallback"] = "You just made a big mistake.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.player_assaulted.aggressive.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.player_assaulted",
            ["textRoles"] = {
                {
                    ["fallback"] = "You just made a big mistake.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.player_assaulted.aggressive.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.player_assaulted.aggressive",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "aggressive",
            ["sourceId"] = "combat.player_assaulted.aggressive",
            ["sourcePath"] = "dialogue/combat_player_assault_reactions/combat_player_assaulted_aggressive.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatPlayerAssaultReactions",
        ["namespace"] = "combat.player_assaulted",
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
                ["category"] = "projecthoomans:combat_kill",
                ["contentOwner"] = "projecthoomans.dialogue_content.combat",
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
                                ["fallback"] = "You just made a big mistake.",
                                ["id"] = "neutral",
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
            ["responsePlanID"] = "combat.player_assaulted.aggressive",
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
                            ["fallback"] = "You just made a big mistake.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.player_assaulted.aggressive.say_1",
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
        ["sourceShard"] = "dialogue/combat_player_assault_reactions/combat_player_assaulted_aggressive.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "You just made a big mistake.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.player_assaulted.aggressive.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_player_assault_reactions",
        ["domainPath"] = "combat_player_assault_reactions",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.player_assaulted.brave",
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
                                ["fallback"] = "That's it. You're done.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.player_assaulted.brave.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.player_assaulted",
            ["textRoles"] = {
                {
                    ["fallback"] = "That's it. You're done.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.player_assaulted.brave.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.player_assaulted.brave",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "brave",
            ["sourceId"] = "combat.player_assaulted.brave",
            ["sourcePath"] = "dialogue/combat_player_assault_reactions/combat_player_assaulted_brave.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatPlayerAssaultReactions",
        ["namespace"] = "combat.player_assaulted",
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
                ["category"] = "projecthoomans:combat_kill",
                ["contentOwner"] = "projecthoomans.dialogue_content.combat",
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
                                ["fallback"] = "That's it. You're done.",
                                ["id"] = "neutral",
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
            ["responsePlanID"] = "combat.player_assaulted.brave",
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
                            ["fallback"] = "That's it. You're done.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.player_assaulted.brave.say_1",
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
        ["sourceShard"] = "dialogue/combat_player_assault_reactions/combat_player_assaulted_brave.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That's it. You're done.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.player_assaulted.brave.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_player_assault_reactions",
        ["domainPath"] = "combat_player_assault_reactions",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.player_assaulted.default",
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
                                ["fallback"] = "Why did you do that?!",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.player_assaulted.default.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.player_assaulted",
            ["textRoles"] = {
                {
                    ["fallback"] = "Why did you do that?!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.player_assaulted.default.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.player_assaulted.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "default",
            ["sourceId"] = "combat.player_assaulted.default",
            ["sourcePath"] = "dialogue/combat_player_assault_reactions/combat_player_assaulted_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatPlayerAssaultReactions",
        ["namespace"] = "combat.player_assaulted",
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
                ["category"] = "projecthoomans:combat_kill",
                ["contentOwner"] = "projecthoomans.dialogue_content.combat",
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
                                ["fallback"] = "Why did you do that?!",
                                ["id"] = "neutral",
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
            ["responsePlanID"] = "combat.player_assaulted.default",
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
                            ["fallback"] = "Why did you do that?!",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.player_assaulted.default.say_1",
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
        ["sourceShard"] = "dialogue/combat_player_assault_reactions/combat_player_assaulted_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Why did you do that?!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.player_assaulted.default.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_player_assault_reactions",
        ["domainPath"] = "combat_player_assault_reactions",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.player_assaulted.friendly_push",
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
                                ["fallback"] = "Whoa, easy there! I'm on your side!",
                                ["id"] = "first",
                                ["templateID"] = "convo.combat.player_assaulted.friendly_push.say.1.first",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Seriously, {addressee.name}, knock it off with the shoving!",
                                ["id"] = "warn",
                                ["templateID"] = "convo.combat.player_assaulted.friendly_push.say.1.warn",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "That does it, {addressee.name}. Keep pulling this stunt and we're going to have real trouble.",
                                ["id"] = "penalty",
                                ["templateID"] = "convo.combat.player_assaulted.friendly_push.say.1.penalty",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.player_assaulted",
            ["textRoles"] = {
                {
                    ["fallback"] = "Whoa, easy there! I'm on your side!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.player_assaulted.friendly_push.say.1.first",
                    ["variantID"] = "first",
                },
                {
                    ["fallback"] = "Seriously, {addressee.name}, knock it off with the shoving!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.player_assaulted.friendly_push.say.1.warn",
                    ["variantID"] = "warn",
                },
                {
                    ["fallback"] = "That does it, {addressee.name}. Keep pulling this stunt and we're going to have real trouble.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.player_assaulted.friendly_push.say.1.penalty",
                    ["variantID"] = "penalty",
                },
            },
        },
        ["id"] = "combat.player_assaulted.friendly_push",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "friendly_push",
            ["sourceId"] = "combat.player_assaulted.friendly_push",
            ["sourcePath"] = "dialogue/combat_player_assault_reactions/combat_player_assaulted_friendly_push.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatPlayerAssaultReactions",
        ["namespace"] = "combat.player_assaulted",
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
                                ["fallback"] = "Whoa, easy there! I'm on your side!",
                                ["id"] = "first",
                            },
                            {
                                ["fallback"] = "Seriously, {addressee.name}, knock it off with the shoving!",
                                ["id"] = "warn",
                            },
                            {
                                ["fallback"] = "That does it, {addressee.name}. Keep pulling this stunt and we're going to have real trouble.",
                                ["id"] = "penalty",
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
            ["responsePlanID"] = "combat.player_assaulted.friendly_push",
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
                            ["fallback"] = "Whoa, easy there! I'm on your side!",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.player_assaulted.friendly_push.say_1",
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
        ["sourceShard"] = "dialogue/combat_player_assault_reactions/combat_player_assaulted_friendly_push.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Whoa, easy there! I'm on your side!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.player_assaulted.friendly_push.say.1.first",
                ["variantID"] = "first",
            },
            {
                ["fallback"] = "Seriously, {addressee.name}, knock it off with the shoving!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.player_assaulted.friendly_push.say.1.warn",
                ["variantID"] = "warn",
            },
            {
                ["fallback"] = "That does it, {addressee.name}. Keep pulling this stunt and we're going to have real trouble.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.player_assaulted.friendly_push.say.1.penalty",
                ["variantID"] = "penalty",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_player_assault_reactions",
        ["domainPath"] = "combat_player_assault_reactions",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.player_assaulted.looter_taunt",
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
                                ["fallback"] = "Nice {slot.loot.name} on your back! Drop it before I pry it off you!",
                                ["id"] = "backpack",
                                ["templateID"] = "convo.combat.player_assaulted.looter_taunt.say.1.backpack",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Nice {slot.loot.name} you've got there! It'll look better in my hands!",
                                ["id"] = "weapon",
                                ["templateID"] = "convo.combat.player_assaulted.looter_taunt.say.1.weapon",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Still carrying {slot.loot.name} around like banks still matter? Drop your pack!",
                                ["id"] = "money",
                                ["templateID"] = "convo.combat.player_assaulted.looter_taunt.say.1.money",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Empty your pockets now or bleed for every scrap you're carrying!",
                                ["id"] = "general",
                                ["templateID"] = "convo.combat.player_assaulted.looter_taunt.say.1.general",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.player_assaulted",
            ["slots"] = {
                ["loot"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.item",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "Nice {slot.loot.name} on your back! Drop it before I pry it off you!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.player_assaulted.looter_taunt.say.1.backpack",
                    ["variantID"] = "backpack",
                },
                {
                    ["fallback"] = "Nice {slot.loot.name} you've got there! It'll look better in my hands!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.player_assaulted.looter_taunt.say.1.weapon",
                    ["variantID"] = "weapon",
                },
                {
                    ["fallback"] = "Still carrying {slot.loot.name} around like banks still matter? Drop your pack!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.player_assaulted.looter_taunt.say.1.money",
                    ["variantID"] = "money",
                },
                {
                    ["fallback"] = "Empty your pockets now or bleed for every scrap you're carrying!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.player_assaulted.looter_taunt.say.1.general",
                    ["variantID"] = "general",
                },
            },
        },
        ["id"] = "combat.player_assaulted.looter_taunt",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "looter_taunt",
            ["sourceId"] = "combat.player_assaulted.looter_taunt",
            ["sourcePath"] = "dialogue/combat_player_assault_reactions/combat_player_assaulted_looter_taunt.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatPlayerAssaultReactions",
        ["namespace"] = "combat.player_assaulted",
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
                                ["fallback"] = "Nice {slot.loot.name} on your back! Drop it before I pry it off you!",
                                ["id"] = "backpack",
                            },
                            {
                                ["fallback"] = "Nice {slot.loot.name} you've got there! It'll look better in my hands!",
                                ["id"] = "weapon",
                            },
                            {
                                ["fallback"] = "Still carrying {slot.loot.name} around like banks still matter? Drop your pack!",
                                ["id"] = "money",
                            },
                            {
                                ["fallback"] = "Empty your pockets now or bleed for every scrap you're carrying!",
                                ["id"] = "general",
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
            ["responsePlanID"] = "combat.player_assaulted.looter_taunt",
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
                            ["fallback"] = "Nice {slot.loot.name} on your back! Drop it before I pry it off you!",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.player_assaulted.looter_taunt.say_1",
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
            ["loot"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.item",
            },
        },
        ["sourceShard"] = "dialogue/combat_player_assault_reactions/combat_player_assaulted_looter_taunt.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Nice {slot.loot.name} on your back! Drop it before I pry it off you!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.player_assaulted.looter_taunt.say.1.backpack",
                ["variantID"] = "backpack",
            },
            {
                ["fallback"] = "Nice {slot.loot.name} you've got there! It'll look better in my hands!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.player_assaulted.looter_taunt.say.1.weapon",
                ["variantID"] = "weapon",
            },
            {
                ["fallback"] = "Still carrying {slot.loot.name} around like banks still matter? Drop your pack!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.player_assaulted.looter_taunt.say.1.money",
                ["variantID"] = "money",
            },
            {
                ["fallback"] = "Empty your pockets now or bleed for every scrap you're carrying!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.player_assaulted.looter_taunt.say.1.general",
                ["variantID"] = "general",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_player_assault_reactions",
        ["domainPath"] = "combat_player_assault_reactions",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.player_assaulted.neutral_turned_hostile",
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
                                ["fallback"] = "I wasn't even looking for a fight, {addressee.name}! Now you're dead!",
                                ["id"] = "default",
                                ["templateID"] = "convo.combat.player_assaulted.neutral_turned_hostile.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Why are you attacking me?! Stay back! I'll fight if I have to!",
                                ["id"] = "shaken",
                                ["templateID"] = "convo.combat.player_assaulted.neutral_turned_hostile.say.1.shaken",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Big mistake jumping someone who wasn't bothering you!",
                                ["id"] = "brave",
                                ["templateID"] = "convo.combat.player_assaulted.neutral_turned_hostile.say.1.brave",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Thought I was an easy target, huh?! Big mistake!",
                                ["id"] = "aggressive",
                                ["templateID"] = "convo.combat.player_assaulted.neutral_turned_hostile.say.1.aggressive",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.player_assaulted",
            ["textRoles"] = {
                {
                    ["fallback"] = "I wasn't even looking for a fight, {addressee.name}! Now you're dead!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.player_assaulted.neutral_turned_hostile.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Why are you attacking me?! Stay back! I'll fight if I have to!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.player_assaulted.neutral_turned_hostile.say.1.shaken",
                    ["variantID"] = "shaken",
                },
                {
                    ["fallback"] = "Big mistake jumping someone who wasn't bothering you!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.player_assaulted.neutral_turned_hostile.say.1.brave",
                    ["variantID"] = "brave",
                },
                {
                    ["fallback"] = "Thought I was an easy target, huh?! Big mistake!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.player_assaulted.neutral_turned_hostile.say.1.aggressive",
                    ["variantID"] = "aggressive",
                },
            },
        },
        ["id"] = "combat.player_assaulted.neutral_turned_hostile",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "neutral_turned_hostile",
            ["sourceId"] = "combat.player_assaulted.neutral_turned_hostile",
            ["sourcePath"] = "dialogue/combat_player_assault_reactions/combat_player_assaulted_neutral_turned_hostile.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatPlayerAssaultReactions",
        ["namespace"] = "combat.player_assaulted",
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
                                ["fallback"] = "I wasn't even looking for a fight, {addressee.name}! Now you're dead!",
                                ["id"] = "default",
                            },
                            {
                                ["fallback"] = "Why are you attacking me?! Stay back! I'll fight if I have to!",
                                ["id"] = "shaken",
                            },
                            {
                                ["fallback"] = "Big mistake jumping someone who wasn't bothering you!",
                                ["id"] = "brave",
                            },
                            {
                                ["fallback"] = "Thought I was an easy target, huh?! Big mistake!",
                                ["id"] = "aggressive",
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
            ["responsePlanID"] = "combat.player_assaulted.neutral_turned_hostile",
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
                            ["fallback"] = "I wasn't even looking for a fight, {addressee.name}! Now you're dead!",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.player_assaulted.neutral_turned_hostile.say_1",
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
        ["sourceShard"] = "dialogue/combat_player_assault_reactions/combat_player_assaulted_neutral_turned_hostile.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I wasn't even looking for a fight, {addressee.name}! Now you're dead!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.player_assaulted.neutral_turned_hostile.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Why are you attacking me?! Stay back! I'll fight if I have to!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.player_assaulted.neutral_turned_hostile.say.1.shaken",
                ["variantID"] = "shaken",
            },
            {
                ["fallback"] = "Big mistake jumping someone who wasn't bothering you!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.player_assaulted.neutral_turned_hostile.say.1.brave",
                ["variantID"] = "brave",
            },
            {
                ["fallback"] = "Thought I was an easy target, huh?! Big mistake!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.player_assaulted.neutral_turned_hostile.say.1.aggressive",
                ["variantID"] = "aggressive",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_player_assault_reactions",
        ["domainPath"] = "combat_player_assault_reactions",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.player_assaulted.reserved",
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
                                ["fallback"] = "Back off. Now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.player_assaulted.reserved.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.player_assaulted",
            ["textRoles"] = {
                {
                    ["fallback"] = "Back off. Now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.player_assaulted.reserved.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.player_assaulted.reserved",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "reserved",
            ["sourceId"] = "combat.player_assaulted.reserved",
            ["sourcePath"] = "dialogue/combat_player_assault_reactions/combat_player_assaulted_reserved.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatPlayerAssaultReactions",
        ["namespace"] = "combat.player_assaulted",
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
                ["category"] = "projecthoomans:combat_kill",
                ["contentOwner"] = "projecthoomans.dialogue_content.combat",
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
                                ["fallback"] = "Back off. Now.",
                                ["id"] = "neutral",
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
            ["responsePlanID"] = "combat.player_assaulted.reserved",
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
                            ["fallback"] = "Back off. Now.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.player_assaulted.reserved.say_1",
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
        ["sourceShard"] = "dialogue/combat_player_assault_reactions/combat_player_assaulted_reserved.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Back off. Now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.player_assaulted.reserved.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_player_assault_reactions",
        ["domainPath"] = "combat_player_assault_reactions",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.player_assaulted.shaken",
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
                                ["fallback"] = "What the hell?! Stay back!",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.player_assaulted.shaken.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.player_assaulted",
            ["textRoles"] = {
                {
                    ["fallback"] = "What the hell?! Stay back!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.player_assaulted.shaken.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.player_assaulted.shaken",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "shaken",
            ["sourceId"] = "combat.player_assaulted.shaken",
            ["sourcePath"] = "dialogue/combat_player_assault_reactions/combat_player_assaulted_shaken.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatPlayerAssaultReactions",
        ["namespace"] = "combat.player_assaulted",
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
                ["category"] = "projecthoomans:combat_kill",
                ["contentOwner"] = "projecthoomans.dialogue_content.combat",
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
                                ["fallback"] = "What the hell?! Stay back!",
                                ["id"] = "neutral",
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
            ["responsePlanID"] = "combat.player_assaulted.shaken",
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
                            ["fallback"] = "What the hell?! Stay back!",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.player_assaulted.shaken.say_1",
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
        ["sourceShard"] = "dialogue/combat_player_assault_reactions/combat_player_assaulted_shaken.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "What the hell?! Stay back!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.player_assaulted.shaken.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
