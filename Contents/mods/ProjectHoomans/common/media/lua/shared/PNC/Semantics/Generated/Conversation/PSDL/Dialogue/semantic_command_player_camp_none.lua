-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_player",
        ["id"] = "semantic.command.player.camp_none",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.player.camp_none",
            ["sourcePath"] = "psdl/dialogue/companion_commands_player.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_player_camp_none",
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
                ["responseTemplateID"] = "semantic.command.player.camp_none",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/player.json",
            },
            ["response"] = {
                ["act"] = "DIRECTIVE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "...",
                            },
                            ["TL"] = {
                                "...",
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
