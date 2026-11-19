-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_hostile_offer_threat",
        ["domainPath"] = "social_reactions_hostile_offer_threat",
        ["exchangeFamily"] = {
            ["familyID"] = "social.hostile_short",
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
                                ["fallback"] = "Watch your language.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.hostile_short.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Watch your mouth. Now.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.social.hostile_short.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Shut it.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.social.hostile_short.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Hey, watch your mouth, friend. We're better than that.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.social.hostile_short.say.1.warm",
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
                    ["fallback"] = "Watch your language.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.hostile_short.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Watch your mouth. Now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.hostile_short.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Shut it.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.hostile_short.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "Hey, watch your mouth, friend. We're better than that.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.hostile_short.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "social.hostile_short",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "hostile_short",
            ["sourceId"] = "social.hostile_short",
            ["sourcePath"] = "dialogue/social_reactions_hostile_offer_threat/social_hostile_short.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialReactionsHostileOfferThreat",
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
                                ["fallback"] = "Watch your language.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Watch your mouth. Now.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Shut it.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "Hey, watch your mouth, friend. We're better than that.",
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
            ["responsePlanID"] = "social.hostile_short",
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
                            ["fallback"] = "Watch your language.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.hostile_short.say_1",
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
        ["sourceShard"] = "dialogue/social_reactions_hostile_offer_threat/social_hostile_short.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Watch your language.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.hostile_short.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Watch your mouth. Now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.hostile_short.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Shut it.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.hostile_short.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "Hey, watch your mouth, friend. We're better than that.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.hostile_short.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_reactions_hostile_offer_threat",
        ["domainPath"] = "social_reactions_hostile_offer_threat",
        ["exchangeFamily"] = {
            ["familyID"] = "social.hostile_stressed",
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
                                ["fallback"] = "That's enough. Everyone needs to step back.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.hostile_stressed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "That's enough. Back away.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.social.hostile_stressed.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Back off.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.social.hostile_stressed.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Hey, please, give me some space. I'm overwhelmed.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.social.hostile_stressed.say.1.warm",
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
                    ["fallback"] = "That's enough. Everyone needs to step back.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.hostile_stressed.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "That's enough. Back away.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.hostile_stressed.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Back off.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.hostile_stressed.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "Hey, please, give me some space. I'm overwhelmed.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.hostile_stressed.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "social.hostile_stressed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "hostile_stressed",
            ["sourceId"] = "social.hostile_stressed",
            ["sourcePath"] = "dialogue/social_reactions_hostile_offer_threat/social_hostile_stressed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialReactionsHostileOfferThreat",
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
                                ["fallback"] = "That's enough. Everyone needs to step back.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "That's enough. Back away.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Back off.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "Hey, please, give me some space. I'm overwhelmed.",
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
            ["responsePlanID"] = "social.hostile_stressed",
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
                            ["fallback"] = "That's enough. Everyone needs to step back.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.hostile_stressed.say_1",
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
        ["sourceShard"] = "dialogue/social_reactions_hostile_offer_threat/social_hostile_stressed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That's enough. Everyone needs to step back.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.hostile_stressed.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "That's enough. Back away.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.hostile_stressed.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Back off.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.hostile_stressed.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "Hey, please, give me some space. I'm overwhelmed.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.hostile_stressed.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_reactions_hostile_offer_threat",
        ["domainPath"] = "social_reactions_hostile_offer_threat",
        ["exchangeFamily"] = {
            ["familyID"] = "social.hostile_withdrawn",
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
                                ["fallback"] = "Please leave me alone.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.hostile_withdrawn.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Leave me alone. Now.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.social.hostile_withdrawn.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Leave.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.social.hostile_withdrawn.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I just need some time alone, friend. Please.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.social.hostile_withdrawn.say.1.warm",
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
                    ["fallback"] = "Please leave me alone.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.hostile_withdrawn.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Leave me alone. Now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.hostile_withdrawn.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Leave.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.hostile_withdrawn.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "I just need some time alone, friend. Please.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.hostile_withdrawn.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "social.hostile_withdrawn",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "hostile_withdrawn",
            ["sourceId"] = "social.hostile_withdrawn",
            ["sourcePath"] = "dialogue/social_reactions_hostile_offer_threat/social_hostile_withdrawn.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialReactionsHostileOfferThreat",
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
                                ["fallback"] = "Please leave me alone.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Leave me alone. Now.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Leave.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "I just need some time alone, friend. Please.",
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
            ["responsePlanID"] = "social.hostile_withdrawn",
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
                            ["fallback"] = "Please leave me alone.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.hostile_withdrawn.say_1",
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
        ["sourceShard"] = "dialogue/social_reactions_hostile_offer_threat/social_hostile_withdrawn.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Please leave me alone.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.hostile_withdrawn.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Leave me alone. Now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.hostile_withdrawn.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Leave.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.hostile_withdrawn.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "I just need some time alone, friend. Please.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.hostile_withdrawn.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_reactions_hostile_offer_threat",
        ["domainPath"] = "social_reactions_hostile_offer_threat",
        ["exchangeFamily"] = {
            ["familyID"] = "social.offer_friendly",
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
                                ["fallback"] = "Thanks. I'll keep that in mind.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.offer_friendly.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "%s, no thanks. I'll handle it.",
                                ["id"] = "bond_guarded",
                                ["templateID"] = "convo.social.offer_friendly.say.1.bond_guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "%s, that's kind of you. I'll keep it in mind.",
                                ["id"] = "bond_neutral",
                                ["templateID"] = "convo.social.offer_friendly.say.1.bond_neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "%s, thanks.",
                                ["id"] = "bond_terse",
                                ["templateID"] = "convo.social.offer_friendly.say.1.bond_terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "%s, thank you. I'll keep it in mind.",
                                ["id"] = "bond_warm",
                                ["templateID"] = "convo.social.offer_friendly.say.1.bond_warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "No thanks. I can handle it.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.social.offer_friendly.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Thanks.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.social.offer_friendly.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Thank you, I appreciate the offer.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.social.offer_friendly.say.1.warm",
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
                    ["fallback"] = "Thanks. I'll keep that in mind.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.offer_friendly.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "%s, no thanks. I'll handle it.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.offer_friendly.say.1.bond_guarded",
                    ["variantID"] = "bond_guarded",
                },
                {
                    ["fallback"] = "%s, that's kind of you. I'll keep it in mind.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.offer_friendly.say.1.bond_neutral",
                    ["variantID"] = "bond_neutral",
                },
                {
                    ["fallback"] = "%s, thanks.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.offer_friendly.say.1.bond_terse",
                    ["variantID"] = "bond_terse",
                },
                {
                    ["fallback"] = "%s, thank you. I'll keep it in mind.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.offer_friendly.say.1.bond_warm",
                    ["variantID"] = "bond_warm",
                },
                {
                    ["fallback"] = "No thanks. I can handle it.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.offer_friendly.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Thanks.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.offer_friendly.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "Thank you, I appreciate the offer.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.offer_friendly.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "social.offer_friendly",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "offer_friendly",
            ["sourceId"] = "social.offer_friendly",
            ["sourcePath"] = "dialogue/social_reactions_hostile_offer_threat/social_offer_friendly.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialReactionsHostileOfferThreat",
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
                                ["fallback"] = "Thanks. I'll keep that in mind.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "%s, no thanks. I'll handle it.",
                                ["id"] = "bond_guarded",
                            },
                            {
                                ["fallback"] = "%s, that's kind of you. I'll keep it in mind.",
                                ["id"] = "bond_neutral",
                            },
                            {
                                ["fallback"] = "%s, thanks.",
                                ["id"] = "bond_terse",
                            },
                            {
                                ["fallback"] = "%s, thank you. I'll keep it in mind.",
                                ["id"] = "bond_warm",
                            },
                            {
                                ["fallback"] = "No thanks. I can handle it.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Thanks.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "Thank you, I appreciate the offer.",
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
            ["responsePlanID"] = "social.offer_friendly",
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
                            ["fallback"] = "Thanks. I'll keep that in mind.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.offer_friendly.say_1",
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
        ["sourceShard"] = "dialogue/social_reactions_hostile_offer_threat/social_offer_friendly.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Thanks. I'll keep that in mind.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.offer_friendly.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "%s, no thanks. I'll handle it.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.offer_friendly.say.1.bond_guarded",
                ["variantID"] = "bond_guarded",
            },
            {
                ["fallback"] = "%s, that's kind of you. I'll keep it in mind.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.offer_friendly.say.1.bond_neutral",
                ["variantID"] = "bond_neutral",
            },
            {
                ["fallback"] = "%s, thanks.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.offer_friendly.say.1.bond_terse",
                ["variantID"] = "bond_terse",
            },
            {
                ["fallback"] = "%s, thank you. I'll keep it in mind.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.offer_friendly.say.1.bond_warm",
                ["variantID"] = "bond_warm",
            },
            {
                ["fallback"] = "No thanks. I can handle it.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.offer_friendly.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Thanks.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.offer_friendly.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "Thank you, I appreciate the offer.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.offer_friendly.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_reactions_hostile_offer_threat",
        ["domainPath"] = "social_reactions_hostile_offer_threat",
        ["exchangeFamily"] = {
            ["familyID"] = "social.parley.ceasefire",
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
                                ["fallback"] = "Let's call a ceasefire.",
                                ["id"] = "default",
                                ["templateID"] = "convo.social.parley.ceasefire.say.1.default",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["invoke"] = {
                ["action"] = "CEASEFIRE",
                ["intent"] = "REQUEST",
            },
            ["namespace"] = "social.parley",
            ["replies"] = {
                ["accepted"] = {
                    ["outcome"] = "accepted",
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
                                        ["fallback"] = "Fine. Stand down.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.parley.ceasefire.reply.accepted.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["already_peaceful"] = {
                    ["outcome"] = "already_peaceful",
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
                                        ["fallback"] = "We aren't fighting.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.parley.ceasefire.reply.already_peaceful.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "Let's call a ceasefire.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.parley.ceasefire.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Fine. Stand down.",
                    ["outcome"] = "accepted",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.parley.ceasefire.reply.accepted.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "We aren't fighting.",
                    ["outcome"] = "already_peaceful",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.parley.ceasefire.reply.already_peaceful.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "social.parley.ceasefire",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "ceasefire",
            ["sourceId"] = "social.parley.ceasefire",
            ["sourcePath"] = "dialogue/social_reactions_hostile_offer_threat/social_parley_ceasefire.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialReactionsHostileOfferThreat",
        ["namespace"] = "social.parley",
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
            ["closure"] = {
                ["closureClass"] = "state_transition",
            },
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["inputPolicy"] = "typed_parity",
            ["invoke"] = {
                ["action"] = "CEASEFIRE",
                ["intent"] = "REQUEST",
            },
            ["postconditions"] = {
                "relationship.ceasefire_active",
            },
            ["repeatPolicy"] = "state_retired",
            ["reply"] = {
                ["accepted"] = {
                    ["outcome"] = "accepted",
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
                                        ["fallback"] = "Fine. Stand down.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["already_peaceful"] = {
                    ["outcome"] = "already_peaceful",
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
                                        ["fallback"] = "We aren't fighting.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
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
                                ["fallback"] = "Let's call a ceasefire.",
                                ["id"] = "default",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["statePolicy"] = {
                {
                    ["admission"] = "no_op",
                    ["id"] = "already_peaceful",
                    ["outcome"] = "already_satisfied",
                    ["reason"] = "not_hostile",
                    ["replyOutcome"] = "already_peaceful",
                    ["when"] = {
                        ["op"] = "neq",
                        ["path"] = "roles.hostile",
                        ["value"] = true,
                    },
                },
                {
                    ["admission"] = "dispatch",
                    ["id"] = "ready",
                    ["outcome"] = "actionable",
                    ["reason"] = "hostile_parley_ready",
                },
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
            ["responsePlanID"] = "social.parley.ceasefire",
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
                            ["fallback"] = "Let's call a ceasefire.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.parley.ceasefire.say_1",
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
        ["sourceShard"] = "dialogue/social_reactions_hostile_offer_threat/social_parley_ceasefire.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Let's call a ceasefire.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.parley.ceasefire.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Fine. Stand down.",
                ["outcome"] = "accepted",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.parley.ceasefire.reply.accepted.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "We aren't fighting.",
                ["outcome"] = "already_peaceful",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.parley.ceasefire.reply.already_peaceful.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_reactions_hostile_offer_threat",
        ["domainPath"] = "social_reactions_hostile_offer_threat",
        ["exchangeFamily"] = {
            ["familyID"] = "social.profanity",
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
                                ["fallback"] = "Watch your language.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.profanity.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social",
            ["textRoles"] = {
                {
                    ["fallback"] = "Watch your language.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.profanity.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.profanity",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "profanity",
            ["sourceId"] = "social.profanity",
            ["sourcePath"] = "dialogue/social_reactions_hostile_offer_threat/social_profanity.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialReactionsHostileOfferThreat",
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
                ["category"] = "projecthoomans:social_reactions_hostile_offer_threat",
                ["responseAct"] = "HOSTILE_REMARK",
            },
            ["recognition"] = {
                ["concepts"] = {
                    {
                        ["aliases"] = {
                            "fuck",
                            "f*ck",
                            "f**k",
                            "f***",
                            "f***k",
                            "f*****",
                            "fuckin",
                            "fucking",
                            "fucked",
                            "shit",
                            "sh*t",
                            "s**t",
                            "shitty",
                            "bullshit",
                            "bullsh*t",
                            "horseshit",
                            "damn",
                            "dammit",
                            "goddamn",
                            "hell",
                            "crap",
                            "ass",
                            "arse",
                            "piss",
                            "pissed",
                            "pissing",
                            "cock",
                        },
                        ["id"] = "profanity",
                    },
                },
                ["ownerModID"] = "ProjectHoomans",
                ["packID"] = "pack.projecthoomans.social_profanity",
                ["patterns"] = {
                    {
                        ["confidence"] = 0.92,
                        ["emit"] = {
                            ["severity"] = "moderate",
                            ["speechAct"] = "HOSTILE_REMARK",
                        },
                        ["id"] = "pnc.social.profanity",
                        ["match"] = {
                            "@PROFANITY",
                        },
                        ["priority"] = 80,
                    },
                    {
                        ["confidence"] = 0.94,
                        ["emit"] = {
                            ["severity"] = "moderate",
                            ["speechAct"] = "HOSTILE_REMARK",
                        },
                        ["id"] = "pnc.social.profanity_prefixed",
                        ["match"] = {
                            {
                                ["kind"] = "literal",
                                ["value"] = "hey",
                            },
                            {
                                ["id"] = "PROFANITY",
                                ["kind"] = "concept",
                            },
                        },
                        ["priority"] = 70,
                    },
                    {
                        ["confidence"] = 0.94,
                        ["emit"] = {
                            ["severity"] = "moderate",
                            ["speechAct"] = "HOSTILE_REMARK",
                        },
                        ["id"] = "pnc.social.profanity_you",
                        ["match"] = {
                            {
                                ["kind"] = "literal",
                                ["value"] = "you",
                            },
                            {
                                ["kind"] = "literal",
                                ["optional"] = true,
                                ["value"] = "are",
                            },
                            {
                                ["kind"] = "literal",
                                ["optional"] = true,
                                ["value"] = "a",
                            },
                            {
                                ["kind"] = "literal",
                                ["optional"] = true,
                                ["value"] = "an",
                            },
                            {
                                ["id"] = "PROFANITY",
                                ["kind"] = "concept",
                            },
                        },
                        ["priority"] = 85,
                    },
                },
                ["speechActs"] = {
                    {
                        ["id"] = "hostile_remark",
                        ["intent"] = "HOSTILE_REMARK",
                        ["polarity"] = "negative",
                        ["tone"] = "hostile",
                    },
                },
                ["version"] = 1,
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
                                ["fallback"] = "Watch your language.",
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
            ["dialogueAct"] = "HOSTILE_REMARK",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.profanity",
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
                            ["fallback"] = "Watch your language.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.profanity.say_1",
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
        ["sourceShard"] = "dialogue/social_reactions_hostile_offer_threat/social_profanity.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Watch your language.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.profanity.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_reactions_hostile_offer_threat",
        ["domainPath"] = "social_reactions_hostile_offer_threat",
        ["exchangeFamily"] = {
            ["familyID"] = "social.threat_boundary",
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
                                ["fallback"] = "Step back or we have a problem.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.threat_boundary.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Back away. Now.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.social.threat_boundary.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Back off.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.social.threat_boundary.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Hey, please, don't do this. Step back.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.social.threat_boundary.say.1.warm",
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
                    ["fallback"] = "Step back or we have a problem.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.threat_boundary.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Back away. Now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.threat_boundary.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Back off.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.threat_boundary.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "Hey, please, don't do this. Step back.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.threat_boundary.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "social.threat_boundary",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "threat_boundary",
            ["sourceId"] = "social.threat_boundary",
            ["sourcePath"] = "dialogue/social_reactions_hostile_offer_threat/social_threat_boundary.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialReactionsHostileOfferThreat",
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
                                ["fallback"] = "Step back or we have a problem.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Back away. Now.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Back off.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "Hey, please, don't do this. Step back.",
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
            ["responsePlanID"] = "social.threat_boundary",
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
                            ["fallback"] = "Step back or we have a problem.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.threat_boundary.say_1",
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
        ["sourceShard"] = "dialogue/social_reactions_hostile_offer_threat/social_threat_boundary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Step back or we have a problem.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.threat_boundary.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Back away. Now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.threat_boundary.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Back off.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.threat_boundary.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "Hey, please, don't do this. Step back.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.threat_boundary.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
}
