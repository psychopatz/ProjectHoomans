-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_replies",
        ["id"] = "semantic.combat.horde.ack.engage_hesitant",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.horde.ack.engage_hesitant",
            ["sourcePath"] = "psdl/dialogue/companion_commands_replies.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_horde_ack_engage_hesitant",
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
                ["responseTemplateID"] = "semantic.combat.horde.ack.engage_hesitant",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/replies.json",
            },
            ["response"] = {
                ["act"] = "ACK",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "If you say so... alright. I'm with you.",
                            },
                            ["TL"] = {
                                "Kung sinasabi mo... sige. Kasama mo ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "This is reckless, but I won't abandon you.",
                            },
                            ["TL"] = {
                                "Kapusukan ito, pero hindi kita iiwan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I have a bad feeling about this, but I'm in.",
                            },
                            ["TL"] = {
                                "Masama ang kutob ko rito, pero sasama ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Watch my back... here we go.",
                            },
                            ["TL"] = {
                                "Bantayan mo ang likod ko... heto na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I hope you know what you're doing. Moving in.",
                            },
                            ["TL"] = {
                                "Sana alam mo ang ginagawa mo. Susulong na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Not loving these odds, but I'll fight beside you.",
                            },
                            ["TL"] = {
                                "Di maganda ang tsansa, pero lalaban ako sa tabi mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Hesitant, but committed. Stay close.",
                            },
                            ["TL"] = {
                                "Nag-aalangan, pero sasabak. Dumikit ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Alright... just don't let them flank us.",
                            },
                            ["TL"] = {
                                "Sige... huwag mo lang silang hayaang pumaligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Stepping into the meat grinder. Let's make it out alive.",
                            },
                            ["TL"] = {
                                "Papasok sa gilingan ng karne. Tiyakin nating makalabas nang buhay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Okay... I trust your blade. Let's go.",
                            },
                            ["TL"] = {
                                "Sige... tiwala ako sa talim mo. Tara.",
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
