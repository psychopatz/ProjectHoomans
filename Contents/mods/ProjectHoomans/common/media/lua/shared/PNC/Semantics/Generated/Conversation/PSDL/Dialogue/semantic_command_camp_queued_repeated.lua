-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.camp.queued.repeated",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.camp.queued.repeated",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_camp_queued_repeated",
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
                ["responseTemplateID"] = "semantic.command.camp.queued.repeated",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/camp.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm still setting up camp there.",
                            },
                            ["TL"] = {
                                "Nagtatayo pa rin ako ng kampo roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Already working on the camp. Give me a minute.",
                            },
                            ["TL"] = {
                                "Ginagawa ko na ang kampo. Bigyan mo ako ng sandali.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Still on it. Setting up takes a little time.",
                            },
                            ["TL"] = {
                                "Inaasikaso pa rin. May katagalan ang pagtatayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'm already pitching the camp there.",
                            },
                            ["TL"] = {
                                "Naglalatag na ako ng kampo roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Working as fast as I can on that camp.",
                            },
                            ["TL"] = {
                                "Ginagawa ko nang mabilis ang kampong 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Yeah, I heard you the first time. Still making camp.",
                            },
                            ["TL"] = {
                                "Oo, narinig ko sa una pa lang. Ginagawa pa rin ang kampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'm already in the middle of setting up.",
                            },
                            ["TL"] = {
                                "Kasalukuyan na akong nagtatayo roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Camp setup is already in progress.",
                            },
                            ["TL"] = {
                                "Kasalukuyan nang isinasagawa ang pagkakampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Still securing the campsite. Hold tight.",
                            },
                            ["TL"] = {
                                "Sinisigurado pa rin ang kampo. Maghintay lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Almost done with the camp. Don't rush me.",
                            },
                            ["TL"] = {
                                "Halos tapos na sa kampo. Huwag mo akong madaliin.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
