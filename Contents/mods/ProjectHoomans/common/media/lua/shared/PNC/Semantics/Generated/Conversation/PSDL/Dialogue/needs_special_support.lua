-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "needs_support",
        ["id"] = "needs.special.support",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "needs.special.support",
            ["sourcePath"] = "psdl/dialogue/needs_support.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/needs_special_support",
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
                ["textDomain"] = "pnc.psdl.needs.special.support",
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
                ["textTarget"] = "psdl/needs/special/support",
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
                            ["labelKey"] = "psdl.needs.special.support.offer.supplies.label",
                            ["utteranceFallback"] = "What can I bring you?",
                            ["utteranceKey"] = "psdl.needs.special.support.offer.supplies.utterance",
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
                            ["labelKey"] = "psdl.needs.special.support.offer.medical.label",
                            ["utteranceFallback"] = "Are you hurt?",
                            ["utteranceKey"] = "psdl.needs.special.support.offer.medical.utterance",
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
                            ["labelKey"] = "psdl.needs.special.support.offer.gift.label",
                            ["utteranceFallback"] = "I have something you might need.",
                            ["utteranceKey"] = "psdl.needs.special.support.offer.gift.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Since it's you, I'll tell you what I need.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.needs.special.support.opening",
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
                            ["labelKey"] = "psdl.needs.special.support.offer.gift_return.label",
                            ["utteranceFallback"] = "I will hold on to the rest.",
                            ["utteranceKey"] = "psdl.needs.special.support.offer.gift_return.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Choose something to give me, then return to the conversation.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.needs.special.support.gift",
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
