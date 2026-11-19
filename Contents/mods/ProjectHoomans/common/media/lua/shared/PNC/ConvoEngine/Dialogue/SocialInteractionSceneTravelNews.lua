-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["domainPath"] = "social_interaction_scene_travel_news",
        ["exchangeFamily"] = {
            ["familyID"] = "interaction.scene.excursion_departing",
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
                                ["fallback"] = "We're moving out. Keep close.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.interaction.scene.excursion_departing.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "We're outbound. Keep the group tight.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.interaction.scene.excursion_departing.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Moving out. Stay close.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.interaction.scene.excursion_departing.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "We're heading out. Stay close and we'll get through it.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.interaction.scene.excursion_departing.say.1.warm",
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
                    ["fallback"] = "We're moving out. Keep close.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.excursion_departing.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "We're outbound. Keep the group tight.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.excursion_departing.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Moving out. Stay close.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.excursion_departing.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "We're heading out. Stay close and we'll get through it.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.excursion_departing.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "interaction.scene.excursion_departing",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "excursion_departing",
            ["sourceId"] = "interaction.scene.excursion_departing",
            ["sourcePath"] = "dialogue/social_interaction_scene_travel_news/interaction_scene_excursion_departing.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneTravelNews",
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
                                ["fallback"] = "We're moving out. Keep close.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "We're outbound. Keep the group tight.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Moving out. Stay close.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "We're heading out. Stay close and we'll get through it.",
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
            ["responsePlanID"] = "interaction.scene.excursion_departing",
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
                            ["fallback"] = "We're moving out. Keep close.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.interaction.scene.excursion_departing.say_1",
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
        ["sourceShard"] = "dialogue/social_interaction_scene_travel_news/interaction_scene_excursion_departing.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "We're moving out. Keep close.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.excursion_departing.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "We're outbound. Keep the group tight.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.excursion_departing.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Moving out. Stay close.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.excursion_departing.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "We're heading out. Stay close and we'll get through it.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.excursion_departing.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["domainPath"] = "social_interaction_scene_travel_news",
        ["exchangeFamily"] = {
            ["familyID"] = "interaction.scene.excursion_failed",
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
                                ["fallback"] = "Trip's off. Something went wrong.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.interaction.scene.excursion_failed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Excursion failed. We regroup here.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.interaction.scene.excursion_failed.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Trip's off.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.interaction.scene.excursion_failed.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "We're calling it off. Better safe than forcing it.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.interaction.scene.excursion_failed.say.1.warm",
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
                    ["fallback"] = "Trip's off. Something went wrong.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.excursion_failed.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Excursion failed. We regroup here.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.excursion_failed.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Trip's off.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.excursion_failed.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "We're calling it off. Better safe than forcing it.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.excursion_failed.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "interaction.scene.excursion_failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "excursion_failed",
            ["sourceId"] = "interaction.scene.excursion_failed",
            ["sourcePath"] = "dialogue/social_interaction_scene_travel_news/interaction_scene_excursion_failed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneTravelNews",
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
                                ["fallback"] = "Trip's off. Something went wrong.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Excursion failed. We regroup here.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Trip's off.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "We're calling it off. Better safe than forcing it.",
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
            ["responsePlanID"] = "interaction.scene.excursion_failed",
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
                            ["fallback"] = "Trip's off. Something went wrong.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.interaction.scene.excursion_failed.say_1",
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
        ["sourceShard"] = "dialogue/social_interaction_scene_travel_news/interaction_scene_excursion_failed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Trip's off. Something went wrong.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.excursion_failed.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Excursion failed. We regroup here.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.excursion_failed.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Trip's off.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.excursion_failed.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "We're calling it off. Better safe than forcing it.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.excursion_failed.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["domainPath"] = "social_interaction_scene_travel_news",
        ["exchangeFamily"] = {
            ["familyID"] = "interaction.scene.excursion_home",
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
                                ["fallback"] = "We're back. Good.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.interaction.scene.excursion_home.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "We're back. Check in and settle down.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.interaction.scene.excursion_home.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Back home.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.interaction.scene.excursion_home.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "We're home. Good to have everyone back.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.interaction.scene.excursion_home.say.1.warm",
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
                    ["fallback"] = "We're back. Good.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.excursion_home.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "We're back. Check in and settle down.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.excursion_home.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Back home.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.excursion_home.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "We're home. Good to have everyone back.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.excursion_home.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "interaction.scene.excursion_home",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "excursion_home",
            ["sourceId"] = "interaction.scene.excursion_home",
            ["sourcePath"] = "dialogue/social_interaction_scene_travel_news/interaction_scene_excursion_home.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneTravelNews",
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
                                ["fallback"] = "We're back. Good.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "We're back. Check in and settle down.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Back home.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "We're home. Good to have everyone back.",
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
            ["responsePlanID"] = "interaction.scene.excursion_home",
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
                            ["fallback"] = "We're back. Good.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.interaction.scene.excursion_home.say_1",
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
        ["sourceShard"] = "dialogue/social_interaction_scene_travel_news/interaction_scene_excursion_home.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "We're back. Good.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.excursion_home.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "We're back. Check in and settle down.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.excursion_home.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Back home.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.excursion_home.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "We're home. Good to have everyone back.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.excursion_home.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["domainPath"] = "social_interaction_scene_travel_news",
        ["exchangeFamily"] = {
            ["familyID"] = "interaction.scene.excursion_preparing",
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
                                ["fallback"] = "We're getting ready to head out.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.interaction.scene.excursion_preparing.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Prep first. We move when everyone's ready.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.interaction.scene.excursion_preparing.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Get ready. We leave soon.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.interaction.scene.excursion_preparing.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "We're getting ready. Make sure you've got what you need.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.interaction.scene.excursion_preparing.say.1.warm",
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
                    ["fallback"] = "We're getting ready to head out.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.excursion_preparing.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Prep first. We move when everyone's ready.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.excursion_preparing.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Get ready. We leave soon.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.excursion_preparing.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "We're getting ready. Make sure you've got what you need.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.excursion_preparing.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "interaction.scene.excursion_preparing",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "excursion_preparing",
            ["sourceId"] = "interaction.scene.excursion_preparing",
            ["sourcePath"] = "dialogue/social_interaction_scene_travel_news/interaction_scene_excursion_preparing.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneTravelNews",
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
                                ["fallback"] = "We're getting ready to head out.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Prep first. We move when everyone's ready.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Get ready. We leave soon.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "We're getting ready. Make sure you've got what you need.",
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
            ["responsePlanID"] = "interaction.scene.excursion_preparing",
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
                            ["fallback"] = "We're getting ready to head out.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.interaction.scene.excursion_preparing.say_1",
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
        ["sourceShard"] = "dialogue/social_interaction_scene_travel_news/interaction_scene_excursion_preparing.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "We're getting ready to head out.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.excursion_preparing.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Prep first. We move when everyone's ready.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.excursion_preparing.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Get ready. We leave soon.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.excursion_preparing.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "We're getting ready. Make sure you've got what you need.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.excursion_preparing.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["domainPath"] = "social_interaction_scene_travel_news",
        ["exchangeFamily"] = {
            ["familyID"] = "interaction.scene.excursion_returning",
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
                                ["fallback"] = "We're heading home.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.interaction.scene.excursion_returning.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "We're returning. Stay alert until we're home.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.interaction.scene.excursion_returning.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Heading home.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.interaction.scene.excursion_returning.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Time to head home. Let's get everyone back safe.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.interaction.scene.excursion_returning.say.1.warm",
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
                    ["fallback"] = "We're heading home.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.excursion_returning.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "We're returning. Stay alert until we're home.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.excursion_returning.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Heading home.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.excursion_returning.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "Time to head home. Let's get everyone back safe.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.excursion_returning.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "interaction.scene.excursion_returning",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "excursion_returning",
            ["sourceId"] = "interaction.scene.excursion_returning",
            ["sourcePath"] = "dialogue/social_interaction_scene_travel_news/interaction_scene_excursion_returning.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneTravelNews",
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
                                ["fallback"] = "We're heading home.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "We're returning. Stay alert until we're home.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Heading home.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "Time to head home. Let's get everyone back safe.",
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
            ["responsePlanID"] = "interaction.scene.excursion_returning",
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
                            ["fallback"] = "We're heading home.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.interaction.scene.excursion_returning.say_1",
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
        ["sourceShard"] = "dialogue/social_interaction_scene_travel_news/interaction_scene_excursion_returning.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "We're heading home.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.excursion_returning.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "We're returning. Stay alert until we're home.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.excursion_returning.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Heading home.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.excursion_returning.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "Time to head home. Let's get everyone back safe.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.excursion_returning.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["domainPath"] = "social_interaction_scene_travel_news",
        ["exchangeFamily"] = {
            ["familyID"] = "interaction.scene.grounded_news_answer",
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
                                ["fallback"] = "That is what I can confirm right now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.interaction.scene.grounded_news_answer.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Nothing else I can verify yet.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.interaction.scene.grounded_news_answer.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "That is all I can confirm.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.interaction.scene.grounded_news_answer.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I wish I knew more, but that is what I can confirm.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.interaction.scene.grounded_news_answer.say.1.warm",
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
                    ["fallback"] = "That is what I can confirm right now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.grounded_news_answer.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Nothing else I can verify yet.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.grounded_news_answer.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "That is all I can confirm.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.grounded_news_answer.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "I wish I knew more, but that is what I can confirm.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.grounded_news_answer.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "interaction.scene.grounded_news_answer",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "grounded_news_answer",
            ["sourceId"] = "interaction.scene.grounded_news_answer",
            ["sourcePath"] = "dialogue/social_interaction_scene_travel_news/interaction_scene_grounded_news_answer.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneTravelNews",
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
                                ["fallback"] = "That is what I can confirm right now.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Nothing else I can verify yet.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "That is all I can confirm.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "I wish I knew more, but that is what I can confirm.",
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
            ["responsePlanID"] = "interaction.scene.grounded_news_answer",
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
                            ["fallback"] = "That is what I can confirm right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.interaction.scene.grounded_news_answer.say_1",
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
        ["sourceShard"] = "dialogue/social_interaction_scene_travel_news/interaction_scene_grounded_news_answer.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That is what I can confirm right now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.grounded_news_answer.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Nothing else I can verify yet.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.grounded_news_answer.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "That is all I can confirm.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.grounded_news_answer.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "I wish I knew more, but that is what I can confirm.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.grounded_news_answer.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["domainPath"] = "social_interaction_scene_travel_news",
        ["exchangeFamily"] = {
            ["familyID"] = "interaction.scene.grounded_news_share",
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
                                ["fallback"] = "I heard something worth passing on.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.interaction.scene.grounded_news_share.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I have something I can confirm.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.interaction.scene.grounded_news_share.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Got some news for you.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.interaction.scene.grounded_news_share.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I thought you should hear what I learned.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.interaction.scene.grounded_news_share.say.1.warm",
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
                    ["fallback"] = "I heard something worth passing on.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.grounded_news_share.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I have something I can confirm.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.grounded_news_share.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Got some news for you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.grounded_news_share.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "I thought you should hear what I learned.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.scene.grounded_news_share.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "interaction.scene.grounded_news_share",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "grounded_news_share",
            ["sourceId"] = "interaction.scene.grounded_news_share",
            ["sourcePath"] = "dialogue/social_interaction_scene_travel_news/interaction_scene_grounded_news_share.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneTravelNews",
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
                                ["fallback"] = "I heard something worth passing on.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "I have something I can confirm.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Got some news for you.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "I thought you should hear what I learned.",
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
            ["responsePlanID"] = "interaction.scene.grounded_news_share",
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
                            ["fallback"] = "I heard something worth passing on.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.interaction.scene.grounded_news_share.say_1",
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
        ["sourceShard"] = "dialogue/social_interaction_scene_travel_news/interaction_scene_grounded_news_share.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I heard something worth passing on.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.grounded_news_share.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I have something I can confirm.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.grounded_news_share.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Got some news for you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.grounded_news_share.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "I thought you should hear what I learned.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.scene.grounded_news_share.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
}
