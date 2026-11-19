-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_memory",
        ["domainPath"] = "social_interaction_memory",
        ["exchangeFamily"] = {
            ["familyID"] = "interaction.memory.acknowledge",
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
                                ["fallback"] = "I hear you.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.interaction.memory.acknowledge.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "All right. I heard you.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.interaction.memory.acknowledge.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Mm.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.interaction.memory.acknowledge.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Yeah. I can see why that stayed with you.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.interaction.memory.acknowledge.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "interaction.memory",
            ["textRoles"] = {
                {
                    ["fallback"] = "I hear you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.memory.acknowledge.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "All right. I heard you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.memory.acknowledge.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Mm.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.memory.acknowledge.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "Yeah. I can see why that stayed with you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.memory.acknowledge.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "interaction.memory.acknowledge",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "acknowledge",
            ["sourceId"] = "interaction.memory.acknowledge",
            ["sourcePath"] = "dialogue/social_interaction_memory/interaction_memory_acknowledge.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionMemory",
        ["namespace"] = "interaction.memory",
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
                                ["fallback"] = "I hear you.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "All right. I heard you.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Mm.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "Yeah. I can see why that stayed with you.",
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
            ["responsePlanID"] = "interaction.memory.acknowledge",
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
                            ["fallback"] = "I hear you.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.interaction.memory.acknowledge.say_1",
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
        ["sourceShard"] = "dialogue/social_interaction_memory/interaction_memory_acknowledge.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I hear you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.memory.acknowledge.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "All right. I heard you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.memory.acknowledge.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Mm.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.memory.acknowledge.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "Yeah. I can see why that stayed with you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.memory.acknowledge.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_memory",
        ["domainPath"] = "social_interaction_memory",
        ["exchangeFamily"] = {
            ["familyID"] = "interaction.memory.acknowledge_flavor",
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
                                ["fallback"] = "The listener gives a small acknowledging nod.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.interaction.memory.acknowledge_flavor.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "The listener gives a guarded nod.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.interaction.memory.acknowledge_flavor.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "A brief nod follows.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.interaction.memory.acknowledge_flavor.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "The listener softens and nods with quiet understanding.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.interaction.memory.acknowledge_flavor.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "interaction.memory",
            ["textRoles"] = {
                {
                    ["fallback"] = "The listener gives a small acknowledging nod.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.memory.acknowledge_flavor.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "The listener gives a guarded nod.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.memory.acknowledge_flavor.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "A brief nod follows.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.memory.acknowledge_flavor.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "The listener softens and nods with quiet understanding.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.memory.acknowledge_flavor.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "interaction.memory.acknowledge_flavor",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "acknowledge_flavor",
            ["sourceId"] = "interaction.memory.acknowledge_flavor",
            ["sourcePath"] = "dialogue/social_interaction_memory/interaction_memory_acknowledge_flavor.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionMemory",
        ["namespace"] = "interaction.memory",
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
                                ["fallback"] = "The listener gives a small acknowledging nod.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "The listener gives a guarded nod.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "A brief nod follows.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "The listener softens and nods with quiet understanding.",
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
            ["responsePlanID"] = "interaction.memory.acknowledge_flavor",
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
                            ["fallback"] = "The listener gives a small acknowledging nod.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.interaction.memory.acknowledge_flavor.say_1",
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
        ["sourceShard"] = "dialogue/social_interaction_memory/interaction_memory_acknowledge_flavor.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "The listener gives a small acknowledging nod.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.memory.acknowledge_flavor.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "The listener gives a guarded nod.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.memory.acknowledge_flavor.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "A brief nod follows.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.memory.acknowledge_flavor.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "The listener softens and nods with quiet understanding.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.memory.acknowledge_flavor.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_memory",
        ["domainPath"] = "social_interaction_memory",
        ["exchangeFamily"] = {
            ["familyID"] = "interaction.memory.followup",
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
                                ["fallback"] = "You did? What happened after that?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.interaction.memory.followup.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Why are you telling me that?",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.interaction.memory.followup.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "And then?",
                                ["id"] = "terse",
                                ["templateID"] = "convo.interaction.memory.followup.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Really? Tell me more about that.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.interaction.memory.followup.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "interaction.memory",
            ["textRoles"] = {
                {
                    ["fallback"] = "You did? What happened after that?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.memory.followup.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Why are you telling me that?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.memory.followup.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "And then?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.memory.followup.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "Really? Tell me more about that.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.memory.followup.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "interaction.memory.followup",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "followup",
            ["sourceId"] = "interaction.memory.followup",
            ["sourcePath"] = "dialogue/social_interaction_memory/interaction_memory_followup.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionMemory",
        ["namespace"] = "interaction.memory",
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
                                ["fallback"] = "You did? What happened after that?",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Why are you telling me that?",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "And then?",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "Really? Tell me more about that.",
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
            ["responsePlanID"] = "interaction.memory.followup",
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
                            ["fallback"] = "You did? What happened after that?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.interaction.memory.followup.say_1",
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
        ["sourceShard"] = "dialogue/social_interaction_memory/interaction_memory_followup.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "You did? What happened after that?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.memory.followup.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Why are you telling me that?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.memory.followup.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "And then?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.memory.followup.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "Really? Tell me more about that.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.memory.followup.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
}
