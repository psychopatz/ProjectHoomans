-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_replies",
        ["domainPath"] = "companion_commands_replies",
        ["exchangeFamily"] = {
            ["familyID"] = "command.reply.attack_auto",
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
                                ["fallback"] = "I'll handle it.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.reply.attack_auto.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'll handle it.",
                                        "Engaging as needed.",
                                        "I'll choose my targets.",
                                        "Free to engage. Understood.",
                                        "I'll fight whatever comes close.",
                                        "On it. I'll take them down as they come.",
                                        "Standard combat stance. Understood.",
                                        "I'll defend myself and support you.",
                                        "Attacking at discretion.",
                                        "Understood. Engaging threats automatically.",
                                    },
                                    ["TL"] = {
                                        "Ako na ang bahala.",
                                        "Lalabanan kapag kinakailangan.",
                                        "Pipiliin ko ang mga puntirya ko.",
                                        "Malaya nang lumaban. Naintindihan.",
                                        "Lalabanan ko ang anumang lumapit.",
                                        "Inaasikaso na. Patutumbahin ko sila habang dumarating.",
                                        "Pangkaraniwang tindig sa laban. Naintindihan.",
                                        "Ipagtatanggol ko ang sarili at tutulungan kita.",
                                        "Aatake ayon sa sitwasyon.",
                                        "Naiintindihan ko. Kusang aatake sa mga banta.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.reply",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'll handle it.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.reply.attack_auto.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'll handle it.",
                            "Engaging as needed.",
                            "I'll choose my targets.",
                            "Free to engage. Understood.",
                            "I'll fight whatever comes close.",
                            "On it. I'll take them down as they come.",
                            "Standard combat stance. Understood.",
                            "I'll defend myself and support you.",
                            "Attacking at discretion.",
                            "Understood. Engaging threats automatically.",
                        },
                        ["TL"] = {
                            "Ako na ang bahala.",
                            "Lalabanan kapag kinakailangan.",
                            "Pipiliin ko ang mga puntirya ko.",
                            "Malaya nang lumaban. Naintindihan.",
                            "Lalabanan ko ang anumang lumapit.",
                            "Inaasikaso na. Patutumbahin ko sila habang dumarating.",
                            "Pangkaraniwang tindig sa laban. Naintindihan.",
                            "Ipagtatanggol ko ang sarili at tutulungan kita.",
                            "Aatake ayon sa sitwasyon.",
                            "Naiintindihan ko. Kusang aatake sa mga banta.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.reply.attack_auto",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "attack_auto",
            ["sourceId"] = "command.reply.attack_auto",
            ["sourcePath"] = "dialogue/companion_commands_replies/command_reply_attack_auto.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsReplies",
        ["namespace"] = "command.reply",
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
            ["activities"] = {
                {
                    ["id"] = "companion_order",
                    ["role"] = "target",
                },
            },
            ["domains"] = {
                {
                    ["domain"] = "companion_commands",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "REPLY",
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
                                        "I'll handle it.",
                                        "Engaging as needed.",
                                        "I'll choose my targets.",
                                        "Free to engage. Understood.",
                                        "I'll fight whatever comes close.",
                                        "On it. I'll take them down as they come.",
                                        "Standard combat stance. Understood.",
                                        "I'll defend myself and support you.",
                                        "Attacking at discretion.",
                                        "Understood. Engaging threats automatically.",
                                    },
                                    ["TL"] = {
                                        "Ako na ang bahala.",
                                        "Lalabanan kapag kinakailangan.",
                                        "Pipiliin ko ang mga puntirya ko.",
                                        "Malaya nang lumaban. Naintindihan.",
                                        "Lalabanan ko ang anumang lumapit.",
                                        "Inaasikaso na. Patutumbahin ko sila habang dumarating.",
                                        "Pangkaraniwang tindig sa laban. Naintindihan.",
                                        "Ipagtatanggol ko ang sarili at tutulungan kita.",
                                        "Aatake ayon sa sitwasyon.",
                                        "Naiintindihan ko. Kusang aatake sa mga banta.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "companion_commands",
                    ["id"] = "companion_command",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REPLY",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.reply.attack_auto",
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
                            ["fallback"] = "I'll handle it.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.command.reply.attack_auto.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_replies/command_reply_attack_auto.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'll handle it.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.reply.attack_auto.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'll handle it.",
                        "Engaging as needed.",
                        "I'll choose my targets.",
                        "Free to engage. Understood.",
                        "I'll fight whatever comes close.",
                        "On it. I'll take them down as they come.",
                        "Standard combat stance. Understood.",
                        "I'll defend myself and support you.",
                        "Attacking at discretion.",
                        "Understood. Engaging threats automatically.",
                    },
                    ["TL"] = {
                        "Ako na ang bahala.",
                        "Lalabanan kapag kinakailangan.",
                        "Pipiliin ko ang mga puntirya ko.",
                        "Malaya nang lumaban. Naintindihan.",
                        "Lalabanan ko ang anumang lumapit.",
                        "Inaasikaso na. Patutumbahin ko sila habang dumarating.",
                        "Pangkaraniwang tindig sa laban. Naintindihan.",
                        "Ipagtatanggol ko ang sarili at tutulungan kita.",
                        "Aatake ayon sa sitwasyon.",
                        "Naiintindihan ko. Kusang aatake sa mga banta.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_replies",
        ["domainPath"] = "companion_commands_replies",
        ["exchangeFamily"] = {
            ["familyID"] = "command.reply.attack_melee",
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
                                ["fallback"] = "Going in close.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.reply.attack_melee.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Going in close.",
                                        "Melee ready. Closing the distance.",
                                        "I'll take them hand-to-hand.",
                                        "Blade and blunt ready.",
                                        "Saving ammo. Taking them up close.",
                                        "Going in with melee.",
                                        "I'll crack some skulls up front.",
                                        "Melee weapon drawn.",
                                        "Moving into striking range.",
                                        "Understood. Close-quarters combat.",
                                    },
                                    ["TL"] = {
                                        "Lalapit ako.",
                                        "Handa ang pambugbog. Lalapit na ako.",
                                        "Lalabanan ko sila nang malapitan.",
                                        "Handa ang talim at pamalo.",
                                        "Magtitipid ng bala. Lalapitan ko sila.",
                                        "Lulusob nang malapitan.",
                                        "Babaliin ko ang bungo nila sa unahan.",
                                        "Nakahugot na ang panlaban nang malapitan.",
                                        "Pumupwesto na sa abot ng hampas.",
                                        "Naintindihan. Malapitang bakbakan.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.reply",
            ["textRoles"] = {
                {
                    ["fallback"] = "Going in close.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.reply.attack_melee.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Going in close.",
                            "Melee ready. Closing the distance.",
                            "I'll take them hand-to-hand.",
                            "Blade and blunt ready.",
                            "Saving ammo. Taking them up close.",
                            "Going in with melee.",
                            "I'll crack some skulls up front.",
                            "Melee weapon drawn.",
                            "Moving into striking range.",
                            "Understood. Close-quarters combat.",
                        },
                        ["TL"] = {
                            "Lalapit ako.",
                            "Handa ang pambugbog. Lalapit na ako.",
                            "Lalabanan ko sila nang malapitan.",
                            "Handa ang talim at pamalo.",
                            "Magtitipid ng bala. Lalapitan ko sila.",
                            "Lulusob nang malapitan.",
                            "Babaliin ko ang bungo nila sa unahan.",
                            "Nakahugot na ang panlaban nang malapitan.",
                            "Pumupwesto na sa abot ng hampas.",
                            "Naintindihan. Malapitang bakbakan.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.reply.attack_melee",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "attack_melee",
            ["sourceId"] = "command.reply.attack_melee",
            ["sourcePath"] = "dialogue/companion_commands_replies/command_reply_attack_melee.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsReplies",
        ["namespace"] = "command.reply",
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
            ["activities"] = {
                {
                    ["id"] = "companion_order",
                    ["role"] = "target",
                },
            },
            ["domains"] = {
                {
                    ["domain"] = "companion_commands",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "REPLY",
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
                                        "Going in close.",
                                        "Melee ready. Closing the distance.",
                                        "I'll take them hand-to-hand.",
                                        "Blade and blunt ready.",
                                        "Saving ammo. Taking them up close.",
                                        "Going in with melee.",
                                        "I'll crack some skulls up front.",
                                        "Melee weapon drawn.",
                                        "Moving into striking range.",
                                        "Understood. Close-quarters combat.",
                                    },
                                    ["TL"] = {
                                        "Lalapit ako.",
                                        "Handa ang pambugbog. Lalapit na ako.",
                                        "Lalabanan ko sila nang malapitan.",
                                        "Handa ang talim at pamalo.",
                                        "Magtitipid ng bala. Lalapitan ko sila.",
                                        "Lulusob nang malapitan.",
                                        "Babaliin ko ang bungo nila sa unahan.",
                                        "Nakahugot na ang panlaban nang malapitan.",
                                        "Pumupwesto na sa abot ng hampas.",
                                        "Naintindihan. Malapitang bakbakan.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "companion_commands",
                    ["id"] = "companion_command",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REPLY",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.reply.attack_melee",
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
                            ["fallback"] = "Going in close.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.command.reply.attack_melee.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_replies/command_reply_attack_melee.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Going in close.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.reply.attack_melee.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Going in close.",
                        "Melee ready. Closing the distance.",
                        "I'll take them hand-to-hand.",
                        "Blade and blunt ready.",
                        "Saving ammo. Taking them up close.",
                        "Going in with melee.",
                        "I'll crack some skulls up front.",
                        "Melee weapon drawn.",
                        "Moving into striking range.",
                        "Understood. Close-quarters combat.",
                    },
                    ["TL"] = {
                        "Lalapit ako.",
                        "Handa ang pambugbog. Lalapit na ako.",
                        "Lalabanan ko sila nang malapitan.",
                        "Handa ang talim at pamalo.",
                        "Magtitipid ng bala. Lalapitan ko sila.",
                        "Lulusob nang malapitan.",
                        "Babaliin ko ang bungo nila sa unahan.",
                        "Nakahugot na ang panlaban nang malapitan.",
                        "Pumupwesto na sa abot ng hampas.",
                        "Naintindihan. Malapitang bakbakan.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_replies",
        ["domainPath"] = "companion_commands_replies",
        ["exchangeFamily"] = {
            ["familyID"] = "command.reply.attack_none",
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
                                ["fallback"] = "I'll avoid trouble.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.reply.attack_none.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'll avoid trouble.",
                                        "Holding fire. Keeping passive.",
                                        "Staying out of fights.",
                                        "Understood. Ceasing all attacks.",
                                        "I won't provoke anything.",
                                        "Keeping my weapon stowed.",
                                        "Pacifist stance. Understood.",
                                        "I'll steer clear of hostiles.",
                                        "Standing down from combat.",
                                        "No attacking. Got it.",
                                    },
                                    ["TL"] = {
                                        "Iiwas ako sa gulo.",
                                        "Tigil-putok. Mananatiling tahimik.",
                                        "Lalayo ako sa anumang labanan.",
                                        "Naiintindihan ko. Ititigil ang lahat ng atake.",
                                        "Wala akong gagalawin o pupukawin.",
                                        "Nakatago ang armas ko.",
                                        "Tahimik na paninindigan. Naintindihan.",
                                        "Iiwas ako sa mga kalaban.",
                                        "Uuurong sa laban.",
                                        "Walang aatake. Nakuha ko.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.reply",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'll avoid trouble.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.reply.attack_none.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'll avoid trouble.",
                            "Holding fire. Keeping passive.",
                            "Staying out of fights.",
                            "Understood. Ceasing all attacks.",
                            "I won't provoke anything.",
                            "Keeping my weapon stowed.",
                            "Pacifist stance. Understood.",
                            "I'll steer clear of hostiles.",
                            "Standing down from combat.",
                            "No attacking. Got it.",
                        },
                        ["TL"] = {
                            "Iiwas ako sa gulo.",
                            "Tigil-putok. Mananatiling tahimik.",
                            "Lalayo ako sa anumang labanan.",
                            "Naiintindihan ko. Ititigil ang lahat ng atake.",
                            "Wala akong gagalawin o pupukawin.",
                            "Nakatago ang armas ko.",
                            "Tahimik na paninindigan. Naintindihan.",
                            "Iiwas ako sa mga kalaban.",
                            "Uuurong sa laban.",
                            "Walang aatake. Nakuha ko.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.reply.attack_none",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "attack_none",
            ["sourceId"] = "command.reply.attack_none",
            ["sourcePath"] = "dialogue/companion_commands_replies/command_reply_attack_none.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsReplies",
        ["namespace"] = "command.reply",
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
            ["activities"] = {
                {
                    ["id"] = "companion_order",
                    ["role"] = "target",
                },
            },
            ["domains"] = {
                {
                    ["domain"] = "companion_commands",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "REPLY",
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
                                        "I'll avoid trouble.",
                                        "Holding fire. Keeping passive.",
                                        "Staying out of fights.",
                                        "Understood. Ceasing all attacks.",
                                        "I won't provoke anything.",
                                        "Keeping my weapon stowed.",
                                        "Pacifist stance. Understood.",
                                        "I'll steer clear of hostiles.",
                                        "Standing down from combat.",
                                        "No attacking. Got it.",
                                    },
                                    ["TL"] = {
                                        "Iiwas ako sa gulo.",
                                        "Tigil-putok. Mananatiling tahimik.",
                                        "Lalayo ako sa anumang labanan.",
                                        "Naiintindihan ko. Ititigil ang lahat ng atake.",
                                        "Wala akong gagalawin o pupukawin.",
                                        "Nakatago ang armas ko.",
                                        "Tahimik na paninindigan. Naintindihan.",
                                        "Iiwas ako sa mga kalaban.",
                                        "Uuurong sa laban.",
                                        "Walang aatake. Nakuha ko.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "companion_commands",
                    ["id"] = "companion_command",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REPLY",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.reply.attack_none",
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
                            ["fallback"] = "I'll avoid trouble.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.command.reply.attack_none.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_replies/command_reply_attack_none.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'll avoid trouble.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.reply.attack_none.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'll avoid trouble.",
                        "Holding fire. Keeping passive.",
                        "Staying out of fights.",
                        "Understood. Ceasing all attacks.",
                        "I won't provoke anything.",
                        "Keeping my weapon stowed.",
                        "Pacifist stance. Understood.",
                        "I'll steer clear of hostiles.",
                        "Standing down from combat.",
                        "No attacking. Got it.",
                    },
                    ["TL"] = {
                        "Iiwas ako sa gulo.",
                        "Tigil-putok. Mananatiling tahimik.",
                        "Lalayo ako sa anumang labanan.",
                        "Naiintindihan ko. Ititigil ang lahat ng atake.",
                        "Wala akong gagalawin o pupukawin.",
                        "Nakatago ang armas ko.",
                        "Tahimik na paninindigan. Naintindihan.",
                        "Iiwas ako sa mga kalaban.",
                        "Uuurong sa laban.",
                        "Walang aatake. Nakuha ko.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_replies",
        ["domainPath"] = "companion_commands_replies",
        ["exchangeFamily"] = {
            ["familyID"] = "command.reply.attack_ranged",
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
                                ["fallback"] = "I'll cover you.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.reply.attack_ranged.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'll cover you.",
                                        "Ranged weapon ready. Watching the distance.",
                                        "Providing covering fire.",
                                        "I'll pick them off from here.",
                                        "Sights aligned. Firing at range.",
                                        "Keeping my distance and shooting.",
                                        "Understood. Overwatching with ranged fire.",
                                        "Ready on the trigger. Staying back.",
                                        "Covering the field from back here.",
                                        "Ranged attack stance confirmed.",
                                    },
                                    ["TL"] = {
                                        "Bibigyan kita ng takip.",
                                        "Handa ang baril. Binabantayan ang malayo.",
                                        "Magbibigay ng suportang putok.",
                                        "Isa-isa ko silang titirahin mula rito.",
                                        "Nakatutok na ang paningin. Babaril sa malayo.",
                                        "Lalayo ako at magpapaputok.",
                                        "Naintindihan. Magbabantay gamit ang baril.",
                                        "Nasa gatilyo ang daliri. Mananatili sa likod.",
                                        "Tatakpan ko ang lugar mula rito.",
                                        "Kumpirmado ang malayuang pag-atake.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.reply",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'll cover you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.reply.attack_ranged.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'll cover you.",
                            "Ranged weapon ready. Watching the distance.",
                            "Providing covering fire.",
                            "I'll pick them off from here.",
                            "Sights aligned. Firing at range.",
                            "Keeping my distance and shooting.",
                            "Understood. Overwatching with ranged fire.",
                            "Ready on the trigger. Staying back.",
                            "Covering the field from back here.",
                            "Ranged attack stance confirmed.",
                        },
                        ["TL"] = {
                            "Bibigyan kita ng takip.",
                            "Handa ang baril. Binabantayan ang malayo.",
                            "Magbibigay ng suportang putok.",
                            "Isa-isa ko silang titirahin mula rito.",
                            "Nakatutok na ang paningin. Babaril sa malayo.",
                            "Lalayo ako at magpapaputok.",
                            "Naintindihan. Magbabantay gamit ang baril.",
                            "Nasa gatilyo ang daliri. Mananatili sa likod.",
                            "Tatakpan ko ang lugar mula rito.",
                            "Kumpirmado ang malayuang pag-atake.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.reply.attack_ranged",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "attack_ranged",
            ["sourceId"] = "command.reply.attack_ranged",
            ["sourcePath"] = "dialogue/companion_commands_replies/command_reply_attack_ranged.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsReplies",
        ["namespace"] = "command.reply",
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
            ["activities"] = {
                {
                    ["id"] = "companion_order",
                    ["role"] = "target",
                },
            },
            ["domains"] = {
                {
                    ["domain"] = "companion_commands",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "REPLY",
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
                                        "I'll cover you.",
                                        "Ranged weapon ready. Watching the distance.",
                                        "Providing covering fire.",
                                        "I'll pick them off from here.",
                                        "Sights aligned. Firing at range.",
                                        "Keeping my distance and shooting.",
                                        "Understood. Overwatching with ranged fire.",
                                        "Ready on the trigger. Staying back.",
                                        "Covering the field from back here.",
                                        "Ranged attack stance confirmed.",
                                    },
                                    ["TL"] = {
                                        "Bibigyan kita ng takip.",
                                        "Handa ang baril. Binabantayan ang malayo.",
                                        "Magbibigay ng suportang putok.",
                                        "Isa-isa ko silang titirahin mula rito.",
                                        "Nakatutok na ang paningin. Babaril sa malayo.",
                                        "Lalayo ako at magpapaputok.",
                                        "Naintindihan. Magbabantay gamit ang baril.",
                                        "Nasa gatilyo ang daliri. Mananatili sa likod.",
                                        "Tatakpan ko ang lugar mula rito.",
                                        "Kumpirmado ang malayuang pag-atake.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "companion_commands",
                    ["id"] = "companion_command",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REPLY",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.reply.attack_ranged",
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
                            ["fallback"] = "I'll cover you.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.command.reply.attack_ranged.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_replies/command_reply_attack_ranged.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'll cover you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.reply.attack_ranged.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'll cover you.",
                        "Ranged weapon ready. Watching the distance.",
                        "Providing covering fire.",
                        "I'll pick them off from here.",
                        "Sights aligned. Firing at range.",
                        "Keeping my distance and shooting.",
                        "Understood. Overwatching with ranged fire.",
                        "Ready on the trigger. Staying back.",
                        "Covering the field from back here.",
                        "Ranged attack stance confirmed.",
                    },
                    ["TL"] = {
                        "Bibigyan kita ng takip.",
                        "Handa ang baril. Binabantayan ang malayo.",
                        "Magbibigay ng suportang putok.",
                        "Isa-isa ko silang titirahin mula rito.",
                        "Nakatutok na ang paningin. Babaril sa malayo.",
                        "Lalayo ako at magpapaputok.",
                        "Naintindihan. Magbabantay gamit ang baril.",
                        "Nasa gatilyo ang daliri. Mananatili sa likod.",
                        "Tatakpan ko ang lugar mula rito.",
                        "Kumpirmado ang malayuang pag-atake.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_replies",
        ["domainPath"] = "companion_commands_replies",
        ["exchangeFamily"] = {
            ["familyID"] = "command.reply.camp",
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
                                ["fallback"] = "We'll make camp here.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.reply.camp.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "We'll make camp here.",
                                        "Setting up camp in this spot.",
                                        "Understood. Resting here.",
                                        "This place works for a camp. Securing it.",
                                        "Making camp. Let's get comfortable.",
                                        "Good spot to bed down.",
                                        "Camp established. I'll settle in.",
                                        "Understood. Dropping gear and resting.",
                                        "Setting watches and bedding down here.",
                                        "Camp confirmed. Staying put.",
                                    },
                                    ["TL"] = {
                                        "Magkakampo tayo rito.",
                                        "Magtatayo ng kampo sa pwestong ito.",
                                        "Naintindihan. Magpapahinga rito.",
                                        "Pwede ang lugar na ito para magkampo. Seselyuhan ito.",
                                        "Nagtatayo ng kampo. Magpahinga na tayo.",
                                        "Magandang lugar para matulog.",
                                        "Naitayo na ang kampo. Aayos na ako ng pwesto.",
                                        "Naiintindihan ko. Ibaba ang gamit at magpahinga.",
                                        "Magtatalaga ng bantay at matutulog dito.",
                                        "Kumpirmadong kampo. Mananatili rito.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.reply",
            ["slots"] = {
                ["location"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.location",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "We'll make camp here.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.reply.camp.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "We'll make camp here.",
                            "Setting up camp in this spot.",
                            "Understood. Resting here.",
                            "This place works for a camp. Securing it.",
                            "Making camp. Let's get comfortable.",
                            "Good spot to bed down.",
                            "Camp established. I'll settle in.",
                            "Understood. Dropping gear and resting.",
                            "Setting watches and bedding down here.",
                            "Camp confirmed. Staying put.",
                        },
                        ["TL"] = {
                            "Magkakampo tayo rito.",
                            "Magtatayo ng kampo sa pwestong ito.",
                            "Naintindihan. Magpapahinga rito.",
                            "Pwede ang lugar na ito para magkampo. Seselyuhan ito.",
                            "Nagtatayo ng kampo. Magpahinga na tayo.",
                            "Magandang lugar para matulog.",
                            "Naitayo na ang kampo. Aayos na ako ng pwesto.",
                            "Naiintindihan ko. Ibaba ang gamit at magpahinga.",
                            "Magtatalaga ng bantay at matutulog dito.",
                            "Kumpirmadong kampo. Mananatili rito.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.reply.camp",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "camp",
            ["sourceId"] = "command.reply.camp",
            ["sourcePath"] = "dialogue/companion_commands_replies/command_reply_camp.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsReplies",
        ["namespace"] = "command.reply",
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
            ["activities"] = {
                {
                    ["id"] = "companion_order",
                    ["role"] = "target",
                },
            },
            ["domains"] = {
                {
                    ["domain"] = "companion_commands",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "REPLY",
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
                                        "We'll make camp here.",
                                        "Setting up camp in this spot.",
                                        "Understood. Resting here.",
                                        "This place works for a camp. Securing it.",
                                        "Making camp. Let's get comfortable.",
                                        "Good spot to bed down.",
                                        "Camp established. I'll settle in.",
                                        "Understood. Dropping gear and resting.",
                                        "Setting watches and bedding down here.",
                                        "Camp confirmed. Staying put.",
                                    },
                                    ["TL"] = {
                                        "Magkakampo tayo rito.",
                                        "Magtatayo ng kampo sa pwestong ito.",
                                        "Naintindihan. Magpapahinga rito.",
                                        "Pwede ang lugar na ito para magkampo. Seselyuhan ito.",
                                        "Nagtatayo ng kampo. Magpahinga na tayo.",
                                        "Magandang lugar para matulog.",
                                        "Naitayo na ang kampo. Aayos na ako ng pwesto.",
                                        "Naiintindihan ko. Ibaba ang gamit at magpahinga.",
                                        "Magtatalaga ng bantay at matutulog dito.",
                                        "Kumpirmadong kampo. Mananatili rito.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "companion_commands",
                    ["id"] = "companion_command",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REPLY",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.reply.camp",
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
                            ["fallback"] = "We'll make camp here.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.command.reply.camp.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
            ["location"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.location",
            },
        },
        ["sourceShard"] = "dialogue/companion_commands_replies/command_reply_camp.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "We'll make camp here.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.reply.camp.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "We'll make camp here.",
                        "Setting up camp in this spot.",
                        "Understood. Resting here.",
                        "This place works for a camp. Securing it.",
                        "Making camp. Let's get comfortable.",
                        "Good spot to bed down.",
                        "Camp established. I'll settle in.",
                        "Understood. Dropping gear and resting.",
                        "Setting watches and bedding down here.",
                        "Camp confirmed. Staying put.",
                    },
                    ["TL"] = {
                        "Magkakampo tayo rito.",
                        "Magtatayo ng kampo sa pwestong ito.",
                        "Naintindihan. Magpapahinga rito.",
                        "Pwede ang lugar na ito para magkampo. Seselyuhan ito.",
                        "Nagtatayo ng kampo. Magpahinga na tayo.",
                        "Magandang lugar para matulog.",
                        "Naitayo na ang kampo. Aayos na ako ng pwesto.",
                        "Naiintindihan ko. Ibaba ang gamit at magpahinga.",
                        "Magtatalaga ng bantay at matutulog dito.",
                        "Kumpirmadong kampo. Mananatili rito.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_replies",
        ["domainPath"] = "companion_commands_replies",
        ["exchangeFamily"] = {
            ["familyID"] = "command.reply.camp_rejected",
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
                                ["templateID"] = "convo.command.reply.camp_rejected.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I can't find a safe room or campfire nearby.",
                                        "Not safe enough to camp here.",
                                        "We need walls or fire before we can camp.",
                                        "Too exposed. Find better shelter first.",
                                        "I refuse to sleep in the open like this.",
                                        "Can't camp here. It's crawling with danger.",
                                        "Find a secure room before we bed down.",
                                        "No cover, no heat. We can't camp here.",
                                        "Invalid camping spot. We need real shelter.",
                                        "We'd get killed sleeping here. Find a safer building.",
                                    },
                                    ["TL"] = {
                                        "Wala akong makitang ligtas na silid o apoy dito.",
                                        "Hindi sapat ang ligtas ng lugar para magkampo rito.",
                                        "Kailangan natin ng pader o apoy bago magkampo.",
                                        "Masyadong bukas. Humanap muna ng mas maayos na silungan.",
                                        "Ayokong matulog sa bukas na lugar nang ganito.",
                                        "Hindi pwedeng magkampo rito. Napakaraming panganib.",
                                        "Maghanap ng ligtas na kwarto bago tayo matulog.",
                                        "Walang silong, walang init. Di tayo pwedeng magkampo rito.",
                                        "Maling pwesto para magkampo. Kailangan natin ng tunay na silungan.",
                                        "Mapapatay tayo kapag natulog dito. Humanap ng mas ligtas na bahay.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.reply",
            ["textRoles"] = {
                {
                    ["fallback"] = "I can't find a safe room or campfire nearby.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.reply.camp_rejected.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I can't find a safe room or campfire nearby.",
                            "Not safe enough to camp here.",
                            "We need walls or fire before we can camp.",
                            "Too exposed. Find better shelter first.",
                            "I refuse to sleep in the open like this.",
                            "Can't camp here. It's crawling with danger.",
                            "Find a secure room before we bed down.",
                            "No cover, no heat. We can't camp here.",
                            "Invalid camping spot. We need real shelter.",
                            "We'd get killed sleeping here. Find a safer building.",
                        },
                        ["TL"] = {
                            "Wala akong makitang ligtas na silid o apoy dito.",
                            "Hindi sapat ang ligtas ng lugar para magkampo rito.",
                            "Kailangan natin ng pader o apoy bago magkampo.",
                            "Masyadong bukas. Humanap muna ng mas maayos na silungan.",
                            "Ayokong matulog sa bukas na lugar nang ganito.",
                            "Hindi pwedeng magkampo rito. Napakaraming panganib.",
                            "Maghanap ng ligtas na kwarto bago tayo matulog.",
                            "Walang silong, walang init. Di tayo pwedeng magkampo rito.",
                            "Maling pwesto para magkampo. Kailangan natin ng tunay na silungan.",
                            "Mapapatay tayo kapag natulog dito. Humanap ng mas ligtas na bahay.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.reply.camp_rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "camp_rejected",
            ["sourceId"] = "command.reply.camp_rejected",
            ["sourcePath"] = "dialogue/companion_commands_replies/command_reply_camp_rejected.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsReplies",
        ["namespace"] = "command.reply",
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
            ["activities"] = {
                {
                    ["id"] = "companion_order",
                    ["role"] = "target",
                },
            },
            ["domains"] = {
                {
                    ["domain"] = "companion_commands",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "REPLY",
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
                                        "Not safe enough to camp here.",
                                        "We need walls or fire before we can camp.",
                                        "Too exposed. Find better shelter first.",
                                        "I refuse to sleep in the open like this.",
                                        "Can't camp here. It's crawling with danger.",
                                        "Find a secure room before we bed down.",
                                        "No cover, no heat. We can't camp here.",
                                        "Invalid camping spot. We need real shelter.",
                                        "We'd get killed sleeping here. Find a safer building.",
                                    },
                                    ["TL"] = {
                                        "Wala akong makitang ligtas na silid o apoy dito.",
                                        "Hindi sapat ang ligtas ng lugar para magkampo rito.",
                                        "Kailangan natin ng pader o apoy bago magkampo.",
                                        "Masyadong bukas. Humanap muna ng mas maayos na silungan.",
                                        "Ayokong matulog sa bukas na lugar nang ganito.",
                                        "Hindi pwedeng magkampo rito. Napakaraming panganib.",
                                        "Maghanap ng ligtas na kwarto bago tayo matulog.",
                                        "Walang silong, walang init. Di tayo pwedeng magkampo rito.",
                                        "Maling pwesto para magkampo. Kailangan natin ng tunay na silungan.",
                                        "Mapapatay tayo kapag natulog dito. Humanap ng mas ligtas na bahay.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "companion_commands",
                    ["id"] = "companion_command",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REPLY",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.reply.camp_rejected",
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
                            ["templateID"] = "convo.command.reply.camp_rejected.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_replies/command_reply_camp_rejected.json",
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
                ["templateID"] = "convo.command.reply.camp_rejected.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I can't find a safe room or campfire nearby.",
                        "Not safe enough to camp here.",
                        "We need walls or fire before we can camp.",
                        "Too exposed. Find better shelter first.",
                        "I refuse to sleep in the open like this.",
                        "Can't camp here. It's crawling with danger.",
                        "Find a secure room before we bed down.",
                        "No cover, no heat. We can't camp here.",
                        "Invalid camping spot. We need real shelter.",
                        "We'd get killed sleeping here. Find a safer building.",
                    },
                    ["TL"] = {
                        "Wala akong makitang ligtas na silid o apoy dito.",
                        "Hindi sapat ang ligtas ng lugar para magkampo rito.",
                        "Kailangan natin ng pader o apoy bago magkampo.",
                        "Masyadong bukas. Humanap muna ng mas maayos na silungan.",
                        "Ayokong matulog sa bukas na lugar nang ganito.",
                        "Hindi pwedeng magkampo rito. Napakaraming panganib.",
                        "Maghanap ng ligtas na kwarto bago tayo matulog.",
                        "Walang silong, walang init. Di tayo pwedeng magkampo rito.",
                        "Maling pwesto para magkampo. Kailangan natin ng tunay na silungan.",
                        "Mapapatay tayo kapag natulog dito. Humanap ng mas ligtas na bahay.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_replies",
        ["domainPath"] = "companion_commands_replies",
        ["exchangeFamily"] = {
            ["familyID"] = "command.reply.follow",
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
                                ["fallback"] = "Right behind you.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.reply.follow.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Right behind you.",
                                        "Following your lead.",
                                        "I'm with you. Lead on.",
                                        "Right on your heels.",
                                        "Understood. Sticking close.",
                                        "Following. Watch our front.",
                                        "I'll follow your pace.",
                                        "Right with you.",
                                        "Moving with you now.",
                                        "Lead the way. I'm right behind.",
                                    },
                                    ["TL"] = {
                                        "Susunod ako sa iyo.",
                                        "Sumusunod sa pangunguna mo.",
                                        "Kasama mo ako. Mauna ka na.",
                                        "Nasa likod mo lang ako.",
                                        "Naintindihan. Didikit ako.",
                                        "Sumusunod na. Bantayan ang unahan natin.",
                                        "Sasabay ako sa bilis mo.",
                                        "Kasabay mo na ako.",
                                        "Kumikilos na kasabay mo ngayon.",
                                        "Ituro ang daan. Kasunod mo lang ako.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.reply",
            ["textRoles"] = {
                {
                    ["fallback"] = "Right behind you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.reply.follow.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Right behind you.",
                            "Following your lead.",
                            "I'm with you. Lead on.",
                            "Right on your heels.",
                            "Understood. Sticking close.",
                            "Following. Watch our front.",
                            "I'll follow your pace.",
                            "Right with you.",
                            "Moving with you now.",
                            "Lead the way. I'm right behind.",
                        },
                        ["TL"] = {
                            "Susunod ako sa iyo.",
                            "Sumusunod sa pangunguna mo.",
                            "Kasama mo ako. Mauna ka na.",
                            "Nasa likod mo lang ako.",
                            "Naintindihan. Didikit ako.",
                            "Sumusunod na. Bantayan ang unahan natin.",
                            "Sasabay ako sa bilis mo.",
                            "Kasabay mo na ako.",
                            "Kumikilos na kasabay mo ngayon.",
                            "Ituro ang daan. Kasunod mo lang ako.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.reply.follow",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "follow",
            ["sourceId"] = "command.reply.follow",
            ["sourcePath"] = "dialogue/companion_commands_replies/command_reply_follow.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsReplies",
        ["namespace"] = "command.reply",
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
            ["activities"] = {
                {
                    ["id"] = "companion_order",
                    ["role"] = "target",
                },
            },
            ["domains"] = {
                {
                    ["domain"] = "companion_commands",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "REPLY",
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
                                        "Right behind you.",
                                        "Following your lead.",
                                        "I'm with you. Lead on.",
                                        "Right on your heels.",
                                        "Understood. Sticking close.",
                                        "Following. Watch our front.",
                                        "I'll follow your pace.",
                                        "Right with you.",
                                        "Moving with you now.",
                                        "Lead the way. I'm right behind.",
                                    },
                                    ["TL"] = {
                                        "Susunod ako sa iyo.",
                                        "Sumusunod sa pangunguna mo.",
                                        "Kasama mo ako. Mauna ka na.",
                                        "Nasa likod mo lang ako.",
                                        "Naintindihan. Didikit ako.",
                                        "Sumusunod na. Bantayan ang unahan natin.",
                                        "Sasabay ako sa bilis mo.",
                                        "Kasabay mo na ako.",
                                        "Kumikilos na kasabay mo ngayon.",
                                        "Ituro ang daan. Kasunod mo lang ako.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "companion_commands",
                    ["id"] = "companion_command",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REPLY",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.reply.follow",
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
                            ["fallback"] = "Right behind you.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.command.reply.follow.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_replies/command_reply_follow.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Right behind you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.reply.follow.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Right behind you.",
                        "Following your lead.",
                        "I'm with you. Lead on.",
                        "Right on your heels.",
                        "Understood. Sticking close.",
                        "Following. Watch our front.",
                        "I'll follow your pace.",
                        "Right with you.",
                        "Moving with you now.",
                        "Lead the way. I'm right behind.",
                    },
                    ["TL"] = {
                        "Susunod ako sa iyo.",
                        "Sumusunod sa pangunguna mo.",
                        "Kasama mo ako. Mauna ka na.",
                        "Nasa likod mo lang ako.",
                        "Naintindihan. Didikit ako.",
                        "Sumusunod na. Bantayan ang unahan natin.",
                        "Sasabay ako sa bilis mo.",
                        "Kasabay mo na ako.",
                        "Kumikilos na kasabay mo ngayon.",
                        "Ituro ang daan. Kasunod mo lang ako.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_replies",
        ["domainPath"] = "companion_commands_replies",
        ["exchangeFamily"] = {
            ["familyID"] = "command.reply.generic_rejected",
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
                                ["fallback"] = "I can't do that right now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.reply.generic_rejected.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I can't do that right now.",
                                        "That's not possible in this situation.",
                                        "Unable to comply with that order.",
                                        "I can't carry that out.",
                                        "Not going to happen right now.",
                                        "I don't have the means to do that.",
                                        "That order doesn't make sense right now.",
                                        "Can't do it. Find another way.",
                                        "I'm tied up or unable to fulfill that.",
                                        "Negative on that request.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko iyan magagawa ngayon.",
                                        "Hindi 'yan posible sa sitwasyong ito.",
                                        "Hindi makakasunod sa utos na 'yan.",
                                        "Hindi ko kayang isakatuparan 'yan.",
                                        "Hindi mangyayari 'yan sa ngayon.",
                                        "Wala akong kakayahan para gawin 'yan.",
                                        "Walang saysay ang utos na 'yan sa ngayon.",
                                        "Di kaya. Humanap ng ibang paraan.",
                                        "Abala ako o hindi ko magagawa 'yan.",
                                        "Hindi maaari ang hiling na 'yan.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.reply",
            ["textRoles"] = {
                {
                    ["fallback"] = "I can't do that right now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.reply.generic_rejected.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I can't do that right now.",
                            "That's not possible in this situation.",
                            "Unable to comply with that order.",
                            "I can't carry that out.",
                            "Not going to happen right now.",
                            "I don't have the means to do that.",
                            "That order doesn't make sense right now.",
                            "Can't do it. Find another way.",
                            "I'm tied up or unable to fulfill that.",
                            "Negative on that request.",
                        },
                        ["TL"] = {
                            "Hindi ko iyan magagawa ngayon.",
                            "Hindi 'yan posible sa sitwasyong ito.",
                            "Hindi makakasunod sa utos na 'yan.",
                            "Hindi ko kayang isakatuparan 'yan.",
                            "Hindi mangyayari 'yan sa ngayon.",
                            "Wala akong kakayahan para gawin 'yan.",
                            "Walang saysay ang utos na 'yan sa ngayon.",
                            "Di kaya. Humanap ng ibang paraan.",
                            "Abala ako o hindi ko magagawa 'yan.",
                            "Hindi maaari ang hiling na 'yan.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.reply.generic_rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "generic_rejected",
            ["sourceId"] = "command.reply.generic_rejected",
            ["sourcePath"] = "dialogue/companion_commands_replies/command_reply_generic_rejected.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsReplies",
        ["namespace"] = "command.reply",
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
            ["activities"] = {
                {
                    ["id"] = "companion_order",
                    ["role"] = "target",
                },
            },
            ["domains"] = {
                {
                    ["domain"] = "companion_commands",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "REPLY",
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
                                        "I can't do that right now.",
                                        "That's not possible in this situation.",
                                        "Unable to comply with that order.",
                                        "I can't carry that out.",
                                        "Not going to happen right now.",
                                        "I don't have the means to do that.",
                                        "That order doesn't make sense right now.",
                                        "Can't do it. Find another way.",
                                        "I'm tied up or unable to fulfill that.",
                                        "Negative on that request.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko iyan magagawa ngayon.",
                                        "Hindi 'yan posible sa sitwasyong ito.",
                                        "Hindi makakasunod sa utos na 'yan.",
                                        "Hindi ko kayang isakatuparan 'yan.",
                                        "Hindi mangyayari 'yan sa ngayon.",
                                        "Wala akong kakayahan para gawin 'yan.",
                                        "Walang saysay ang utos na 'yan sa ngayon.",
                                        "Di kaya. Humanap ng ibang paraan.",
                                        "Abala ako o hindi ko magagawa 'yan.",
                                        "Hindi maaari ang hiling na 'yan.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "companion_commands",
                    ["id"] = "companion_command",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REPLY",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.reply.generic_rejected",
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
                            ["fallback"] = "I can't do that right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.command.reply.generic_rejected.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_replies/command_reply_generic_rejected.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I can't do that right now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.reply.generic_rejected.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I can't do that right now.",
                        "That's not possible in this situation.",
                        "Unable to comply with that order.",
                        "I can't carry that out.",
                        "Not going to happen right now.",
                        "I don't have the means to do that.",
                        "That order doesn't make sense right now.",
                        "Can't do it. Find another way.",
                        "I'm tied up or unable to fulfill that.",
                        "Negative on that request.",
                    },
                    ["TL"] = {
                        "Hindi ko iyan magagawa ngayon.",
                        "Hindi 'yan posible sa sitwasyong ito.",
                        "Hindi makakasunod sa utos na 'yan.",
                        "Hindi ko kayang isakatuparan 'yan.",
                        "Hindi mangyayari 'yan sa ngayon.",
                        "Wala akong kakayahan para gawin 'yan.",
                        "Walang saysay ang utos na 'yan sa ngayon.",
                        "Di kaya. Humanap ng ibang paraan.",
                        "Abala ako o hindi ko magagawa 'yan.",
                        "Hindi maaari ang hiling na 'yan.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_replies",
        ["domainPath"] = "companion_commands_replies",
        ["exchangeFamily"] = {
            ["familyID"] = "command.reply.return_home",
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
                                ["fallback"] = "Heading home.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.reply.return_home.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Heading home.",
                                        "Returning to our base now.",
                                        "Understood. Going back to safe ground.",
                                        "I'll head back to our shelter.",
                                        "Making my way back home.",
                                        "Homeward bound. See you back at camp.",
                                        "Understood. I will return to base.",
                                        "Heading back to the compound.",
                                        "Heading home. Stay safe out here.",
                                        "Returning to base coordinates.",
                                    },
                                    ["TL"] = {
                                        "Uuwi na ako.",
                                        "Pabalik na sa base natin ngayon.",
                                        "Naiintindihan ko. Babalik sa ligtas na lugar.",
                                        "Babalik ako sa silungan natin.",
                                        "Pauwi na ako ngayon.",
                                        "Pauwi na. Magkita tayo sa kampo.",
                                        "Naintindihan. Babalik ako sa base.",
                                        "Pabalik na sa himpilan.",
                                        "Pauwi na ako. Mag-ingat ka rito.",
                                        "Pabalik na sa mga coordinate ng base.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.reply",
            ["textRoles"] = {
                {
                    ["fallback"] = "Heading home.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.reply.return_home.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Heading home.",
                            "Returning to our base now.",
                            "Understood. Going back to safe ground.",
                            "I'll head back to our shelter.",
                            "Making my way back home.",
                            "Homeward bound. See you back at camp.",
                            "Understood. I will return to base.",
                            "Heading back to the compound.",
                            "Heading home. Stay safe out here.",
                            "Returning to base coordinates.",
                        },
                        ["TL"] = {
                            "Uuwi na ako.",
                            "Pabalik na sa base natin ngayon.",
                            "Naiintindihan ko. Babalik sa ligtas na lugar.",
                            "Babalik ako sa silungan natin.",
                            "Pauwi na ako ngayon.",
                            "Pauwi na. Magkita tayo sa kampo.",
                            "Naintindihan. Babalik ako sa base.",
                            "Pabalik na sa himpilan.",
                            "Pauwi na ako. Mag-ingat ka rito.",
                            "Pabalik na sa mga coordinate ng base.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.reply.return_home",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "return_home",
            ["sourceId"] = "command.reply.return_home",
            ["sourcePath"] = "dialogue/companion_commands_replies/command_reply_return_home.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsReplies",
        ["namespace"] = "command.reply",
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
            ["activities"] = {
                {
                    ["id"] = "companion_order",
                    ["role"] = "target",
                },
            },
            ["domains"] = {
                {
                    ["domain"] = "companion_commands",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "REPLY",
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
                                        "Heading home.",
                                        "Returning to our base now.",
                                        "Understood. Going back to safe ground.",
                                        "I'll head back to our shelter.",
                                        "Making my way back home.",
                                        "Homeward bound. See you back at camp.",
                                        "Understood. I will return to base.",
                                        "Heading back to the compound.",
                                        "Heading home. Stay safe out here.",
                                        "Returning to base coordinates.",
                                    },
                                    ["TL"] = {
                                        "Uuwi na ako.",
                                        "Pabalik na sa base natin ngayon.",
                                        "Naiintindihan ko. Babalik sa ligtas na lugar.",
                                        "Babalik ako sa silungan natin.",
                                        "Pauwi na ako ngayon.",
                                        "Pauwi na. Magkita tayo sa kampo.",
                                        "Naintindihan. Babalik ako sa base.",
                                        "Pabalik na sa himpilan.",
                                        "Pauwi na ako. Mag-ingat ka rito.",
                                        "Pabalik na sa mga coordinate ng base.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "companion_commands",
                    ["id"] = "companion_command",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REPLY",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.reply.return_home",
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
                            ["fallback"] = "Heading home.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.command.reply.return_home.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_replies/command_reply_return_home.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Heading home.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.reply.return_home.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Heading home.",
                        "Returning to our base now.",
                        "Understood. Going back to safe ground.",
                        "I'll head back to our shelter.",
                        "Making my way back home.",
                        "Homeward bound. See you back at camp.",
                        "Understood. I will return to base.",
                        "Heading back to the compound.",
                        "Heading home. Stay safe out here.",
                        "Returning to base coordinates.",
                    },
                    ["TL"] = {
                        "Uuwi na ako.",
                        "Pabalik na sa base natin ngayon.",
                        "Naiintindihan ko. Babalik sa ligtas na lugar.",
                        "Babalik ako sa silungan natin.",
                        "Pauwi na ako ngayon.",
                        "Pauwi na. Magkita tayo sa kampo.",
                        "Naintindihan. Babalik ako sa base.",
                        "Pabalik na sa himpilan.",
                        "Pauwi na ako. Mag-ingat ka rito.",
                        "Pabalik na sa mga coordinate ng base.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_replies",
        ["domainPath"] = "companion_commands_replies",
        ["exchangeFamily"] = {
            ["familyID"] = "command.reply.stay",
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
                                ["fallback"] = "I'll stay here.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.reply.stay.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'll stay here.",
                                        "Holding position right here.",
                                        "I'll keep watch in this spot.",
                                        "Understood. Standing firm.",
                                        "I won't budge from this area.",
                                        "Holding ground until you return.",
                                        "Staying put. Keep safe.",
                                        "Understood. Guarding this position.",
                                        "I'll stay right here.",
                                        "Holding this spot. Don't take too long.",
                                    },
                                    ["TL"] = {
                                        "Mananatili ako rito.",
                                        "Hawak ko ang pwestong ito.",
                                        "Magbabantay ako sa lugar na 'to.",
                                        "Naiintindihan ko. Nakatayo rito nang matatag.",
                                        "Hindi ako aalis sa lugar na ito.",
                                        "Bantay dito hanggang sa bumalik ka.",
                                        "Dito lang ako. Mag-ingat ka.",
                                        "Naintindihan. Babantayan ang pwestong ito.",
                                        "Dito lang ako.",
                                        "Hawak ko ang pwesto. Huwag kang magtatagal.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.reply",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'll stay here.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.reply.stay.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'll stay here.",
                            "Holding position right here.",
                            "I'll keep watch in this spot.",
                            "Understood. Standing firm.",
                            "I won't budge from this area.",
                            "Holding ground until you return.",
                            "Staying put. Keep safe.",
                            "Understood. Guarding this position.",
                            "I'll stay right here.",
                            "Holding this spot. Don't take too long.",
                        },
                        ["TL"] = {
                            "Mananatili ako rito.",
                            "Hawak ko ang pwestong ito.",
                            "Magbabantay ako sa lugar na 'to.",
                            "Naiintindihan ko. Nakatayo rito nang matatag.",
                            "Hindi ako aalis sa lugar na ito.",
                            "Bantay dito hanggang sa bumalik ka.",
                            "Dito lang ako. Mag-ingat ka.",
                            "Naintindihan. Babantayan ang pwestong ito.",
                            "Dito lang ako.",
                            "Hawak ko ang pwesto. Huwag kang magtatagal.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.reply.stay",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "stay",
            ["sourceId"] = "command.reply.stay",
            ["sourcePath"] = "dialogue/companion_commands_replies/command_reply_stay.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsReplies",
        ["namespace"] = "command.reply",
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
            ["activities"] = {
                {
                    ["id"] = "companion_order",
                    ["role"] = "target",
                },
            },
            ["domains"] = {
                {
                    ["domain"] = "companion_commands",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "REPLY",
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
                                        "I'll stay here.",
                                        "Holding position right here.",
                                        "I'll keep watch in this spot.",
                                        "Understood. Standing firm.",
                                        "I won't budge from this area.",
                                        "Holding ground until you return.",
                                        "Staying put. Keep safe.",
                                        "Understood. Guarding this position.",
                                        "I'll stay right here.",
                                        "Holding this spot. Don't take too long.",
                                    },
                                    ["TL"] = {
                                        "Mananatili ako rito.",
                                        "Hawak ko ang pwestong ito.",
                                        "Magbabantay ako sa lugar na 'to.",
                                        "Naiintindihan ko. Nakatayo rito nang matatag.",
                                        "Hindi ako aalis sa lugar na ito.",
                                        "Bantay dito hanggang sa bumalik ka.",
                                        "Dito lang ako. Mag-ingat ka.",
                                        "Naintindihan. Babantayan ang pwestong ito.",
                                        "Dito lang ako.",
                                        "Hawak ko ang pwesto. Huwag kang magtatagal.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "companion_commands",
                    ["id"] = "companion_command",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REPLY",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.reply.stay",
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
                            ["fallback"] = "I'll stay here.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.command.reply.stay.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_replies/command_reply_stay.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'll stay here.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.reply.stay.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'll stay here.",
                        "Holding position right here.",
                        "I'll keep watch in this spot.",
                        "Understood. Standing firm.",
                        "I won't budge from this area.",
                        "Holding ground until you return.",
                        "Staying put. Keep safe.",
                        "Understood. Guarding this position.",
                        "I'll stay right here.",
                        "Holding this spot. Don't take too long.",
                    },
                    ["TL"] = {
                        "Mananatili ako rito.",
                        "Hawak ko ang pwestong ito.",
                        "Magbabantay ako sa lugar na 'to.",
                        "Naiintindihan ko. Nakatayo rito nang matatag.",
                        "Hindi ako aalis sa lugar na ito.",
                        "Bantay dito hanggang sa bumalik ka.",
                        "Dito lang ako. Mag-ingat ka.",
                        "Naintindihan. Babantayan ang pwestong ito.",
                        "Dito lang ako.",
                        "Hawak ko ang pwesto. Huwag kang magtatagal.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_replies",
        ["domainPath"] = "companion_commands_replies",
        ["exchangeFamily"] = {
            ["familyID"] = "companion.action.responses",
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
                                ["fallback"] = "I can't follow you right now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.companion.action.responses.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I can't follow you right now.",
                                    },
                                    ["TL"] = {
                                        "Hindi kita masusundan ngayon.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "companion.action",
            ["textRoles"] = {
                {
                    ["fallback"] = "I can't follow you right now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.companion.action.responses.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I can't follow you right now.",
                        },
                        ["TL"] = {
                            "Hindi kita masusundan ngayon.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "companion.action.responses",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "responses",
            ["sourceId"] = "companion.action.responses",
            ["sourcePath"] = "dialogue/companion_commands_replies/companion_action_responses.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsReplies",
        ["namespace"] = "companion.action",
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
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_ActionFollowUnavailable",
                        ["text"] = {
                            ["EN"] = "I can't follow you right now.",
                            ["TL"] = "Hindi kita masusundan ngayon.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_ActionStayUnavailable",
                        ["text"] = {
                            ["EN"] = "I can't stay right now.",
                            ["TL"] = "Hindi ako makapananatili ngayon.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_ActionStopUnavailable",
                        ["text"] = {
                            ["EN"] = "I can't stop right now.",
                            ["TL"] = "Hindi ako makahinto ngayon.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_RealizationCompanionFollowGuarded",
                        ["text"] = {
                            ["EN"] = "I'll follow. Stay close.",
                            ["TL"] = "Susunod ako. Manatili kang malapit.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_RealizationCompanionFollowNeutral",
                        ["text"] = {
                            ["EN"] = "Of course, I'll follow.",
                            ["TL"] = "Siyempre, susunod ako.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_RealizationCompanionFollowTerse",
                        ["text"] = {
                            ["EN"] = "I'll follow.",
                            ["TL"] = "Susunod ako.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_RealizationCompanionFollowWarm",
                        ["text"] = {
                            ["EN"] = "Of course, I'll follow you.",
                            ["TL"] = "Siyempre, susunod ako sa iyo.",
                        },
                    },
                },
                ["textTarget"] = "convo/SemanticResponses",
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
                                        "I can't follow you right now.",
                                    },
                                    ["TL"] = {
                                        "Hindi kita masusundan ngayon.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "companion.action.responses",
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
                            ["fallback"] = "I can't follow you right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.companion.action.responses.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_replies/companion_action_responses.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I can't follow you right now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.companion.action.responses.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I can't follow you right now.",
                    },
                    ["TL"] = {
                        "Hindi kita masusundan ngayon.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
