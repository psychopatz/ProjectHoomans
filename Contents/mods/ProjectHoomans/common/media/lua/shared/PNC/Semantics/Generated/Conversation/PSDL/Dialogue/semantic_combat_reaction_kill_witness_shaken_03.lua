-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_kill_witness_shaken",
        ["id"] = "semantic.combat.reaction.kill_witness_shaken_03",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.reaction.kill_witness_shaken_03",
            ["sourcePath"] = "psdl/dialogue/combat_kill_witness_shaken.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_reaction_kill_witness_shaken_03",
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
                ["category"] = "projecthoomans:combat_kill",
                ["contentOwner"] = "projecthoomans.dialogue_content.events",
                ["responseTemplateID"] = "semantic.combat.reaction.kill_witness_shaken_03",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/combat_kill/witness/shaken.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Okay. One less. I still don't like this.",
                            },
                            ["TL"] = {
                                "Sige. Isa na lang ang nabawas. Ayoko pa rin nito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "One down... this whole place creeps me out.",
                            },
                            ["TL"] = {
                                "Isang bagsak... kinikilabutan ako sa buong lugar na 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "It's dead. I hate being surrounded like this.",
                            },
                            ["TL"] = {
                                "Patay na. Ayaw na ayaw kong napapalibutan tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "One less threat... my knees are shaking.",
                            },
                            ["TL"] = {
                                "Bawas ang isang banta... nanginginig ang mga tuhod ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Good, it stopped moving... I'm terrified.",
                            },
                            ["TL"] = {
                                "Mabuti at tumigil na sa paggalaw... natatakot ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Down. I just want this nightmare to end.",
                            },
                            ["TL"] = {
                                "Bagsak. Gusto ko nang matapos ang bangungot na 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "One less rotten thing... still scares me to death.",
                            },
                            ["TL"] = {
                                "Bawas ang isang bulok... takot na takot pa rin ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "It's gone. I really, really don't like this.",
                            },
                            ["TL"] = {
                                "Wala na. Ayoko talaga, ayoko sa ganito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Dead. Can we leave as soon as it's quiet?",
                            },
                            ["TL"] = {
                                "Patay na. Pwede ba tayong umalis kapag tumahimik na?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "You killed it... but my hands are ice cold.",
                            },
                            ["TL"] = {
                                "Napatay mo... pero parang yelo ang lamig ng mga kamay ko.",
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
        ["sourceShard"] = "psdl/dialogue/combat_kill_witness_shaken.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
