-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_first_contact",
        ["domainPath"] = "social_interaction_first_contact",
        ["exchangeFamily"] = {
            ["familyID"] = "interaction.first_contact.challenge",
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
                                ["fallback"] = "Hold it. Who are you?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.interaction.first_contact.challenge.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "That's close enough. What do you want?",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.interaction.first_contact.challenge.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Who are you?",
                                ["id"] = "terse",
                                ["templateID"] = "convo.interaction.first_contact.challenge.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Easy. I don't know you yet.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.interaction.first_contact.challenge.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "interaction.first_contact",
            ["textRoles"] = {
                {
                    ["fallback"] = "Hold it. Who are you?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.first_contact.challenge.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "That's close enough. What do you want?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.first_contact.challenge.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Who are you?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.first_contact.challenge.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "Easy. I don't know you yet.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.first_contact.challenge.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "interaction.first_contact.challenge",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "challenge",
            ["sourceId"] = "interaction.first_contact.challenge",
            ["sourcePath"] = "dialogue/social_interaction_first_contact/interaction_first_contact_challenge.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionFirstContact",
        ["namespace"] = "interaction.first_contact",
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
                                ["fallback"] = "Hold it. Who are you?",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "That's close enough. What do you want?",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Who are you?",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "Easy. I don't know you yet.",
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
            ["responsePlanID"] = "interaction.first_contact.challenge",
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
                            ["fallback"] = "Hold it. Who are you?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.interaction.first_contact.challenge.say_1",
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
        ["sourceShard"] = "dialogue/social_interaction_first_contact/interaction_first_contact_challenge.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Hold it. Who are you?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.first_contact.challenge.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "That's close enough. What do you want?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.first_contact.challenge.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Who are you?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.first_contact.challenge.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "Easy. I don't know you yet.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.first_contact.challenge.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
}
