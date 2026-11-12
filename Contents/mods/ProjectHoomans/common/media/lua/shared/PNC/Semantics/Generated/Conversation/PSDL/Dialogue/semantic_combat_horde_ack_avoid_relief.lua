-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_replies",
        ["id"] = "semantic.combat.horde.ack.avoid_relief",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.horde.ack.avoid_relief",
            ["sourcePath"] = "psdl/dialogue/companion_commands_replies.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_horde_ack_avoid_relief",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.combat.horde.ack.avoid_relief",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/replies.json",
            },
            ["response"] = {
                ["act"] = "ACK",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Good. Let's go around.",
                            },
                            ["TL"] = {
                                "Mabuti. Umikot tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Thank goodness. That pack was massive.",
                            },
                            ["TL"] = {
                                "Salamat sa Diyos. Napakalaki ng kawang 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Glad you made that call. Slipping away.",
                            },
                            ["TL"] = {
                                "Mabuti at nagpasya ka ng ganoon. Tatakas na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Smart move. We live to fight another hour.",
                            },
                            ["TL"] = {
                                "Matalinong desisyon. Mabubuhay pa tayo sa susunod na oras.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Relieved to hear that. Detouring now.",
                            },
                            ["TL"] = {
                                "Gumaan ang loob ko nang marinig 'yan. Iikot na ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Good choice. Keep it quiet as we skirt past.",
                            },
                            ["TL"] = {
                                "Magandang pasya. Manahimik habang lumalampas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Much better than dying out here. Moving around.",
                            },
                            ["TL"] = {
                                "Mas maganda kaysa mamatay dito. Iikot na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Sigh of relief. Let's keep our heads down.",
                            },
                            ["TL"] = {
                                "Nakahinga nang maluwag. Yumuko tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Glad we're avoiding that bloodbath. Lead on.",
                            },
                            ["TL"] = {
                                "Mabuti at iniwasan natin ang katayang 'yon. Mauna ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Safe decision. Taking the alternate route.",
                            },
                            ["TL"] = {
                                "Ligtas na pasya. Dadaan sa ibang ruta.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_replies.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
