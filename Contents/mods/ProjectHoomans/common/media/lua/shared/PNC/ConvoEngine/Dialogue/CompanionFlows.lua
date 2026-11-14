-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_flows",
        ["exchangeFamily"] = {
            ["familyID"] = "pnc.dialogue.follow",
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
                                ["fallback"] = "Okay, I'll come with you.",
                                ["id"] = "accepted",
                                ["templateID"] = "convo.pnc.dialogue.follow.say.1.accepted",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Okay, I'll come with you.",
                                    },
                                    ["TL"] = {
                                        "Sige, sasama ako sa iyo.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "pnc.dialogue",
            ["textRoles"] = {
                {
                    ["fallback"] = "Okay, I'll come with you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.pnc.dialogue.follow.say.1.accepted",
                    ["translations"] = {
                        ["EN"] = {
                            "Okay, I'll come with you.",
                        },
                        ["TL"] = {
                            "Sige, sasama ako sa iyo.",
                        },
                    },
                    ["variantID"] = "accepted",
                },
            },
        },
        ["id"] = "pnc.dialogue.follow",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "follow",
            ["sourceId"] = "pnc.dialogue.follow",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_flows/follow.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionFlows",
        ["namespace"] = "pnc.dialogue",
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
                ["capability"] = "pnc:companion.follow",
                ["confidence"] = 0.99,
                ["emit"] = {
                    ["action"] = "FOLLOW",
                    ["intent"] = "REQUEST",
                    ["reference"] = "AUTHORED_FOLLOW",
                    ["speechAct"] = "REQUEST",
                },
                ["flow"] = {
                    ["id"] = "pnc.dialogue.follow.flow",
                    ["initial"] = "accepted",
                    ["nodes"] = {
                        ["accepted"] = {
                            ["responsePool"] = "semantic.authored.follow",
                            ["terminal"] = true,
                        },
                    },
                    ["version"] = 1,
                },
                ["priority"] = 165,
                ["responseAct"] = "FLOW_RESPONSE",
                ["responsePoolID"] = "authored.follow",
                ["triggers"] = {
                    {
                        ["action"] = "FOLLOW",
                        ["intent"] = "REQUEST",
                        ["pattern"] = "pnc.dialogue.follow.keep_close_behind_me",
                        ["speechAct"] = "REQUEST",
                    },
                    {
                        ["action"] = "FOLLOW",
                        ["intent"] = "REQUEST",
                        ["pattern"] = "pnc.dialogue.follow.please_keep_close_behind_me",
                        ["speechAct"] = "REQUEST",
                    },
                },
                ["utterances"] = {
                    ["negatives"] = {
                        "don't keep close behind me",
                        "are you keeping close behind me",
                        "i kept close behind you",
                    },
                    ["positives"] = {
                        "keep close behind me",
                        "please keep close behind me",
                    },
                },
            },
            ["on"] = {
                ["action"] = "FOLLOW",
                ["intent"] = "REQUEST",
                ["speechAct"] = "REQUEST",
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
                                ["id"] = "accepted",
                                ["metadata"] = {
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_AuthoredFollowAccepted",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "Okay, I'll come with you.",
                                    },
                                    ["TL"] = {
                                        "Sige, sasama ako sa iyo.",
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
            ["dialogueAct"] = "FLOW_RESPONSE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "pnc.dialogue.follow",
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
                            ["fallback"] = "Okay, I'll come with you.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.pnc.dialogue.follow.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_flows/follow.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Okay, I'll come with you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.pnc.dialogue.follow.say.1.accepted",
                ["translations"] = {
                    ["EN"] = {
                        "Okay, I'll come with you.",
                    },
                    ["TL"] = {
                        "Sige, sasama ako sa iyo.",
                    },
                },
                ["variantID"] = "accepted",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_flows",
        ["exchangeFamily"] = {
            ["familyID"] = "pnc.lab.stay_with_you",
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
                                ["fallback"] = "Okay, I'll stay with you.",
                                ["id"] = "accepted",
                                ["templateID"] = "convo.pnc.lab.stay_with_you.say.1.accepted",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Okay, I'll stay with you.",
                                    },
                                    ["TL"] = {
                                        "Sige, mananatili ako sa iyo.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "pnc.lab",
            ["textRoles"] = {
                {
                    ["fallback"] = "Okay, I'll stay with you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.pnc.lab.stay_with_you.say.1.accepted",
                    ["translations"] = {
                        ["EN"] = {
                            "Okay, I'll stay with you.",
                        },
                        ["TL"] = {
                            "Sige, mananatili ako sa iyo.",
                        },
                    },
                    ["variantID"] = "accepted",
                },
            },
        },
        ["id"] = "pnc.lab.stay_with_you",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "stay_with_you",
            ["sourceId"] = "pnc.lab.stay_with_you",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_flows/lab_stay_with_you.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionFlows",
        ["namespace"] = "pnc.lab",
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
                ["capability"] = "pnc:companion.stay",
                ["confidence"] = 0.99,
                ["emit"] = {
                    ["action"] = "STAY",
                    ["intent"] = "REQUEST",
                    ["speechAct"] = "REQUEST",
                },
                ["flow"] = {
                    ["id"] = "pnc.lab.stay_with_you.flow",
                    ["initial"] = "accepted",
                    ["nodes"] = {
                        ["accepted"] = {
                            ["responsePool"] = "semantic.lab.stay.with.you",
                            ["terminal"] = true,
                        },
                    },
                    ["version"] = 1,
                },
                ["priority"] = 170,
                ["responseAct"] = "FLOW_RESPONSE",
                ["responsePoolID"] = "lab.stay.with.you",
                ["triggers"] = {
                    {
                        ["action"] = "STAY",
                        ["intent"] = "REQUEST",
                        ["pattern"] = "pnc.lab.stay_with_you.stay_with_you",
                        ["speechAct"] = "REQUEST",
                    },
                },
                ["utterances"] = {
                    ["negatives"] = {
                        "don't stay with you",
                    },
                    ["positives"] = {
                        "stay with you",
                    },
                },
            },
            ["on"] = {
                ["action"] = "STAY",
                ["intent"] = "REQUEST",
                ["speechAct"] = "REQUEST",
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
                                ["id"] = "accepted",
                                ["metadata"] = {
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_PncLabStayWithYouAccepted",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "Okay, I'll stay with you.",
                                    },
                                    ["TL"] = {
                                        "Sige, mananatili ako sa iyo.",
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
            ["dialogueAct"] = "FLOW_RESPONSE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "pnc.lab.stay_with_you",
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
                            ["fallback"] = "Okay, I'll stay with you.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.pnc.lab.stay_with_you.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_flows/lab_stay_with_you.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Okay, I'll stay with you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.pnc.lab.stay_with_you.say.1.accepted",
                ["translations"] = {
                    ["EN"] = {
                        "Okay, I'll stay with you.",
                    },
                    ["TL"] = {
                        "Sige, mananatili ako sa iyo.",
                    },
                },
                ["variantID"] = "accepted",
            },
        },
        ["when"] = nil,
    },
}
