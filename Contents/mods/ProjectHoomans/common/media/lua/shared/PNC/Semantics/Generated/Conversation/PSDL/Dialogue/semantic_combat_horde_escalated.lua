-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_combat",
        ["id"] = "semantic.combat.horde.escalated",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.horde.escalated",
            ["sourcePath"] = "psdl/dialogue/companion_commands_combat.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_horde_escalated",
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
                ["responseTemplateID"] = "semantic.combat.horde.escalated",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/combat_horde_reactions.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "More are piling in. This is getting bad.",
                            },
                            ["TL"] = {
                                "Dumarami sila. Lumalala ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "They keep coming! We're losing ground.",
                            },
                            ["TL"] = {
                                "Patuloy silang dumarami! Nawawalan tayo ng espasyo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "The herd just doubled. We need a plan.",
                            },
                            ["TL"] = {
                                "Doble na ang dami nila. Kailangan natin ng plano.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Too many to push through! Fall back a step.",
                            },
                            ["TL"] = {
                                "Masyadong marami para lusubin! Umatras nang kaunti.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "The swarm's thickening. Watch your flanks!",
                            },
                            ["TL"] = {
                                "Kumakapal ang kuyog. Bantayan ang gilid mo!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Every window is shaking. They're surrounding us.",
                            },
                            ["TL"] = {
                                "Nanginginig ang bawat bintana. Pinalilibutan nila tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "They're pouring through the gaps. Steady!",
                            },
                            ["TL"] = {
                                "Bumubuhos sila sa mga butas. Magpakatatag!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "This isn't thinning out, it's growing!",
                            },
                            ["TL"] = {
                                "Hindi sila kumokonti, lalo pang dumarami!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "More rottens behind the first wave!",
                            },
                            ["TL"] = {
                                "May mga bulok pa sa likod ng unang grupo!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "We're getting boxed in. Don't stop swinging.",
                            },
                            ["TL"] = {
                                "Naiipit na tayo. Huwag titigil sa paghataw.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_combat.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
