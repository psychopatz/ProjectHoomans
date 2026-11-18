-- Generated; do not edit by hand.
return {
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
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsReplies/CommandReplyFollowToCompanionActionResponses",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsReplies/CommandReplyFollowToCompanionActionResponses",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsReplies/CommandReplyFollowToCompanionActionResponses",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsReplies/CommandReplyFollowToCompanionActionResponses",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsReplies/CommandReplyFollowToCompanionActionResponses",
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
