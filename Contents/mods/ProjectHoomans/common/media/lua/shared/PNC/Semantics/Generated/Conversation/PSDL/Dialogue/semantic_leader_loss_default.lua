-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "event_reactions_leader_loss",
        ["id"] = "semantic.leader_loss.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.leader_loss.default",
            ["sourcePath"] = "psdl/dialogue/event_reactions_leader_loss.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_leader_loss_default",
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
                ["responseTemplateID"] = "semantic.leader_loss.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/reactions/leader_loss.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "We lost our leader. We need to decide what comes next.",
                            },
                            ["TL"] = {
                                "Nawalan tayo ng pinuno. Kailangan nating pagpasyahan ang susunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "The boss is down. Who's taking charge?",
                            },
                            ["TL"] = {
                                "Bagsak ang pinuno. Sino'ng hahawak ng pamumuno?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Without leadership, we need to regroup and plan.",
                            },
                            ["TL"] = {
                                "Kung walang namumuno, kailangan nating magtipon at magplano.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Our leader is dead. What do we do now?",
                            },
                            ["TL"] = {
                                "Patay na ang pinuno natin. Ano'ng gagawin natin ngayon?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "We need to talk about who leads us forward.",
                            },
                            ["TL"] = {
                                "Kailangan nating pag-usapan kung sino ang mangunguna sa atin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "The head is cut off. We need a new direction.",
                            },
                            ["TL"] = {
                                "Naputol ang ulo ng grupo. Kailangan natin ng bagong direksyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Leader's gone. Let's not fall into chaos.",
                            },
                            ["TL"] = {
                                "Wala na ang lider. Huwag tayong mahulog sa kaguluhan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Someone needs to step up and guide the crew.",
                            },
                            ["TL"] = {
                                "May kailangang tumindig at gumabay sa grupo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "We're leaderless right now. Keep calm and talk.",
                            },
                            ["TL"] = {
                                "Wala tayong pinuno ngayon. Kumalma at mag-usap tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Terrible news. Let's figure out our next steps.",
                            },
                            ["TL"] = {
                                "Masamang balita. Pag-isipan natin ang susunod nating hakbang.",
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
        ["sourceShard"] = "psdl/dialogue/event_reactions_leader_loss.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
