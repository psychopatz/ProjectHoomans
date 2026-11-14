-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_player",
        ["exchangeFamily"] = {
            ["familyID"] = "command.player.attack_auto",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "{addressee.name}, use your best judgment.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.player.attack_auto.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "{addressee.name}, use your best judgment.",
                                        "{addressee.name}, handle threats as you see fit.",
                                        "Watch our backs, {addressee.name}.",
                                    },
                                    ["TL"] = {
                                        "{addressee.name}, gamitin ang iyong pasya.",
                                        "{addressee.name}, harapin ang banta ayon sa iyong pasya.",
                                        "Bantayan mo kami, {addressee.name}.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.player",
            ["textRoles"] = {
                {
                    ["fallback"] = "{addressee.name}, use your best judgment.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.player.attack_auto.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "{addressee.name}, use your best judgment.",
                            "{addressee.name}, handle threats as you see fit.",
                            "Watch our backs, {addressee.name}.",
                        },
                        ["TL"] = {
                            "{addressee.name}, gamitin ang iyong pasya.",
                            "{addressee.name}, harapin ang banta ayon sa iyong pasya.",
                            "Bantayan mo kami, {addressee.name}.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.player.attack_auto",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "attack_auto",
            ["sourceId"] = "command.player.attack_auto",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_player/command_player_attack_auto.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
        ["namespace"] = "command.player",
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
                ["responseAct"] = "DIRECTIVE",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "{addressee.name}, use your best judgment.",
                                        "{addressee.name}, handle threats as you see fit.",
                                        "Watch our backs, {addressee.name}.",
                                    },
                                    ["TL"] = {
                                        "{addressee.name}, gamitin ang iyong pasya.",
                                        "{addressee.name}, harapin ang banta ayon sa iyong pasya.",
                                        "Bantayan mo kami, {addressee.name}.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "DIRECTIVE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.player.attack_auto",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "{addressee.name}, use your best judgment.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.command.player.attack_auto.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_player/command_player_attack_auto.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "{addressee.name}, use your best judgment.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.player.attack_auto.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "{addressee.name}, use your best judgment.",
                        "{addressee.name}, handle threats as you see fit.",
                        "Watch our backs, {addressee.name}.",
                    },
                    ["TL"] = {
                        "{addressee.name}, gamitin ang iyong pasya.",
                        "{addressee.name}, harapin ang banta ayon sa iyong pasya.",
                        "Bantayan mo kami, {addressee.name}.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_player",
        ["exchangeFamily"] = {
            ["familyID"] = "command.player.attack_melee",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "{addressee.name}, keep it close.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.player.attack_melee.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "{addressee.name}, keep it close.",
                                        "Take the front line, {addressee.name}.",
                                        "{addressee.name}, save your ammunition.",
                                    },
                                    ["TL"] = {
                                        "{addressee.name}, lumaban nang malapitan.",
                                        "Ikaw sa unahan, {addressee.name}.",
                                        "{addressee.name}, itabi ang bala.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.player",
            ["textRoles"] = {
                {
                    ["fallback"] = "{addressee.name}, keep it close.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.player.attack_melee.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "{addressee.name}, keep it close.",
                            "Take the front line, {addressee.name}.",
                            "{addressee.name}, save your ammunition.",
                        },
                        ["TL"] = {
                            "{addressee.name}, lumaban nang malapitan.",
                            "Ikaw sa unahan, {addressee.name}.",
                            "{addressee.name}, itabi ang bala.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.player.attack_melee",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "attack_melee",
            ["sourceId"] = "command.player.attack_melee",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_player/command_player_attack_melee.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
        ["namespace"] = "command.player",
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
                ["responseAct"] = "DIRECTIVE",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "{addressee.name}, keep it close.",
                                        "Take the front line, {addressee.name}.",
                                        "{addressee.name}, save your ammunition.",
                                    },
                                    ["TL"] = {
                                        "{addressee.name}, lumaban nang malapitan.",
                                        "Ikaw sa unahan, {addressee.name}.",
                                        "{addressee.name}, itabi ang bala.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "DIRECTIVE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.player.attack_melee",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "{addressee.name}, keep it close.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.command.player.attack_melee.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_player/command_player_attack_melee.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "{addressee.name}, keep it close.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.player.attack_melee.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "{addressee.name}, keep it close.",
                        "Take the front line, {addressee.name}.",
                        "{addressee.name}, save your ammunition.",
                    },
                    ["TL"] = {
                        "{addressee.name}, lumaban nang malapitan.",
                        "Ikaw sa unahan, {addressee.name}.",
                        "{addressee.name}, itabi ang bala.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_player",
        ["exchangeFamily"] = {
            ["familyID"] = "command.player.attack_none",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "{addressee.name}, stay out of the fight.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.player.attack_none.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "{addressee.name}, stay out of the fight.",
                                        "Avoid trouble, {addressee.name}.",
                                        "{addressee.name}, don't engage unless I change the order.",
                                    },
                                    ["TL"] = {
                                        "{addressee.name}, huwag sumali sa laban.",
                                        "Iwasan ang gulo, {addressee.name}.",
                                        "{addressee.name}, huwag lumaban hangga't hindi ko binabago ang utos.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.player",
            ["textRoles"] = {
                {
                    ["fallback"] = "{addressee.name}, stay out of the fight.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.player.attack_none.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "{addressee.name}, stay out of the fight.",
                            "Avoid trouble, {addressee.name}.",
                            "{addressee.name}, don't engage unless I change the order.",
                        },
                        ["TL"] = {
                            "{addressee.name}, huwag sumali sa laban.",
                            "Iwasan ang gulo, {addressee.name}.",
                            "{addressee.name}, huwag lumaban hangga't hindi ko binabago ang utos.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.player.attack_none",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "attack_none",
            ["sourceId"] = "command.player.attack_none",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_player/command_player_attack_none.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
        ["namespace"] = "command.player",
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
                ["responseAct"] = "DIRECTIVE",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "{addressee.name}, stay out of the fight.",
                                        "Avoid trouble, {addressee.name}.",
                                        "{addressee.name}, don't engage unless I change the order.",
                                    },
                                    ["TL"] = {
                                        "{addressee.name}, huwag sumali sa laban.",
                                        "Iwasan ang gulo, {addressee.name}.",
                                        "{addressee.name}, huwag lumaban hangga't hindi ko binabago ang utos.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "DIRECTIVE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.player.attack_none",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "{addressee.name}, stay out of the fight.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.command.player.attack_none.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_player/command_player_attack_none.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "{addressee.name}, stay out of the fight.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.player.attack_none.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "{addressee.name}, stay out of the fight.",
                        "Avoid trouble, {addressee.name}.",
                        "{addressee.name}, don't engage unless I change the order.",
                    },
                    ["TL"] = {
                        "{addressee.name}, huwag sumali sa laban.",
                        "Iwasan ang gulo, {addressee.name}.",
                        "{addressee.name}, huwag lumaban hangga't hindi ko binabago ang utos.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_player",
        ["exchangeFamily"] = {
            ["familyID"] = "command.player.attack_ranged",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "{addressee.name}, keep your distance.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.player.attack_ranged.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "{addressee.name}, keep your distance.",
                                        "Give us ranged cover, {addressee.name}.",
                                        "{addressee.name}, engage from a safe distance.",
                                    },
                                    ["TL"] = {
                                        "{addressee.name}, panatilihin ang distansya.",
                                        "Takpan kami mula sa malayo, {addressee.name}.",
                                        "{addressee.name}, lumaban mula sa ligtas na layo.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.player",
            ["textRoles"] = {
                {
                    ["fallback"] = "{addressee.name}, keep your distance.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.player.attack_ranged.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "{addressee.name}, keep your distance.",
                            "Give us ranged cover, {addressee.name}.",
                            "{addressee.name}, engage from a safe distance.",
                        },
                        ["TL"] = {
                            "{addressee.name}, panatilihin ang distansya.",
                            "Takpan kami mula sa malayo, {addressee.name}.",
                            "{addressee.name}, lumaban mula sa ligtas na layo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.player.attack_ranged",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "attack_ranged",
            ["sourceId"] = "command.player.attack_ranged",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_player/command_player_attack_ranged.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
        ["namespace"] = "command.player",
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
                ["responseAct"] = "DIRECTIVE",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "{addressee.name}, keep your distance.",
                                        "Give us ranged cover, {addressee.name}.",
                                        "{addressee.name}, engage from a safe distance.",
                                    },
                                    ["TL"] = {
                                        "{addressee.name}, panatilihin ang distansya.",
                                        "Takpan kami mula sa malayo, {addressee.name}.",
                                        "{addressee.name}, lumaban mula sa ligtas na layo.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "DIRECTIVE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.player.attack_ranged",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "{addressee.name}, keep your distance.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.command.player.attack_ranged.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_player/command_player_attack_ranged.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "{addressee.name}, keep your distance.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.player.attack_ranged.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "{addressee.name}, keep your distance.",
                        "Give us ranged cover, {addressee.name}.",
                        "{addressee.name}, engage from a safe distance.",
                    },
                    ["TL"] = {
                        "{addressee.name}, panatilihin ang distansya.",
                        "Takpan kami mula sa malayo, {addressee.name}.",
                        "{addressee.name}, lumaban mula sa ligtas na layo.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_player",
        ["exchangeFamily"] = {
            ["familyID"] = "command.player.camp",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "Make camp here, {addressee.name}.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.player.camp.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Make camp here, {addressee.name}.",
                                        "Settle in here, {addressee.name}.",
                                        "We'll camp here for now, {addressee.name}.",
                                        "We could make camp here, {addressee.name}.",
                                        "Let's make this our camp, {addressee.name}.",
                                    },
                                    ["TL"] = {
                                        "Magkampo tayo rito, {addressee.name}.",
                                        "Manatili tayo rito, {addressee.name}.",
                                        "Magkakampo muna tayo rito, {addressee.name}.",
                                        "Maaari tayong magkampo rito, {addressee.name}.",
                                        "Gawin nating kampo ito, {addressee.name}.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.player",
            ["textRoles"] = {
                {
                    ["fallback"] = "Make camp here, {addressee.name}.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.player.camp.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Make camp here, {addressee.name}.",
                            "Settle in here, {addressee.name}.",
                            "We'll camp here for now, {addressee.name}.",
                            "We could make camp here, {addressee.name}.",
                            "Let's make this our camp, {addressee.name}.",
                        },
                        ["TL"] = {
                            "Magkampo tayo rito, {addressee.name}.",
                            "Manatili tayo rito, {addressee.name}.",
                            "Magkakampo muna tayo rito, {addressee.name}.",
                            "Maaari tayong magkampo rito, {addressee.name}.",
                            "Gawin nating kampo ito, {addressee.name}.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.player.camp",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "camp",
            ["sourceId"] = "command.player.camp",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_player/command_player_camp.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
        ["namespace"] = "command.player",
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
                ["responseAct"] = "DIRECTIVE",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Make camp here, {addressee.name}.",
                                        "Settle in here, {addressee.name}.",
                                        "We'll camp here for now, {addressee.name}.",
                                        "We could make camp here, {addressee.name}.",
                                        "Let's make this our camp, {addressee.name}.",
                                    },
                                    ["TL"] = {
                                        "Magkampo tayo rito, {addressee.name}.",
                                        "Manatili tayo rito, {addressee.name}.",
                                        "Magkakampo muna tayo rito, {addressee.name}.",
                                        "Maaari tayong magkampo rito, {addressee.name}.",
                                        "Gawin nating kampo ito, {addressee.name}.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "DIRECTIVE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.player.camp",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Make camp here, {addressee.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.command.player.camp.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_player/command_player_camp.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Make camp here, {addressee.name}.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.player.camp.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Make camp here, {addressee.name}.",
                        "Settle in here, {addressee.name}.",
                        "We'll camp here for now, {addressee.name}.",
                        "We could make camp here, {addressee.name}.",
                        "Let's make this our camp, {addressee.name}.",
                    },
                    ["TL"] = {
                        "Magkampo tayo rito, {addressee.name}.",
                        "Manatili tayo rito, {addressee.name}.",
                        "Magkakampo muna tayo rito, {addressee.name}.",
                        "Maaari tayong magkampo rito, {addressee.name}.",
                        "Gawin nating kampo ito, {addressee.name}.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_player",
        ["exchangeFamily"] = {
            ["familyID"] = "command.player.camp_none",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "...",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.player.camp_none.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
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
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.player",
            ["textRoles"] = {
                {
                    ["fallback"] = "...",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.player.camp_none.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "...",
                        },
                        ["TL"] = {
                            "...",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.player.camp_none",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "camp_none",
            ["sourceId"] = "command.player.camp_none",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_player/command_player_camp_none.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
        ["namespace"] = "command.player",
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
                ["responseAct"] = "DIRECTIVE",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
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
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "DIRECTIVE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.player.camp_none",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "...",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.command.player.camp_none.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_player/command_player_camp_none.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "...",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.player.camp_none.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "...",
                    },
                    ["TL"] = {
                        "...",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_player",
        ["exchangeFamily"] = {
            ["familyID"] = "command.player.camp_rejected",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "I can't find a safe room or campfire nearby.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.player.camp_rejected.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I can't find a safe room or campfire nearby.",
                                        "We need a nearby room or campfire before we make camp.",
                                        "No usable camp site is visible from here.",
                                    },
                                    ["TL"] = {
                                        "Wala akong makitang ligtas na silid o apoy dito.",
                                        "Kailangan natin ng malapit na silid o apoy bago magkampo.",
                                        "Walang angkop na lugar ng kampo rito.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.player",
            ["textRoles"] = {
                {
                    ["fallback"] = "I can't find a safe room or campfire nearby.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.player.camp_rejected.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I can't find a safe room or campfire nearby.",
                            "We need a nearby room or campfire before we make camp.",
                            "No usable camp site is visible from here.",
                        },
                        ["TL"] = {
                            "Wala akong makitang ligtas na silid o apoy dito.",
                            "Kailangan natin ng malapit na silid o apoy bago magkampo.",
                            "Walang angkop na lugar ng kampo rito.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.player.camp_rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "camp_rejected",
            ["sourceId"] = "command.player.camp_rejected",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_player/command_player_camp_rejected.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
        ["namespace"] = "command.player",
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
                ["responseAct"] = "DIRECTIVE",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "I can't find a safe room or campfire nearby.",
                                        "We need a nearby room or campfire before we make camp.",
                                        "No usable camp site is visible from here.",
                                    },
                                    ["TL"] = {
                                        "Wala akong makitang ligtas na silid o apoy dito.",
                                        "Kailangan natin ng malapit na silid o apoy bago magkampo.",
                                        "Walang angkop na lugar ng kampo rito.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "DIRECTIVE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.player.camp_rejected",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I can't find a safe room or campfire nearby.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.command.player.camp_rejected.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_player/command_player_camp_rejected.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I can't find a safe room or campfire nearby.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.player.camp_rejected.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I can't find a safe room or campfire nearby.",
                        "We need a nearby room or campfire before we make camp.",
                        "No usable camp site is visible from here.",
                    },
                    ["TL"] = {
                        "Wala akong makitang ligtas na silid o apoy dito.",
                        "Kailangan natin ng malapit na silid o apoy bago magkampo.",
                        "Walang angkop na lugar ng kampo rito.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_player",
        ["exchangeFamily"] = {
            ["familyID"] = "command.player.follow",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "{addressee.name}, on me.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.player.follow.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "{addressee.name}, on me.",
                                        "Stay close, {addressee.name}.",
                                        "{addressee.name}, let's move.",
                                    },
                                    ["TL"] = {
                                        "{addressee.name}, sumunod kayo sa akin.",
                                        "Manatili kayong malapit, {addressee.name}.",
                                        "{addressee.name}, umalis na tayo.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.player",
            ["textRoles"] = {
                {
                    ["fallback"] = "{addressee.name}, on me.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.player.follow.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "{addressee.name}, on me.",
                            "Stay close, {addressee.name}.",
                            "{addressee.name}, let's move.",
                        },
                        ["TL"] = {
                            "{addressee.name}, sumunod kayo sa akin.",
                            "Manatili kayong malapit, {addressee.name}.",
                            "{addressee.name}, umalis na tayo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.player.follow",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "follow",
            ["sourceId"] = "command.player.follow",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_player/command_player_follow.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
        ["namespace"] = "command.player",
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
                ["responseAct"] = "DIRECTIVE",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "{addressee.name}, on me.",
                                        "Stay close, {addressee.name}.",
                                        "{addressee.name}, let's move.",
                                    },
                                    ["TL"] = {
                                        "{addressee.name}, sumunod kayo sa akin.",
                                        "Manatili kayong malapit, {addressee.name}.",
                                        "{addressee.name}, umalis na tayo.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "DIRECTIVE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.player.follow",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "{addressee.name}, on me.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.command.player.follow.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_player/command_player_follow.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "{addressee.name}, on me.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.player.follow.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "{addressee.name}, on me.",
                        "Stay close, {addressee.name}.",
                        "{addressee.name}, let's move.",
                    },
                    ["TL"] = {
                        "{addressee.name}, sumunod kayo sa akin.",
                        "Manatili kayong malapit, {addressee.name}.",
                        "{addressee.name}, umalis na tayo.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_player",
        ["exchangeFamily"] = {
            ["familyID"] = "command.player.generic",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "Understood, {addressee.name}.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.player.generic.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
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
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.player",
            ["textRoles"] = {
                {
                    ["fallback"] = "Understood, {addressee.name}.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.player.generic.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Understood, {addressee.name}.",
                        },
                        ["TL"] = {
                            "Naiintindihan ko, {addressee.name}.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.player.generic",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "generic",
            ["sourceId"] = "command.player.generic",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_player/command_player_generic.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
        ["namespace"] = "command.player",
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
                ["responseAct"] = "DIRECTIVE",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
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
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "DIRECTIVE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.player.generic",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Understood, {addressee.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.command.player.generic.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_player/command_player_generic.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Understood, {addressee.name}.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.player.generic.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Understood, {addressee.name}.",
                    },
                    ["TL"] = {
                        "Naiintindihan ko, {addressee.name}.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_player",
        ["exchangeFamily"] = {
            ["familyID"] = "command.player.return_home",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "{addressee.name}, head home.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.player.return_home.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "{addressee.name}, head home.",
                                        "Return to the base, {addressee.name}.",
                                        "{addressee.name}, get back home safely.",
                                    },
                                    ["TL"] = {
                                        "{addressee.name}, umuwi na kayo.",
                                        "Bumalik sa base, {addressee.name}.",
                                        "{addressee.name}, ligtas na umuwi.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.player",
            ["textRoles"] = {
                {
                    ["fallback"] = "{addressee.name}, head home.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.player.return_home.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "{addressee.name}, head home.",
                            "Return to the base, {addressee.name}.",
                            "{addressee.name}, get back home safely.",
                        },
                        ["TL"] = {
                            "{addressee.name}, umuwi na kayo.",
                            "Bumalik sa base, {addressee.name}.",
                            "{addressee.name}, ligtas na umuwi.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.player.return_home",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "return_home",
            ["sourceId"] = "command.player.return_home",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_player/command_player_return_home.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
        ["namespace"] = "command.player",
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
                ["responseAct"] = "DIRECTIVE",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "{addressee.name}, head home.",
                                        "Return to the base, {addressee.name}.",
                                        "{addressee.name}, get back home safely.",
                                    },
                                    ["TL"] = {
                                        "{addressee.name}, umuwi na kayo.",
                                        "Bumalik sa base, {addressee.name}.",
                                        "{addressee.name}, ligtas na umuwi.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "DIRECTIVE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.player.return_home",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "{addressee.name}, head home.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.command.player.return_home.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_player/command_player_return_home.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "{addressee.name}, head home.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.player.return_home.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "{addressee.name}, head home.",
                        "Return to the base, {addressee.name}.",
                        "{addressee.name}, get back home safely.",
                    },
                    ["TL"] = {
                        "{addressee.name}, umuwi na kayo.",
                        "Bumalik sa base, {addressee.name}.",
                        "{addressee.name}, ligtas na umuwi.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_player",
        ["exchangeFamily"] = {
            ["familyID"] = "command.player.stay",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "{addressee.name}, wait here.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.player.stay.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "{addressee.name}, wait here.",
                                        "Hold this position, {addressee.name}.",
                                        "{addressee.name}, stay put for now.",
                                    },
                                    ["TL"] = {
                                        "{addressee.name}, maghintay kayo rito.",
                                        "Panatilihin ang posisyon, {addressee.name}.",
                                        "{addressee.name}, manatili muna rito.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.player",
            ["textRoles"] = {
                {
                    ["fallback"] = "{addressee.name}, wait here.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.player.stay.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "{addressee.name}, wait here.",
                            "Hold this position, {addressee.name}.",
                            "{addressee.name}, stay put for now.",
                        },
                        ["TL"] = {
                            "{addressee.name}, maghintay kayo rito.",
                            "Panatilihin ang posisyon, {addressee.name}.",
                            "{addressee.name}, manatili muna rito.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.player.stay",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "stay",
            ["sourceId"] = "command.player.stay",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_player/command_player_stay.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
        ["namespace"] = "command.player",
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
                ["responseAct"] = "DIRECTIVE",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "{addressee.name}, wait here.",
                                        "Hold this position, {addressee.name}.",
                                        "{addressee.name}, stay put for now.",
                                    },
                                    ["TL"] = {
                                        "{addressee.name}, maghintay kayo rito.",
                                        "Panatilihin ang posisyon, {addressee.name}.",
                                        "{addressee.name}, manatili muna rito.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "DIRECTIVE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.player.stay",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "{addressee.name}, wait here.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.command.player.stay.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_player/command_player_stay.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "{addressee.name}, wait here.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.player.stay.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "{addressee.name}, wait here.",
                        "Hold this position, {addressee.name}.",
                        "{addressee.name}, stay put for now.",
                    },
                    ["TL"] = {
                        "{addressee.name}, maghintay kayo rito.",
                        "Panatilihin ang posisyon, {addressee.name}.",
                        "{addressee.name}, manatili muna rito.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
