-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_kill_witness_shaken",
        ["id"] = "semantic.combat.reaction.kill_witness_shaken_01",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.reaction.kill_witness_shaken_01",
            ["sourcePath"] = "psdl/dialogue/combat_kill_witness_shaken.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_reaction_kill_witness_shaken_01",
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
                ["responseTemplateID"] = "semantic.combat.reaction.kill_witness_shaken_01",
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
                                "It's down... but there are more.",
                            },
                            ["TL"] = {
                                "Patay na... pero may iba pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "You got it... God, look around us.",
                            },
                            ["TL"] = {
                                "Nakuha mo... Diyos ko, tingnan mo ang paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Dead... but I hear more shuffling.",
                            },
                            ["TL"] = {
                                "Patay na... pero may naririnig pa akong kaluskos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "That one's down... don't let others flank.",
                            },
                            ["TL"] = {
                                "Bagsak na ang isang 'yon... huwag hayaang may pumaligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "It's over for that one... but we're not safe.",
                            },
                            ["TL"] = {
                                "Tapos na ang isa... pero hindi pa tayo ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "You killed it... please tell me that's the last one.",
                            },
                            ["TL"] = {
                                "Napatay mo... pakiusap sabihin mong huli na 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "One is down... but more could come.",
                            },
                            ["TL"] = {
                                "Isang bagsak... pero baka may dumating pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Good, it's dead... just watch the darkness.",
                            },
                            ["TL"] = {
                                "Mabuti at patay na... mag-ingat lang sa dilim.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Down... but my heart won't stop racing.",
                            },
                            ["TL"] = {
                                "Bagsak... pero ayaw humupa ng kaba ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "You stopped it... but we have to keep checking.",
                            },
                            ["TL"] = {
                                "Napigilan mo... pero kailangan nating patuloy na magmasid.",
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
