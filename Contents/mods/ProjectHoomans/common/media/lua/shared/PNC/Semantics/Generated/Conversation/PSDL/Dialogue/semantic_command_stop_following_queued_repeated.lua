-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.stop_following.queued.repeated",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.stop_following.queued.repeated",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[31]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_stop_following_queued_repeated",
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
                ["responseTemplateID"] = "semantic.command.stop_following.queued.repeated",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/stop_following.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I've already stopped following.",
                            },
                            ["TL"] = {
                                "Tumigil na ako sa pagsunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I'm already standing still. Not following you.",
                            },
                            ["TL"] = {
                                "Nakatayo na nga ako. Di na kita sinusundan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Already halted. Look, I'm not moving.",
                            },
                            ["TL"] = {
                                "Huminto na. Tingnan mo, di ako gumagalaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I stopped following after the first command.",
                            },
                            ["TL"] = {
                                "Huminto na ako sa pagsunod pagkatapos ng unang utos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Still not following you. I'm right here.",
                            },
                            ["TL"] = {
                                "Di pa rin kita sinusundan. Narito lang ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Already stopped. Go ahead without me.",
                            },
                            ["TL"] = {
                                "Huminto na. Sige na, mauna ka nang wala ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not following anymore, I promise.",
                            },
                            ["TL"] = {
                                "Di na kita sinusundan, pangako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Already stationary. No need to tell me again.",
                            },
                            ["TL"] = {
                                "Nakatigil na ako. Di na kailangang sabihin ulit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I've been stopped for a while now.",
                            },
                            ["TL"] = {
                                "Kanina pa ako huminto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Still halted. Move along freely.",
                            },
                            ["TL"] = {
                                "Nakatigil pa rin. Lumakad ka na nang malaya.",
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
