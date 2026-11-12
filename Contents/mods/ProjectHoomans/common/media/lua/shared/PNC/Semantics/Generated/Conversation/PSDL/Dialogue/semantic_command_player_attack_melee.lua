-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_player",
        ["id"] = "semantic.command.player.attack_melee",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.player.attack_melee",
            ["sourcePath"] = "psdl/dialogue/companion_commands_player.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_player_attack_melee",
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
                ["responseTemplateID"] = "semantic.command.player.attack_melee",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/player.json",
            },
            ["response"] = {
                ["act"] = "DIRECTIVE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, keep it close.",
                            },
                            ["TL"] = {
                                "{addressee.name}, lumaban nang malapitan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Take the front line, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Ikaw sa unahan, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, save your ammunition.",
                            },
                            ["TL"] = {
                                "{addressee.name}, itabi ang bala.",
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
