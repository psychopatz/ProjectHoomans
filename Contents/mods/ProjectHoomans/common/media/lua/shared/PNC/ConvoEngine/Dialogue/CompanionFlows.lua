-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_flows",
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
                ["originalOwner"] = "ProjectHoomans",
                ["priority"] = 165,
                ["responsePoolID"] = "semantic.authored.follow",
                ["sourceProfile"] = "conversation.source.projecthoomans.8378f35867",
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
            ["response"] = {
                ["act"] = "FLOW_RESPONSE",
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
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_flows/follow.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_flows",
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
                ["originalOwner"] = "SemanticLab",
                ["priority"] = 170,
                ["responsePoolID"] = "semantic.lab.stay.with.you",
                ["sourceProfile"] = "conversation.source.projecthoomans.8378f35867",
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
            ["response"] = {
                ["act"] = "FLOW_RESPONSE",
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
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_flows/lab_stay_with_you.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
