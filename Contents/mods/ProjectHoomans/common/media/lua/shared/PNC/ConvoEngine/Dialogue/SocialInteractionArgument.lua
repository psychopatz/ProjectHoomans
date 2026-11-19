-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_argument",
        ["domainPath"] = "social_interaction_argument",
        ["exchangeFamily"] = {
            ["familyID"] = "interaction.argument.deescalate",
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
                                ["fallback"] = "Easy. We don't need to make this worse.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.interaction.argument.deescalate.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Fine. Just lower your voice.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.interaction.argument.deescalate.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Easy.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.interaction.argument.deescalate.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Calm down. This isn't helping either of us.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.interaction.argument.deescalate.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "interaction.argument",
            ["textRoles"] = {
                {
                    ["fallback"] = "Easy. We don't need to make this worse.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.argument.deescalate.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Fine. Just lower your voice.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.argument.deescalate.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Easy.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.argument.deescalate.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "Calm down. This isn't helping either of us.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.argument.deescalate.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "interaction.argument.deescalate",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "deescalate",
            ["sourceId"] = "interaction.argument.deescalate",
            ["sourcePath"] = "dialogue/social_interaction_argument/interaction_argument_deescalate.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionArgument",
        ["namespace"] = "interaction.argument",
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
                    ["domain"] = "social",
                    ["owner"] = "ProjectHoomans",
                },
            },
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
                                ["fallback"] = "Easy. We don't need to make this worse.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Fine. Just lower your voice.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Easy.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "Calm down. This isn't helping either of us.",
                                ["id"] = "warm",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "interaction.argument.deescalate",
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
                            ["fallback"] = "Easy. We don't need to make this worse.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.interaction.argument.deescalate.say_1",
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
        ["sourceShard"] = "dialogue/social_interaction_argument/interaction_argument_deescalate.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Easy. We don't need to make this worse.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.argument.deescalate.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Fine. Just lower your voice.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.argument.deescalate.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Easy.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.argument.deescalate.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "Calm down. This isn't helping either of us.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.argument.deescalate.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_argument",
        ["domainPath"] = "social_interaction_argument",
        ["exchangeFamily"] = {
            ["familyID"] = "interaction.argument.retaliate",
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
                                ["fallback"] = "You're really testing me right now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.interaction.argument.retaliate.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Say that again and see how far it gets you.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.interaction.argument.retaliate.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Keep talking.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.interaction.argument.retaliate.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "You're pushing this too far.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.interaction.argument.retaliate.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "interaction.argument",
            ["textRoles"] = {
                {
                    ["fallback"] = "You're really testing me right now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.argument.retaliate.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Say that again and see how far it gets you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.argument.retaliate.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Keep talking.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.argument.retaliate.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "You're pushing this too far.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.argument.retaliate.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "interaction.argument.retaliate",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "retaliate",
            ["sourceId"] = "interaction.argument.retaliate",
            ["sourcePath"] = "dialogue/social_interaction_argument/interaction_argument_retaliate.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionArgument",
        ["namespace"] = "interaction.argument",
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
                    ["domain"] = "social",
                    ["owner"] = "ProjectHoomans",
                },
            },
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
                                ["fallback"] = "You're really testing me right now.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Say that again and see how far it gets you.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Keep talking.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "You're pushing this too far.",
                                ["id"] = "warm",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "interaction.argument.retaliate",
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
                            ["fallback"] = "You're really testing me right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.interaction.argument.retaliate.say_1",
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
        ["sourceShard"] = "dialogue/social_interaction_argument/interaction_argument_retaliate.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "You're really testing me right now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.argument.retaliate.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Say that again and see how far it gets you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.argument.retaliate.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Keep talking.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.argument.retaliate.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "You're pushing this too far.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.argument.retaliate.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
}
