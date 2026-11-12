-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_player",
        ["id"] = "semantic.command.player.camp",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.player.camp",
            ["sourcePath"] = "psdl/dialogue/companion_commands_player.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_player_camp",
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
                ["responseTemplateID"] = "semantic.command.player.camp",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/player.json",
            },
            ["response"] = {
                ["act"] = "DIRECTIVE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Make camp here, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Magkampo tayo rito, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Settle in here, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Manatili tayo rito, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "We'll camp here for now, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Magkakampo muna tayo rito, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "We could make camp here, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Maaari tayong magkampo rito, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Let's make this our camp, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Gawin nating kampo ito, {addressee.name}.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_player.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
