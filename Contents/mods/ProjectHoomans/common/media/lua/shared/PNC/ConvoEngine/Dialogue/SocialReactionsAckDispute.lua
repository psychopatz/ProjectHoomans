-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["domainPath"] = "social_reactions_ack_dispute",
        ["exchangeFamily"] = {
            ["familyID"] = "social.acknowledged",
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
                                ["fallback"] = "All right. Understood.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.acknowledged.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "%s, understood. We'll leave it there.",
                                ["id"] = "bond_guarded",
                                ["templateID"] = "convo.social.acknowledged.say.1.bond_guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "%s, all right.",
                                ["id"] = "bond_neutral",
                                ["templateID"] = "convo.social.acknowledged.say.1.bond_neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "%s, all right.",
                                ["id"] = "bond_terse",
                                ["templateID"] = "convo.social.acknowledged.say.1.bond_terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "%s, all right. I hear you.",
                                ["id"] = "bond_warm",
                                ["templateID"] = "convo.social.acknowledged.say.1.bond_warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Understood. We'll leave it there.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.social.acknowledged.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "All right.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.social.acknowledged.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "All right. I hear you.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.social.acknowledged.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social",
            ["textRoles"] = {
                {
                    ["fallback"] = "All right. Understood.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.acknowledged.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "%s, understood. We'll leave it there.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.acknowledged.say.1.bond_guarded",
                    ["variantID"] = "bond_guarded",
                },
                {
                    ["fallback"] = "%s, all right.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.acknowledged.say.1.bond_neutral",
                    ["variantID"] = "bond_neutral",
                },
                {
                    ["fallback"] = "%s, all right.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.acknowledged.say.1.bond_terse",
                    ["variantID"] = "bond_terse",
                },
                {
                    ["fallback"] = "%s, all right. I hear you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.acknowledged.say.1.bond_warm",
                    ["variantID"] = "bond_warm",
                },
                {
                    ["fallback"] = "Understood. We'll leave it there.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.acknowledged.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "All right.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.acknowledged.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "All right. I hear you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.acknowledged.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "social.acknowledged",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "acknowledged",
            ["sourceId"] = "social.acknowledged",
            ["sourcePath"] = "dialogue/social_reactions_ack_dispute/social_acknowledged.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialReactionsAckDispute",
        ["namespace"] = "social",
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
                                ["fallback"] = "All right. Understood.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "%s, understood. We'll leave it there.",
                                ["id"] = "bond_guarded",
                            },
                            {
                                ["fallback"] = "%s, all right.",
                                ["id"] = "bond_neutral",
                            },
                            {
                                ["fallback"] = "%s, all right.",
                                ["id"] = "bond_terse",
                            },
                            {
                                ["fallback"] = "%s, all right. I hear you.",
                                ["id"] = "bond_warm",
                            },
                            {
                                ["fallback"] = "Understood. We'll leave it there.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "All right.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "All right. I hear you.",
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
            ["responsePlanID"] = "social.acknowledged",
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
                            ["fallback"] = "All right. Understood.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.acknowledged.say_1",
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
        ["sourceShard"] = "dialogue/social_reactions_ack_dispute/social_acknowledged.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "All right. Understood.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.acknowledged.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "%s, understood. We'll leave it there.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.acknowledged.say.1.bond_guarded",
                ["variantID"] = "bond_guarded",
            },
            {
                ["fallback"] = "%s, all right.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.acknowledged.say.1.bond_neutral",
                ["variantID"] = "bond_neutral",
            },
            {
                ["fallback"] = "%s, all right.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.acknowledged.say.1.bond_terse",
                ["variantID"] = "bond_terse",
            },
            {
                ["fallback"] = "%s, all right. I hear you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.acknowledged.say.1.bond_warm",
                ["variantID"] = "bond_warm",
            },
            {
                ["fallback"] = "Understood. We'll leave it there.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.acknowledged.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "All right.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.acknowledged.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "All right. I hear you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.acknowledged.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["domainPath"] = "social_reactions_ack_dispute",
        ["exchangeFamily"] = {
            ["familyID"] = "social.dispute_friendly",
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
                                ["fallback"] = "I disagree, but I hear what you're saying.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.dispute_friendly.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I disagree. Leave it there.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.social.dispute_friendly.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Disagree.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.social.dispute_friendly.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I disagree, friend, but I respect your perspective.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.social.dispute_friendly.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social",
            ["textRoles"] = {
                {
                    ["fallback"] = "I disagree, but I hear what you're saying.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.dispute_friendly.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I disagree. Leave it there.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.dispute_friendly.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Disagree.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.dispute_friendly.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "I disagree, friend, but I respect your perspective.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.dispute_friendly.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "social.dispute_friendly",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "dispute_friendly",
            ["sourceId"] = "social.dispute_friendly",
            ["sourcePath"] = "dialogue/social_reactions_ack_dispute/social_dispute_friendly.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialReactionsAckDispute",
        ["namespace"] = "social",
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
                                ["fallback"] = "I disagree, but I hear what you're saying.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "I disagree. Leave it there.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Disagree.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "I disagree, friend, but I respect your perspective.",
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
            ["responsePlanID"] = "social.dispute_friendly",
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
                            ["fallback"] = "I disagree, but I hear what you're saying.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.dispute_friendly.say_1",
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
        ["sourceShard"] = "dialogue/social_reactions_ack_dispute/social_dispute_friendly.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I disagree, but I hear what you're saying.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.dispute_friendly.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I disagree. Leave it there.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.dispute_friendly.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Disagree.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.dispute_friendly.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "I disagree, friend, but I respect your perspective.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.dispute_friendly.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["domainPath"] = "social_reactions_ack_dispute",
        ["exchangeFamily"] = {
            ["familyID"] = "social.dispute_stressed",
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
                                ["fallback"] = "Tensions are high. Let's table this for later.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.dispute_stressed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I hear you. Not now.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.social.dispute_stressed.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Not now.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.social.dispute_stressed.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Hey, we're both frayed right now. Let's take a breath.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.social.dispute_stressed.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social",
            ["textRoles"] = {
                {
                    ["fallback"] = "Tensions are high. Let's table this for later.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.dispute_stressed.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I hear you. Not now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.dispute_stressed.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Not now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.dispute_stressed.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "Hey, we're both frayed right now. Let's take a breath.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.dispute_stressed.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "social.dispute_stressed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "dispute_stressed",
            ["sourceId"] = "social.dispute_stressed",
            ["sourcePath"] = "dialogue/social_reactions_ack_dispute/social_dispute_stressed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialReactionsAckDispute",
        ["namespace"] = "social",
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
                                ["fallback"] = "Tensions are high. Let's table this for later.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "I hear you. Not now.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Not now.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "Hey, we're both frayed right now. Let's take a breath.",
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
            ["responsePlanID"] = "social.dispute_stressed",
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
                            ["fallback"] = "Tensions are high. Let's table this for later.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.dispute_stressed.say_1",
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
        ["sourceShard"] = "dialogue/social_reactions_ack_dispute/social_dispute_stressed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Tensions are high. Let's table this for later.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.dispute_stressed.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I hear you. Not now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.dispute_stressed.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Not now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.dispute_stressed.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "Hey, we're both frayed right now. Let's take a breath.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.dispute_stressed.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["domainPath"] = "social_reactions_ack_dispute",
        ["exchangeFamily"] = {
            ["familyID"] = "social.dispute_trusted",
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
                                ["fallback"] = "I trust your judgment usually, but not on this.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.dispute_trusted.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I still don't agree. Leave it there.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.social.dispute_trusted.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Not this time.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.social.dispute_trusted.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "You know I'd follow you through hell, but not into this.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.social.dispute_trusted.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social",
            ["textRoles"] = {
                {
                    ["fallback"] = "I trust your judgment usually, but not on this.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.dispute_trusted.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I still don't agree. Leave it there.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.dispute_trusted.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Not this time.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.dispute_trusted.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "You know I'd follow you through hell, but not into this.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.dispute_trusted.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "social.dispute_trusted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "dispute_trusted",
            ["sourceId"] = "social.dispute_trusted",
            ["sourcePath"] = "dialogue/social_reactions_ack_dispute/social_dispute_trusted.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialReactionsAckDispute",
        ["namespace"] = "social",
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
                                ["fallback"] = "I trust your judgment usually, but not on this.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "I still don't agree. Leave it there.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Not this time.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "You know I'd follow you through hell, but not into this.",
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
            ["responsePlanID"] = "social.dispute_trusted",
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
                            ["fallback"] = "I trust your judgment usually, but not on this.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.dispute_trusted.say_1",
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
        ["sourceShard"] = "dialogue/social_reactions_ack_dispute/social_dispute_trusted.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I trust your judgment usually, but not on this.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.dispute_trusted.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I still don't agree. Leave it there.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.dispute_trusted.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Not this time.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.dispute_trusted.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "You know I'd follow you through hell, but not into this.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.dispute_trusted.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["domainPath"] = "social_reactions_ack_dispute",
        ["exchangeFamily"] = {
            ["familyID"] = "social.dispute_withdrawn",
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
                                ["fallback"] = "All right. Let's step back from this.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.dispute_withdrawn.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Let's leave it there.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.social.dispute_withdrawn.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Drop it.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.social.dispute_withdrawn.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Let's leave it there for now, friend. We're still good.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.social.dispute_withdrawn.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social",
            ["textRoles"] = {
                {
                    ["fallback"] = "All right. Let's step back from this.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.dispute_withdrawn.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Let's leave it there.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.dispute_withdrawn.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Drop it.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.dispute_withdrawn.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "Let's leave it there for now, friend. We're still good.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.dispute_withdrawn.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "social.dispute_withdrawn",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "dispute_withdrawn",
            ["sourceId"] = "social.dispute_withdrawn",
            ["sourcePath"] = "dialogue/social_reactions_ack_dispute/social_dispute_withdrawn.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialReactionsAckDispute",
        ["namespace"] = "social",
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
                                ["fallback"] = "All right. Let's step back from this.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Let's leave it there.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Drop it.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "Let's leave it there for now, friend. We're still good.",
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
            ["responsePlanID"] = "social.dispute_withdrawn",
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
                            ["fallback"] = "All right. Let's step back from this.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.dispute_withdrawn.say_1",
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
        ["sourceShard"] = "dialogue/social_reactions_ack_dispute/social_dispute_withdrawn.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "All right. Let's step back from this.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.dispute_withdrawn.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Let's leave it there.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.dispute_withdrawn.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Drop it.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.dispute_withdrawn.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "Let's leave it there for now, friend. We're still good.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.dispute_withdrawn.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["domainPath"] = "social_reactions_ack_dispute",
        ["exchangeFamily"] = {
            ["familyID"] = "social.hostile_boundary",
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
                                ["fallback"] = "That tone isn't acceptable.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.hostile_boundary.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Don't talk to me like that.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.social.hostile_boundary.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Watch it.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.social.hostile_boundary.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Hey, where is this hostility coming from? We're allies.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.social.hostile_boundary.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social",
            ["textRoles"] = {
                {
                    ["fallback"] = "That tone isn't acceptable.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.hostile_boundary.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Don't talk to me like that.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.hostile_boundary.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Watch it.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.hostile_boundary.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "Hey, where is this hostility coming from? We're allies.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.hostile_boundary.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "social.hostile_boundary",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "hostile_boundary",
            ["sourceId"] = "social.hostile_boundary",
            ["sourcePath"] = "dialogue/social_reactions_ack_dispute/social_hostile_boundary.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialReactionsAckDispute",
        ["namespace"] = "social",
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
                                ["fallback"] = "That tone isn't acceptable.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Don't talk to me like that.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Watch it.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "Hey, where is this hostility coming from? We're allies.",
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
            ["responsePlanID"] = "social.hostile_boundary",
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
                            ["fallback"] = "That tone isn't acceptable.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.hostile_boundary.say_1",
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
        ["sourceShard"] = "dialogue/social_reactions_ack_dispute/social_hostile_boundary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That tone isn't acceptable.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.hostile_boundary.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Don't talk to me like that.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.hostile_boundary.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Watch it.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.hostile_boundary.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "Hey, where is this hostility coming from? We're allies.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.hostile_boundary.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["domainPath"] = "social_reactions_ack_dispute",
        ["exchangeFamily"] = {
            ["familyID"] = "social.reaction.responses",
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
                                ["fallback"] = "I appreciate you saying that. We're all under pressure.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.reaction.responses.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.reaction",
            ["textRoles"] = {
                {
                    ["fallback"] = "I appreciate you saying that. We're all under pressure.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.reaction.responses.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.reaction.responses",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "responses",
            ["sourceId"] = "social.reaction.responses",
            ["sourcePath"] = "dialogue/social_reactions_ack_dispute/social_reaction_responses.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialReactionsAckDispute",
        ["namespace"] = "social.reaction",
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
                ["textRows"] = {
                    {
                        ["fallback"] = "I appreciate you saying that. We're all under pressure.",
                        ["key"] = "UI_PNC_Conversation_Semantic_ApologyTrusted",
                    },
                    {
                        ["fallback"] = "I appreciate you saying that.",
                        ["key"] = "UI_PNC_Conversation_Semantic_ComplimentAlternate",
                    },
                    {
                        ["fallback"] = "Thanks. That's kind of you.",
                        ["key"] = "UI_PNC_Conversation_Semantic_ComplimentDefault",
                    },
                    {
                        ["fallback"] = "Thanks. You seem pretty great yourself.",
                        ["key"] = "UI_PNC_Conversation_Semantic_ComplimentFriendly",
                    },
                    {
                        ["fallback"] = "Thanks. Hearing that from you means a lot.",
                        ["key"] = "UI_PNC_Conversation_Semantic_ComplimentTrusted",
                    },
                    {
                        ["fallback"] = "Oh. Thank you, that's kind of you.",
                        ["key"] = "UI_PNC_Conversation_Semantic_ComplimentWithdrawn",
                    },
                    {
                        ["fallback"] = "I see it differently, but we're okay.",
                        ["key"] = "UI_PNC_Conversation_Semantic_DisputeFriendly",
                    },
                    {
                        ["fallback"] = "I hear you, but I can't take that on while I'm this tense.",
                        ["key"] = "UI_PNC_Conversation_Semantic_DisputeStressed",
                    },
                    {
                        ["fallback"] = "I respect that. I still don't agree.",
                        ["key"] = "UI_PNC_Conversation_Semantic_DisputeTrusted",
                    },
                    {
                        ["fallback"] = "Let's leave it there.",
                        ["key"] = "UI_PNC_Conversation_Semantic_DisputeWithdrawn",
                    },
                    {
                        ["fallback"] = "That's kind of you. I'll keep it in mind.",
                        ["key"] = "UI_PNC_Conversation_Semantic_OfferFriendly",
                    },
                    {
                        ["fallback"] = "I appreciate it, but I need a moment before I can think about food.",
                        ["key"] = "UI_PNC_Conversation_Semantic_OfferStressed",
                    },
                    {
                        ["fallback"] = "Thanks. I know I can count on you.",
                        ["key"] = "UI_PNC_Conversation_Semantic_OfferTrusted",
                    },
                    {
                        ["fallback"] = "No, thanks. I'd rather handle it myself.",
                        ["key"] = "UI_PNC_Conversation_Semantic_OfferWithdrawn",
                    },
                    {
                        ["fallback"] = "That's kind of you to ask. I don't have a clear answer right now.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusAfterCompliment",
                    },
                    {
                        ["fallback"] = "Thanks for saying that. I can't give you a clear answer about relationships right now.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusAfterComplimentAlt",
                    },
                    {
                        ["fallback"] = "Thanks for the compliment, but I thought we were already together.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusAfterComplimentCommitted",
                    },
                    {
                        ["fallback"] = "Thanks, but I'd rather keep that personal.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusAfterComplimentWithdrawn",
                    },
                    {
                        ["fallback"] = "No problem. I'll leave it.",
                        ["key"] = "UI_PNC_Conversation_Semantic_RefuseRequest",
                    },
                    {
                        ["fallback"] = "Don't talk about yourself like that.",
                        ["key"] = "UI_PNC_Conversation_Semantic_SelfReflectionDefault",
                    },
                    {
                        ["fallback"] = "Hey. Don't talk about yourself like that. You matter.",
                        ["key"] = "UI_PNC_Conversation_Semantic_SelfReflectionFriendly",
                    },
                    {
                        ["fallback"] = "We've all made mistakes. Focus on what comes next.",
                        ["key"] = "UI_PNC_Conversation_Semantic_SelfReflectionStressed",
                    },
                    {
                        ["fallback"] = "You're harder on yourself than you need to be.",
                        ["key"] = "UI_PNC_Conversation_Semantic_SelfReflectionTrusted",
                    },
                    {
                        ["fallback"] = "Don't make a habit of saying things like that.",
                        ["key"] = "UI_PNC_Conversation_Semantic_SelfReflectionWithdrawn",
                    },
                    {
                        ["fallback"] = "I heard you, but I couldn't apply that social reaction.",
                        ["key"] = "UI_PNC_Conversation_Semantic_SocialInteractionRejected",
                    },
                    {
                        ["fallback"] = "I heard you, but I couldn't send that social reaction right now.",
                        ["key"] = "UI_PNC_Conversation_Semantic_SocialInteractionUnavailable",
                    },
                    {
                        ["fallback"] = "I've had enough. Back off before this gets worse.",
                        ["key"] = "UI_PNC_Conversation_Semantic_ThreatStressed",
                    },
                    {
                        ["fallback"] = "Don't make this personal. Step back.",
                        ["key"] = "UI_PNC_Conversation_Semantic_ThreatTrusted",
                    },
                    {
                        ["fallback"] = "Keep your distance. I'm not discussing this.",
                        ["key"] = "UI_PNC_Conversation_Semantic_ThreatWithdrawn",
                    },
                },
                ["textTarget"] = "convo/SemanticResponses",
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
                                ["fallback"] = "I appreciate you saying that. We're all under pressure.",
                                ["id"] = "neutral",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.reaction.responses",
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
                            ["fallback"] = "I appreciate you saying that. We're all under pressure.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.reaction.responses.say_1",
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
        ["sourceShard"] = "dialogue/social_reactions_ack_dispute/social_reaction_responses.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I appreciate you saying that. We're all under pressure.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.reaction.responses.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
