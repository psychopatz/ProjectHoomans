-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_ask_about",
        ["id"] = "social.ask_about.member",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "member",
            ["sourceId"] = "social.ask_about.member",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_ask_about/social_ask_about_member.json",
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
            ["metadata"] = {
                ["audience"] = "member",
                ["category"] = "projecthoomans:ask_about",
                ["runtimeBlockID"] = "projecthoomans:ask_about_member",
                ["textDomain"] = "pnc.psdl.social.ask_about.member",
                ["textTarget"] = "psdl/social/ask_about/member",
            },
            ["response"] = {
                ["act"] = "ASK_ABOUT",
                ["turns"] = {
                    {
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
                                ["label"] = {
                                    ["EN"] = {
                                        "Tell me about your old life.",
                                    },
                                    ["TL"] = {
                                        "Sabihin mo sa akin ang tungkol sa iyong lumang buhay.",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.background",
                                    ["responseKey"] = "response.background",
                                    ["responseText"] = {
                                        ["EN"] = "It feels like someone else's life now.",
                                        ["TL"] = "Parang may buhay ng iba ngayon.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "Tell me about your old life.",
                                    },
                                    ["TL"] = {
                                        "Sabihin mo sa akin ang tungkol sa iyong lumang buhay.",
                                    },
                                },
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
                                ["label"] = {
                                    ["EN"] = {
                                        "What can you teach the group?",
                                    },
                                    ["TL"] = {
                                        "What can you teach the grupo?",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.skills",
                                    ["responseKey"] = "response.skills",
                                    ["responseText"] = {
                                        ["EN"] = "Give me a job and I'll show you.",
                                        ["TL"] = "Bigyan mo ako ng trabaho at ipapakita ko sa iyo.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "What can you teach the group?",
                                    },
                                    ["TL"] = {
                                        "What can you teach the grupo?",
                                    },
                                },
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Go ahead, {addressee.name}. What do you want to ask about?",
                            },
                            ["TL"] = {
                                "Sige, {addressee.name}. Ano ang gusto mong itanong?",
                            },
                        },
                    },
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
                            ["labelKey"] = "psdl.social.ask_about.member.offer.background.label",
                            ["utteranceFallback"] = "Tell me about your old life.",
                            ["utteranceKey"] = "psdl.social.ask_about.member.offer.background.utterance",
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
                            ["labelKey"] = "psdl.social.ask_about.member.offer.skills.label",
                            ["utteranceFallback"] = "What can you teach the group?",
                            ["utteranceKey"] = "psdl.social.ask_about.member.offer.skills.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Go ahead, {addressee.name}. What do you want to ask about?",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.social.ask_about.member.opening",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_ask_about/social_ask_about_member.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_ask_about",
        ["id"] = "social.ask_about.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "neutral",
            ["sourceId"] = "social.ask_about.neutral",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_ask_about/social_ask_about.json",
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
            ["metadata"] = {
                ["audience"] = "neutral",
                ["category"] = "projecthoomans:ask_about",
                ["runtimeBlockID"] = "projecthoomans:ask_about_neutral",
                ["textDomain"] = "pnc.psdl.social.ask_about.neutral",
                ["textTarget"] = "psdl/social/ask_about/neutral",
            },
            ["response"] = {
                ["act"] = "ASK_ABOUT",
                ["turns"] = {
                    {
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
                                ["label"] = {
                                    ["EN"] = {
                                        "What did you do before all this?",
                                    },
                                    ["TL"] = {
                                        "Ano ang ginawa mo bago ang lahat ng ito?",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.background",
                                    ["responseKey"] = "response.background",
                                    ["responseText"] = {
                                        ["EN"] = "That's a long story. Maybe one worth telling.",
                                        ["TL"] = "mahabang kwento yan. Siguro isa na dapat sabihin.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "What did you do before all this?",
                                    },
                                    ["TL"] = {
                                        "Ano ang ginawa mo bago ang lahat ng ito?",
                                    },
                                },
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
                                ["label"] = {
                                    ["EN"] = {
                                        "What are you good at?",
                                    },
                                    ["TL"] = {
                                        "Ano ang kaya mong gawin?",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.skills",
                                    ["responseKey"] = "response.skills",
                                    ["responseText"] = {
                                        ["EN"] = "Enough things to have survived this long.",
                                        ["TL"] = "Sapat na ang mga bagay para mabuhay ng ganito katagal.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "What are you good at?",
                                    },
                                    ["TL"] = {
                                        "Ano ang kaya mong gawin?",
                                    },
                                },
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What do you want to know?",
                            },
                            ["TL"] = {
                                "Ano ang gusto mong malaman?",
                            },
                        },
                    },
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
                            ["labelKey"] = "psdl.social.ask_about.neutral.offer.background.label",
                            ["utteranceFallback"] = "What did you do before all this?",
                            ["utteranceKey"] = "psdl.social.ask_about.neutral.offer.background.utterance",
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
                            ["labelKey"] = "psdl.social.ask_about.neutral.offer.skills.label",
                            ["utteranceFallback"] = "What are you good at?",
                            ["utteranceKey"] = "psdl.social.ask_about.neutral.offer.skills.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "What do you want to know?",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.social.ask_about.neutral.opening",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_ask_about/social_ask_about.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_ask_about",
        ["id"] = "social.ask_about.special",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "special",
            ["sourceId"] = "social.ask_about.special",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_ask_about/social_ask_about_special.json",
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
            ["metadata"] = {
                ["audience"] = "special",
                ["category"] = "projecthoomans:ask_about",
                ["runtimeBlockID"] = "projecthoomans:ask_about_special",
                ["textDomain"] = "pnc.psdl.social.ask_about.special",
                ["textTarget"] = "psdl/social/ask_about/special",
            },
            ["response"] = {
                ["act"] = "ASK_ABOUT",
                ["turns"] = {
                    {
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
                                ["label"] = {
                                    ["EN"] = {
                                        "Tell me something about your old life.",
                                    },
                                    ["TL"] = {
                                        "Sabihin mo sa akin ang tungkol sa iyong dating buhay.",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.background",
                                    ["responseKey"] = "response.background",
                                    ["responseText"] = {
                                        ["EN"] = "Only if you tell me something about yours afterward.",
                                        ["TL"] = "Kung sasabihin mo lang sa akin ang tungkol sa iyo pagkatapos.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "Tell me something about your old life.",
                                    },
                                    ["TL"] = {
                                        "Sabihin mo sa akin ang tungkol sa iyong dating buhay.",
                                    },
                                },
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
                                ["label"] = {
                                    ["EN"] = {
                                        "What are you proud of?",
                                    },
                                    ["TL"] = {
                                        "Ano ang ipinagmamalaki mo?",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.skills",
                                    ["responseKey"] = "response.skills",
                                    ["responseText"] = {
                                        ["EN"] = "Surviving long enough to meet you.",
                                        ["TL"] = "Nakaligtas nang sapat upang makilala ka.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "What are you proud of?",
                                    },
                                    ["TL"] = {
                                        "Ano ang ipinagmamalaki mo?",
                                    },
                                },
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You can ask me anything, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Maaari mo akong tanungin tungkol sa kahit ano, {addressee.name}.",
                            },
                        },
                    },
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
                            ["labelKey"] = "psdl.social.ask_about.special.offer.background.label",
                            ["utteranceFallback"] = "Tell me something about your old life.",
                            ["utteranceKey"] = "psdl.social.ask_about.special.offer.background.utterance",
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
                            ["labelKey"] = "psdl.social.ask_about.special.offer.skills.label",
                            ["utteranceFallback"] = "What are you proud of?",
                            ["utteranceKey"] = "psdl.social.ask_about.special.offer.skills.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "You can ask me anything, {addressee.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.social.ask_about.special.opening",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_ask_about/social_ask_about_special.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
