-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_player",
        ["id"] = "semantic.command.player.attack_ranged",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.player.attack_ranged",
            ["sourcePath"] = "psdl/dialogue/companion_commands_player.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_player_attack_ranged",
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
                ["responseTemplateID"] = "semantic.command.player.attack_ranged",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/player.json",
            },
            ["response"] = {
                ["act"] = "DIRECTIVE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, keep your distance.",
                            },
                            ["TL"] = {
                                "{addressee.name}, panatilihin ang distansya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Give us ranged cover, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Takpan kami mula sa malayo, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, engage from a safe distance.",
                            },
                            ["TL"] = {
                                "{addressee.name}, lumaban mula sa ligtas na layo.",
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
