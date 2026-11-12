-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "needs_support",
        ["id"] = "needs.neutral.support",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "needs.neutral.support",
            ["sourcePath"] = "psdl/dialogue/needs_support.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/needs_neutral_support",
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
                ["textDomain"] = "pnc.psdl.needs.neutral.support",
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
                ["textTarget"] = "psdl/needs/neutral/support",
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
                            ["labelKey"] = "psdl.needs.neutral.support.offer.supplies.label",
                            ["utteranceFallback"] = "Need any supplies?",
                            ["utteranceKey"] = "psdl.needs.neutral.support.offer.supplies.utterance",
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
                            ["labelKey"] = "psdl.needs.neutral.support.offer.medical.label",
                            ["utteranceFallback"] = "Any medical problems?",
                            ["utteranceKey"] = "psdl.needs.neutral.support.offer.medical.utterance",
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
                            ["labelKey"] = "psdl.needs.neutral.support.offer.gift.label",
                            ["utteranceFallback"] = "I have something you might need.",
                            ["utteranceKey"] = "psdl.needs.neutral.support.offer.gift.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "There are a few things I could use.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.needs.neutral.support.opening",
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
                            ["labelKey"] = "psdl.needs.neutral.support.offer.gift_return.label",
                            ["utteranceFallback"] = "I will hold on to the rest.",
                            ["utteranceKey"] = "psdl.needs.neutral.support.offer.gift_return.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Choose something to give me, then return to the conversation.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.needs.neutral.support.gift",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/needs_support.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
