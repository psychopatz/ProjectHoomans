-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_player",
        ["id"] = "semantic.command.player.attack_auto",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.command.player.attack_auto",
            ["sourcePath"] = "psdl/dialogue/companion_commands_player.json#records[0]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
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
                ["responseTemplateID"] = "semantic.command.player.attack_auto",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/player.json",
            },
            ["response"] = {
                ["act"] = "DIRECTIVE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, use your best judgment.",
                            },
                            ["TL"] = {
                                "{addressee.name}, gamitin ang iyong pasya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, handle threats as you see fit.",
                            },
                            ["TL"] = {
                                "{addressee.name}, harapin ang banta ayon sa iyong pasya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Watch our backs, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Bantayan mo kami, {addressee.name}.",
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
    {
        ["domain"] = "companion_commands_player",
        ["id"] = "semantic.command.player.attack_melee",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.command.player.attack_melee",
            ["sourcePath"] = "psdl/dialogue/companion_commands_player.json#records[1]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
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
    {
        ["domain"] = "companion_commands_player",
        ["id"] = "semantic.command.player.attack_none",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.command.player.attack_none",
            ["sourcePath"] = "psdl/dialogue/companion_commands_player.json#records[2]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
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
                ["responseTemplateID"] = "semantic.command.player.attack_none",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/player.json",
            },
            ["response"] = {
                ["act"] = "DIRECTIVE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, stay out of the fight.",
                            },
                            ["TL"] = {
                                "{addressee.name}, huwag sumali sa laban.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Avoid trouble, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Iwasan ang gulo, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, don't engage unless I change the order.",
                            },
                            ["TL"] = {
                                "{addressee.name}, huwag lumaban hangga't hindi ko binabago ang utos.",
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
    {
        ["domain"] = "companion_commands_player",
        ["id"] = "semantic.command.player.attack_ranged",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.command.player.attack_ranged",
            ["sourcePath"] = "psdl/dialogue/companion_commands_player.json#records[3]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
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
    {
        ["domain"] = "companion_commands_player",
        ["id"] = "semantic.command.player.camp",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.command.player.camp",
            ["sourcePath"] = "psdl/dialogue/companion_commands_player.json#records[4]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
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
    {
        ["domain"] = "companion_commands_player",
        ["id"] = "semantic.command.player.camp_none",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.command.player.camp_none",
            ["sourcePath"] = "psdl/dialogue/companion_commands_player.json#records[5]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
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
    {
        ["domain"] = "companion_commands_player",
        ["id"] = "semantic.command.player.camp_rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.command.player.camp_rejected",
            ["sourcePath"] = "psdl/dialogue/companion_commands_player.json#records[6]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
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
                ["responseTemplateID"] = "semantic.command.player.camp_rejected",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/player.json",
            },
            ["response"] = {
                ["act"] = "DIRECTIVE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't find a safe room or campfire nearby.",
                            },
                            ["TL"] = {
                                "Wala akong makitang ligtas na silid o apoy dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "We need a nearby room or campfire before we make camp.",
                            },
                            ["TL"] = {
                                "Kailangan natin ng malapit na silid o apoy bago magkampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "No usable camp site is visible from here.",
                            },
                            ["TL"] = {
                                "Walang angkop na lugar ng kampo rito.",
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
    {
        ["domain"] = "companion_commands_player",
        ["id"] = "semantic.command.player.follow",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.command.player.follow",
            ["sourcePath"] = "psdl/dialogue/companion_commands_player.json#records[7]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
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
                ["responseTemplateID"] = "semantic.command.player.follow",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/player.json",
            },
            ["response"] = {
                ["act"] = "DIRECTIVE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, on me.",
                            },
                            ["TL"] = {
                                "{addressee.name}, sumunod kayo sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Stay close, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Manatili kayong malapit, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, let's move.",
                            },
                            ["TL"] = {
                                "{addressee.name}, umalis na tayo.",
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
    {
        ["domain"] = "companion_commands_player",
        ["id"] = "semantic.command.player.generic",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.command.player.generic",
            ["sourcePath"] = "psdl/dialogue/companion_commands_player.json#records[8]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
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
                ["responseTemplateID"] = "semantic.command.player.generic",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/player.json",
            },
            ["response"] = {
                ["act"] = "DIRECTIVE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Understood, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko, {addressee.name}.",
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
    {
        ["domain"] = "companion_commands_player",
        ["id"] = "semantic.command.player.return_home",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.command.player.return_home",
            ["sourcePath"] = "psdl/dialogue/companion_commands_player.json#records[9]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
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
                ["responseTemplateID"] = "semantic.command.player.return_home",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/player.json",
            },
            ["response"] = {
                ["act"] = "DIRECTIVE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, head home.",
                            },
                            ["TL"] = {
                                "{addressee.name}, umuwi na kayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Return to the base, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Bumalik sa base, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, get back home safely.",
                            },
                            ["TL"] = {
                                "{addressee.name}, ligtas na umuwi.",
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
    {
        ["domain"] = "companion_commands_player",
        ["id"] = "semantic.command.player.stay",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.command.player.stay",
            ["sourcePath"] = "psdl/dialogue/companion_commands_player.json#records[10]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
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
                ["responseTemplateID"] = "semantic.command.player.stay",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/player.json",
            },
            ["response"] = {
                ["act"] = "DIRECTIVE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, wait here.",
                            },
                            ["TL"] = {
                                "{addressee.name}, maghintay kayo rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Hold this position, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Panatilihin ang posisyon, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, stay put for now.",
                            },
                            ["TL"] = {
                                "{addressee.name}, manatili muna rito.",
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
