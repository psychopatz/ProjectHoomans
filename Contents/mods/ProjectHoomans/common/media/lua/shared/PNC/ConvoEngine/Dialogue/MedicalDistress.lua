-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_distress",
        ["domainPath"] = "medical_distress",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress",
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
                                ["fallback"] = "I need help with this wound.",
                                ["id"] = "default",
                                ["templateID"] = "convo.medical.distress.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Please. I need help with this wound, don't let me die.",
                                ["id"] = "mercy",
                                ["templateID"] = "convo.medical.distress.say.1.mercy",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I am hurt! I need help now!",
                                ["id"] = "urgent",
                                ["templateID"] = "convo.medical.distress.say.1.urgent",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical",
            ["textRoles"] = {
                {
                    ["fallback"] = "I need help with this wound.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Please. I need help with this wound, don't let me die.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.say.1.mercy",
                    ["variantID"] = "mercy",
                },
                {
                    ["fallback"] = "I am hurt! I need help now!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.say.1.urgent",
                    ["variantID"] = "urgent",
                },
            },
        },
        ["id"] = "medical.distress",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "distress",
            ["sourceId"] = "medical.distress",
            ["sourcePath"] = "dialogue/medical_distress/medical_distress.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalDistress",
        ["namespace"] = "medical",
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
                    ["id"] = "medical_emergency",
                    ["kind"] = "health_event",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:medical_event",
                ["responseAct"] = "MEDICAL_RESPONSE",
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
                                ["fallback"] = "I need help with this wound.",
                                ["id"] = "default",
                            },
                            {
                                ["fallback"] = "Please. I need help with this wound, don't let me die.",
                                ["id"] = "mercy",
                            },
                            {
                                ["fallback"] = "I am hurt! I need help now!",
                                ["id"] = "urgent",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "medical",
                    ["id"] = "medical_distress",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "MEDICAL_RESPONSE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "medical.distress",
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
                            ["fallback"] = "I need help with this wound.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.medical.distress.say_1",
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
        ["sourceShard"] = "dialogue/medical_distress/medical_distress.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I need help with this wound.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Please. I need help with this wound, don't let me die.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.say.1.mercy",
                ["variantID"] = "mercy",
            },
            {
                ["fallback"] = "I am hurt! I need help now!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.say.1.urgent",
                ["variantID"] = "urgent",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_distress",
        ["domainPath"] = "medical_distress",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.call",
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
                                ["fallback"] = "I'm hurt and down! Need a bandage over here!",
                                ["id"] = "bandage",
                                ["templateID"] = "convo.medical.distress.call.say.1.bandage",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I'm bleeding out! I need a tourniquet or bandage now!",
                                ["id"] = "bleedout",
                                ["templateID"] = "convo.medical.distress.call.say.1.bleedout",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I'm down! I need help over here!",
                                ["id"] = "default",
                                ["templateID"] = "convo.medical.distress.call.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "So thirsty... I need water before I pass out.",
                                ["id"] = "dehydration",
                                ["templateID"] = "convo.medical.distress.call.say.1.dehydration",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Pushed too far. I can't lift my arms.",
                                ["id"] = "exhaustion",
                                ["templateID"] = "convo.medical.distress.call.say.1.exhaustion",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I'm down! Please, don't kill me!",
                                ["id"] = "mercy",
                                ["templateID"] = "convo.medical.distress.call.say.1.mercy",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I'm trapped here! I need help over here!",
                                ["id"] = "rescue",
                                ["templateID"] = "convo.medical.distress.call.say.1.rescue",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Haven't eaten in days... I'm starving to death.",
                                ["id"] = "starvation",
                                ["templateID"] = "convo.medical.distress.call.say.1.starvation",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm hurt and down! Need a bandage over here!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.call.say.1.bandage",
                    ["variantID"] = "bandage",
                },
                {
                    ["fallback"] = "I'm bleeding out! I need a tourniquet or bandage now!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.call.say.1.bleedout",
                    ["variantID"] = "bleedout",
                },
                {
                    ["fallback"] = "I'm down! I need help over here!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.call.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "So thirsty... I need water before I pass out.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.call.say.1.dehydration",
                    ["variantID"] = "dehydration",
                },
                {
                    ["fallback"] = "Pushed too far. I can't lift my arms.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.call.say.1.exhaustion",
                    ["variantID"] = "exhaustion",
                },
                {
                    ["fallback"] = "I'm down! Please, don't kill me!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.call.say.1.mercy",
                    ["variantID"] = "mercy",
                },
                {
                    ["fallback"] = "I'm trapped here! I need help over here!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.call.say.1.rescue",
                    ["variantID"] = "rescue",
                },
                {
                    ["fallback"] = "Haven't eaten in days... I'm starving to death.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.call.say.1.starvation",
                    ["variantID"] = "starvation",
                },
            },
        },
        ["id"] = "medical.distress.call",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "call",
            ["sourceId"] = "medical.distress.call",
            ["sourcePath"] = "dialogue/medical_distress/medical_distress_call.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalDistress",
        ["namespace"] = "medical.distress",
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
                    ["id"] = "medical_emergency",
                    ["kind"] = "health_event",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:medical_event",
                ["responseAct"] = "MEDICAL_RESPONSE",
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
                                ["fallback"] = "I'm hurt and down! Need a bandage over here!",
                                ["id"] = "bandage",
                            },
                            {
                                ["fallback"] = "I'm bleeding out! I need a tourniquet or bandage now!",
                                ["id"] = "bleedout",
                            },
                            {
                                ["fallback"] = "I'm down! I need help over here!",
                                ["id"] = "default",
                            },
                            {
                                ["fallback"] = "So thirsty... I need water before I pass out.",
                                ["id"] = "dehydration",
                            },
                            {
                                ["fallback"] = "Pushed too far. I can't lift my arms.",
                                ["id"] = "exhaustion",
                            },
                            {
                                ["fallback"] = "I'm down! Please, don't kill me!",
                                ["id"] = "mercy",
                            },
                            {
                                ["fallback"] = "I'm trapped here! I need help over here!",
                                ["id"] = "rescue",
                            },
                            {
                                ["fallback"] = "Haven't eaten in days... I'm starving to death.",
                                ["id"] = "starvation",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "medical",
                    ["id"] = "medical_distress",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "MEDICAL_RESPONSE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "medical.distress.call",
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
                            ["fallback"] = "I'm hurt and down! Need a bandage over here!",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.medical.distress.call.say_1",
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
        ["sourceShard"] = "dialogue/medical_distress/medical_distress_call.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm hurt and down! Need a bandage over here!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.call.say.1.bandage",
                ["variantID"] = "bandage",
            },
            {
                ["fallback"] = "I'm bleeding out! I need a tourniquet or bandage now!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.call.say.1.bleedout",
                ["variantID"] = "bleedout",
            },
            {
                ["fallback"] = "I'm down! I need help over here!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.call.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "So thirsty... I need water before I pass out.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.call.say.1.dehydration",
                ["variantID"] = "dehydration",
            },
            {
                ["fallback"] = "Pushed too far. I can't lift my arms.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.call.say.1.exhaustion",
                ["variantID"] = "exhaustion",
            },
            {
                ["fallback"] = "I'm down! Please, don't kill me!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.call.say.1.mercy",
                ["variantID"] = "mercy",
            },
            {
                ["fallback"] = "I'm trapped here! I need help over here!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.call.say.1.rescue",
                ["variantID"] = "rescue",
            },
            {
                ["fallback"] = "Haven't eaten in days... I'm starving to death.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.call.say.1.starvation",
                ["variantID"] = "starvation",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_distress",
        ["domainPath"] = "medical_distress",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.repeat",
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
                                ["fallback"] = "I still need these wounds patched! Hurry!",
                                ["id"] = "bandage",
                                ["templateID"] = "convo.medical.distress.repeat.say.1.bandage",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I am still losing blood! Please, help me!",
                                ["id"] = "bleedout",
                                ["templateID"] = "convo.medical.distress.repeat.say.1.bleedout",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I'm not up yet. Please help me.",
                                ["id"] = "default",
                                ["templateID"] = "convo.medical.distress.repeat.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I still need water to recover. My throat is on fire.",
                                ["id"] = "dehydration",
                                ["templateID"] = "convo.medical.distress.repeat.say.1.dehydration",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I still need a little more time to recover.",
                                ["id"] = "exhaustion",
                                ["templateID"] = "convo.medical.distress.repeat.say.1.exhaustion",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I am still asking you to spare me. Please.",
                                ["id"] = "mercy",
                                ["templateID"] = "convo.medical.distress.repeat.say.1.mercy",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I am still down here! Do not leave me!",
                                ["id"] = "rescue",
                                ["templateID"] = "convo.medical.distress.repeat.say.1.rescue",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I still need something to eat. I'm fading fast.",
                                ["id"] = "starvation",
                                ["templateID"] = "convo.medical.distress.repeat.say.1.starvation",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress",
            ["textRoles"] = {
                {
                    ["fallback"] = "I still need these wounds patched! Hurry!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.repeat.say.1.bandage",
                    ["variantID"] = "bandage",
                },
                {
                    ["fallback"] = "I am still losing blood! Please, help me!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.repeat.say.1.bleedout",
                    ["variantID"] = "bleedout",
                },
                {
                    ["fallback"] = "I'm not up yet. Please help me.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.repeat.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I still need water to recover. My throat is on fire.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.repeat.say.1.dehydration",
                    ["variantID"] = "dehydration",
                },
                {
                    ["fallback"] = "I still need a little more time to recover.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.repeat.say.1.exhaustion",
                    ["variantID"] = "exhaustion",
                },
                {
                    ["fallback"] = "I am still asking you to spare me. Please.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.repeat.say.1.mercy",
                    ["variantID"] = "mercy",
                },
                {
                    ["fallback"] = "I am still down here! Do not leave me!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.repeat.say.1.rescue",
                    ["variantID"] = "rescue",
                },
                {
                    ["fallback"] = "I still need something to eat. I'm fading fast.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.repeat.say.1.starvation",
                    ["variantID"] = "starvation",
                },
            },
        },
        ["id"] = "medical.distress.repeat",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "repeat",
            ["sourceId"] = "medical.distress.repeat",
            ["sourcePath"] = "dialogue/medical_distress/medical_distress_repeat.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalDistress",
        ["namespace"] = "medical.distress",
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
                    ["id"] = "medical_emergency",
                    ["kind"] = "health_event",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:medical_event",
                ["responseAct"] = "MEDICAL_RESPONSE",
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
                                ["fallback"] = "I still need these wounds patched! Hurry!",
                                ["id"] = "bandage",
                            },
                            {
                                ["fallback"] = "I am still losing blood! Please, help me!",
                                ["id"] = "bleedout",
                            },
                            {
                                ["fallback"] = "I'm not up yet. Please help me.",
                                ["id"] = "default",
                            },
                            {
                                ["fallback"] = "I still need water to recover. My throat is on fire.",
                                ["id"] = "dehydration",
                            },
                            {
                                ["fallback"] = "I still need a little more time to recover.",
                                ["id"] = "exhaustion",
                            },
                            {
                                ["fallback"] = "I am still asking you to spare me. Please.",
                                ["id"] = "mercy",
                            },
                            {
                                ["fallback"] = "I am still down here! Do not leave me!",
                                ["id"] = "rescue",
                            },
                            {
                                ["fallback"] = "I still need something to eat. I'm fading fast.",
                                ["id"] = "starvation",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "medical",
                    ["id"] = "medical_distress",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "MEDICAL_RESPONSE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "medical.distress.repeat",
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
                            ["fallback"] = "I still need these wounds patched! Hurry!",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.medical.distress.repeat.say_1",
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
        ["sourceShard"] = "dialogue/medical_distress/medical_distress_repeat.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I still need these wounds patched! Hurry!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.repeat.say.1.bandage",
                ["variantID"] = "bandage",
            },
            {
                ["fallback"] = "I am still losing blood! Please, help me!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.repeat.say.1.bleedout",
                ["variantID"] = "bleedout",
            },
            {
                ["fallback"] = "I'm not up yet. Please help me.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.repeat.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I still need water to recover. My throat is on fire.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.repeat.say.1.dehydration",
                ["variantID"] = "dehydration",
            },
            {
                ["fallback"] = "I still need a little more time to recover.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.repeat.say.1.exhaustion",
                ["variantID"] = "exhaustion",
            },
            {
                ["fallback"] = "I am still asking you to spare me. Please.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.repeat.say.1.mercy",
                ["variantID"] = "mercy",
            },
            {
                ["fallback"] = "I am still down here! Do not leave me!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.repeat.say.1.rescue",
                ["variantID"] = "rescue",
            },
            {
                ["fallback"] = "I still need something to eat. I'm fading fast.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.repeat.say.1.starvation",
                ["variantID"] = "starvation",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_distress",
        ["domainPath"] = "medical_distress",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.teammate",
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
                                ["fallback"] = "They are hurt! Stay with them while I cover you.",
                                ["id"] = "default",
                                ["templateID"] = "convo.medical.distress.teammate.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I found a bandage for them. Hold still while I patch them up.",
                                ["id"] = "found",
                                ["templateID"] = "convo.medical.distress.teammate.say.1.found",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I am out of bandages! Can someone spare one for them?",
                                ["id"] = "missing",
                                ["templateID"] = "convo.medical.distress.teammate.say.1.missing",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress",
            ["textRoles"] = {
                {
                    ["fallback"] = "They are hurt! Stay with them while I cover you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.teammate.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I found a bandage for them. Hold still while I patch them up.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.teammate.say.1.found",
                    ["variantID"] = "found",
                },
                {
                    ["fallback"] = "I am out of bandages! Can someone spare one for them?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.teammate.say.1.missing",
                    ["variantID"] = "missing",
                },
            },
        },
        ["id"] = "medical.distress.teammate",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "teammate",
            ["sourceId"] = "medical.distress.teammate",
            ["sourcePath"] = "dialogue/medical_distress/medical_distress_teammate.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalDistress",
        ["namespace"] = "medical.distress",
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
                    ["id"] = "medical_emergency",
                    ["kind"] = "health_event",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:medical_event",
                ["responseAct"] = "MEDICAL_RESPONSE",
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
                                ["fallback"] = "They are hurt! Stay with them while I cover you.",
                                ["id"] = "default",
                            },
                            {
                                ["fallback"] = "I found a bandage for them. Hold still while I patch them up.",
                                ["id"] = "found",
                            },
                            {
                                ["fallback"] = "I am out of bandages! Can someone spare one for them?",
                                ["id"] = "missing",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "medical",
                    ["id"] = "medical_distress",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "MEDICAL_RESPONSE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "medical.distress.teammate",
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
                            ["fallback"] = "They are hurt! Stay with them while I cover you.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.medical.distress.teammate.say_1",
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
        ["sourceShard"] = "dialogue/medical_distress/medical_distress_teammate.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "They are hurt! Stay with them while I cover you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.teammate.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I found a bandage for them. Hold still while I patch them up.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.teammate.say.1.found",
                ["variantID"] = "found",
            },
            {
                ["fallback"] = "I am out of bandages! Can someone spare one for them?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.teammate.say.1.missing",
                ["variantID"] = "missing",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_distress",
        ["domainPath"] = "medical_distress",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.update",
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
                                ["fallback"] = "I am still down and waiting for a patch.",
                                ["id"] = "bandage",
                                ["templateID"] = "convo.medical.distress.update.say.1.bandage",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "The bleeding has not stopped. I still need a bandage.",
                                ["id"] = "bleedout",
                                ["templateID"] = "convo.medical.distress.update.say.1.bleedout",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I am still down. I still need help.",
                                ["id"] = "default",
                                ["templateID"] = "convo.medical.distress.update.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I still need water before I can move.",
                                ["id"] = "dehydration",
                                ["templateID"] = "convo.medical.distress.update.say.1.dehydration",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I still need time to recover my strength.",
                                ["id"] = "exhaustion",
                                ["templateID"] = "convo.medical.distress.update.say.1.exhaustion",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I am still down. Please do not finish me.",
                                ["id"] = "mercy",
                                ["templateID"] = "convo.medical.distress.update.say.1.mercy",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I am still here. Please come back for me.",
                                ["id"] = "rescue",
                                ["templateID"] = "convo.medical.distress.update.say.1.rescue",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I still need food before I can get up.",
                                ["id"] = "starvation",
                                ["templateID"] = "convo.medical.distress.update.say.1.starvation",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress",
            ["textRoles"] = {
                {
                    ["fallback"] = "I am still down and waiting for a patch.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.update.say.1.bandage",
                    ["variantID"] = "bandage",
                },
                {
                    ["fallback"] = "The bleeding has not stopped. I still need a bandage.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.update.say.1.bleedout",
                    ["variantID"] = "bleedout",
                },
                {
                    ["fallback"] = "I am still down. I still need help.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.update.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I still need water before I can move.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.update.say.1.dehydration",
                    ["variantID"] = "dehydration",
                },
                {
                    ["fallback"] = "I still need time to recover my strength.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.update.say.1.exhaustion",
                    ["variantID"] = "exhaustion",
                },
                {
                    ["fallback"] = "I am still down. Please do not finish me.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.update.say.1.mercy",
                    ["variantID"] = "mercy",
                },
                {
                    ["fallback"] = "I am still here. Please come back for me.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.update.say.1.rescue",
                    ["variantID"] = "rescue",
                },
                {
                    ["fallback"] = "I still need food before I can get up.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.update.say.1.starvation",
                    ["variantID"] = "starvation",
                },
            },
        },
        ["id"] = "medical.distress.update",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "update",
            ["sourceId"] = "medical.distress.update",
            ["sourcePath"] = "dialogue/medical_distress/medical_distress_update.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalDistress",
        ["namespace"] = "medical.distress",
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
                    ["id"] = "medical_emergency",
                    ["kind"] = "health_event",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:medical_event",
                ["responseAct"] = "MEDICAL_RESPONSE",
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
                                ["fallback"] = "I am still down and waiting for a patch.",
                                ["id"] = "bandage",
                            },
                            {
                                ["fallback"] = "The bleeding has not stopped. I still need a bandage.",
                                ["id"] = "bleedout",
                            },
                            {
                                ["fallback"] = "I am still down. I still need help.",
                                ["id"] = "default",
                            },
                            {
                                ["fallback"] = "I still need water before I can move.",
                                ["id"] = "dehydration",
                            },
                            {
                                ["fallback"] = "I still need time to recover my strength.",
                                ["id"] = "exhaustion",
                            },
                            {
                                ["fallback"] = "I am still down. Please do not finish me.",
                                ["id"] = "mercy",
                            },
                            {
                                ["fallback"] = "I am still here. Please come back for me.",
                                ["id"] = "rescue",
                            },
                            {
                                ["fallback"] = "I still need food before I can get up.",
                                ["id"] = "starvation",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "medical",
                    ["id"] = "medical_distress",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "MEDICAL_RESPONSE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "medical.distress.update",
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
                            ["fallback"] = "I am still down and waiting for a patch.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.medical.distress.update.say_1",
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
        ["sourceShard"] = "dialogue/medical_distress/medical_distress_update.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I am still down and waiting for a patch.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.update.say.1.bandage",
                ["variantID"] = "bandage",
            },
            {
                ["fallback"] = "The bleeding has not stopped. I still need a bandage.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.update.say.1.bleedout",
                ["variantID"] = "bleedout",
            },
            {
                ["fallback"] = "I am still down. I still need help.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.update.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I still need water before I can move.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.update.say.1.dehydration",
                ["variantID"] = "dehydration",
            },
            {
                ["fallback"] = "I still need time to recover my strength.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.update.say.1.exhaustion",
                ["variantID"] = "exhaustion",
            },
            {
                ["fallback"] = "I am still down. Please do not finish me.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.update.say.1.mercy",
                ["variantID"] = "mercy",
            },
            {
                ["fallback"] = "I am still here. Please come back for me.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.update.say.1.rescue",
                ["variantID"] = "rescue",
            },
            {
                ["fallback"] = "I still need food before I can get up.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.update.say.1.starvation",
                ["variantID"] = "starvation",
            },
        },
        ["when"] = nil,
    },
}
