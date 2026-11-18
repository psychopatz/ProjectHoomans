-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "compatibility_content",
        ["domainPath"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.projectalife.meta.crash",
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
                                ["fallback"] = "That crash sounded close. Keep your eyes open.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.projectalife.meta.crash.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "That crash sounded close. Keep your eyes open.",
                                    },
                                    ["TL"] = {
                                        "That crash sounded close. Keep your eyes open.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.projectalife.meta",
            ["textRoles"] = {
                {
                    ["fallback"] = "That crash sounded close. Keep your eyes open.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.projectalife.meta.crash.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "That crash sounded close. Keep your eyes open.",
                        },
                        ["TL"] = {
                            "That crash sounded close. Keep your eyes open.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.projectalife.meta.crash",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "crash",
            ["sourceId"] = "integration.projectalife.meta.crash",
            ["sourcePath"] = "dialogue/compatibility_content/integration_projectalife_meta_crash.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent/CrashToGunfire",
        ["namespace"] = "integration.projectalife.meta",
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
                    ["domain"] = "integration",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
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
                                        "That crash sounded close. Keep your eyes open.",
                                    },
                                    ["TL"] = {
                                        "That crash sounded close. Keep your eyes open.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "integration",
                    ["id"] = "projectalife",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.projectalife.meta.crash",
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
                            ["fallback"] = "That crash sounded close. Keep your eyes open.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.integration.projectalife.meta.crash.say_1",
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
        ["sourceShard"] = "dialogue/compatibility_content/integration_projectalife_meta_crash.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That crash sounded close. Keep your eyes open.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.projectalife.meta.crash.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "That crash sounded close. Keep your eyes open.",
                    },
                    ["TL"] = {
                        "That crash sounded close. Keep your eyes open.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["domainPath"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.projectalife.meta.gunfire",
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
                                ["fallback"] = "Someone is shooting nearby. Keep your head down.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.projectalife.meta.gunfire.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Someone is shooting nearby. Keep your head down.",
                                    },
                                    ["TL"] = {
                                        "Someone is shooting nearby. Keep your head down.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.projectalife.meta",
            ["textRoles"] = {
                {
                    ["fallback"] = "Someone is shooting nearby. Keep your head down.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.projectalife.meta.gunfire.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Someone is shooting nearby. Keep your head down.",
                        },
                        ["TL"] = {
                            "Someone is shooting nearby. Keep your head down.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.projectalife.meta.gunfire",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "gunfire",
            ["sourceId"] = "integration.projectalife.meta.gunfire",
            ["sourcePath"] = "dialogue/compatibility_content/integration_projectalife_meta_gunfire.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent/CrashToGunfire",
        ["namespace"] = "integration.projectalife.meta",
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
                    ["domain"] = "integration",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
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
                                        "Someone is shooting nearby. Keep your head down.",
                                    },
                                    ["TL"] = {
                                        "Someone is shooting nearby. Keep your head down.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "integration",
                    ["id"] = "projectalife",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.projectalife.meta.gunfire",
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
                            ["fallback"] = "Someone is shooting nearby. Keep your head down.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.integration.projectalife.meta.gunfire.say_1",
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
        ["sourceShard"] = "dialogue/compatibility_content/integration_projectalife_meta_gunfire.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Someone is shooting nearby. Keep your head down.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.projectalife.meta.gunfire.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Someone is shooting nearby. Keep your head down.",
                    },
                    ["TL"] = {
                        "Someone is shooting nearby. Keep your head down.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
