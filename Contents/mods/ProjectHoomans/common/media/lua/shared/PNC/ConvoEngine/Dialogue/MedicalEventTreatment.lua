-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_treatment",
        ["domainPath"] = "medical_event_treatment",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.treatment",
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
                                ["fallback"] = "The wound is treated. I can move when you are ready.",
                                ["id"] = "bandage",
                                ["templateID"] = "convo.medical.distress.treatment.say.1.bandage",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Thank you. That treatment helped.",
                                ["id"] = "default",
                                ["templateID"] = "convo.medical.distress.treatment.say.1.default",
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
                    ["fallback"] = "The wound is treated. I can move when you are ready.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.treatment.say.1.bandage",
                    ["variantID"] = "bandage",
                },
                {
                    ["fallback"] = "Thank you. That treatment helped.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.treatment.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "medical.distress.treatment",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "treatment",
            ["sourceId"] = "medical.distress.treatment",
            ["sourcePath"] = "dialogue/medical_event_treatment/medical_distress_treatment.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventTreatment",
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
                                ["fallback"] = "The wound is treated. I can move when you are ready.",
                                ["id"] = "bandage",
                            },
                            {
                                ["fallback"] = "Thank you. That treatment helped.",
                                ["id"] = "default",
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
            ["responsePlanID"] = "medical.distress.treatment",
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
                            ["fallback"] = "The wound is treated. I can move when you are ready.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.medical.distress.treatment.say_1",
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
        ["sourceShard"] = "dialogue/medical_event_treatment/medical_distress_treatment.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "The wound is treated. I can move when you are ready.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.treatment.say.1.bandage",
                ["variantID"] = "bandage",
            },
            {
                ["fallback"] = "Thank you. That treatment helped.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.treatment.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
}
