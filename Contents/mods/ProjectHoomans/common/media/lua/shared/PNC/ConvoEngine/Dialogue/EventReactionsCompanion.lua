-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "event_reactions_companion",
        ["exchangeFamily"] = {
            ["familyID"] = "companion.reaction.abandonment",
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
                                ["fallback"] = "Stay with me next time. We watch each other's backs.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.companion.reaction.abandonment.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Stay with me next time. We watch each other's backs.",
                                        "Don't leave me behind like that. We survive together.",
                                        "I almost got swarmed when you ran off. Stick close.",
                                        "We're a team. Don't take off on your own.",
                                        "Where did you go?! You can't just vanish.",
                                        "Next time, warn me before you leave.",
                                        "Thought I was on my own out there. Stay together.",
                                        "Leaving your partner gets people killed. Keep near.",
                                        "Glad you're back, but don't ditch me again.",
                                        "Stick with me. We're stronger as a pair.",
                                    },
                                    ["TL"] = {
                                        "Sumabay ka sa akin sa susunod. Nagbabantayan tayo ng likod.",
                                        "Huwag mo akong iiwan nang gano'n. Sabay tayong mabubuhay.",
                                        "Halos makuyog ako no'ng umalis ka. Dumikit ka lang.",
                                        "Magkasama tayo. Huwag kang aalis nang mag-isa.",
                                        "Saan ka pumunta?! Hindi ka pwedeng mawala na lang.",
                                        "Sa susunod, sabihan mo ako bago ka umalis.",
                                        "Akala ko naiwan na akong mag-isa. Magsama tayo.",
                                        "Ang pag-iwan sa kasama ay nakakamatay. Dumikit ka.",
                                        "Mabuti at bumalik ka, pero huwag mo na akong iiwan ulit.",
                                        "Sumabay ka sa akin. Mas malakas tayo kapag magkasama.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "companion.reaction",
            ["textRoles"] = {
                {
                    ["fallback"] = "Stay with me next time. We watch each other's backs.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.companion.reaction.abandonment.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Stay with me next time. We watch each other's backs.",
                            "Don't leave me behind like that. We survive together.",
                            "I almost got swarmed when you ran off. Stick close.",
                            "We're a team. Don't take off on your own.",
                            "Where did you go?! You can't just vanish.",
                            "Next time, warn me before you leave.",
                            "Thought I was on my own out there. Stay together.",
                            "Leaving your partner gets people killed. Keep near.",
                            "Glad you're back, but don't ditch me again.",
                            "Stick with me. We're stronger as a pair.",
                        },
                        ["TL"] = {
                            "Sumabay ka sa akin sa susunod. Nagbabantayan tayo ng likod.",
                            "Huwag mo akong iiwan nang gano'n. Sabay tayong mabubuhay.",
                            "Halos makuyog ako no'ng umalis ka. Dumikit ka lang.",
                            "Magkasama tayo. Huwag kang aalis nang mag-isa.",
                            "Saan ka pumunta?! Hindi ka pwedeng mawala na lang.",
                            "Sa susunod, sabihan mo ako bago ka umalis.",
                            "Akala ko naiwan na akong mag-isa. Magsama tayo.",
                            "Ang pag-iwan sa kasama ay nakakamatay. Dumikit ka.",
                            "Mabuti at bumalik ka, pero huwag mo na akong iiwan ulit.",
                            "Sumabay ka sa akin. Mas malakas tayo kapag magkasama.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "companion.reaction.abandonment",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "abandonment",
            ["sourceId"] = "companion.reaction.abandonment",
            ["sourcePath"] = "adopters/hoomans/dialogue/event_reactions_companion/companion_reaction_abandonment.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsCompanion",
        ["namespace"] = "companion.reaction",
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
                ["responseAct"] = "REACT",
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
                                        "Stay with me next time. We watch each other's backs.",
                                        "Don't leave me behind like that. We survive together.",
                                        "I almost got swarmed when you ran off. Stick close.",
                                        "We're a team. Don't take off on your own.",
                                        "Where did you go?! You can't just vanish.",
                                        "Next time, warn me before you leave.",
                                        "Thought I was on my own out there. Stay together.",
                                        "Leaving your partner gets people killed. Keep near.",
                                        "Glad you're back, but don't ditch me again.",
                                        "Stick with me. We're stronger as a pair.",
                                    },
                                    ["TL"] = {
                                        "Sumabay ka sa akin sa susunod. Nagbabantayan tayo ng likod.",
                                        "Huwag mo akong iiwan nang gano'n. Sabay tayong mabubuhay.",
                                        "Halos makuyog ako no'ng umalis ka. Dumikit ka lang.",
                                        "Magkasama tayo. Huwag kang aalis nang mag-isa.",
                                        "Saan ka pumunta?! Hindi ka pwedeng mawala na lang.",
                                        "Sa susunod, sabihan mo ako bago ka umalis.",
                                        "Akala ko naiwan na akong mag-isa. Magsama tayo.",
                                        "Ang pag-iwan sa kasama ay nakakamatay. Dumikit ka.",
                                        "Mabuti at bumalik ka, pero huwag mo na akong iiwan ulit.",
                                        "Sumabay ka sa akin. Mas malakas tayo kapag magkasama.",
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
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "companion.reaction.abandonment",
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
                            ["fallback"] = "Stay with me next time. We watch each other's backs.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.companion.reaction.abandonment.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/event_reactions_companion/companion_reaction_abandonment.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Stay with me next time. We watch each other's backs.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.companion.reaction.abandonment.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Stay with me next time. We watch each other's backs.",
                        "Don't leave me behind like that. We survive together.",
                        "I almost got swarmed when you ran off. Stick close.",
                        "We're a team. Don't take off on your own.",
                        "Where did you go?! You can't just vanish.",
                        "Next time, warn me before you leave.",
                        "Thought I was on my own out there. Stay together.",
                        "Leaving your partner gets people killed. Keep near.",
                        "Glad you're back, but don't ditch me again.",
                        "Stick with me. We're stronger as a pair.",
                    },
                    ["TL"] = {
                        "Sumabay ka sa akin sa susunod. Nagbabantayan tayo ng likod.",
                        "Huwag mo akong iiwan nang gano'n. Sabay tayong mabubuhay.",
                        "Halos makuyog ako no'ng umalis ka. Dumikit ka lang.",
                        "Magkasama tayo. Huwag kang aalis nang mag-isa.",
                        "Saan ka pumunta?! Hindi ka pwedeng mawala na lang.",
                        "Sa susunod, sabihan mo ako bago ka umalis.",
                        "Akala ko naiwan na akong mag-isa. Magsama tayo.",
                        "Ang pag-iwan sa kasama ay nakakamatay. Dumikit ka.",
                        "Mabuti at bumalik ka, pero huwag mo na akong iiwan ulit.",
                        "Sumabay ka sa akin. Mas malakas tayo kapag magkasama.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_companion",
        ["exchangeFamily"] = {
            ["familyID"] = "companion.reaction.camp_rejected",
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
                                ["templateID"] = "convo.companion.reaction.camp_rejected.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I can't find a safe room or campfire nearby.",
                                        "Nowhere safe to rest around here. We need better cover.",
                                        "Can't camp in the open like this. Too dangerous.",
                                        "We need walls or a fire before we settle down.",
                                        "This spot isn't secure enough for camp. Keep walking.",
                                        "No shelter here. Let's find four walls first.",
                                        "Can't sleep here. Infected could walk right in.",
                                        "We need a barricaded room or a campfire before resting.",
                                        "Not pitching camp here. Let's find a secure building.",
                                        "Too exposed. Find us a real camp spot.",
                                    },
                                    ["TL"] = {
                                        "Wala akong makitang ligtas na kwarto o campfire sa malapit.",
                                        "Walang ligtas na pahingahan dito. Kailangan natin ng mas maayos na silungan.",
                                        "Hindi pwedeng magkampo sa lantad nang ganito. Masyadong delikado.",
                                        "Kailangan natin ng pader o apoy bago huminto.",
                                        "Hindi sapat ang kaligtasan ng pwestong 'to para sa kampo. Lakad pa.",
                                        "Walang masisilungan dito. Maghanap muna tayo ng apat na pader.",
                                        "Hindi pwedeng matulog dito. Madaling makakapasok ang mga infected.",
                                        "Kailangan natin ng may barikadang kwarto o campfire bago magpahinga.",
                                        "Hindi ako magkakampo rito. Maghanap tayo ng ligtas na gusali.",
                                        "Masyadong lantad. Hanapan mo tayo ng tunay na matutuluyan.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "companion.reaction",
            ["textRoles"] = {
                {
                    ["fallback"] = "I can't find a safe room or campfire nearby.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.companion.reaction.camp_rejected.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I can't find a safe room or campfire nearby.",
                            "Nowhere safe to rest around here. We need better cover.",
                            "Can't camp in the open like this. Too dangerous.",
                            "We need walls or a fire before we settle down.",
                            "This spot isn't secure enough for camp. Keep walking.",
                            "No shelter here. Let's find four walls first.",
                            "Can't sleep here. Infected could walk right in.",
                            "We need a barricaded room or a campfire before resting.",
                            "Not pitching camp here. Let's find a secure building.",
                            "Too exposed. Find us a real camp spot.",
                        },
                        ["TL"] = {
                            "Wala akong makitang ligtas na kwarto o campfire sa malapit.",
                            "Walang ligtas na pahingahan dito. Kailangan natin ng mas maayos na silungan.",
                            "Hindi pwedeng magkampo sa lantad nang ganito. Masyadong delikado.",
                            "Kailangan natin ng pader o apoy bago huminto.",
                            "Hindi sapat ang kaligtasan ng pwestong 'to para sa kampo. Lakad pa.",
                            "Walang masisilungan dito. Maghanap muna tayo ng apat na pader.",
                            "Hindi pwedeng matulog dito. Madaling makakapasok ang mga infected.",
                            "Kailangan natin ng may barikadang kwarto o campfire bago magpahinga.",
                            "Hindi ako magkakampo rito. Maghanap tayo ng ligtas na gusali.",
                            "Masyadong lantad. Hanapan mo tayo ng tunay na matutuluyan.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "companion.reaction.camp_rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "camp_rejected",
            ["sourceId"] = "companion.reaction.camp_rejected",
            ["sourcePath"] = "adopters/hoomans/dialogue/event_reactions_companion/companion_reaction_camp_rejected.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsCompanion",
        ["namespace"] = "companion.reaction",
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
                ["responseAct"] = "REACT",
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
                                        "Nowhere safe to rest around here. We need better cover.",
                                        "Can't camp in the open like this. Too dangerous.",
                                        "We need walls or a fire before we settle down.",
                                        "This spot isn't secure enough for camp. Keep walking.",
                                        "No shelter here. Let's find four walls first.",
                                        "Can't sleep here. Infected could walk right in.",
                                        "We need a barricaded room or a campfire before resting.",
                                        "Not pitching camp here. Let's find a secure building.",
                                        "Too exposed. Find us a real camp spot.",
                                    },
                                    ["TL"] = {
                                        "Wala akong makitang ligtas na kwarto o campfire sa malapit.",
                                        "Walang ligtas na pahingahan dito. Kailangan natin ng mas maayos na silungan.",
                                        "Hindi pwedeng magkampo sa lantad nang ganito. Masyadong delikado.",
                                        "Kailangan natin ng pader o apoy bago huminto.",
                                        "Hindi sapat ang kaligtasan ng pwestong 'to para sa kampo. Lakad pa.",
                                        "Walang masisilungan dito. Maghanap muna tayo ng apat na pader.",
                                        "Hindi pwedeng matulog dito. Madaling makakapasok ang mga infected.",
                                        "Kailangan natin ng may barikadang kwarto o campfire bago magpahinga.",
                                        "Hindi ako magkakampo rito. Maghanap tayo ng ligtas na gusali.",
                                        "Masyadong lantad. Hanapan mo tayo ng tunay na matutuluyan.",
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
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "companion.reaction.camp_rejected",
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
                            ["templateID"] = "convo.companion.reaction.camp_rejected.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/event_reactions_companion/companion_reaction_camp_rejected.json",
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
                ["templateID"] = "convo.companion.reaction.camp_rejected.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I can't find a safe room or campfire nearby.",
                        "Nowhere safe to rest around here. We need better cover.",
                        "Can't camp in the open like this. Too dangerous.",
                        "We need walls or a fire before we settle down.",
                        "This spot isn't secure enough for camp. Keep walking.",
                        "No shelter here. Let's find four walls first.",
                        "Can't sleep here. Infected could walk right in.",
                        "We need a barricaded room or a campfire before resting.",
                        "Not pitching camp here. Let's find a secure building.",
                        "Too exposed. Find us a real camp spot.",
                    },
                    ["TL"] = {
                        "Wala akong makitang ligtas na kwarto o campfire sa malapit.",
                        "Walang ligtas na pahingahan dito. Kailangan natin ng mas maayos na silungan.",
                        "Hindi pwedeng magkampo sa lantad nang ganito. Masyadong delikado.",
                        "Kailangan natin ng pader o apoy bago huminto.",
                        "Hindi sapat ang kaligtasan ng pwestong 'to para sa kampo. Lakad pa.",
                        "Walang masisilungan dito. Maghanap muna tayo ng apat na pader.",
                        "Hindi pwedeng matulog dito. Madaling makakapasok ang mga infected.",
                        "Kailangan natin ng may barikadang kwarto o campfire bago magpahinga.",
                        "Hindi ako magkakampo rito. Maghanap tayo ng ligtas na gusali.",
                        "Masyadong lantad. Hanapan mo tayo ng tunay na matutuluyan.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_companion",
        ["exchangeFamily"] = {
            ["familyID"] = "companion.reaction.default",
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
                                ["fallback"] = "I heard you. We will handle it together.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.companion.reaction.default.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I heard you. We will handle it together.",
                                        "Understood. I'm right here with you.",
                                        "Got your message. Let's get it done.",
                                        "I'm with you. Lead the way.",
                                        "Heard. Whatever comes, we take it on.",
                                        "Copy that. Staying right by your side.",
                                        "I hear you loud and clear. Let's move.",
                                        "Count on me. We're in this together.",
                                        "Understood. Let's keep our heads clear.",
                                        "Right behind you. Let's handle this.",
                                    },
                                    ["TL"] = {
                                        "Narinig kita. Sabay natin 'yang haharapin.",
                                        "Naintindihan ko. Nandito lang ako kasama mo.",
                                        "Nakuha ko ang sabi mo. Tapusin na natin.",
                                        "Kasama mo ako. Ikaw ang manguna.",
                                        "Narinig ko. Kahit ano'ng dumating, lalabanan natin.",
                                        "Kopya. Dito lang ako sa tabi mo.",
                                        "Malinaw kong narinig. Kilos na tayo.",
                                        "Maaasahan mo ako. Magkasama tayo rito.",
                                        "Naiintindihan ko. Panatilihing malinaw ang isip natin.",
                                        "Nasa likod mo lang ako. Asikasuhin natin 'to.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "companion.reaction",
            ["textRoles"] = {
                {
                    ["fallback"] = "I heard you. We will handle it together.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.companion.reaction.default.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I heard you. We will handle it together.",
                            "Understood. I'm right here with you.",
                            "Got your message. Let's get it done.",
                            "I'm with you. Lead the way.",
                            "Heard. Whatever comes, we take it on.",
                            "Copy that. Staying right by your side.",
                            "I hear you loud and clear. Let's move.",
                            "Count on me. We're in this together.",
                            "Understood. Let's keep our heads clear.",
                            "Right behind you. Let's handle this.",
                        },
                        ["TL"] = {
                            "Narinig kita. Sabay natin 'yang haharapin.",
                            "Naintindihan ko. Nandito lang ako kasama mo.",
                            "Nakuha ko ang sabi mo. Tapusin na natin.",
                            "Kasama mo ako. Ikaw ang manguna.",
                            "Narinig ko. Kahit ano'ng dumating, lalabanan natin.",
                            "Kopya. Dito lang ako sa tabi mo.",
                            "Malinaw kong narinig. Kilos na tayo.",
                            "Maaasahan mo ako. Magkasama tayo rito.",
                            "Naiintindihan ko. Panatilihing malinaw ang isip natin.",
                            "Nasa likod mo lang ako. Asikasuhin natin 'to.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "companion.reaction.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "default",
            ["sourceId"] = "companion.reaction.default",
            ["sourcePath"] = "adopters/hoomans/dialogue/event_reactions_companion/companion_reaction_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsCompanion",
        ["namespace"] = "companion.reaction",
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
                ["responseAct"] = "ACK",
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
                                        "I heard you. We will handle it together.",
                                        "Understood. I'm right here with you.",
                                        "Got your message. Let's get it done.",
                                        "I'm with you. Lead the way.",
                                        "Heard. Whatever comes, we take it on.",
                                        "Copy that. Staying right by your side.",
                                        "I hear you loud and clear. Let's move.",
                                        "Count on me. We're in this together.",
                                        "Understood. Let's keep our heads clear.",
                                        "Right behind you. Let's handle this.",
                                    },
                                    ["TL"] = {
                                        "Narinig kita. Sabay natin 'yang haharapin.",
                                        "Naintindihan ko. Nandito lang ako kasama mo.",
                                        "Nakuha ko ang sabi mo. Tapusin na natin.",
                                        "Kasama mo ako. Ikaw ang manguna.",
                                        "Narinig ko. Kahit ano'ng dumating, lalabanan natin.",
                                        "Kopya. Dito lang ako sa tabi mo.",
                                        "Malinaw kong narinig. Kilos na tayo.",
                                        "Maaasahan mo ako. Magkasama tayo rito.",
                                        "Naiintindihan ko. Panatilihing malinaw ang isip natin.",
                                        "Nasa likod mo lang ako. Asikasuhin natin 'to.",
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
            ["dialogueAct"] = "ACK",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "companion.reaction.default",
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
                            ["fallback"] = "I heard you. We will handle it together.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.companion.reaction.default.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/event_reactions_companion/companion_reaction_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I heard you. We will handle it together.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.companion.reaction.default.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I heard you. We will handle it together.",
                        "Understood. I'm right here with you.",
                        "Got your message. Let's get it done.",
                        "I'm with you. Lead the way.",
                        "Heard. Whatever comes, we take it on.",
                        "Copy that. Staying right by your side.",
                        "I hear you loud and clear. Let's move.",
                        "Count on me. We're in this together.",
                        "Understood. Let's keep our heads clear.",
                        "Right behind you. Let's handle this.",
                    },
                    ["TL"] = {
                        "Narinig kita. Sabay natin 'yang haharapin.",
                        "Naintindihan ko. Nandito lang ako kasama mo.",
                        "Nakuha ko ang sabi mo. Tapusin na natin.",
                        "Kasama mo ako. Ikaw ang manguna.",
                        "Narinig ko. Kahit ano'ng dumating, lalabanan natin.",
                        "Kopya. Dito lang ako sa tabi mo.",
                        "Malinaw kong narinig. Kilos na tayo.",
                        "Maaasahan mo ako. Magkasama tayo rito.",
                        "Naiintindihan ko. Panatilihing malinaw ang isip natin.",
                        "Nasa likod mo lang ako. Asikasuhin natin 'to.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
