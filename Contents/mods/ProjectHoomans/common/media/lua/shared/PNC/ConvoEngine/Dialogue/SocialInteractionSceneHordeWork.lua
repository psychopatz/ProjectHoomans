-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["domainPath"] = "social_interaction_scene_horde_work",
        ["exchangeFamily"] = {
            ["familyID"] = "interaction.scene.horde_prompt",
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
                                ["fallback"] = "That's a horde. We fighting through or pulling back?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.interaction.scene.horde_prompt.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Big group ahead. We decide now: engage or avoid.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.interaction.scene.horde_prompt.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Horde. Fight or fall back?",
                                ["id"] = "terse",
                                ["templateID"] = "convo.interaction.scene.horde_prompt.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "That's a lot of them. Stay close—fight or fall back?",
                                ["id"] = "warm",
                                ["templateID"] = "convo.interaction.scene.horde_prompt.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "interaction.scene",
            ["textRoles"] = {
                {
                    ["fallback"] = "That's a horde. We fighting through or pulling back?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.horde_prompt.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Big group ahead. We decide now: engage or avoid.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.horde_prompt.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Horde. Fight or fall back?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.horde_prompt.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "That's a lot of them. Stay close—fight or fall back?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.horde_prompt.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "interaction.scene.horde_prompt",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "horde_prompt",
            ["sourceId"] = "interaction.scene.horde_prompt",
            ["sourcePath"] = "dialogue/social_interaction_scene_horde_work/interaction_scene_horde_prompt.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "interaction.scene",
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
            ["activities"] = {
                {
                    ["id"] = "excursion",
                    ["role"] = "actor",
                },
            },
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
                                ["fallback"] = "That's a horde. We fighting through or pulling back?",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Big group ahead. We decide now: engage or avoid.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Horde. Fight or fall back?",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "That's a lot of them. Stay close—fight or fall back?",
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
                    ["id"] = "scene_excursion",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "interaction.scene.horde_prompt",
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
                            ["fallback"] = "That's a horde. We fighting through or pulling back?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.interaction.scene.horde_prompt.say_1",
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
        ["sourceShard"] = "dialogue/social_interaction_scene_horde_work/interaction_scene_horde_prompt.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That's a horde. We fighting through or pulling back?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.horde_prompt.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Big group ahead. We decide now: engage or avoid.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.horde_prompt.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Horde. Fight or fall back?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.horde_prompt.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "That's a lot of them. Stay close—fight or fall back?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.horde_prompt.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["domainPath"] = "social_interaction_scene_horde_work",
        ["exchangeFamily"] = {
            ["familyID"] = "interaction.scene.horde_reply_brave",
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
                                ["fallback"] = "We can take them.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.interaction.scene.horde_reply_brave.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "If we commit, we hit hard and stay together.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.interaction.scene.horde_reply_brave.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Stand and fight.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.interaction.scene.horde_reply_brave.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I'm with you. We can take them.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.interaction.scene.horde_reply_brave.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "interaction.scene",
            ["textRoles"] = {
                {
                    ["fallback"] = "We can take them.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.horde_reply_brave.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "If we commit, we hit hard and stay together.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.horde_reply_brave.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Stand and fight.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.horde_reply_brave.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "I'm with you. We can take them.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.horde_reply_brave.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "interaction.scene.horde_reply_brave",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "horde_reply_brave",
            ["sourceId"] = "interaction.scene.horde_reply_brave",
            ["sourcePath"] = "dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_brave.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "interaction.scene",
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
            ["activities"] = {
                {
                    ["id"] = "excursion",
                    ["role"] = "actor",
                },
            },
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
                                ["fallback"] = "We can take them.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "If we commit, we hit hard and stay together.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Stand and fight.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "I'm with you. We can take them.",
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
                    ["id"] = "scene_excursion",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "interaction.scene.horde_reply_brave",
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
                            ["fallback"] = "We can take them.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.interaction.scene.horde_reply_brave.say_1",
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
        ["sourceShard"] = "dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_brave.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "We can take them.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.horde_reply_brave.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "If we commit, we hit hard and stay together.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.horde_reply_brave.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Stand and fight.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.horde_reply_brave.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "I'm with you. We can take them.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.horde_reply_brave.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["domainPath"] = "social_interaction_scene_horde_work",
        ["exchangeFamily"] = {
            ["familyID"] = "interaction.scene.horde_reply_cautious",
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
                                ["fallback"] = "Too many. We should pull back.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.interaction.scene.horde_reply_cautious.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Bad odds. Give them space.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.interaction.scene.horde_reply_cautious.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Pull back.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.interaction.scene.horde_reply_cautious.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I'd rather get us out of this alive. Pull back.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.interaction.scene.horde_reply_cautious.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "interaction.scene",
            ["textRoles"] = {
                {
                    ["fallback"] = "Too many. We should pull back.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.horde_reply_cautious.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Bad odds. Give them space.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.horde_reply_cautious.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Pull back.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.horde_reply_cautious.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "I'd rather get us out of this alive. Pull back.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.horde_reply_cautious.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "interaction.scene.horde_reply_cautious",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "horde_reply_cautious",
            ["sourceId"] = "interaction.scene.horde_reply_cautious",
            ["sourcePath"] = "dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_cautious.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "interaction.scene",
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
            ["activities"] = {
                {
                    ["id"] = "excursion",
                    ["role"] = "actor",
                },
            },
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
                                ["fallback"] = "Too many. We should pull back.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Bad odds. Give them space.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Pull back.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "I'd rather get us out of this alive. Pull back.",
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
                    ["id"] = "scene_excursion",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "interaction.scene.horde_reply_cautious",
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
                            ["fallback"] = "Too many. We should pull back.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.interaction.scene.horde_reply_cautious.say_1",
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
        ["sourceShard"] = "dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_cautious.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Too many. We should pull back.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.horde_reply_cautious.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Bad odds. Give them space.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.horde_reply_cautious.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Pull back.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.horde_reply_cautious.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "I'd rather get us out of this alive. Pull back.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.horde_reply_cautious.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["domainPath"] = "social_interaction_scene_horde_work",
        ["exchangeFamily"] = {
            ["familyID"] = "interaction.scene.horde_reply_steady",
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
                                ["fallback"] = "Hold here. Don't rush it.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.interaction.scene.horde_reply_steady.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "No rush. Hold position and watch the pressure.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.interaction.scene.horde_reply_steady.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Hold. Watch them.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.interaction.scene.horde_reply_steady.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Stay together. Let's hold before we commit.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.interaction.scene.horde_reply_steady.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "interaction.scene",
            ["textRoles"] = {
                {
                    ["fallback"] = "Hold here. Don't rush it.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.horde_reply_steady.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "No rush. Hold position and watch the pressure.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.horde_reply_steady.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Hold. Watch them.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.horde_reply_steady.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "Stay together. Let's hold before we commit.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.horde_reply_steady.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "interaction.scene.horde_reply_steady",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "horde_reply_steady",
            ["sourceId"] = "interaction.scene.horde_reply_steady",
            ["sourcePath"] = "dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_steady.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "interaction.scene",
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
            ["activities"] = {
                {
                    ["id"] = "excursion",
                    ["role"] = "actor",
                },
            },
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
                                ["fallback"] = "Hold here. Don't rush it.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "No rush. Hold position and watch the pressure.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Hold. Watch them.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "Stay together. Let's hold before we commit.",
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
                    ["id"] = "scene_excursion",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "interaction.scene.horde_reply_steady",
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
                            ["fallback"] = "Hold here. Don't rush it.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.interaction.scene.horde_reply_steady.say_1",
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
        ["sourceShard"] = "dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_steady.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Hold here. Don't rush it.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.horde_reply_steady.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "No rush. Hold position and watch the pressure.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.horde_reply_steady.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Hold. Watch them.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.horde_reply_steady.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "Stay together. Let's hold before we commit.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.horde_reply_steady.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["domainPath"] = "social_interaction_scene_horde_work",
        ["exchangeFamily"] = {
            ["familyID"] = "interaction.scene.post_combat_clear",
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
                                ["fallback"] = "Looks clear now. That got rough for a minute.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.interaction.scene.post_combat_clear.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Don't relax yet. Scan for stragglers.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.interaction.scene.post_combat_clear.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Clear.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.interaction.scene.post_combat_clear.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "We made it through! Is everyone okay?",
                                ["id"] = "warm",
                                ["templateID"] = "convo.interaction.scene.post_combat_clear.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "interaction.scene",
            ["textRoles"] = {
                {
                    ["fallback"] = "Looks clear now. That got rough for a minute.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.post_combat_clear.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Don't relax yet. Scan for stragglers.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.post_combat_clear.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Clear.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.post_combat_clear.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "We made it through! Is everyone okay?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.post_combat_clear.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "interaction.scene.post_combat_clear",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "post_combat_clear",
            ["sourceId"] = "interaction.scene.post_combat_clear",
            ["sourcePath"] = "dialogue/social_interaction_scene_horde_work/interaction_scene_post_combat_clear.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "interaction.scene",
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
            ["activities"] = {
                {
                    ["id"] = "excursion",
                    ["role"] = "actor",
                },
            },
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
                                ["fallback"] = "Looks clear now. That got rough for a minute.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Don't relax yet. Scan for stragglers.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Clear.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "We made it through! Is everyone okay?",
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
                    ["id"] = "scene_excursion",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "interaction.scene.post_combat_clear",
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
                            ["fallback"] = "Looks clear now. That got rough for a minute.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.interaction.scene.post_combat_clear.say_1",
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
        ["sourceShard"] = "dialogue/social_interaction_scene_horde_work/interaction_scene_post_combat_clear.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Looks clear now. That got rough for a minute.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.post_combat_clear.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Don't relax yet. Scan for stragglers.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.post_combat_clear.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Clear.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.post_combat_clear.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "We made it through! Is everyone okay?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.post_combat_clear.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["domainPath"] = "social_interaction_scene_horde_work",
        ["exchangeFamily"] = {
            ["familyID"] = "interaction.scene.task_work_assigned",
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
                                ["fallback"] = "I've got work to do. I'll get on it.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.interaction.scene.task_work_assigned.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I'll do the work. Watch my back while I do.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.interaction.scene.task_work_assigned.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "On it.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.interaction.scene.task_work_assigned.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Happy to help with this! I'll get right on it.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.interaction.scene.task_work_assigned.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "interaction.scene",
            ["textRoles"] = {
                {
                    ["fallback"] = "I've got work to do. I'll get on it.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.task_work_assigned.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I'll do the work. Watch my back while I do.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.task_work_assigned.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "On it.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.task_work_assigned.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "Happy to help with this! I'll get right on it.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.task_work_assigned.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "interaction.scene.task_work_assigned",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "task_work_assigned",
            ["sourceId"] = "interaction.scene.task_work_assigned",
            ["sourcePath"] = "dialogue/social_interaction_scene_horde_work/interaction_scene_task_work_assigned.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "interaction.scene",
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
            ["activities"] = {
                {
                    ["id"] = "excursion",
                    ["role"] = "actor",
                },
            },
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
                                ["fallback"] = "I've got work to do. I'll get on it.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "I'll do the work. Watch my back while I do.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "On it.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "Happy to help with this! I'll get right on it.",
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
                    ["id"] = "scene_excursion",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "interaction.scene.task_work_assigned",
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
                            ["fallback"] = "I've got work to do. I'll get on it.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.interaction.scene.task_work_assigned.say_1",
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
        ["sourceShard"] = "dialogue/social_interaction_scene_horde_work/interaction_scene_task_work_assigned.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I've got work to do. I'll get on it.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.task_work_assigned.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I'll do the work. Watch my back while I do.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.task_work_assigned.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "On it.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.task_work_assigned.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "Happy to help with this! I'll get right on it.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.task_work_assigned.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["domainPath"] = "social_interaction_scene_horde_work",
        ["exchangeFamily"] = {
            ["familyID"] = "interaction.scene.task_work_completed",
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
                                ["fallback"] = "That's done. One less thing to worry about.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.interaction.scene.task_work_completed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Task is done. I'm taking a breather.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.interaction.scene.task_work_completed.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Done.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.interaction.scene.task_work_completed.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "All finished! Glad I could help get this done.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.interaction.scene.task_work_completed.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "interaction.scene",
            ["textRoles"] = {
                {
                    ["fallback"] = "That's done. One less thing to worry about.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.task_work_completed.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Task is done. I'm taking a breather.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.task_work_completed.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Done.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.task_work_completed.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "All finished! Glad I could help get this done.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.task_work_completed.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "interaction.scene.task_work_completed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "task_work_completed",
            ["sourceId"] = "interaction.scene.task_work_completed",
            ["sourcePath"] = "dialogue/social_interaction_scene_horde_work/interaction_scene_task_work_completed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "interaction.scene",
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
            ["activities"] = {
                {
                    ["id"] = "excursion",
                    ["role"] = "actor",
                },
            },
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
                                ["fallback"] = "That's done. One less thing to worry about.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Task is done. I'm taking a breather.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Done.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "All finished! Glad I could help get this done.",
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
                    ["id"] = "scene_excursion",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "interaction.scene.task_work_completed",
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
                            ["fallback"] = "That's done. One less thing to worry about.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.interaction.scene.task_work_completed.say_1",
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
        ["sourceShard"] = "dialogue/social_interaction_scene_horde_work/interaction_scene_task_work_completed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That's done. One less thing to worry about.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.task_work_completed.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Task is done. I'm taking a breather.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.task_work_completed.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Done.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.task_work_completed.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "All finished! Glad I could help get this done.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.task_work_completed.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
}
