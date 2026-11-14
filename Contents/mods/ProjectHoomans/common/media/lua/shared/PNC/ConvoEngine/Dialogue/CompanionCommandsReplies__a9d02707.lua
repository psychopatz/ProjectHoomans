-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_replies",
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
            ["localId"] = "return_home",
            ["sourceId"] = "command.reply.return_home",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_replies/command_reply_return_home.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsReplies__a9d02707",
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
                            ["templateID"] = "psdl.command.reply.return_home.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_replies/command_reply_return_home.json",
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
            ["localId"] = "stay",
            ["sourceId"] = "command.reply.stay",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_replies/command_reply_stay.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsReplies__a9d02707",
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
                            ["templateID"] = "psdl.command.reply.stay.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_replies/command_reply_stay.json",
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
}
