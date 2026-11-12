-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "event_reactions_leader_loss",
        ["id"] = "semantic.leader_loss.colonist",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.leader_loss.colonist",
            ["sourcePath"] = "psdl/dialogue/event_reactions_leader_loss.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_leader_loss_colonist",
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
                ["responseTemplateID"] = "semantic.leader_loss.colonist",
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
                                "Our leader is gone. We keep the group together.",
                            },
                            ["TL"] = {
                                "Wala na ang pinuno natin. Panatilihin nating buo ang grupo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "The leader fell, but the colony endures.",
                            },
                            ["TL"] = {
                                "Bumagsak ang pinuno, pero mananatili ang kolonya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "We must maintain order. The group cannot collapse.",
                            },
                            ["TL"] = {
                                "Kailangan nating panatilihin ang kaayusan. Hindi dapat bumagsak ang grupo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Our founder is dead, but our camp will survive.",
                            },
                            ["TL"] = {
                                "Patay na ang nagtatag sa atin, pero mabubuhay ang kampo natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Stay organized. We carry on their work.",
                            },
                            ["TL"] = {
                                "Manatiling organisado. Ipagpatuloy natin ang nasimulan nila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "A terrible loss, but our community must stand firm.",
                            },
                            ["TL"] = {
                                "Matinding kawalan, pero kailangang tumindig ang komunidad natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Don't panic. We keep rations and duties moving.",
                            },
                            ["TL"] = {
                                "Huwag mag-panic. Tuloy ang rasyon at mga tungkulin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "The colony needs everyone focused right now.",
                            },
                            ["TL"] = {
                                "Kailangan ng kolonya ang pokus ng lahat ngayon din.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "We built this together. We keep it standing together.",
                            },
                            ["TL"] = {
                                "Sabay natin 'tong binuo. Sabay natin 'tong pananatilihing nakatayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Leadership may change, but the settlement survives.",
                            },
                            ["TL"] = {
                                "Maaaring magbago ang pamumuno, pero mabubuhay ang paninirahan.",
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
