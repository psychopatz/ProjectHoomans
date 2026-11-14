-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "event_reactions_safety",
        ["exchangeFamily"] = {
            ["familyID"] = "conversation.safety.danger",
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
                                ["fallback"] = "Watch out. We need to move now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.conversation.safety.danger.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Watch out. We need to move now.",
                                        "Danger close! Move, move!",
                                        "Not safe here. Clear out now.",
                                        "Look around! We need to leave this spot.",
                                        "Infected coming! Get into cover right now.",
                                        "Trouble's right on us. Relocate immediately.",
                                        "Heads up! We're in the open and exposed.",
                                        "Drop what you're doing, we have to move.",
                                        "Danger! Don't freeze up, run!",
                                        "Move now! We're getting cornered.",
                                    },
                                    ["TL"] = {
                                        "Mag-ingat. Kailangan nating kumilos ngayon din.",
                                        "Malapit ang panganib! Kilos, kilos!",
                                        "Hindi ligtas dito. Lumikas na ngayon.",
                                        "Tumingin ka sa paligid! Kailangan nating umalis dito.",
                                        "Paparating ang mga infected! Magtago na ngayon din.",
                                        "Nandito na ang gulo. Lumipat agad.",
                                        "Ulo niyo! Lantad tayo sa bukas na lugar.",
                                        "Bitawan ang ginagawa mo, kailangan nating tumakbo.",
                                        "Panganib! Huwag kang matulala, takbo!",
                                        "Kilos na! Naiipit na tayo.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "conversation.safety",
            ["textRoles"] = {
                {
                    ["fallback"] = "Watch out. We need to move now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.conversation.safety.danger.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Watch out. We need to move now.",
                            "Danger close! Move, move!",
                            "Not safe here. Clear out now.",
                            "Look around! We need to leave this spot.",
                            "Infected coming! Get into cover right now.",
                            "Trouble's right on us. Relocate immediately.",
                            "Heads up! We're in the open and exposed.",
                            "Drop what you're doing, we have to move.",
                            "Danger! Don't freeze up, run!",
                            "Move now! We're getting cornered.",
                        },
                        ["TL"] = {
                            "Mag-ingat. Kailangan nating kumilos ngayon din.",
                            "Malapit ang panganib! Kilos, kilos!",
                            "Hindi ligtas dito. Lumikas na ngayon.",
                            "Tumingin ka sa paligid! Kailangan nating umalis dito.",
                            "Paparating ang mga infected! Magtago na ngayon din.",
                            "Nandito na ang gulo. Lumipat agad.",
                            "Ulo niyo! Lantad tayo sa bukas na lugar.",
                            "Bitawan ang ginagawa mo, kailangan nating tumakbo.",
                            "Panganib! Huwag kang matulala, takbo!",
                            "Kilos na! Naiipit na tayo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "conversation.safety.danger",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "danger",
            ["sourceId"] = "conversation.safety.danger",
            ["sourcePath"] = "adopters/hoomans/dialogue/event_reactions_safety/conversation_safety_danger.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsSafety",
        ["namespace"] = "conversation.safety",
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
                ["category"] = "projecthoomans:event_reactions",
                ["contentOwner"] = "projecthoomans.dialogue_content.events",
                ["responseAct"] = "WARN",
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
                                        "Watch out. We need to move now.",
                                        "Danger close! Move, move!",
                                        "Not safe here. Clear out now.",
                                        "Look around! We need to leave this spot.",
                                        "Infected coming! Get into cover right now.",
                                        "Trouble's right on us. Relocate immediately.",
                                        "Heads up! We're in the open and exposed.",
                                        "Drop what you're doing, we have to move.",
                                        "Danger! Don't freeze up, run!",
                                        "Move now! We're getting cornered.",
                                    },
                                    ["TL"] = {
                                        "Mag-ingat. Kailangan nating kumilos ngayon din.",
                                        "Malapit ang panganib! Kilos, kilos!",
                                        "Hindi ligtas dito. Lumikas na ngayon.",
                                        "Tumingin ka sa paligid! Kailangan nating umalis dito.",
                                        "Paparating ang mga infected! Magtago na ngayon din.",
                                        "Nandito na ang gulo. Lumipat agad.",
                                        "Ulo niyo! Lantad tayo sa bukas na lugar.",
                                        "Bitawan ang ginagawa mo, kailangan nating tumakbo.",
                                        "Panganib! Huwag kang matulala, takbo!",
                                        "Kilos na! Naiipit na tayo.",
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
            ["dialogueAct"] = "WARN",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "conversation.safety.danger",
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
                            ["fallback"] = "Watch out. We need to move now.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.conversation.safety.danger.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/event_reactions_safety/conversation_safety_danger.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Watch out. We need to move now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.conversation.safety.danger.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Watch out. We need to move now.",
                        "Danger close! Move, move!",
                        "Not safe here. Clear out now.",
                        "Look around! We need to leave this spot.",
                        "Infected coming! Get into cover right now.",
                        "Trouble's right on us. Relocate immediately.",
                        "Heads up! We're in the open and exposed.",
                        "Drop what you're doing, we have to move.",
                        "Danger! Don't freeze up, run!",
                        "Move now! We're getting cornered.",
                    },
                    ["TL"] = {
                        "Mag-ingat. Kailangan nating kumilos ngayon din.",
                        "Malapit ang panganib! Kilos, kilos!",
                        "Hindi ligtas dito. Lumikas na ngayon.",
                        "Tumingin ka sa paligid! Kailangan nating umalis dito.",
                        "Paparating ang mga infected! Magtago na ngayon din.",
                        "Nandito na ang gulo. Lumipat agad.",
                        "Ulo niyo! Lantad tayo sa bukas na lugar.",
                        "Bitawan ang ginagawa mo, kailangan nating tumakbo.",
                        "Panganib! Huwag kang matulala, takbo!",
                        "Kilos na! Naiipit na tayo.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_safety",
        ["exchangeFamily"] = {
            ["familyID"] = "conversation.safety.default",
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
                                ["fallback"] = "Stay alert.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.conversation.safety.default.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Stay alert.",
                                        "Keep your eyes peeled.",
                                        "Watch our surroundings.",
                                        "Don't let your guard down.",
                                        "Stay sharp out here.",
                                        "Keep quiet and listen.",
                                        "Keep checking the corners.",
                                        "Stay cautious.",
                                        "Eyes front and back.",
                                        "Stay focused.",
                                    },
                                    ["TL"] = {
                                        "Manatiling alerto.",
                                        "Buksan ang mga mata.",
                                        "Bantayan ang paligid natin.",
                                        "Huwag ibaba ang depensa.",
                                        "Maging handa rito sa labas.",
                                        "Tumahimik at makinig.",
                                        "Tignan palagi ang mga sulok.",
                                        "Mag-ingat palagi.",
                                        "Tumingin sa harap at likod.",
                                        "Manatiling nakapokus.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "conversation.safety",
            ["textRoles"] = {
                {
                    ["fallback"] = "Stay alert.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.conversation.safety.default.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Stay alert.",
                            "Keep your eyes peeled.",
                            "Watch our surroundings.",
                            "Don't let your guard down.",
                            "Stay sharp out here.",
                            "Keep quiet and listen.",
                            "Keep checking the corners.",
                            "Stay cautious.",
                            "Eyes front and back.",
                            "Stay focused.",
                        },
                        ["TL"] = {
                            "Manatiling alerto.",
                            "Buksan ang mga mata.",
                            "Bantayan ang paligid natin.",
                            "Huwag ibaba ang depensa.",
                            "Maging handa rito sa labas.",
                            "Tumahimik at makinig.",
                            "Tignan palagi ang mga sulok.",
                            "Mag-ingat palagi.",
                            "Tumingin sa harap at likod.",
                            "Manatiling nakapokus.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "conversation.safety.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "default",
            ["sourceId"] = "conversation.safety.default",
            ["sourcePath"] = "adopters/hoomans/dialogue/event_reactions_safety/conversation_safety_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsSafety",
        ["namespace"] = "conversation.safety",
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
                ["category"] = "projecthoomans:event_reactions",
                ["contentOwner"] = "projecthoomans.dialogue_content.events",
                ["responseAct"] = "WARN",
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
                                        "Stay alert.",
                                        "Keep your eyes peeled.",
                                        "Watch our surroundings.",
                                        "Don't let your guard down.",
                                        "Stay sharp out here.",
                                        "Keep quiet and listen.",
                                        "Keep checking the corners.",
                                        "Stay cautious.",
                                        "Eyes front and back.",
                                        "Stay focused.",
                                    },
                                    ["TL"] = {
                                        "Manatiling alerto.",
                                        "Buksan ang mga mata.",
                                        "Bantayan ang paligid natin.",
                                        "Huwag ibaba ang depensa.",
                                        "Maging handa rito sa labas.",
                                        "Tumahimik at makinig.",
                                        "Tignan palagi ang mga sulok.",
                                        "Mag-ingat palagi.",
                                        "Tumingin sa harap at likod.",
                                        "Manatiling nakapokus.",
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
            ["dialogueAct"] = "WARN",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "conversation.safety.default",
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
                            ["fallback"] = "Stay alert.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.conversation.safety.default.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/event_reactions_safety/conversation_safety_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Stay alert.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.conversation.safety.default.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Stay alert.",
                        "Keep your eyes peeled.",
                        "Watch our surroundings.",
                        "Don't let your guard down.",
                        "Stay sharp out here.",
                        "Keep quiet and listen.",
                        "Keep checking the corners.",
                        "Stay cautious.",
                        "Eyes front and back.",
                        "Stay focused.",
                    },
                    ["TL"] = {
                        "Manatiling alerto.",
                        "Buksan ang mga mata.",
                        "Bantayan ang paligid natin.",
                        "Huwag ibaba ang depensa.",
                        "Maging handa rito sa labas.",
                        "Tumahimik at makinig.",
                        "Tignan palagi ang mga sulok.",
                        "Mag-ingat palagi.",
                        "Tumingin sa harap at likod.",
                        "Manatiling nakapokus.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
