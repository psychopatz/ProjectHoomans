-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "event_reactions_corpse",
        ["id"] = "semantic.corpse.reaction.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.corpse.reaction.default",
            ["sourcePath"] = "psdl/dialogue/event_reactions_corpse.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_corpse_reaction_default",
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
                ["responseTemplateID"] = "semantic.corpse.reaction.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/reactions/corpse.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Someone died here. We should remember that.",
                            },
                            ["TL"] = {
                                "May namatay dito. Dapat nating alalahanin 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Poor bastard. Didn't make it.",
                            },
                            ["TL"] = {
                                "Kawawa naman. Hindi nakaligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Another body in the dirt. World's unforgiving.",
                            },
                            ["TL"] = {
                                "Isa na namang bangkay sa lupa. Malupit ang mundo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "They fought hard, by the looks of it.",
                            },
                            ["TL"] = {
                                "Lumaban nang husto, base sa hitsura.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Someone lost a life here. Tread with respect.",
                            },
                            ["TL"] = {
                                "May nawalan ng buhay rito. Maglakad nang may galang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Looks like they got trapped. Rest easy.",
                            },
                            ["TL"] = {
                                "Mukhang naipit sila rito. Mamahinga ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Could've been any of us. Keep walking.",
                            },
                            ["TL"] = {
                                "Kahit sino sa atin pwedeng maging ganyan. Lakad na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Another survivor cut down too early.",
                            },
                            ["TL"] = {
                                "Isa na namang survivor ang pumanaw nang maaga.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Body's cold. Let's make sure we don't end up like this.",
                            },
                            ["TL"] = {
                                "Malamig na ang bangkay. Siguruhin nating hindi tayo matutulad dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Rest in peace, stranger. Let's keep moving.",
                            },
                            ["TL"] = {
                                "Sumalangit nawa ang kaluluwa mo. Magpatuloy tayo.",
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
        ["sourceShard"] = "psdl/dialogue/event_reactions_corpse.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
