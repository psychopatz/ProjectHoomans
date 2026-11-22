-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_player_assault_reactions",
        ["domainPath"] = "combat_player_assault_reactions",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.assault.betrayal",
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
                                ["templateID"] = "convo.combat.assault.betrayal.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Why are you attacking me?! Stay back! I'll fight if I have to!",
                                ["id"] = "shaken",
                                ["templateID"] = "convo.combat.assault.betrayal.say.1.shaken",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Big mistake jumping someone who wasn't bothering you!",
                                ["id"] = "brave",
                                ["templateID"] = "convo.combat.assault.betrayal.say.1.brave",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Thought I was an easy target, huh?! Big mistake!",
                                ["id"] = "aggressive",
                                ["templateID"] = "convo.combat.assault.betrayal.say.1.aggressive",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.assault",
            ["textRoles"] = {
                {
                    ["fallback"] = "I wasn't even looking for a fight, {addressee.name}! Now you're dead!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.assault.betrayal.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Why are you attacking me?! Stay back! I'll fight if I have to!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.assault.betrayal.say.1.shaken",
                    ["variantID"] = "shaken",
                },
                {
                    ["fallback"] = "Big mistake jumping someone who wasn't bothering you!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.assault.betrayal.say.1.brave",
                    ["variantID"] = "brave",
                },
                {
                    ["fallback"] = "Thought I was an easy target, huh?! Big mistake!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.assault.betrayal.say.1.aggressive",
                    ["variantID"] = "aggressive",
                },
            },
        },
        ["id"] = "combat.assault.betrayal",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "betrayal",
            ["sourceId"] = "combat.assault.betrayal",
            ["sourcePath"] = "dialogue/combat_player_assault_reactions/combat_assault_betrayal.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatPlayerAssaultReactions",
        ["namespace"] = "combat.assault",
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
            ["responsePlanID"] = "combat.assault.betrayal",
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
                            ["templateID"] = "convo.combat.assault.betrayal.say_1",
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
        ["sourceShard"] = "dialogue/combat_player_assault_reactions/combat_assault_betrayal.json",
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
                ["templateID"] = "convo.combat.assault.betrayal.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Why are you attacking me?! Stay back! I'll fight if I have to!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.assault.betrayal.say.1.shaken",
                ["variantID"] = "shaken",
            },
            {
                ["fallback"] = "Big mistake jumping someone who wasn't bothering you!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.assault.betrayal.say.1.brave",
                ["variantID"] = "brave",
            },
            {
                ["fallback"] = "Thought I was an easy target, huh?! Big mistake!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.assault.betrayal.say.1.aggressive",
                ["variantID"] = "aggressive",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_player_assault_reactions",
        ["domainPath"] = "combat_player_assault_reactions",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.assault.friendly_fire",
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
                                ["templateID"] = "convo.combat.assault.friendly_fire.say.1.first",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Seriously, {addressee.name}, knock it off with the shoving!",
                                ["id"] = "warn",
                                ["templateID"] = "convo.combat.assault.friendly_fire.say.1.warn",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "That does it, {addressee.name}. Keep pulling this stunt and we're going to have real trouble.",
                                ["id"] = "penalty",
                                ["templateID"] = "convo.combat.assault.friendly_fire.say.1.penalty",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.assault",
            ["textRoles"] = {
                {
                    ["fallback"] = "Whoa, easy there! I'm on your side!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.assault.friendly_fire.say.1.first",
                    ["variantID"] = "first",
                },
                {
                    ["fallback"] = "Seriously, {addressee.name}, knock it off with the shoving!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.assault.friendly_fire.say.1.warn",
                    ["variantID"] = "warn",
                },
                {
                    ["fallback"] = "That does it, {addressee.name}. Keep pulling this stunt and we're going to have real trouble.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.assault.friendly_fire.say.1.penalty",
                    ["variantID"] = "penalty",
                },
            },
        },
        ["id"] = "combat.assault.friendly_fire",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "friendly_fire",
            ["sourceId"] = "combat.assault.friendly_fire",
            ["sourcePath"] = "dialogue/combat_player_assault_reactions/combat_assault_friendly_fire.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatPlayerAssaultReactions",
        ["namespace"] = "combat.assault",
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
            ["responsePlanID"] = "combat.assault.friendly_fire",
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
                            ["templateID"] = "convo.combat.assault.friendly_fire.say_1",
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
        ["sourceShard"] = "dialogue/combat_player_assault_reactions/combat_assault_friendly_fire.json",
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
                ["templateID"] = "convo.combat.assault.friendly_fire.say.1.first",
                ["variantID"] = "first",
            },
            {
                ["fallback"] = "Seriously, {addressee.name}, knock it off with the shoving!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.assault.friendly_fire.say.1.warn",
                ["variantID"] = "warn",
            },
            {
                ["fallback"] = "That does it, {addressee.name}. Keep pulling this stunt and we're going to have real trouble.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.assault.friendly_fire.say.1.penalty",
                ["variantID"] = "penalty",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_player_assault_reactions",
        ["domainPath"] = "combat_player_assault_reactions",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.assault.hostile_taunt",
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
                                ["templateID"] = "convo.combat.assault.hostile_taunt.say.1.backpack",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Nice {slot.loot.name} you've got there! It'll look better in my hands!",
                                ["id"] = "weapon",
                                ["templateID"] = "convo.combat.assault.hostile_taunt.say.1.weapon",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Still carrying {slot.loot.name} around like banks still matter? Drop your pack!",
                                ["id"] = "money",
                                ["templateID"] = "convo.combat.assault.hostile_taunt.say.1.money",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                            {
                                ["fallback"] = "Empty your pockets now or bleed for every scrap you're carrying!",
                                ["id"] = "general",
                                ["templateID"] = "convo.combat.assault.hostile_taunt.say.1.general",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 4,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.assault",
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
                    ["templateID"] = "convo.combat.assault.hostile_taunt.say.1.backpack",
                    ["variantID"] = "backpack",
                },
                {
                    ["fallback"] = "Nice {slot.loot.name} you've got there! It'll look better in my hands!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.assault.hostile_taunt.say.1.weapon",
                    ["variantID"] = "weapon",
                },
                {
                    ["fallback"] = "Still carrying {slot.loot.name} around like banks still matter? Drop your pack!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.assault.hostile_taunt.say.1.money",
                    ["variantID"] = "money",
                },
                {
                    ["fallback"] = "Empty your pockets now or bleed for every scrap you're carrying!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.assault.hostile_taunt.say.1.general",
                    ["variantID"] = "general",
                },
            },
        },
        ["id"] = "combat.assault.hostile_taunt",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "hostile_taunt",
            ["sourceId"] = "combat.assault.hostile_taunt",
            ["sourcePath"] = "dialogue/combat_player_assault_reactions/combat_assault_hostile_taunt.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatPlayerAssaultReactions",
        ["namespace"] = "combat.assault",
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
            ["responsePlanID"] = "combat.assault.hostile_taunt",
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
                            ["templateID"] = "convo.combat.assault.hostile_taunt.say_1",
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
        ["sourceShard"] = "dialogue/combat_player_assault_reactions/combat_assault_hostile_taunt.json",
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
                ["templateID"] = "convo.combat.assault.hostile_taunt.say.1.backpack",
                ["variantID"] = "backpack",
            },
            {
                ["fallback"] = "Nice {slot.loot.name} you've got there! It'll look better in my hands!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.assault.hostile_taunt.say.1.weapon",
                ["variantID"] = "weapon",
            },
            {
                ["fallback"] = "Still carrying {slot.loot.name} around like banks still matter? Drop your pack!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.assault.hostile_taunt.say.1.money",
                ["variantID"] = "money",
            },
            {
                ["fallback"] = "Empty your pockets now or bleed for every scrap you're carrying!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.assault.hostile_taunt.say.1.general",
                ["variantID"] = "general",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_player_assault_reactions",
        ["domainPath"] = "combat_player_assault_reactions",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.assault.react",
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
                                ["id"] = "default",
                                ["templateID"] = "convo.combat.assault.react.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "You just made a big mistake.",
                                ["id"] = "aggressive",
                                ["templateID"] = "convo.combat.assault.react.say.1.aggressive",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "That's it. You're done.",
                                ["id"] = "brave",
                                ["templateID"] = "convo.combat.assault.react.say.1.brave",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Back off. Now.",
                                ["id"] = "reserved",
                                ["templateID"] = "convo.combat.assault.react.say.1.reserved",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "What the hell?! Stay back!",
                                ["id"] = "shaken",
                                ["templateID"] = "convo.combat.assault.react.say.1.shaken",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.assault",
            ["textRoles"] = {
                {
                    ["fallback"] = "Why did you do that?!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.assault.react.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "You just made a big mistake.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.assault.react.say.1.aggressive",
                    ["variantID"] = "aggressive",
                },
                {
                    ["fallback"] = "That's it. You're done.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.assault.react.say.1.brave",
                    ["variantID"] = "brave",
                },
                {
                    ["fallback"] = "Back off. Now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.assault.react.say.1.reserved",
                    ["variantID"] = "reserved",
                },
                {
                    ["fallback"] = "What the hell?! Stay back!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.assault.react.say.1.shaken",
                    ["variantID"] = "shaken",
                },
            },
        },
        ["id"] = "combat.assault.react",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "react",
            ["sourceId"] = "combat.assault.react",
            ["sourcePath"] = "dialogue/combat_player_assault_reactions/combat_assault_react.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatPlayerAssaultReactions",
        ["namespace"] = "combat.assault",
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
                                ["id"] = "default",
                            },
                            {
                                ["fallback"] = "You just made a big mistake.",
                                ["id"] = "aggressive",
                            },
                            {
                                ["fallback"] = "That's it. You're done.",
                                ["id"] = "brave",
                            },
                            {
                                ["fallback"] = "Back off. Now.",
                                ["id"] = "reserved",
                            },
                            {
                                ["fallback"] = "What the hell?! Stay back!",
                                ["id"] = "shaken",
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
            ["responsePlanID"] = "combat.assault.react",
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
                            ["templateID"] = "convo.combat.assault.react.say_1",
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
        ["sourceShard"] = "dialogue/combat_player_assault_reactions/combat_assault_react.json",
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
                ["templateID"] = "convo.combat.assault.react.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "You just made a big mistake.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.assault.react.say.1.aggressive",
                ["variantID"] = "aggressive",
            },
            {
                ["fallback"] = "That's it. You're done.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.assault.react.say.1.brave",
                ["variantID"] = "brave",
            },
            {
                ["fallback"] = "Back off. Now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.assault.react.say.1.reserved",
                ["variantID"] = "reserved",
            },
            {
                ["fallback"] = "What the hell?! Stay back!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.assault.react.say.1.shaken",
                ["variantID"] = "shaken",
            },
        },
        ["when"] = nil,
    },
}
