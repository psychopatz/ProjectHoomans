-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_settlement_admission",
        ["exchangeFamily"] = {
            ["familyID"] = "social.settlement_admission",
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
                                ["fallback"] = "Please… let me stay. We have been walking for days, and I do not know how much longer the others can keep going.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.settlement_admission.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Please… let me stay. We have been walking for days, and I do not know how much longer the others can keep going.",
                                        "I am not asking for much. A roof, a meal, and a chance to be useful. Please let us join you.",
                                        "You have a settlement. We have nothing left but each other. If there is room, I will work for it.",
                                    },
                                    ["TL"] = {
                                        "Please... hayaan mo akong manatili. Ilang araw na kaming naglalakad, at hindi ko alam kung gaano katagal kayang magpatuloy ang iba.",
                                        "Hindi ako humihingi ng marami. Isang bubong, isang pagkain, at isang pagkakataon na maging kapaki-pakinabang. Mangyaring hayaan mo kaming samahan ka.",
                                        "You have a pamayanan. We have nothing left but each other. If there is room, I will trabaho for it.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social",
            ["textRoles"] = {
                {
                    ["fallback"] = "Please… let me stay. We have been walking for days, and I do not know how much longer the others can keep going.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.settlement_admission.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Please… let me stay. We have been walking for days, and I do not know how much longer the others can keep going.",
                            "I am not asking for much. A roof, a meal, and a chance to be useful. Please let us join you.",
                            "You have a settlement. We have nothing left but each other. If there is room, I will work for it.",
                        },
                        ["TL"] = {
                            "Please... hayaan mo akong manatili. Ilang araw na kaming naglalakad, at hindi ko alam kung gaano katagal kayang magpatuloy ang iba.",
                            "Hindi ako humihingi ng marami. Isang bubong, isang pagkain, at isang pagkakataon na maging kapaki-pakinabang. Mangyaring hayaan mo kaming samahan ka.",
                            "You have a pamayanan. We have nothing left but each other. If there is room, I will trabaho for it.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.settlement_admission",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "settlement_admission",
            ["sourceId"] = "social.settlement_admission",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_settlement_admission/social_settlement_admission.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialSettlementAdmission",
        ["namespace"] = "social",
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
                    "member",
                    "special",
                },
                ["category"] = "projecthoomans:greetings",
                ["priority"] = 1000,
                ["responseAct"] = "SETTLEMENT_ADMISSION",
                ["runtimeBlockID"] = "projecthoomans:settlement_admission",
                ["textDomain"] = "pnc.convo.social.greetings.settlement_admission.arrival",
                ["textRows"] = {
                    {
                        ["key"] = "opening.001",
                        ["text"] = {
                            ["EN"] = "Please… let me stay. We have been walking for days, and I do not know how much longer the others can keep going.",
                            ["TL"] = "Please... hayaan mo akong manatili. Ilang araw na kaming naglalakad, at hindi ko alam kung gaano katagal kayang magpatuloy ang iba.",
                        },
                    },
                    {
                        ["key"] = "opening.002",
                        ["text"] = {
                            ["EN"] = "I am not asking for much. A roof, a meal, and a chance to be useful. Please let us join you.",
                            ["TL"] = "Hindi ako humihingi ng marami. Isang bubong, isang pagkain, at isang pagkakataon na maging kapaki-pakinabang. Mangyaring hayaan mo kaming samahan ka.",
                        },
                    },
                    {
                        ["key"] = "opening.003",
                        ["text"] = {
                            ["EN"] = "You have a settlement. We have nothing left but each other. If there is room, I will work for it.",
                            ["TL"] = "You have a pamayanan. We have nothing left but each other. If there is room, I will trabaho for it.",
                        },
                    },
                    {
                        ["key"] = "response.settlement_admission.accepted.1",
                        ["text"] = {
                            ["EN"] = "Thank you. I thought I would have to keep walking until there was nowhere left to go.",
                            ["TL"] = "salamat po. Naisip ko na kailangan kong magpatuloy sa paglalakad hanggang sa wala na akong mapupuntahan.",
                        },
                    },
                },
                ["textTarget"] = "convo/social/greetings/settlement_admission/arrival",
                ["weight"] = 100,
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
                                        "Please… let me stay. We have been walking for days, and I do not know how much longer the others can keep going.",
                                        "I am not asking for much. A roof, a meal, and a chance to be useful. Please let us join you.",
                                        "You have a settlement. We have nothing left but each other. If there is room, I will work for it.",
                                    },
                                    ["TL"] = {
                                        "Please... hayaan mo akong manatili. Ilang araw na kaming naglalakad, at hindi ko alam kung gaano katagal kayang magpatuloy ang iba.",
                                        "Hindi ako humihingi ng marami. Isang bubong, isang pagkain, at isang pagkakataon na maging kapaki-pakinabang. Mangyaring hayaan mo kaming samahan ka.",
                                        "You have a pamayanan. We have nothing left but each other. If there is room, I will trabaho for it.",
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
            ["dialogueAct"] = "SETTLEMENT_ADMISSION",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.settlement_admission",
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
                            ["fallback"] = "Please… let me stay. We have been walking for days, and I do not know how much longer the others can keep going.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.settlement_admission.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_settlement_admission/social_settlement_admission.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Please… let me stay. We have been walking for days, and I do not know how much longer the others can keep going.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.settlement_admission.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Please… let me stay. We have been walking for days, and I do not know how much longer the others can keep going.",
                        "I am not asking for much. A roof, a meal, and a chance to be useful. Please let us join you.",
                        "You have a settlement. We have nothing left but each other. If there is room, I will work for it.",
                    },
                    ["TL"] = {
                        "Please... hayaan mo akong manatili. Ilang araw na kaming naglalakad, at hindi ko alam kung gaano katagal kayang magpatuloy ang iba.",
                        "Hindi ako humihingi ng marami. Isang bubong, isang pagkain, at isang pagkakataon na maging kapaki-pakinabang. Mangyaring hayaan mo kaming samahan ka.",
                        "You have a pamayanan. We have nothing left but each other. If there is room, I will trabaho for it.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "relationship.settlementVisit.active",
            ["value"] = true,
        },
    },
}
