-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "event_reactions_leader_loss",
        ["id"] = "semantic.leader_loss.close",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.leader_loss.close",
            ["sourcePath"] = "psdl/dialogue/event_reactions_leader_loss.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_leader_loss_close",
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
                ["responseTemplateID"] = "semantic.leader_loss.close",
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
                                "We lost someone close to us. We need to stay together.",
                            },
                            ["TL"] = {
                                "Nawalan tayo ng taong malapit sa atin. Kailangan nating magsama-sama.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I can't believe they're gone... we have to hold each other up.",
                            },
                            ["TL"] = {
                                "Hindi ako makapaniwalang wala na sila... kailangan nating magtulungan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "They were family to us. Don't let our grief break us apart.",
                            },
                            ["TL"] = {
                                "Pamilya na ang turing natin sa kanila. Huwag nating hayaang wasakin tayo ng lungkot.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "It hurts so much, but we have to keep going for them.",
                            },
                            ["TL"] = {
                                "Masakit sobra, pero kailangan nating magpatuloy para sa kanila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "They protected us. Now we protect each other.",
                            },
                            ["TL"] = {
                                "Pinrotektahan nila tayo. Ngayon tayo naman ang magpoprotekta sa isa't isa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Losing them leaves a hole in my heart. Stay close, everyone.",
                            },
                            ["TL"] = {
                                "Naiwang sugatan ang puso ko sa pagkawala nila. Magdikit-dikit tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "We honor their memory by surviving. Stick together.",
                            },
                            ["TL"] = {
                                "Igalang natin ang alaala nila sa pamamagitan ng pamumuhay. Magsama tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I will miss them terribly. We can't scatter now.",
                            },
                            ["TL"] = {
                                "Mamimiss ko sila nang husto. Hindi tayo dapat maghiwa-hiwalay ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "They gave everything for this group. We stay united.",
                            },
                            ["TL"] = {
                                "Ibinigay nila ang lahat para sa grupong 'to. Manatili tayong nagkakaisa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Rest in peace. We'll hold the line for you.",
                            },
                            ["TL"] = {
                                "Mamahinga ka na. Hahawakan namin ang linya para sa'yo.",
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
