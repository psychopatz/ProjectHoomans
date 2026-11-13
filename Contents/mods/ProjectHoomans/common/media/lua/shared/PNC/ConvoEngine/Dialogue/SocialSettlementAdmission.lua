-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_settlement_admission",
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
                ["runtimeBlockID"] = "projecthoomans:settlement_admission",
                ["textDomain"] = "pnc.psdl.social.greetings.settlement_admission.arrival",
                ["textRows"] = {
                    {
                        ["key"] = "response.settlement_admission.accepted.1",
                        ["text"] = {
                            ["EN"] = "Thank you. I thought I would have to keep walking until there was nowhere left to go.",
                            ["TL"] = "salamat po. Naisip ko na kailangan kong magpatuloy sa paglalakad hanggang sa wala na akong mapupuntahan.",
                        },
                    },
                },
                ["textTarget"] = "psdl/social/greetings/settlement_admission/arrival",
                ["weight"] = 100,
            },
            ["response"] = {
                ["act"] = "SETTLEMENT_ADMISSION",
                ["variants"] = {
                    {
                        ["id"] = "opening.001",
                        ["metadata"] = {
                            ["textKey"] = "opening.001",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Please… let me stay. We have been walking for days, and I do not know how much longer the others can keep going.",
                            },
                            ["TL"] = {
                                "Please... hayaan mo akong manatili. Ilang araw na kaming naglalakad, at hindi ko alam kung gaano katagal kayang magpatuloy ang iba.",
                            },
                        },
                    },
                    {
                        ["id"] = "opening.002",
                        ["metadata"] = {
                            ["textKey"] = "opening.002",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I am not asking for much. A roof, a meal, and a chance to be useful. Please let us join you.",
                            },
                            ["TL"] = {
                                "Hindi ako humihingi ng marami. Isang bubong, isang pagkain, at isang pagkakataon na maging kapaki-pakinabang. Mangyaring hayaan mo kaming samahan ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "opening.003",
                        ["metadata"] = {
                            ["textKey"] = "opening.003",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You have a settlement. We have nothing left but each other. If there is room, I will work for it.",
                            },
                            ["TL"] = {
                                "You have a pamayanan. We have nothing left but each other. If there is room, I will trabaho for it.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_settlement_admission/social_settlement_admission.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "relationship.settlementVisit.active",
            ["value"] = true,
        },
    },
}
