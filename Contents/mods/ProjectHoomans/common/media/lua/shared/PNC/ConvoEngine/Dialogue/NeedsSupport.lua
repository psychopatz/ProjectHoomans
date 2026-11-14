-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "needs_support",
        ["id"] = "needs.member.support",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "support",
            ["sourceId"] = "needs.member.support",
            ["sourcePath"] = "adopters/hoomans/dialogue/needs_support/needs_member_support.json",
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
            ["metadata"] = {
                ["audiences"] = {
                    "member",
                },
                ["category"] = "projecthoomans:needs",
                ["runtimeBlockID"] = "projecthoomans:needs_member",
                ["textDomain"] = "pnc.convo.needs.member.support",
                ["textRows"] = {
                    {
                        ["key"] = "gift.offer.multiple",
                        ["text"] = {
                            ["EN"] = "I have {giftItemSummary} for the group.",
                            ["TL"] = "Mayroon akong {giftItemSummary} para sa grupo.",
                        },
                    },
                    {
                        ["key"] = "gift.offer.multiple.alt",
                        ["text"] = {
                            ["EN"] = "Put these into our stores: {giftItemSummary}.",
                            ["TL"] = "Ilagay ang mga ito sa aming mga tindahan: {giftItemSummary}.",
                        },
                    },
                    {
                        ["key"] = "gift.offer.single",
                        ["text"] = {
                            ["EN"] = "Here's {giftItemName} for the group.",
                            ["TL"] = "Narito ang {giftItemName} para sa grupo.",
                        },
                    },
                    {
                        ["key"] = "gift.offer.single.alt",
                        ["text"] = {
                            ["EN"] = "I brought this for us: {giftItemName}.",
                            ["TL"] = "Dinala ko ito para sa atin: {giftItemName}.",
                        },
                    },
                    {
                        ["key"] = "gift.received.equipment",
                        ["text"] = {
                            ["EN"] = "That is exactly the kind of contribution that keeps a community moving.",
                            ["TL"] = "Iyan mismo ang uri ng kontribusyon na nagpapanatili sa isang komunidad na gumagalaw.",
                        },
                    },
                    {
                        ["key"] = "gift.received.food",
                        ["text"] = {
                            ["EN"] = "Perfect timing. I will make sure it reaches someone who needs it.",
                            ["TL"] = "Perpektong timing. Sisiguraduhin kong makakarating ito sa taong nangangailangan nito.",
                        },
                    },
                    {
                        ["key"] = "gift.received.general",
                        ["text"] = {
                            ["EN"] = "Thank you. I will put it where it does the most good.",
                            ["TL"] = "salamat po. Ilalagay ko ito kung saan ito nagdudulot ng pinakamabuti.",
                        },
                    },
                    {
                        ["key"] = "gift.received.medical",
                        ["text"] = {
                            ["EN"] = "This goes straight into our reserves. You just made the whole group safer.",
                            ["TL"] = "Diretso ito sa ating mga reserba. Ginawa mo lang mas ligtas ang buong grupo.",
                        },
                    },
                },
                ["textTarget"] = "convo/needs/member/support",
            },
            ["response"] = {
                ["act"] = "NEEDS",
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
                                    ["subject"] = "SUPPLIES",
                                    ["topic"] = "needs",
                                },
                                ["id"] = "supplies",
                                ["label"] = {
                                    ["EN"] = {
                                        "What supplies are we short on?",
                                    },
                                    ["TL"] = {
                                        "What supplies are we short buhay?",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.supplies",
                                    ["responseKey"] = "response.supplies",
                                    ["responseText"] = {
                                        ["EN"] = "Food, water, and tools. The usual.",
                                        ["TL"] = "Pagkain, tubig, at mga kasangkapan. Ang karaniwan.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "What supplies are we short on?",
                                    },
                                    ["TL"] = {
                                        "What supplies are we short buhay?",
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
                                    ["subject"] = "MEDICAL",
                                    ["topic"] = "needs",
                                },
                                ["id"] = "medical",
                                ["label"] = {
                                    ["EN"] = {
                                        "Does anyone need medical help?",
                                    },
                                    ["TL"] = {
                                        "May nangangailangan ba ng tulong medikal?",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.medical",
                                    ["responseKey"] = "response.medical",
                                    ["responseText"] = {
                                        ["EN"] = "Nothing urgent, but check the bandages.",
                                        ["TL"] = "Walang kagyat, ngunit suriin ang mga bendahe.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "Does anyone need medical help?",
                                    },
                                    ["TL"] = {
                                        "May nangangailangan ba ng tulong medikal?",
                                    },
                                },
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
                                ["label"] = {
                                    ["EN"] = {
                                        "I have something you might need.",
                                    },
                                    ["TL"] = {
                                        "Mayroon akong isang bagay na maaaring kailanganin mo.",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.gift",
                                    ["next"] = "gift",
                                    ["responseKey"] = "response.gift",
                                    ["responseText"] = {
                                        ["EN"] = "Let me see what you can spare.",
                                        ["TL"] = "Hayaan akong makita kung ano ang maaari mong matitira.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "I have something you might need.",
                                    },
                                    ["TL"] = {
                                        "Mayroon akong isang bagay na maaaring kailanganin mo.",
                                    },
                                },
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Let me think about what the group is short on.",
                            },
                            ["TL"] = {
                                "Hayaan akong isipin kung ano ang kulang sa grupo.",
                            },
                        },
                    },
                    {
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
                                ["label"] = {
                                    ["EN"] = {
                                        "I will hold on to the rest.",
                                    },
                                    ["TL"] = {
                                        "Hahawakan ko ang natitira.",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.gift_return",
                                    ["responseKey"] = "response.gift_return",
                                    ["responseText"] = {
                                        ["EN"] = "Understood.",
                                        ["TL"] = "Understood.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "I will hold on to the rest.",
                                    },
                                    ["TL"] = {
                                        "Hahawakan ko ang natitira.",
                                    },
                                },
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Choose something to give me, then return to the conversation.",
                            },
                            ["TL"] = {
                                "Pumili ng ibibigay sa akin, pagkatapos ay bumalik sa usapan.",
                            },
                        },
                    },
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/needs_support/needs_member_support.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "needs_support",
        ["id"] = "needs.neutral.support",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "support",
            ["sourceId"] = "needs.neutral.support",
            ["sourcePath"] = "adopters/hoomans/dialogue/needs_support/needs_neutral_support.json",
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
            ["metadata"] = {
                ["audiences"] = {
                    "neutral",
                },
                ["category"] = "projecthoomans:needs",
                ["runtimeBlockID"] = "projecthoomans:needs_neutral",
                ["textDomain"] = "pnc.convo.needs.neutral.support",
                ["textRows"] = {
                    {
                        ["key"] = "gift.offer.multiple",
                        ["text"] = {
                            ["EN"] = "I have {giftItemSummary} for you.",
                            ["TL"] = "Mayroon akong {giftItemSummary} para sa iyo.",
                        },
                    },
                    {
                        ["key"] = "gift.offer.multiple.alt",
                        ["text"] = {
                            ["EN"] = "Take these if you can use them: {giftItemSummary}.",
                            ["TL"] = "Kunin ang mga ito kung magagamit mo ang mga ito: {giftItemSummary}.",
                        },
                    },
                    {
                        ["key"] = "gift.offer.single",
                        ["text"] = {
                            ["EN"] = "Here's {giftItemName}.",
                            ["TL"] = "Narito ang {giftItemName}.",
                        },
                    },
                    {
                        ["key"] = "gift.offer.single.alt",
                        ["text"] = {
                            ["EN"] = "I can spare this: {giftItemName}.",
                            ["TL"] = "Maaari ko itong iligtas: {giftItemName}.",
                        },
                    },
                    {
                        ["key"] = "gift.received.equipment",
                        ["text"] = {
                            ["EN"] = "Good choice. Something like this can keep a bad day from getting worse.",
                            ["TL"] = "Magandang pagpipilian. Maaaring pigilan ng isang bagay na tulad nito ang masamang araw na lumala.",
                        },
                    },
                    {
                        ["key"] = "gift.received.food",
                        ["text"] = {
                            ["EN"] = "This will not go to waste. I appreciate you sharing it with me.",
                            ["TL"] = "Hindi ito mauubos. Pinapahalagahan ko ang pagbabahagi mo nito sa akin.",
                        },
                    },
                    {
                        ["key"] = "gift.received.general",
                        ["text"] = {
                            ["EN"] = "I can make use of this. Thank you.",
                            ["TL"] = "Magagamit ko ito. salamat po.",
                        },
                    },
                    {
                        ["key"] = "gift.received.medical",
                        ["text"] = {
                            ["EN"] = "That is useful. Thank you for thinking ahead instead of waiting for a crisis.",
                            ["TL"] = "Kapaki-pakinabang iyan. Salamat sa pag-iisip nang maaga sa halip na maghintay ng krisis.",
                        },
                    },
                },
                ["textTarget"] = "convo/needs/neutral/support",
            },
            ["response"] = {
                ["act"] = "NEEDS",
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
                                    ["subject"] = "SUPPLIES",
                                    ["topic"] = "needs",
                                },
                                ["id"] = "supplies",
                                ["label"] = {
                                    ["EN"] = {
                                        "Need any supplies?",
                                    },
                                    ["TL"] = {
                                        "Kailangan ng anumang mga supply?",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.supplies",
                                    ["responseKey"] = "response.supplies",
                                    ["responseText"] = {
                                        ["EN"] = "Food and clean water never hurt.",
                                        ["TL"] = "Ang pagkain at malinis na tubig ay hindi nasaktan.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "Need any supplies?",
                                    },
                                    ["TL"] = {
                                        "Kailangan ng anumang mga supply?",
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
                                    ["subject"] = "MEDICAL",
                                    ["topic"] = "needs",
                                },
                                ["id"] = "medical",
                                ["label"] = {
                                    ["EN"] = {
                                        "Any medical problems?",
                                    },
                                    ["TL"] = {
                                        "Anumang mga medikal na problema?",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.medical",
                                    ["responseKey"] = "response.medical",
                                    ["responseText"] = {
                                        ["EN"] = "Nothing I cannot handle right now.",
                                        ["TL"] = "Wala akong kakayanin ngayon.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "Any medical problems?",
                                    },
                                    ["TL"] = {
                                        "Anumang mga medikal na problema?",
                                    },
                                },
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
                                ["label"] = {
                                    ["EN"] = {
                                        "I have something you might need.",
                                    },
                                    ["TL"] = {
                                        "Mayroon akong isang bagay na maaaring kailanganin mo.",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.gift",
                                    ["next"] = "gift",
                                    ["responseKey"] = "response.gift",
                                    ["responseText"] = {
                                        ["EN"] = "Let me see what you can spare.",
                                        ["TL"] = "Hayaan akong makita kung ano ang maaari mong matitira.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "I have something you might need.",
                                    },
                                    ["TL"] = {
                                        "Mayroon akong isang bagay na maaaring kailanganin mo.",
                                    },
                                },
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "There are a few things I could use.",
                            },
                            ["TL"] = {
                                "May ilang bagay akong magagamit.",
                            },
                        },
                    },
                    {
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
                                ["label"] = {
                                    ["EN"] = {
                                        "I will hold on to the rest.",
                                    },
                                    ["TL"] = {
                                        "Hahawakan ko ang natitira.",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.gift_return",
                                    ["responseKey"] = "response.gift_return",
                                    ["responseText"] = {
                                        ["EN"] = "Understood.",
                                        ["TL"] = "Understood.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "I will hold on to the rest.",
                                    },
                                    ["TL"] = {
                                        "Hahawakan ko ang natitira.",
                                    },
                                },
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Choose something to give me, then return to the conversation.",
                            },
                            ["TL"] = {
                                "Pumili ng ibibigay sa akin, pagkatapos ay bumalik sa usapan.",
                            },
                        },
                    },
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/needs_support/needs_neutral_support.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "needs_support",
        ["id"] = "needs.special.support",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "support",
            ["sourceId"] = "needs.special.support",
            ["sourcePath"] = "adopters/hoomans/dialogue/needs_support/needs_special_support.json",
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
            ["metadata"] = {
                ["audiences"] = {
                    "special",
                },
                ["category"] = "projecthoomans:needs",
                ["runtimeBlockID"] = "projecthoomans:needs_special",
                ["textDomain"] = "pnc.convo.needs.special.support",
                ["textRows"] = {
                    {
                        ["key"] = "gift.offer.multiple",
                        ["text"] = {
                            ["EN"] = "I brought {giftItemSummary} for you.",
                            ["TL"] = "Nagdala ako ng {giftItemSummary} para sa iyo.",
                        },
                    },
                    {
                        ["key"] = "gift.offer.multiple.alt",
                        ["text"] = {
                            ["EN"] = "These are yours if you need them: {giftItemSummary}.",
                            ["TL"] = "Iyo ang mga ito kung kailangan mo: {giftItemSummary}.",
                        },
                    },
                    {
                        ["key"] = "gift.offer.single",
                        ["text"] = {
                            ["EN"] = "Here's {giftItemName}. I thought you could use it.",
                            ["TL"] = "Narito ang {giftItemName}. Akala ko magagamit mo.",
                        },
                    },
                    {
                        ["key"] = "gift.offer.single.alt",
                        ["text"] = {
                            ["EN"] = "This is for you: {giftItemName}.",
                            ["TL"] = "Para sa iyo ito: {giftItemName}.",
                        },
                    },
                    {
                        ["key"] = "gift.received.equipment",
                        ["text"] = {
                            ["EN"] = "Useful, deliberate, and well chosen. You are learning how I think.",
                            ["TL"] = "Kapaki-pakinabang, pinag-isipan, at mahusay na pinili. Natututuhan mo na kung paano ako mag-isip.",
                        },
                    },
                    {
                        ["key"] = "gift.received.food",
                        ["text"] = {
                            ["EN"] = "You remembered me. I will enjoy this, and I will remember the gesture.",
                            ["TL"] = "Naalala mo ako. Masisiyahan ako rito, at maaalala ko ang ginawa mong ito.",
                        },
                    },
                    {
                        ["key"] = "gift.received.general",
                        ["text"] = {
                            ["EN"] = "That is thoughtful of you. Thank you.",
                            ["TL"] = "Iyan ay nag-iisip sa iyo. salamat po.",
                        },
                    },
                    {
                        ["key"] = "gift.received.medical",
                        ["text"] = {
                            ["EN"] = "You noticed what I needed before I had to ask. That means more than the medicine itself.",
                            ["TL"] = "Napansin mo ang kailangan ko bago ko pa hingin. Mas mahalaga iyon kaysa sa mismong gamot.",
                        },
                    },
                },
                ["textTarget"] = "convo/needs/special/support",
            },
            ["response"] = {
                ["act"] = "NEEDS",
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
                                    ["subject"] = "SUPPLIES",
                                    ["topic"] = "needs",
                                },
                                ["id"] = "supplies",
                                ["label"] = {
                                    ["EN"] = {
                                        "What can I bring you?",
                                    },
                                    ["TL"] = {
                                        "Ano ang maaari kong dalhin sa iyo?",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.supplies",
                                    ["responseKey"] = "response.supplies",
                                    ["responseText"] = {
                                        ["EN"] = "Just come back safely. Anything else is extra.",
                                        ["TL"] = "Bumalik ka na lang ng matiwasay. Anumang bagay ay dagdag.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "What can I bring you?",
                                    },
                                    ["TL"] = {
                                        "Ano ang maaari kong dalhin sa iyo?",
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
                                    ["subject"] = "MEDICAL",
                                    ["topic"] = "needs",
                                },
                                ["id"] = "medical",
                                ["label"] = {
                                    ["EN"] = {
                                        "Are you hurt?",
                                    },
                                    ["TL"] = {
                                        "nasaktan ka ba",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.medical",
                                    ["responseKey"] = "response.medical",
                                    ["responseText"] = {
                                        ["EN"] = "No. I would tell you if I was.",
                                        ["TL"] = "Hindi. Sasabihin ko sa iyo kung ako nga.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "Are you hurt?",
                                    },
                                    ["TL"] = {
                                        "nasaktan ka ba",
                                    },
                                },
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
                                ["label"] = {
                                    ["EN"] = {
                                        "I have something you might need.",
                                    },
                                    ["TL"] = {
                                        "Mayroon akong isang bagay na maaaring kailanganin mo.",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.gift",
                                    ["next"] = "gift",
                                    ["responseKey"] = "response.gift",
                                    ["responseText"] = {
                                        ["EN"] = "Let me see what you can spare.",
                                        ["TL"] = "Hayaan akong makita kung ano ang maaari mong matitira.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "I have something you might need.",
                                    },
                                    ["TL"] = {
                                        "Mayroon akong isang bagay na maaaring kailanganin mo.",
                                    },
                                },
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Since it's you, I'll tell you what I need.",
                            },
                            ["TL"] = {
                                "Dahil ikaw ito, sasabihin ko sa iyo kung ano ang kailangan ko.",
                            },
                        },
                    },
                    {
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
                                ["label"] = {
                                    ["EN"] = {
                                        "I will hold on to the rest.",
                                    },
                                    ["TL"] = {
                                        "Hahawakan ko ang natitira.",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.gift_return",
                                    ["responseKey"] = "response.gift_return",
                                    ["responseText"] = {
                                        ["EN"] = "Understood.",
                                        ["TL"] = "Understood.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "I will hold on to the rest.",
                                    },
                                    ["TL"] = {
                                        "Hahawakan ko ang natitira.",
                                    },
                                },
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Choose something to give me, then return to the conversation.",
                            },
                            ["TL"] = {
                                "Pumili ng ibibigay sa akin, pagkatapos ay bumalik sa usapan.",
                            },
                        },
                    },
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/needs_support/needs_special_support.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
