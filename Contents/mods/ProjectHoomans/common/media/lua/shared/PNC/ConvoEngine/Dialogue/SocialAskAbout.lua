-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_ask_about",
        ["domainPath"] = "social_ask_about",
        ["id"] = "social.ask_about.member",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "member",
            ["sourceId"] = "social.ask_about.member",
            ["sourcePath"] = "dialogue/social_ask_about/social_ask_about_member.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialAskAbout",
        ["namespace"] = "social.ask_about",
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
                ["audience"] = "member",
                ["category"] = "projecthoomans:ask_about",
                ["runtimeBlockID"] = "projecthoomans:ask_about_member",
                ["textDomain"] = "pnc.convo.social.ask_about.member",
                ["textTarget"] = "convo/social/ask_about/member",
            },
            ["response"] = {
                ["act"] = "ASK_ABOUT",
                ["turns"] = {
                    {
                        ["fallback"] = "Go ahead, {addressee.name}. What do you want to ask about?",
                        ["id"] = "opening",
                        ["metadata"] = {
                            ["textKey"] = "opening",
                        },
                        ["offers"] = {
                            {
                                ["consumers"] = {
                                    "participant",
                                },
                                ["frame"] = {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "BACKGROUND",
                                    ["topic"] = "ask_about",
                                },
                                ["id"] = "background",
                                ["labelFallback"] = "Tell me about your old life.",
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.background",
                                    ["responseKey"] = "response.background",
                                    ["responseTextFallback"] = "It feels like someone else's life now.",
                                },
                                ["utteranceFallback"] = "Tell me about your old life.",
                            },
                            {
                                ["consumers"] = {
                                    "participant",
                                },
                                ["frame"] = {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "SKILLS",
                                    ["topic"] = "ask_about",
                                },
                                ["id"] = "skills",
                                ["labelFallback"] = "What can you teach the group?",
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.skills",
                                    ["responseKey"] = "response.skills",
                                    ["responseTextFallback"] = "Give me a job and I'll show you.",
                                },
                                ["utteranceFallback"] = "What can you teach the group?",
                            },
                        },
                    },
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
            ["dialogueAct"] = "ASK_ABOUT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.ask_about.member",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "opening",
                    ["offers"] = {
                        {
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "BACKGROUND",
                                ["topic"] = "ask_about",
                            },
                            ["id"] = "background",
                            ["labelFallback"] = "Tell me about your old life.",
                            ["labelKey"] = "convo.social.ask_about.member.offer.background.label",
                            ["utteranceFallback"] = "Tell me about your old life.",
                            ["utteranceKey"] = "convo.social.ask_about.member.offer.background.utterance",
                        },
                        {
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "SKILLS",
                                ["topic"] = "ask_about",
                            },
                            ["id"] = "skills",
                            ["labelFallback"] = "What can you teach the group?",
                            ["labelKey"] = "convo.social.ask_about.member.offer.skills.label",
                            ["utteranceFallback"] = "What can you teach the group?",
                            ["utteranceKey"] = "convo.social.ask_about.member.offer.skills.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Go ahead, {addressee.name}. What do you want to ask about?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.ask_about.member.opening",
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
        ["sourceShard"] = "dialogue/social_ask_about/social_ask_about_member.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_ask_about",
        ["domainPath"] = "social_ask_about",
        ["id"] = "social.ask_about.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "neutral",
            ["sourceId"] = "social.ask_about.neutral",
            ["sourcePath"] = "dialogue/social_ask_about/social_ask_about.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialAskAbout",
        ["namespace"] = "social.ask_about",
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
                ["audience"] = "neutral",
                ["category"] = "projecthoomans:ask_about",
                ["runtimeBlockID"] = "projecthoomans:ask_about_neutral",
                ["textDomain"] = "pnc.convo.social.ask_about.neutral",
                ["textTarget"] = "convo/social/ask_about/neutral",
            },
            ["response"] = {
                ["act"] = "ASK_ABOUT",
                ["turns"] = {
                    {
                        ["fallback"] = "What do you want to know?",
                        ["id"] = "opening",
                        ["metadata"] = {
                            ["textKey"] = "opening",
                        },
                        ["offers"] = {
                            {
                                ["consumers"] = {
                                    "participant",
                                },
                                ["frame"] = {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "BACKGROUND",
                                    ["topic"] = "ask_about",
                                },
                                ["id"] = "background",
                                ["labelFallback"] = "What did you do before all this?",
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.background",
                                    ["responseKey"] = "response.background",
                                    ["responseTextFallback"] = "That's a long story. Maybe one worth telling.",
                                },
                                ["utteranceFallback"] = "What did you do before all this?",
                            },
                            {
                                ["consumers"] = {
                                    "participant",
                                },
                                ["frame"] = {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "SKILLS",
                                    ["topic"] = "ask_about",
                                },
                                ["id"] = "skills",
                                ["labelFallback"] = "What are you good at?",
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.skills",
                                    ["responseKey"] = "response.skills",
                                    ["responseTextFallback"] = "Enough things to have survived this long.",
                                },
                                ["utteranceFallback"] = "What are you good at?",
                            },
                        },
                    },
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
            ["dialogueAct"] = "ASK_ABOUT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.ask_about.neutral",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "opening",
                    ["offers"] = {
                        {
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "BACKGROUND",
                                ["topic"] = "ask_about",
                            },
                            ["id"] = "background",
                            ["labelFallback"] = "What did you do before all this?",
                            ["labelKey"] = "convo.social.ask_about.neutral.offer.background.label",
                            ["utteranceFallback"] = "What did you do before all this?",
                            ["utteranceKey"] = "convo.social.ask_about.neutral.offer.background.utterance",
                        },
                        {
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "SKILLS",
                                ["topic"] = "ask_about",
                            },
                            ["id"] = "skills",
                            ["labelFallback"] = "What are you good at?",
                            ["labelKey"] = "convo.social.ask_about.neutral.offer.skills.label",
                            ["utteranceFallback"] = "What are you good at?",
                            ["utteranceKey"] = "convo.social.ask_about.neutral.offer.skills.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "What do you want to know?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.ask_about.neutral.opening",
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
        ["sourceShard"] = "dialogue/social_ask_about/social_ask_about.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_ask_about",
        ["domainPath"] = "social_ask_about",
        ["id"] = "social.ask_about.special",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "special",
            ["sourceId"] = "social.ask_about.special",
            ["sourcePath"] = "dialogue/social_ask_about/social_ask_about_special.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialAskAbout",
        ["namespace"] = "social.ask_about",
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
                ["audience"] = "special",
                ["category"] = "projecthoomans:ask_about",
                ["runtimeBlockID"] = "projecthoomans:ask_about_special",
                ["textDomain"] = "pnc.convo.social.ask_about.special",
                ["textTarget"] = "convo/social/ask_about/special",
            },
            ["response"] = {
                ["act"] = "ASK_ABOUT",
                ["turns"] = {
                    {
                        ["fallback"] = "You can ask me anything, {addressee.name}.",
                        ["id"] = "opening",
                        ["metadata"] = {
                            ["textKey"] = "opening",
                        },
                        ["offers"] = {
                            {
                                ["consumers"] = {
                                    "participant",
                                },
                                ["frame"] = {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "BACKGROUND",
                                    ["topic"] = "ask_about",
                                },
                                ["id"] = "background",
                                ["labelFallback"] = "Tell me something about your old life.",
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.background",
                                    ["responseKey"] = "response.background",
                                    ["responseTextFallback"] = "Only if you tell me something about yours afterward.",
                                },
                                ["utteranceFallback"] = "Tell me something about your old life.",
                            },
                            {
                                ["consumers"] = {
                                    "participant",
                                },
                                ["frame"] = {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "SKILLS",
                                    ["topic"] = "ask_about",
                                },
                                ["id"] = "skills",
                                ["labelFallback"] = "What are you proud of?",
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.skills",
                                    ["responseKey"] = "response.skills",
                                    ["responseTextFallback"] = "Surviving long enough to meet you.",
                                },
                                ["utteranceFallback"] = "What are you proud of?",
                            },
                        },
                    },
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
            ["dialogueAct"] = "ASK_ABOUT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.ask_about.special",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "opening",
                    ["offers"] = {
                        {
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "BACKGROUND",
                                ["topic"] = "ask_about",
                            },
                            ["id"] = "background",
                            ["labelFallback"] = "Tell me something about your old life.",
                            ["labelKey"] = "convo.social.ask_about.special.offer.background.label",
                            ["utteranceFallback"] = "Tell me something about your old life.",
                            ["utteranceKey"] = "convo.social.ask_about.special.offer.background.utterance",
                        },
                        {
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "SKILLS",
                                ["topic"] = "ask_about",
                            },
                            ["id"] = "skills",
                            ["labelFallback"] = "What are you proud of?",
                            ["labelKey"] = "convo.social.ask_about.special.offer.skills.label",
                            ["utteranceFallback"] = "What are you proud of?",
                            ["utteranceKey"] = "convo.social.ask_about.special.offer.skills.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "You can ask me anything, {addressee.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.ask_about.special.opening",
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
        ["sourceShard"] = "dialogue/social_ask_about/social_ask_about_special.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
