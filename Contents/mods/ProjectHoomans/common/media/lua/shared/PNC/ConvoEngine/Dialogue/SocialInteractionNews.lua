-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_news",
        ["domainPath"] = "social_interaction_news",
        ["exchangeFamily"] = {
            ["familyID"] = "interaction.news.acknowledge",
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
                                ["fallback"] = "That's good to know.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.interaction.news.acknowledge.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I'll keep it in mind.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.interaction.news.acknowledge.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Got it.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.interaction.news.acknowledge.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Thanks for telling me. I'll keep that in mind.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.interaction.news.acknowledge.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "interaction.news",
            ["textRoles"] = {
                {
                    ["fallback"] = "That's good to know.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.news.acknowledge.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I'll keep it in mind.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.news.acknowledge.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Got it.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.news.acknowledge.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "Thanks for telling me. I'll keep that in mind.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.news.acknowledge.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "interaction.news.acknowledge",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "acknowledge",
            ["sourceId"] = "interaction.news.acknowledge",
            ["sourcePath"] = "dialogue/social_interaction_news/interaction_news_acknowledge.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionNews",
        ["namespace"] = "interaction.news",
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
                                ["fallback"] = "That's good to know.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "I'll keep it in mind.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Got it.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "Thanks for telling me. I'll keep that in mind.",
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
            ["responsePlanID"] = "interaction.news.acknowledge",
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
                            ["fallback"] = "That's good to know.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.interaction.news.acknowledge.say_1",
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
        ["sourceShard"] = "dialogue/social_interaction_news/interaction_news_acknowledge.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That's good to know.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.news.acknowledge.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I'll keep it in mind.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.news.acknowledge.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Got it.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.news.acknowledge.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "Thanks for telling me. I'll keep that in mind.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.news.acknowledge.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
}
