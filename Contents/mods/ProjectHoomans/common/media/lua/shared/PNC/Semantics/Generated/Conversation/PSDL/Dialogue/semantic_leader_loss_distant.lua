-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "event_reactions_leader_loss",
        ["id"] = "semantic.leader_loss.distant",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.leader_loss.distant",
            ["sourcePath"] = "psdl/dialogue/event_reactions_leader_loss.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_leader_loss_distant",
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
                ["responseTemplateID"] = "semantic.leader_loss.distant",
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
                                "The leader is gone. Someone needs to decide what comes next.",
                            },
                            ["TL"] = {
                                "Wala na ang pinuno. May kailangang magpasya sa susunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I barely knew them, but we still need structure.",
                            },
                            ["TL"] = {
                                "Halos hindi ko sila kilala, pero kailangan pa rin natin ng kaayusan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Leader died. Life goes on. Who's in charge?",
                            },
                            ["TL"] = {
                                "Namatay ang pinuno. Tuloy ang buhay. Sino'ng mamumuno?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "A casualty like any other. Let's elect someone new.",
                            },
                            ["TL"] = {
                                "Biktima tulad ng iba. Pumili tayo ng bago.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "They're gone. We still need food and guards.",
                            },
                            ["TL"] = {
                                "Wala na sila. Kailangan pa rin natin ng pagkain at bantay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Another name scratched off. Let's sort out the command.",
                            },
                            ["TL"] = {
                                "Isa na namang pangalan ang nabura. Ayusin natin ang pamumuno.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Doesn't change my daily tasks. Who's giving orders now?",
                            },
                            ["TL"] = {
                                "Hindi nababago ang gawain ko. Sino na ang mag-uutos ngayon?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Leader's expired. Pick a replacement and move forward.",
                            },
                            ["TL"] = {
                                "Pumanaw na ang lider. Pumili ng kapalit at magpatuloy.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Death is common here. Let's figure out our routine.",
                            },
                            ["TL"] = {
                                "Pangkaraniwan ang kamatayan dito. Ayusin natin ang patakaran.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "They're dead. What's the practical plan?",
                            },
                            ["TL"] = {
                                "Patay na sila. Ano ang praktikal na plano?",
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
