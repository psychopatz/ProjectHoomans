-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "event_reactions_farewell",
        ["exchangeFamily"] = {
            ["familyID"] = "flow.farewell.default",
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
                                ["fallback"] = "Take care.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.flow.farewell.default.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Take care.",
                                        "Stay safe out there.",
                                        "Watch yourself.",
                                        "Until next time.",
                                        "Keep your guard up.",
                                        "Stay sharp on the road.",
                                        "Catch you later.",
                                        "Safe travels.",
                                        "Keep breathing out there.",
                                        "See you around.",
                                    },
                                    ["TL"] = {
                                        "Mag-ingat ka.",
                                        "Maging ligtas ka sa labas.",
                                        "Ingatan mo sarili mo.",
                                        "Hanggang sa muli.",
                                        "Panatilihing mataas ang depensa.",
                                        "Magmatyag sa kalsada.",
                                        "Mamaya ulit.",
                                        "Ligtas na paglalakbay.",
                                        "Manatiling buhay sa labas.",
                                        "Magkita na lang tayo.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "flow.farewell",
            ["textRoles"] = {
                {
                    ["fallback"] = "Take care.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.farewell.default.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Take care.",
                            "Stay safe out there.",
                            "Watch yourself.",
                            "Until next time.",
                            "Keep your guard up.",
                            "Stay sharp on the road.",
                            "Catch you later.",
                            "Safe travels.",
                            "Keep breathing out there.",
                            "See you around.",
                        },
                        ["TL"] = {
                            "Mag-ingat ka.",
                            "Maging ligtas ka sa labas.",
                            "Ingatan mo sarili mo.",
                            "Hanggang sa muli.",
                            "Panatilihing mataas ang depensa.",
                            "Magmatyag sa kalsada.",
                            "Mamaya ulit.",
                            "Ligtas na paglalakbay.",
                            "Manatiling buhay sa labas.",
                            "Magkita na lang tayo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "flow.farewell.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "default",
            ["sourceId"] = "flow.farewell.default",
            ["sourcePath"] = "adopters/hoomans/dialogue/event_reactions_farewell/flow_farewell_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsFarewell",
        ["namespace"] = "flow.farewell",
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
                ["category"] = "projecthoomans:event_reactions",
                ["contentOwner"] = "projecthoomans.dialogue_content.events",
                ["responseAct"] = "FAREWELL",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/reactions/farewell.json",
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Take care.",
                                        "Stay safe out there.",
                                        "Watch yourself.",
                                        "Until next time.",
                                        "Keep your guard up.",
                                        "Stay sharp on the road.",
                                        "Catch you later.",
                                        "Safe travels.",
                                        "Keep breathing out there.",
                                        "See you around.",
                                    },
                                    ["TL"] = {
                                        "Mag-ingat ka.",
                                        "Maging ligtas ka sa labas.",
                                        "Ingatan mo sarili mo.",
                                        "Hanggang sa muli.",
                                        "Panatilihing mataas ang depensa.",
                                        "Magmatyag sa kalsada.",
                                        "Mamaya ulit.",
                                        "Ligtas na paglalakbay.",
                                        "Manatiling buhay sa labas.",
                                        "Magkita na lang tayo.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "FAREWELL",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "flow.farewell.default",
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
                            ["fallback"] = "Take care.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.flow.farewell.default.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/event_reactions_farewell/flow_farewell_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Take care.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.farewell.default.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Take care.",
                        "Stay safe out there.",
                        "Watch yourself.",
                        "Until next time.",
                        "Keep your guard up.",
                        "Stay sharp on the road.",
                        "Catch you later.",
                        "Safe travels.",
                        "Keep breathing out there.",
                        "See you around.",
                    },
                    ["TL"] = {
                        "Mag-ingat ka.",
                        "Maging ligtas ka sa labas.",
                        "Ingatan mo sarili mo.",
                        "Hanggang sa muli.",
                        "Panatilihing mataas ang depensa.",
                        "Magmatyag sa kalsada.",
                        "Mamaya ulit.",
                        "Ligtas na paglalakbay.",
                        "Manatiling buhay sa labas.",
                        "Magkita na lang tayo.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_farewell",
        ["exchangeFamily"] = {
            ["familyID"] = "flow.farewell.friendly",
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
                                ["fallback"] = "Take care. I will see you soon.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.flow.farewell.friendly.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Take care. I will see you soon.",
                                        "Stay safe, my friend. Come back in one piece.",
                                        "Look after yourself. Don't be a stranger.",
                                        "Good luck out there. See you soon.",
                                        "Keep your head down and stay safe. Talk soon.",
                                        "It was good seeing you. Safe travels.",
                                        "Take care of yourself. I'll be waiting.",
                                        "Watch your back out there, friend.",
                                        "Stay alive. We'll share a drink next time.",
                                        "Be careful out there. See you shortly.",
                                    },
                                    ["TL"] = {
                                        "Mag-ingat ka. Magkikita tayo sa lalong madaling panahon.",
                                        "Mag-ingat ka, kaibigan. Bumalik kang buo.",
                                        "Alagaan mo sarili mo. Huwag kang mawawala.",
                                        "Magandang kapalaran sa labas. Hanggang sa muli.",
                                        "Yumuko sa panganib at mag-ingat. Usap tayo ulit.",
                                        "Mabuti at nagkita tayo. Ligtas na paglalakbay.",
                                        "Alagaan mo sarili mo. Hihintayin kita.",
                                        "Bantayan ang likod mo sa labas, kaibigan.",
                                        "Manatiling buhay. Mag-inuman tayo sa susunod.",
                                        "Mag-ingat ka sa labas. Magkikita tayo sa lalong madaling panahon.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "flow.farewell",
            ["textRoles"] = {
                {
                    ["fallback"] = "Take care. I will see you soon.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.farewell.friendly.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Take care. I will see you soon.",
                            "Stay safe, my friend. Come back in one piece.",
                            "Look after yourself. Don't be a stranger.",
                            "Good luck out there. See you soon.",
                            "Keep your head down and stay safe. Talk soon.",
                            "It was good seeing you. Safe travels.",
                            "Take care of yourself. I'll be waiting.",
                            "Watch your back out there, friend.",
                            "Stay alive. We'll share a drink next time.",
                            "Be careful out there. See you shortly.",
                        },
                        ["TL"] = {
                            "Mag-ingat ka. Magkikita tayo sa lalong madaling panahon.",
                            "Mag-ingat ka, kaibigan. Bumalik kang buo.",
                            "Alagaan mo sarili mo. Huwag kang mawawala.",
                            "Magandang kapalaran sa labas. Hanggang sa muli.",
                            "Yumuko sa panganib at mag-ingat. Usap tayo ulit.",
                            "Mabuti at nagkita tayo. Ligtas na paglalakbay.",
                            "Alagaan mo sarili mo. Hihintayin kita.",
                            "Bantayan ang likod mo sa labas, kaibigan.",
                            "Manatiling buhay. Mag-inuman tayo sa susunod.",
                            "Mag-ingat ka sa labas. Magkikita tayo sa lalong madaling panahon.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "flow.farewell.friendly",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "friendly",
            ["sourceId"] = "flow.farewell.friendly",
            ["sourcePath"] = "adopters/hoomans/dialogue/event_reactions_farewell/flow_farewell.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsFarewell",
        ["namespace"] = "flow.farewell",
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
                ["category"] = "projecthoomans:event_reactions",
                ["contentOwner"] = "projecthoomans.dialogue_content.events",
                ["responseAct"] = "FAREWELL",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/reactions/farewell.json",
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Take care. I will see you soon.",
                                        "Stay safe, my friend. Come back in one piece.",
                                        "Look after yourself. Don't be a stranger.",
                                        "Good luck out there. See you soon.",
                                        "Keep your head down and stay safe. Talk soon.",
                                        "It was good seeing you. Safe travels.",
                                        "Take care of yourself. I'll be waiting.",
                                        "Watch your back out there, friend.",
                                        "Stay alive. We'll share a drink next time.",
                                        "Be careful out there. See you shortly.",
                                    },
                                    ["TL"] = {
                                        "Mag-ingat ka. Magkikita tayo sa lalong madaling panahon.",
                                        "Mag-ingat ka, kaibigan. Bumalik kang buo.",
                                        "Alagaan mo sarili mo. Huwag kang mawawala.",
                                        "Magandang kapalaran sa labas. Hanggang sa muli.",
                                        "Yumuko sa panganib at mag-ingat. Usap tayo ulit.",
                                        "Mabuti at nagkita tayo. Ligtas na paglalakbay.",
                                        "Alagaan mo sarili mo. Hihintayin kita.",
                                        "Bantayan ang likod mo sa labas, kaibigan.",
                                        "Manatiling buhay. Mag-inuman tayo sa susunod.",
                                        "Mag-ingat ka sa labas. Magkikita tayo sa lalong madaling panahon.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "FAREWELL",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "flow.farewell.friendly",
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
                            ["fallback"] = "Take care. I will see you soon.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.flow.farewell.friendly.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/event_reactions_farewell/flow_farewell.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Take care. I will see you soon.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.farewell.friendly.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Take care. I will see you soon.",
                        "Stay safe, my friend. Come back in one piece.",
                        "Look after yourself. Don't be a stranger.",
                        "Good luck out there. See you soon.",
                        "Keep your head down and stay safe. Talk soon.",
                        "It was good seeing you. Safe travels.",
                        "Take care of yourself. I'll be waiting.",
                        "Watch your back out there, friend.",
                        "Stay alive. We'll share a drink next time.",
                        "Be careful out there. See you shortly.",
                    },
                    ["TL"] = {
                        "Mag-ingat ka. Magkikita tayo sa lalong madaling panahon.",
                        "Mag-ingat ka, kaibigan. Bumalik kang buo.",
                        "Alagaan mo sarili mo. Huwag kang mawawala.",
                        "Magandang kapalaran sa labas. Hanggang sa muli.",
                        "Yumuko sa panganib at mag-ingat. Usap tayo ulit.",
                        "Mabuti at nagkita tayo. Ligtas na paglalakbay.",
                        "Alagaan mo sarili mo. Hihintayin kita.",
                        "Bantayan ang likod mo sa labas, kaibigan.",
                        "Manatiling buhay. Mag-inuman tayo sa susunod.",
                        "Mag-ingat ka sa labas. Magkikita tayo sa lalong madaling panahon.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
