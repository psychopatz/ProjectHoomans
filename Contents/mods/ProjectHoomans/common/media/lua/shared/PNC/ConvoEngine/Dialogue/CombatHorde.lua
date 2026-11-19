-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_horde",
        ["domainPath"] = "combat_horde",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.horde.ack",
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
                                ["fallback"] = "Copy. We go around.",
                                ["id"] = "avoid_default",
                                ["templateID"] = "convo.combat.horde.ack.say.1.avoid_default",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Good. Let's go around.",
                                ["id"] = "avoid_relief",
                                ["templateID"] = "convo.combat.horde.ack.say.1.avoid_relief",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I'm with you. Let's go.",
                                ["id"] = "engage_default",
                                ["templateID"] = "convo.combat.horde.ack.say.1.engage_default",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Ready to strike! Let's take them down.",
                                ["id"] = "engage_eager",
                                ["templateID"] = "convo.combat.horde.ack.say.1.engage_eager",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "If you say so... alright. I'm with you.",
                                ["id"] = "engage_hesitant",
                                ["templateID"] = "convo.combat.horde.ack.say.1.engage_hesitant",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Alright. Moving.",
                                ["id"] = "engage_reserved",
                                ["templateID"] = "convo.combat.horde.ack.say.1.engage_reserved",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Holding for now.",
                                ["id"] = "hold_default",
                                ["templateID"] = "convo.combat.horde.ack.say.1.hold_default",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Holding. Say when.",
                                ["id"] = "hold_eager",
                                ["templateID"] = "convo.combat.horde.ack.say.1.hold_eager",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Okay. Holding here.",
                                ["id"] = "hold_hesitant",
                                ["templateID"] = "convo.combat.horde.ack.say.1.hold_hesitant",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.horde",
            ["slots"] = {
                ["threat"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.threat",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "Copy. We go around.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.ack.say.1.avoid_default",
                    ["variantID"] = "avoid_default",
                },
                {
                    ["fallback"] = "Good. Let's go around.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.ack.say.1.avoid_relief",
                    ["variantID"] = "avoid_relief",
                },
                {
                    ["fallback"] = "I'm with you. Let's go.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.ack.say.1.engage_default",
                    ["variantID"] = "engage_default",
                },
                {
                    ["fallback"] = "Ready to strike! Let's take them down.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.ack.say.1.engage_eager",
                    ["variantID"] = "engage_eager",
                },
                {
                    ["fallback"] = "If you say so... alright. I'm with you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.ack.say.1.engage_hesitant",
                    ["variantID"] = "engage_hesitant",
                },
                {
                    ["fallback"] = "Alright. Moving.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.ack.say.1.engage_reserved",
                    ["variantID"] = "engage_reserved",
                },
                {
                    ["fallback"] = "Holding for now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.ack.say.1.hold_default",
                    ["variantID"] = "hold_default",
                },
                {
                    ["fallback"] = "Holding. Say when.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.ack.say.1.hold_eager",
                    ["variantID"] = "hold_eager",
                },
                {
                    ["fallback"] = "Okay. Holding here.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.ack.say.1.hold_hesitant",
                    ["variantID"] = "hold_hesitant",
                },
            },
        },
        ["id"] = "combat.horde.ack",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "ack",
            ["sourceId"] = "combat.horde.ack",
            ["sourcePath"] = "dialogue/combat_horde/combat_horde_ack.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatHorde",
        ["namespace"] = "combat.horde",
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
                    ["id"] = "horde_detected",
                    ["kind"] = "world_event",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
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
                                ["fallback"] = "Copy. We go around.",
                                ["id"] = "avoid_default",
                            },
                            {
                                ["fallback"] = "Good. Let's go around.",
                                ["id"] = "avoid_relief",
                            },
                            {
                                ["fallback"] = "I'm with you. Let's go.",
                                ["id"] = "engage_default",
                            },
                            {
                                ["fallback"] = "Ready to strike! Let's take them down.",
                                ["id"] = "engage_eager",
                            },
                            {
                                ["fallback"] = "If you say so... alright. I'm with you.",
                                ["id"] = "engage_hesitant",
                            },
                            {
                                ["fallback"] = "Alright. Moving.",
                                ["id"] = "engage_reserved",
                            },
                            {
                                ["fallback"] = "Holding for now.",
                                ["id"] = "hold_default",
                            },
                            {
                                ["fallback"] = "Holding. Say when.",
                                ["id"] = "hold_eager",
                            },
                            {
                                ["fallback"] = "Okay. Holding here.",
                                ["id"] = "hold_hesitant",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "combat",
                    ["id"] = "horde_threat",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "ACK",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "combat.horde.ack",
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
                            ["fallback"] = "Copy. We go around.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.horde.ack.say_1",
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
            ["threat"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.threat",
            },
        },
        ["sourceShard"] = "dialogue/combat_horde/combat_horde_ack.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Copy. We go around.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.ack.say.1.avoid_default",
                ["variantID"] = "avoid_default",
            },
            {
                ["fallback"] = "Good. Let's go around.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.ack.say.1.avoid_relief",
                ["variantID"] = "avoid_relief",
            },
            {
                ["fallback"] = "I'm with you. Let's go.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.ack.say.1.engage_default",
                ["variantID"] = "engage_default",
            },
            {
                ["fallback"] = "Ready to strike! Let's take them down.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.ack.say.1.engage_eager",
                ["variantID"] = "engage_eager",
            },
            {
                ["fallback"] = "If you say so... alright. I'm with you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.ack.say.1.engage_hesitant",
                ["variantID"] = "engage_hesitant",
            },
            {
                ["fallback"] = "Alright. Moving.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.ack.say.1.engage_reserved",
                ["variantID"] = "engage_reserved",
            },
            {
                ["fallback"] = "Holding for now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.ack.say.1.hold_default",
                ["variantID"] = "hold_default",
            },
            {
                ["fallback"] = "Holding. Say when.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.ack.say.1.hold_eager",
                ["variantID"] = "hold_eager",
            },
            {
                ["fallback"] = "Okay. Holding here.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.ack.say.1.hold_hesitant",
                ["variantID"] = "hold_hesitant",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_horde",
        ["domainPath"] = "combat_horde",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.horde.prompt",
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
                                ["fallback"] = "That's a lot of them. We fighting or going around?",
                                ["id"] = "default",
                                ["templateID"] = "convo.combat.horde.prompt.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "That's a hell of a crowd. We taking them?",
                                ["id"] = "eager",
                                ["templateID"] = "convo.combat.horde.prompt.say.1.eager",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Horde ahead. Engage or go around?",
                                ["id"] = "reserved",
                                ["templateID"] = "convo.combat.horde.prompt.say.1.reserved",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "God... that's a lot. Are we really fighting all of them?",
                                ["id"] = "shaken",
                                ["templateID"] = "convo.combat.horde.prompt.say.1.shaken",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.horde",
            ["slots"] = {
                ["threat"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.threat",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "That's a lot of them. We fighting or going around?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.prompt.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "That's a hell of a crowd. We taking them?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.prompt.say.1.eager",
                    ["variantID"] = "eager",
                },
                {
                    ["fallback"] = "Horde ahead. Engage or go around?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.prompt.say.1.reserved",
                    ["variantID"] = "reserved",
                },
                {
                    ["fallback"] = "God... that's a lot. Are we really fighting all of them?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.prompt.say.1.shaken",
                    ["variantID"] = "shaken",
                },
            },
        },
        ["id"] = "combat.horde.prompt",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "prompt",
            ["sourceId"] = "combat.horde.prompt",
            ["sourcePath"] = "dialogue/combat_horde/combat_horde_prompt.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatHorde",
        ["namespace"] = "combat.horde",
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
                    ["id"] = "horde_detected",
                    ["kind"] = "world_event",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "REPLY",
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
                                ["fallback"] = "That's a lot of them. We fighting or going around?",
                                ["id"] = "default",
                            },
                            {
                                ["fallback"] = "That's a hell of a crowd. We taking them?",
                                ["id"] = "eager",
                            },
                            {
                                ["fallback"] = "Horde ahead. Engage or go around?",
                                ["id"] = "reserved",
                            },
                            {
                                ["fallback"] = "God... that's a lot. Are we really fighting all of them?",
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
                    ["id"] = "horde_threat",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REPLY",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "combat.horde.prompt",
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
                            ["fallback"] = "That's a lot of them. We fighting or going around?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.horde.prompt.say_1",
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
            ["threat"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.threat",
            },
        },
        ["sourceShard"] = "dialogue/combat_horde/combat_horde_prompt.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That's a lot of them. We fighting or going around?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.prompt.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "That's a hell of a crowd. We taking them?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.prompt.say.1.eager",
                ["variantID"] = "eager",
            },
            {
                ["fallback"] = "Horde ahead. Engage or go around?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.prompt.say.1.reserved",
                ["variantID"] = "reserved",
            },
            {
                ["fallback"] = "God... that's a lot. Are we really fighting all of them?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.prompt.say.1.shaken",
                ["variantID"] = "shaken",
            },
        },
        ["when"] = nil,
    },
}
