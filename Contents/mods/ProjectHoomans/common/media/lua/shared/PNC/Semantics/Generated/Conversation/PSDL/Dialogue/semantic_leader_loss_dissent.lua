-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "event_reactions_leader_loss",
        ["id"] = "semantic.leader_loss.dissent",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.leader_loss.dissent",
            ["sourcePath"] = "psdl/dialogue/event_reactions_leader_loss.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_leader_loss_dissent",
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
                ["responseTemplateID"] = "semantic.leader_loss.dissent",
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
                                "The old order is gone. What happens next is up to us.",
                            },
                            ["TL"] = {
                                "Wala na ang dating patakaran. Nasa atin na kung ano ang susunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Their reign is over. Time for a better way.",
                            },
                            ["TL"] = {
                                "Tapos na ang pamumuno nila. Oras na para sa mas maayos na paraan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "They made terrible choices and paid for it.",
                            },
                            ["TL"] = {
                                "Maling desisyon ang ginawa nila at binayaran nila 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "No more taking orders from that fool.",
                            },
                            ["TL"] = {
                                "Wala nang susunod sa mga utos ng hangal na 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "The tyrant is dead. Now we decide our own fate.",
                            },
                            ["TL"] = {
                                "Patay na ang pinuno. Ngayon tayo na ang magpapasya sa sariling kapalaran.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I won't shed tears for them. Let's build something fair.",
                            },
                            ["TL"] = {
                                "Hindi ako iiyak para sa kanila. Magtayo tayo ng makatarungang samahan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Their leadership was leading us to the grave anyway.",
                            },
                            ["TL"] = {
                                "Dadalhin lang din naman tayo ng pamumuno nila sa libingan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "A slate wiped clean. We govern ourselves now.",
                            },
                            ["TL"] = {
                                "Burado na ang nakaraan. Pamahalaan natin ang sarili natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "They're gone. Good riddance to bad orders.",
                            },
                            ["TL"] = {
                                "Wala na sila. Mabuti at tapos na ang maling pamamalakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "We're free to choose our own path now.",
                            },
                            ["TL"] = {
                                "Malaya na tayong pumili ng sarili nating landas.",
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
