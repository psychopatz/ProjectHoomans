-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "needs_support",
        ["id"] = "needs.member.support",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "needs.member.support",
            ["sourcePath"] = "psdl/dialogue/needs_support.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/needs_member_support",
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
                ["textDomain"] = "pnc.psdl.needs.member.support",
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
                ["textTarget"] = "psdl/needs/member/support",
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
                            ["labelKey"] = "psdl.needs.member.support.offer.supplies.label",
                            ["utteranceFallback"] = "What supplies are we short on?",
                            ["utteranceKey"] = "psdl.needs.member.support.offer.supplies.utterance",
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
                            ["labelKey"] = "psdl.needs.member.support.offer.medical.label",
                            ["utteranceFallback"] = "Does anyone need medical help?",
                            ["utteranceKey"] = "psdl.needs.member.support.offer.medical.utterance",
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
                            ["labelKey"] = "psdl.needs.member.support.offer.gift.label",
                            ["utteranceFallback"] = "I have something you might need.",
                            ["utteranceKey"] = "psdl.needs.member.support.offer.gift.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Let me think about what the group is short on.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.needs.member.support.opening",
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
                            ["labelKey"] = "psdl.needs.member.support.offer.gift_return.label",
                            ["utteranceFallback"] = "I will hold on to the rest.",
                            ["utteranceKey"] = "psdl.needs.member.support.offer.gift_return.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Choose something to give me, then return to the conversation.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.needs.member.support.gift",
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
