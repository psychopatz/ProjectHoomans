-- Hand-maintained ProjectHoomans ConvoEngine module.
return {
    {
        ["domain"] = "needs_support",
        ["domainPath"] = "needs_support",
        ["id"] = "needs.member.support",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "support",
            ["sourceId"] = "needs.member.support",
            ["sourcePath"] = "dialogue/needs_support/needs_member_support.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/NeedsSupport",
        ["namespace"] = "needs.member",
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
                ["audiences"] = {
                    "member",
                },
                ["category"] = "projecthoomans:needs",
                ["runtimeBlockID"] = "projecthoomans:needs_member",
                ["textDomain"] = "pnc.convo.needs.member.support",
                ["textRows"] = {
                    {
                        ["fallback"] = "I have {giftItemSummary} for the group.",
                        ["key"] = "gift.offer.multiple",
                    },
                    {
                        ["fallback"] = "Put these into our stores: {giftItemSummary}.",
                        ["key"] = "gift.offer.multiple.alt",
                    },
                    {
                        ["fallback"] = "Here's {giftItemName} for the group.",
                        ["key"] = "gift.offer.single",
                    },
                    {
                        ["fallback"] = "I brought this for us: {giftItemName}.",
                        ["key"] = "gift.offer.single.alt",
                    },
                    {
                        ["fallback"] = "That is exactly the kind of contribution that keeps a community moving.",
                        ["key"] = "gift.received.equipment",
                    },
                    {
                        ["fallback"] = "Perfect timing. I will make sure it reaches someone who needs it.",
                        ["key"] = "gift.received.food",
                    },
                    {
                        ["fallback"] = "Thank you. I will put it where it does the most good.",
                        ["key"] = "gift.received.general",
                    },
                    {
                        ["fallback"] = "This goes straight into our reserves. You just made the whole group safer.",
                        ["key"] = "gift.received.medical",
                    },
                },
                ["textTarget"] = "convo/needs/member/support",
            },
            ["response"] = {
                ["act"] = "NEEDS",
                ["turns"] = {
                    {
                        ["fallback"] = "Let me think about what the group is short on.",
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
                                    ["subject"] = "SUPPLIES",
                                    ["topic"] = "needs",
                                },
                                ["id"] = "supplies",
                                ["labelFallback"] = "What supplies are we short on?",
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.supplies",
                                    ["responseKey"] = "response.supplies",
                                    ["responseTextFallback"] = "Food, water, and tools. The usual.",
                                },
                                ["utteranceFallback"] = "What supplies are we short on?",
                            },
                            {
                                ["consumers"] = {
                                    "participant",
                                },
                                ["frame"] = {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "MEDICAL",
                                    ["topic"] = "needs",
                                },
                                ["id"] = "medical",
                                ["labelFallback"] = "Does anyone need medical help?",
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.medical",
                                    ["responseKey"] = "response.medical",
                                    ["responseTextFallback"] = "Nothing urgent, but check the bandages.",
                                },
                                ["utteranceFallback"] = "Does anyone need medical help?",
                            },
                            {
                                ["consumers"] = {
                                    "participant",
                                },
                                ["frame"] = {
                                    ["intent"] = "OFFER",
                                    ["speechAct"] = "OFFER",
                                    ["subject"] = "GIFT",
                                    ["topic"] = "needs",
                                },
                                ["id"] = "gift",
                                ["labelFallback"] = "I have something you might need.",
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.gift",
                                    ["next"] = "gift",
                                    ["responseKey"] = "response.gift",
                                    ["responseTextFallback"] = "Let me see what you can spare.",
                                },
                                ["utteranceFallback"] = "I have something you might need.",
                            },
                        },
                    },
                    {
                        ["fallback"] = "Choose something to give me, then return to the conversation.",
                        ["id"] = "gift",
                        ["metadata"] = {
                            ["textKey"] = "gift.opening",
                        },
                        ["offers"] = {
                            {
                                ["consumers"] = {
                                    "participant",
                                },
                                ["frame"] = {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["subject"] = "GIFT_RETURN",
                                    ["topic"] = "needs",
                                },
                                ["id"] = "gift_return",
                                ["labelFallback"] = "I will hold on to the rest.",
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.gift_return",
                                    ["responseKey"] = "response.gift_return",
                                    ["responseTextFallback"] = "Understood.",
                                },
                                ["utteranceFallback"] = "I will hold on to the rest.",
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
            ["dialogueAct"] = "NEEDS",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "needs.member.support",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "continue",
                    ["id"] = "opening",
                    ["offers"] = {
                        {
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "SUPPLIES",
                                ["topic"] = "needs",
                            },
                            ["id"] = "supplies",
                            ["labelFallback"] = "What supplies are we short on?",
                            ["labelKey"] = "convo.needs.member.support.offer.supplies.label",
                            ["utteranceFallback"] = "What supplies are we short on?",
                            ["utteranceKey"] = "convo.needs.member.support.offer.supplies.utterance",
                        },
                        {
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "MEDICAL",
                                ["topic"] = "needs",
                            },
                            ["id"] = "medical",
                            ["labelFallback"] = "Does anyone need medical help?",
                            ["labelKey"] = "convo.needs.member.support.offer.medical.label",
                            ["utteranceFallback"] = "Does anyone need medical help?",
                            ["utteranceKey"] = "convo.needs.member.support.offer.medical.utterance",
                        },
                        {
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "OFFER",
                                ["speechAct"] = "OFFER",
                                ["subject"] = "GIFT",
                                ["topic"] = "needs",
                            },
                            ["id"] = "gift",
                            ["labelFallback"] = "I have something you might need.",
                            ["labelKey"] = "convo.needs.member.support.offer.gift.label",
                            ["utteranceFallback"] = "I have something you might need.",
                            ["utteranceKey"] = "convo.needs.member.support.offer.gift.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Let me think about what the group is short on.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.needs.member.support.opening",
                        },
                    },
                },
                {
                    ["continuation"] = "end",
                    ["id"] = "gift",
                    ["offers"] = {
                        {
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "INFORM",
                                ["speechAct"] = "INFORM",
                                ["subject"] = "GIFT_RETURN",
                                ["topic"] = "needs",
                            },
                            ["id"] = "gift_return",
                            ["labelFallback"] = "I will hold on to the rest.",
                            ["labelKey"] = "convo.needs.member.support.offer.gift_return.label",
                            ["utteranceFallback"] = "I will hold on to the rest.",
                            ["utteranceKey"] = "convo.needs.member.support.offer.gift_return.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Choose something to give me, then return to the conversation.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.needs.member.support.gift",
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
        ["sourceShard"] = "dialogue/needs_support/needs_member_support.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "needs_support",
        ["domainPath"] = "needs_support",
        ["id"] = "needs.neutral.support",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "support",
            ["sourceId"] = "needs.neutral.support",
            ["sourcePath"] = "dialogue/needs_support/needs_neutral_support.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/NeedsSupport",
        ["namespace"] = "needs.neutral",
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
                ["audiences"] = {
                    "neutral",
                },
                ["category"] = "projecthoomans:needs",
                ["runtimeBlockID"] = "projecthoomans:needs_neutral",
                ["textDomain"] = "pnc.convo.needs.neutral.support",
                ["textRows"] = {
                    {
                        ["fallback"] = "I have {giftItemSummary} for you.",
                        ["key"] = "gift.offer.multiple",
                    },
                    {
                        ["fallback"] = "Take these if you can use them: {giftItemSummary}.",
                        ["key"] = "gift.offer.multiple.alt",
                    },
                    {
                        ["fallback"] = "Here's {giftItemName}.",
                        ["key"] = "gift.offer.single",
                    },
                    {
                        ["fallback"] = "I can spare this: {giftItemName}.",
                        ["key"] = "gift.offer.single.alt",
                    },
                    {
                        ["fallback"] = "Good choice. Something like this can keep a bad day from getting worse.",
                        ["key"] = "gift.received.equipment",
                    },
                    {
                        ["fallback"] = "This will not go to waste. I appreciate you sharing it with me.",
                        ["key"] = "gift.received.food",
                    },
                    {
                        ["fallback"] = "I can make use of this. Thank you.",
                        ["key"] = "gift.received.general",
                    },
                    {
                        ["fallback"] = "That is useful. Thank you for thinking ahead instead of waiting for a crisis.",
                        ["key"] = "gift.received.medical",
                    },
                },
                ["textTarget"] = "convo/needs/neutral/support",
            },
            ["response"] = {
                ["act"] = "NEEDS",
                ["turns"] = {
                    {
                        ["fallback"] = "There are a few things I could use.",
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
                                    ["subject"] = "SUPPLIES",
                                    ["topic"] = "needs",
                                },
                                ["id"] = "supplies",
                                ["labelFallback"] = "Need any supplies?",
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.supplies",
                                    ["responseKey"] = "response.supplies",
                                    ["responseTextFallback"] = "Food and clean water never hurt.",
                                },
                                ["utteranceFallback"] = "Need any supplies?",
                            },
                            {
                                ["consumers"] = {
                                    "participant",
                                },
                                ["frame"] = {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "MEDICAL",
                                    ["topic"] = "needs",
                                },
                                ["id"] = "medical",
                                ["labelFallback"] = "Any medical problems?",
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.medical",
                                    ["responseKey"] = "response.medical",
                                    ["responseTextFallback"] = "Nothing I cannot handle right now.",
                                },
                                ["utteranceFallback"] = "Any medical problems?",
                            },
                            {
                                ["consumers"] = {
                                    "participant",
                                },
                                ["frame"] = {
                                    ["intent"] = "OFFER",
                                    ["speechAct"] = "OFFER",
                                    ["subject"] = "GIFT",
                                    ["topic"] = "needs",
                                },
                                ["id"] = "gift",
                                ["labelFallback"] = "I have something you might need.",
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.gift",
                                    ["next"] = "gift",
                                    ["responseKey"] = "response.gift",
                                    ["responseTextFallback"] = "Let me see what you can spare.",
                                },
                                ["utteranceFallback"] = "I have something you might need.",
                            },
                        },
                    },
                    {
                        ["fallback"] = "Choose something to give me, then return to the conversation.",
                        ["id"] = "gift",
                        ["metadata"] = {
                            ["textKey"] = "gift.opening",
                        },
                        ["offers"] = {
                            {
                                ["consumers"] = {
                                    "participant",
                                },
                                ["frame"] = {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["subject"] = "GIFT_RETURN",
                                    ["topic"] = "needs",
                                },
                                ["id"] = "gift_return",
                                ["labelFallback"] = "I will hold on to the rest.",
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.gift_return",
                                    ["responseKey"] = "response.gift_return",
                                    ["responseTextFallback"] = "Understood.",
                                },
                                ["utteranceFallback"] = "I will hold on to the rest.",
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
            ["dialogueAct"] = "NEEDS",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "needs.neutral.support",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "continue",
                    ["id"] = "opening",
                    ["offers"] = {
                        {
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "SUPPLIES",
                                ["topic"] = "needs",
                            },
                            ["id"] = "supplies",
                            ["labelFallback"] = "Need any supplies?",
                            ["labelKey"] = "convo.needs.neutral.support.offer.supplies.label",
                            ["utteranceFallback"] = "Need any supplies?",
                            ["utteranceKey"] = "convo.needs.neutral.support.offer.supplies.utterance",
                        },
                        {
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "MEDICAL",
                                ["topic"] = "needs",
                            },
                            ["id"] = "medical",
                            ["labelFallback"] = "Any medical problems?",
                            ["labelKey"] = "convo.needs.neutral.support.offer.medical.label",
                            ["utteranceFallback"] = "Any medical problems?",
                            ["utteranceKey"] = "convo.needs.neutral.support.offer.medical.utterance",
                        },
                        {
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "OFFER",
                                ["speechAct"] = "OFFER",
                                ["subject"] = "GIFT",
                                ["topic"] = "needs",
                            },
                            ["id"] = "gift",
                            ["labelFallback"] = "I have something you might need.",
                            ["labelKey"] = "convo.needs.neutral.support.offer.gift.label",
                            ["utteranceFallback"] = "I have something you might need.",
                            ["utteranceKey"] = "convo.needs.neutral.support.offer.gift.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "There are a few things I could use.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.needs.neutral.support.opening",
                        },
                    },
                },
                {
                    ["continuation"] = "end",
                    ["id"] = "gift",
                    ["offers"] = {
                        {
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "INFORM",
                                ["speechAct"] = "INFORM",
                                ["subject"] = "GIFT_RETURN",
                                ["topic"] = "needs",
                            },
                            ["id"] = "gift_return",
                            ["labelFallback"] = "I will hold on to the rest.",
                            ["labelKey"] = "convo.needs.neutral.support.offer.gift_return.label",
                            ["utteranceFallback"] = "I will hold on to the rest.",
                            ["utteranceKey"] = "convo.needs.neutral.support.offer.gift_return.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Choose something to give me, then return to the conversation.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.needs.neutral.support.gift",
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
        ["sourceShard"] = "dialogue/needs_support/needs_neutral_support.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "needs_support",
        ["domainPath"] = "needs_support",
        ["id"] = "needs.special.support",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "support",
            ["sourceId"] = "needs.special.support",
            ["sourcePath"] = "dialogue/needs_support/needs_special_support.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/NeedsSupport",
        ["namespace"] = "needs.special",
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
                ["audiences"] = {
                    "special",
                },
                ["category"] = "projecthoomans:needs",
                ["runtimeBlockID"] = "projecthoomans:needs_special",
                ["textDomain"] = "pnc.convo.needs.special.support",
                ["textRows"] = {
                    {
                        ["fallback"] = "I brought {giftItemSummary} for you.",
                        ["key"] = "gift.offer.multiple",
                    },
                    {
                        ["fallback"] = "These are yours if you need them: {giftItemSummary}.",
                        ["key"] = "gift.offer.multiple.alt",
                    },
                    {
                        ["fallback"] = "Here's {giftItemName}. I thought you could use it.",
                        ["key"] = "gift.offer.single",
                    },
                    {
                        ["fallback"] = "This is for you: {giftItemName}.",
                        ["key"] = "gift.offer.single.alt",
                    },
                    {
                        ["fallback"] = "Useful, deliberate, and well chosen. You are learning how I think.",
                        ["key"] = "gift.received.equipment",
                    },
                    {
                        ["fallback"] = "You remembered me. I will enjoy this, and I will remember the gesture.",
                        ["key"] = "gift.received.food",
                    },
                    {
                        ["fallback"] = "That is thoughtful of you. Thank you.",
                        ["key"] = "gift.received.general",
                    },
                    {
                        ["fallback"] = "You noticed what I needed before I had to ask. That means more than the medicine itself.",
                        ["key"] = "gift.received.medical",
                    },
                },
                ["textTarget"] = "convo/needs/special/support",
            },
            ["response"] = {
                ["act"] = "NEEDS",
                ["turns"] = {
                    {
                        ["fallback"] = "Since it's you, I'll tell you what I need.",
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
                                    ["subject"] = "SUPPLIES",
                                    ["topic"] = "needs",
                                },
                                ["id"] = "supplies",
                                ["labelFallback"] = "What can I bring you?",
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.supplies",
                                    ["responseKey"] = "response.supplies",
                                    ["responseTextFallback"] = "Just come back safely. Anything else is extra.",
                                },
                                ["utteranceFallback"] = "What can I bring you?",
                            },
                            {
                                ["consumers"] = {
                                    "participant",
                                },
                                ["frame"] = {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "MEDICAL",
                                    ["topic"] = "needs",
                                },
                                ["id"] = "medical",
                                ["labelFallback"] = "Are you hurt?",
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.medical",
                                    ["responseKey"] = "response.medical",
                                    ["responseTextFallback"] = "No. I would tell you if I was.",
                                },
                                ["utteranceFallback"] = "Are you hurt?",
                            },
                            {
                                ["consumers"] = {
                                    "participant",
                                },
                                ["frame"] = {
                                    ["intent"] = "OFFER",
                                    ["speechAct"] = "OFFER",
                                    ["subject"] = "GIFT",
                                    ["topic"] = "needs",
                                },
                                ["id"] = "gift",
                                ["labelFallback"] = "I have something you might need.",
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.gift",
                                    ["next"] = "gift",
                                    ["responseKey"] = "response.gift",
                                    ["responseTextFallback"] = "Let me see what you can spare.",
                                },
                                ["utteranceFallback"] = "I have something you might need.",
                            },
                        },
                    },
                    {
                        ["fallback"] = "Choose something to give me, then return to the conversation.",
                        ["id"] = "gift",
                        ["metadata"] = {
                            ["textKey"] = "gift.opening",
                        },
                        ["offers"] = {
                            {
                                ["consumers"] = {
                                    "participant",
                                },
                                ["frame"] = {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["subject"] = "GIFT_RETURN",
                                    ["topic"] = "needs",
                                },
                                ["id"] = "gift_return",
                                ["labelFallback"] = "I will hold on to the rest.",
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.gift_return",
                                    ["responseKey"] = "response.gift_return",
                                    ["responseTextFallback"] = "Understood.",
                                },
                                ["utteranceFallback"] = "I will hold on to the rest.",
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
            ["dialogueAct"] = "NEEDS",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "needs.special.support",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "continue",
                    ["id"] = "opening",
                    ["offers"] = {
                        {
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "SUPPLIES",
                                ["topic"] = "needs",
                            },
                            ["id"] = "supplies",
                            ["labelFallback"] = "What can I bring you?",
                            ["labelKey"] = "convo.needs.special.support.offer.supplies.label",
                            ["utteranceFallback"] = "What can I bring you?",
                            ["utteranceKey"] = "convo.needs.special.support.offer.supplies.utterance",
                        },
                        {
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "MEDICAL",
                                ["topic"] = "needs",
                            },
                            ["id"] = "medical",
                            ["labelFallback"] = "Are you hurt?",
                            ["labelKey"] = "convo.needs.special.support.offer.medical.label",
                            ["utteranceFallback"] = "Are you hurt?",
                            ["utteranceKey"] = "convo.needs.special.support.offer.medical.utterance",
                        },
                        {
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "OFFER",
                                ["speechAct"] = "OFFER",
                                ["subject"] = "GIFT",
                                ["topic"] = "needs",
                            },
                            ["id"] = "gift",
                            ["labelFallback"] = "I have something you might need.",
                            ["labelKey"] = "convo.needs.special.support.offer.gift.label",
                            ["utteranceFallback"] = "I have something you might need.",
                            ["utteranceKey"] = "convo.needs.special.support.offer.gift.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Since it's you, I'll tell you what I need.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.needs.special.support.opening",
                        },
                    },
                },
                {
                    ["continuation"] = "end",
                    ["id"] = "gift",
                    ["offers"] = {
                        {
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "INFORM",
                                ["speechAct"] = "INFORM",
                                ["subject"] = "GIFT_RETURN",
                                ["topic"] = "needs",
                            },
                            ["id"] = "gift_return",
                            ["labelFallback"] = "I will hold on to the rest.",
                            ["labelKey"] = "convo.needs.special.support.offer.gift_return.label",
                            ["utteranceFallback"] = "I will hold on to the rest.",
                            ["utteranceKey"] = "convo.needs.special.support.offer.gift_return.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Choose something to give me, then return to the conversation.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.needs.special.support.gift",
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
        ["sourceShard"] = "dialogue/needs_support/needs_special_support.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
