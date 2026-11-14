-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_replies",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.horde.ack.avoid_default",
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
                                ["fallback"] = "Copy. We go around.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.horde.ack.avoid_default.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Copy. We go around.",
                                        "Understood. Avoiding the swarm.",
                                        "Bypassing the horde.",
                                        "Taking the side path. Quietly.",
                                        "Copy that. Staying out of their sight line.",
                                        "We'll detour around them.",
                                        "Understood. No engagement.",
                                        "Steering clear of the horde.",
                                        "Copy. Slipping past the dead.",
                                        "Avoiding contact. Lead the way.",
                                    },
                                    ["TL"] = {
                                        "Sige. Iikot tayo.",
                                        "Naintindihan. Iiwasan ang kawan.",
                                        "Lalampasan ang kawan sa malayo.",
                                        "Dadaan sa gilid. Nang tahimik.",
                                        "Kopyado. Lalayo sa paningin nila.",
                                        "Iikot tayo sa paligid nila.",
                                        "Naiintindihan ko. Walang labanang magaganap.",
                                        "Lalayo sa kawan.",
                                        "Sige. Papalusot sa mga patay.",
                                        "Iiwas sa engkwentro. Ituro ang daan.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.horde.ack",
            ["textRoles"] = {
                {
                    ["fallback"] = "Copy. We go around.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.ack.avoid_default.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Copy. We go around.",
                            "Understood. Avoiding the swarm.",
                            "Bypassing the horde.",
                            "Taking the side path. Quietly.",
                            "Copy that. Staying out of their sight line.",
                            "We'll detour around them.",
                            "Understood. No engagement.",
                            "Steering clear of the horde.",
                            "Copy. Slipping past the dead.",
                            "Avoiding contact. Lead the way.",
                        },
                        ["TL"] = {
                            "Sige. Iikot tayo.",
                            "Naintindihan. Iiwasan ang kawan.",
                            "Lalampasan ang kawan sa malayo.",
                            "Dadaan sa gilid. Nang tahimik.",
                            "Kopyado. Lalayo sa paningin nila.",
                            "Iikot tayo sa paligid nila.",
                            "Naiintindihan ko. Walang labanang magaganap.",
                            "Lalayo sa kawan.",
                            "Sige. Papalusot sa mga patay.",
                            "Iiwas sa engkwentro. Ituro ang daan.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.horde.ack.avoid_default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "avoid_default",
            ["sourceId"] = "combat.horde.ack.avoid_default",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_replies/combat_horde_ack_avoid_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsReplies",
        ["namespace"] = "combat.horde.ack",
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
                                        "Copy. We go around.",
                                        "Understood. Avoiding the swarm.",
                                        "Bypassing the horde.",
                                        "Taking the side path. Quietly.",
                                        "Copy that. Staying out of their sight line.",
                                        "We'll detour around them.",
                                        "Understood. No engagement.",
                                        "Steering clear of the horde.",
                                        "Copy. Slipping past the dead.",
                                        "Avoiding contact. Lead the way.",
                                    },
                                    ["TL"] = {
                                        "Sige. Iikot tayo.",
                                        "Naintindihan. Iiwasan ang kawan.",
                                        "Lalampasan ang kawan sa malayo.",
                                        "Dadaan sa gilid. Nang tahimik.",
                                        "Kopyado. Lalayo sa paningin nila.",
                                        "Iikot tayo sa paligid nila.",
                                        "Naiintindihan ko. Walang labanang magaganap.",
                                        "Lalayo sa kawan.",
                                        "Sige. Papalusot sa mga patay.",
                                        "Iiwas sa engkwentro. Ituro ang daan.",
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
            ["responsePlanID"] = "combat.horde.ack.avoid_default",
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
                            ["fallback"] = "Copy. We go around.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.horde.ack.avoid_default.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_replies/combat_horde_ack_avoid_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Copy. We go around.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.ack.avoid_default.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Copy. We go around.",
                        "Understood. Avoiding the swarm.",
                        "Bypassing the horde.",
                        "Taking the side path. Quietly.",
                        "Copy that. Staying out of their sight line.",
                        "We'll detour around them.",
                        "Understood. No engagement.",
                        "Steering clear of the horde.",
                        "Copy. Slipping past the dead.",
                        "Avoiding contact. Lead the way.",
                    },
                    ["TL"] = {
                        "Sige. Iikot tayo.",
                        "Naintindihan. Iiwasan ang kawan.",
                        "Lalampasan ang kawan sa malayo.",
                        "Dadaan sa gilid. Nang tahimik.",
                        "Kopyado. Lalayo sa paningin nila.",
                        "Iikot tayo sa paligid nila.",
                        "Naiintindihan ko. Walang labanang magaganap.",
                        "Lalayo sa kawan.",
                        "Sige. Papalusot sa mga patay.",
                        "Iiwas sa engkwentro. Ituro ang daan.",
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
            ["familyID"] = "combat.horde.ack.avoid_relief",
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
                                ["fallback"] = "Good. Let's go around.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.horde.ack.avoid_relief.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Good. Let's go around.",
                                        "Thank goodness. That pack was massive.",
                                        "Glad you made that call. Slipping away.",
                                        "Smart move. We live to fight another hour.",
                                        "Relieved to hear that. Detouring now.",
                                        "Good choice. Keep it quiet as we skirt past.",
                                        "Much better than dying out here. Moving around.",
                                        "Sigh of relief. Let's keep our heads down.",
                                        "Glad we're avoiding that bloodbath. Lead on.",
                                        "Safe decision. Taking the alternate route.",
                                    },
                                    ["TL"] = {
                                        "Mabuti. Umikot tayo.",
                                        "Salamat sa Diyos. Napakalaki ng kawang 'yon.",
                                        "Mabuti at nagpasya ka ng ganoon. Tatakas na tayo.",
                                        "Matalinong desisyon. Mabubuhay pa tayo sa susunod na oras.",
                                        "Gumaan ang loob ko nang marinig 'yan. Iikot na ngayon.",
                                        "Magandang pasya. Manahimik habang lumalampas.",
                                        "Mas maganda kaysa mamatay dito. Iikot na tayo.",
                                        "Nakahinga nang maluwag. Yumuko tayo.",
                                        "Mabuti at iniwasan natin ang katayang 'yon. Mauna ka na.",
                                        "Ligtas na pasya. Dadaan sa ibang ruta.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.horde.ack",
            ["textRoles"] = {
                {
                    ["fallback"] = "Good. Let's go around.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.ack.avoid_relief.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Good. Let's go around.",
                            "Thank goodness. That pack was massive.",
                            "Glad you made that call. Slipping away.",
                            "Smart move. We live to fight another hour.",
                            "Relieved to hear that. Detouring now.",
                            "Good choice. Keep it quiet as we skirt past.",
                            "Much better than dying out here. Moving around.",
                            "Sigh of relief. Let's keep our heads down.",
                            "Glad we're avoiding that bloodbath. Lead on.",
                            "Safe decision. Taking the alternate route.",
                        },
                        ["TL"] = {
                            "Mabuti. Umikot tayo.",
                            "Salamat sa Diyos. Napakalaki ng kawang 'yon.",
                            "Mabuti at nagpasya ka ng ganoon. Tatakas na tayo.",
                            "Matalinong desisyon. Mabubuhay pa tayo sa susunod na oras.",
                            "Gumaan ang loob ko nang marinig 'yan. Iikot na ngayon.",
                            "Magandang pasya. Manahimik habang lumalampas.",
                            "Mas maganda kaysa mamatay dito. Iikot na tayo.",
                            "Nakahinga nang maluwag. Yumuko tayo.",
                            "Mabuti at iniwasan natin ang katayang 'yon. Mauna ka na.",
                            "Ligtas na pasya. Dadaan sa ibang ruta.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.horde.ack.avoid_relief",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "avoid_relief",
            ["sourceId"] = "combat.horde.ack.avoid_relief",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_replies/combat_horde_ack_avoid_relief.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsReplies",
        ["namespace"] = "combat.horde.ack",
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
                                        "Good. Let's go around.",
                                        "Thank goodness. That pack was massive.",
                                        "Glad you made that call. Slipping away.",
                                        "Smart move. We live to fight another hour.",
                                        "Relieved to hear that. Detouring now.",
                                        "Good choice. Keep it quiet as we skirt past.",
                                        "Much better than dying out here. Moving around.",
                                        "Sigh of relief. Let's keep our heads down.",
                                        "Glad we're avoiding that bloodbath. Lead on.",
                                        "Safe decision. Taking the alternate route.",
                                    },
                                    ["TL"] = {
                                        "Mabuti. Umikot tayo.",
                                        "Salamat sa Diyos. Napakalaki ng kawang 'yon.",
                                        "Mabuti at nagpasya ka ng ganoon. Tatakas na tayo.",
                                        "Matalinong desisyon. Mabubuhay pa tayo sa susunod na oras.",
                                        "Gumaan ang loob ko nang marinig 'yan. Iikot na ngayon.",
                                        "Magandang pasya. Manahimik habang lumalampas.",
                                        "Mas maganda kaysa mamatay dito. Iikot na tayo.",
                                        "Nakahinga nang maluwag. Yumuko tayo.",
                                        "Mabuti at iniwasan natin ang katayang 'yon. Mauna ka na.",
                                        "Ligtas na pasya. Dadaan sa ibang ruta.",
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
            ["responsePlanID"] = "combat.horde.ack.avoid_relief",
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
                            ["fallback"] = "Good. Let's go around.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.horde.ack.avoid_relief.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_replies/combat_horde_ack_avoid_relief.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Good. Let's go around.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.ack.avoid_relief.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Good. Let's go around.",
                        "Thank goodness. That pack was massive.",
                        "Glad you made that call. Slipping away.",
                        "Smart move. We live to fight another hour.",
                        "Relieved to hear that. Detouring now.",
                        "Good choice. Keep it quiet as we skirt past.",
                        "Much better than dying out here. Moving around.",
                        "Sigh of relief. Let's keep our heads down.",
                        "Glad we're avoiding that bloodbath. Lead on.",
                        "Safe decision. Taking the alternate route.",
                    },
                    ["TL"] = {
                        "Mabuti. Umikot tayo.",
                        "Salamat sa Diyos. Napakalaki ng kawang 'yon.",
                        "Mabuti at nagpasya ka ng ganoon. Tatakas na tayo.",
                        "Matalinong desisyon. Mabubuhay pa tayo sa susunod na oras.",
                        "Gumaan ang loob ko nang marinig 'yan. Iikot na ngayon.",
                        "Magandang pasya. Manahimik habang lumalampas.",
                        "Mas maganda kaysa mamatay dito. Iikot na tayo.",
                        "Nakahinga nang maluwag. Yumuko tayo.",
                        "Mabuti at iniwasan natin ang katayang 'yon. Mauna ka na.",
                        "Ligtas na pasya. Dadaan sa ibang ruta.",
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
            ["familyID"] = "combat.horde.ack.engage_default",
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
                                ["fallback"] = "I'm with you. Let's go.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.horde.ack.engage_default.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'm with you. Let's go.",
                                        "Engaging now. Watch your side.",
                                        "Right behind you into the fight.",
                                        "Understood. We fight together.",
                                        "Moving in to strike.",
                                        "Let's clear the way.",
                                        "Ready for combat. Let's do this.",
                                        "On it. Target locked.",
                                        "Moving forward to engage.",
                                        "With you all the way. Let's strike.",
                                    },
                                    ["TL"] = {
                                        "Kasama mo ako. Tara.",
                                        "Lalaban na ngayon. Bantayan ang tagiliran.",
                                        "Nasa likod mo papunta sa laban.",
                                        "Naintindihan. Sabay tayong lalaban.",
                                        "Lalapit para humampas.",
                                        "Hawiin natin ang daan.",
                                        "Handa sa laban. Gawin na natin ito.",
                                        "Inaasikaso na. Nakatutok sa kalaban.",
                                        "Susulong para lumaban.",
                                        "Kasama mo sa buong laban. Sumugod na tayo.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.horde.ack",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm with you. Let's go.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.ack.engage_default.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'm with you. Let's go.",
                            "Engaging now. Watch your side.",
                            "Right behind you into the fight.",
                            "Understood. We fight together.",
                            "Moving in to strike.",
                            "Let's clear the way.",
                            "Ready for combat. Let's do this.",
                            "On it. Target locked.",
                            "Moving forward to engage.",
                            "With you all the way. Let's strike.",
                        },
                        ["TL"] = {
                            "Kasama mo ako. Tara.",
                            "Lalaban na ngayon. Bantayan ang tagiliran.",
                            "Nasa likod mo papunta sa laban.",
                            "Naintindihan. Sabay tayong lalaban.",
                            "Lalapit para humampas.",
                            "Hawiin natin ang daan.",
                            "Handa sa laban. Gawin na natin ito.",
                            "Inaasikaso na. Nakatutok sa kalaban.",
                            "Susulong para lumaban.",
                            "Kasama mo sa buong laban. Sumugod na tayo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.horde.ack.engage_default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "engage_default",
            ["sourceId"] = "combat.horde.ack.engage_default",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_replies/combat_horde_ack_engage_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsReplies",
        ["namespace"] = "combat.horde.ack",
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
                                        "I'm with you. Let's go.",
                                        "Engaging now. Watch your side.",
                                        "Right behind you into the fight.",
                                        "Understood. We fight together.",
                                        "Moving in to strike.",
                                        "Let's clear the way.",
                                        "Ready for combat. Let's do this.",
                                        "On it. Target locked.",
                                        "Moving forward to engage.",
                                        "With you all the way. Let's strike.",
                                    },
                                    ["TL"] = {
                                        "Kasama mo ako. Tara.",
                                        "Lalaban na ngayon. Bantayan ang tagiliran.",
                                        "Nasa likod mo papunta sa laban.",
                                        "Naintindihan. Sabay tayong lalaban.",
                                        "Lalapit para humampas.",
                                        "Hawiin natin ang daan.",
                                        "Handa sa laban. Gawin na natin ito.",
                                        "Inaasikaso na. Nakatutok sa kalaban.",
                                        "Susulong para lumaban.",
                                        "Kasama mo sa buong laban. Sumugod na tayo.",
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
            ["responsePlanID"] = "combat.horde.ack.engage_default",
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
                            ["fallback"] = "I'm with you. Let's go.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.horde.ack.engage_default.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_replies/combat_horde_ack_engage_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm with you. Let's go.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.ack.engage_default.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'm with you. Let's go.",
                        "Engaging now. Watch your side.",
                        "Right behind you into the fight.",
                        "Understood. We fight together.",
                        "Moving in to strike.",
                        "Let's clear the way.",
                        "Ready for combat. Let's do this.",
                        "On it. Target locked.",
                        "Moving forward to engage.",
                        "With you all the way. Let's strike.",
                    },
                    ["TL"] = {
                        "Kasama mo ako. Tara.",
                        "Lalaban na ngayon. Bantayan ang tagiliran.",
                        "Nasa likod mo papunta sa laban.",
                        "Naintindihan. Sabay tayong lalaban.",
                        "Lalapit para humampas.",
                        "Hawiin natin ang daan.",
                        "Handa sa laban. Gawin na natin ito.",
                        "Inaasikaso na. Nakatutok sa kalaban.",
                        "Susulong para lumaban.",
                        "Kasama mo sa buong laban. Sumugod na tayo.",
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
            ["familyID"] = "combat.horde.ack.engage_eager",
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
                                ["fallback"] = "Ready to strike! Let's take them down.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.horde.ack.engage_eager.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Ready to strike! Let's take them down.",
                                        "Let's go! I've got your back.",
                                        "Ready when you are! Charge!",
                                        "Line them up! We can clear this whole pack.",
                                        "Eager and armed. Let's do some damage.",
                                        "I'm ready to fight! Moving in!",
                                        "Let's smash through them together!",
                                        "Weapon's ready. Let's take the field!",
                                        "Full speed ahead! They won't know what hit them.",
                                        "Hell yeah! Let's wipe them out.",
                                    },
                                    ["TL"] = {
                                        "Handa nang humampas! Patumbahin natin sila.",
                                        "Tara na! Hawak ko ang likod mo.",
                                        "Handa na ako kapag handa ka na! Sugod!",
                                        "Pilahin sila! Kaya nating ubusin ang buong kawan.",
                                        "Sabik at armado. Manalanta na tayo.",
                                        "Handa na akong lumaban! Susulong na!",
                                        "Durogin natin sila nang sabay!",
                                        "Handa ang armas. Angkinin natin ang labanan!",
                                        "Buong bilis pasulong! Di nila malalaman ang tumama sa kanila.",
                                        "Oo naman! Ubusin natin sila.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.horde.ack",
            ["textRoles"] = {
                {
                    ["fallback"] = "Ready to strike! Let's take them down.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.ack.engage_eager.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Ready to strike! Let's take them down.",
                            "Let's go! I've got your back.",
                            "Ready when you are! Charge!",
                            "Line them up! We can clear this whole pack.",
                            "Eager and armed. Let's do some damage.",
                            "I'm ready to fight! Moving in!",
                            "Let's smash through them together!",
                            "Weapon's ready. Let's take the field!",
                            "Full speed ahead! They won't know what hit them.",
                            "Hell yeah! Let's wipe them out.",
                        },
                        ["TL"] = {
                            "Handa nang humampas! Patumbahin natin sila.",
                            "Tara na! Hawak ko ang likod mo.",
                            "Handa na ako kapag handa ka na! Sugod!",
                            "Pilahin sila! Kaya nating ubusin ang buong kawan.",
                            "Sabik at armado. Manalanta na tayo.",
                            "Handa na akong lumaban! Susulong na!",
                            "Durogin natin sila nang sabay!",
                            "Handa ang armas. Angkinin natin ang labanan!",
                            "Buong bilis pasulong! Di nila malalaman ang tumama sa kanila.",
                            "Oo naman! Ubusin natin sila.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.horde.ack.engage_eager",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "engage_eager",
            ["sourceId"] = "combat.horde.ack.engage_eager",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_replies/combat_horde_ack_engage_eager.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsReplies",
        ["namespace"] = "combat.horde.ack",
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
                                        "Ready to strike! Let's take them down.",
                                        "Let's go! I've got your back.",
                                        "Ready when you are! Charge!",
                                        "Line them up! We can clear this whole pack.",
                                        "Eager and armed. Let's do some damage.",
                                        "I'm ready to fight! Moving in!",
                                        "Let's smash through them together!",
                                        "Weapon's ready. Let's take the field!",
                                        "Full speed ahead! They won't know what hit them.",
                                        "Hell yeah! Let's wipe them out.",
                                    },
                                    ["TL"] = {
                                        "Handa nang humampas! Patumbahin natin sila.",
                                        "Tara na! Hawak ko ang likod mo.",
                                        "Handa na ako kapag handa ka na! Sugod!",
                                        "Pilahin sila! Kaya nating ubusin ang buong kawan.",
                                        "Sabik at armado. Manalanta na tayo.",
                                        "Handa na akong lumaban! Susulong na!",
                                        "Durogin natin sila nang sabay!",
                                        "Handa ang armas. Angkinin natin ang labanan!",
                                        "Buong bilis pasulong! Di nila malalaman ang tumama sa kanila.",
                                        "Oo naman! Ubusin natin sila.",
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
            ["responsePlanID"] = "combat.horde.ack.engage_eager",
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
                            ["fallback"] = "Ready to strike! Let's take them down.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.horde.ack.engage_eager.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_replies/combat_horde_ack_engage_eager.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Ready to strike! Let's take them down.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.ack.engage_eager.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Ready to strike! Let's take them down.",
                        "Let's go! I've got your back.",
                        "Ready when you are! Charge!",
                        "Line them up! We can clear this whole pack.",
                        "Eager and armed. Let's do some damage.",
                        "I'm ready to fight! Moving in!",
                        "Let's smash through them together!",
                        "Weapon's ready. Let's take the field!",
                        "Full speed ahead! They won't know what hit them.",
                        "Hell yeah! Let's wipe them out.",
                    },
                    ["TL"] = {
                        "Handa nang humampas! Patumbahin natin sila.",
                        "Tara na! Hawak ko ang likod mo.",
                        "Handa na ako kapag handa ka na! Sugod!",
                        "Pilahin sila! Kaya nating ubusin ang buong kawan.",
                        "Sabik at armado. Manalanta na tayo.",
                        "Handa na akong lumaban! Susulong na!",
                        "Durogin natin sila nang sabay!",
                        "Handa ang armas. Angkinin natin ang labanan!",
                        "Buong bilis pasulong! Di nila malalaman ang tumama sa kanila.",
                        "Oo naman! Ubusin natin sila.",
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
            ["familyID"] = "combat.horde.ack.engage_hesitant",
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
                                ["fallback"] = "If you say so... alright. I'm with you.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.horde.ack.engage_hesitant.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "If you say so... alright. I'm with you.",
                                        "This is reckless, but I won't abandon you.",
                                        "I have a bad feeling about this, but I'm in.",
                                        "Watch my back... here we go.",
                                        "I hope you know what you're doing. Moving in.",
                                        "Not loving these odds, but I'll fight beside you.",
                                        "Hesitant, but committed. Stay close.",
                                        "Alright... just don't let them flank us.",
                                        "Stepping into the meat grinder. Let's make it out alive.",
                                        "Okay... I trust your blade. Let's go.",
                                    },
                                    ["TL"] = {
                                        "Kung sinasabi mo... sige. Kasama mo ako.",
                                        "Kapusukan ito, pero hindi kita iiwan.",
                                        "Masama ang kutob ko rito, pero sasama ako.",
                                        "Bantayan mo ang likod ko... heto na tayo.",
                                        "Sana alam mo ang ginagawa mo. Susulong na.",
                                        "Di maganda ang tsansa, pero lalaban ako sa tabi mo.",
                                        "Nag-aalangan, pero sasabak. Dumikit ka.",
                                        "Sige... huwag mo lang silang hayaang pumaligid.",
                                        "Papasok sa gilingan ng karne. Tiyakin nating makalabas nang buhay.",
                                        "Sige... tiwala ako sa talim mo. Tara.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.horde.ack",
            ["textRoles"] = {
                {
                    ["fallback"] = "If you say so... alright. I'm with you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.ack.engage_hesitant.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "If you say so... alright. I'm with you.",
                            "This is reckless, but I won't abandon you.",
                            "I have a bad feeling about this, but I'm in.",
                            "Watch my back... here we go.",
                            "I hope you know what you're doing. Moving in.",
                            "Not loving these odds, but I'll fight beside you.",
                            "Hesitant, but committed. Stay close.",
                            "Alright... just don't let them flank us.",
                            "Stepping into the meat grinder. Let's make it out alive.",
                            "Okay... I trust your blade. Let's go.",
                        },
                        ["TL"] = {
                            "Kung sinasabi mo... sige. Kasama mo ako.",
                            "Kapusukan ito, pero hindi kita iiwan.",
                            "Masama ang kutob ko rito, pero sasama ako.",
                            "Bantayan mo ang likod ko... heto na tayo.",
                            "Sana alam mo ang ginagawa mo. Susulong na.",
                            "Di maganda ang tsansa, pero lalaban ako sa tabi mo.",
                            "Nag-aalangan, pero sasabak. Dumikit ka.",
                            "Sige... huwag mo lang silang hayaang pumaligid.",
                            "Papasok sa gilingan ng karne. Tiyakin nating makalabas nang buhay.",
                            "Sige... tiwala ako sa talim mo. Tara.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.horde.ack.engage_hesitant",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "engage_hesitant",
            ["sourceId"] = "combat.horde.ack.engage_hesitant",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_replies/combat_horde_ack_engage_hesitant.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsReplies",
        ["namespace"] = "combat.horde.ack",
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
                                        "If you say so... alright. I'm with you.",
                                        "This is reckless, but I won't abandon you.",
                                        "I have a bad feeling about this, but I'm in.",
                                        "Watch my back... here we go.",
                                        "I hope you know what you're doing. Moving in.",
                                        "Not loving these odds, but I'll fight beside you.",
                                        "Hesitant, but committed. Stay close.",
                                        "Alright... just don't let them flank us.",
                                        "Stepping into the meat grinder. Let's make it out alive.",
                                        "Okay... I trust your blade. Let's go.",
                                    },
                                    ["TL"] = {
                                        "Kung sinasabi mo... sige. Kasama mo ako.",
                                        "Kapusukan ito, pero hindi kita iiwan.",
                                        "Masama ang kutob ko rito, pero sasama ako.",
                                        "Bantayan mo ang likod ko... heto na tayo.",
                                        "Sana alam mo ang ginagawa mo. Susulong na.",
                                        "Di maganda ang tsansa, pero lalaban ako sa tabi mo.",
                                        "Nag-aalangan, pero sasabak. Dumikit ka.",
                                        "Sige... huwag mo lang silang hayaang pumaligid.",
                                        "Papasok sa gilingan ng karne. Tiyakin nating makalabas nang buhay.",
                                        "Sige... tiwala ako sa talim mo. Tara.",
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
            ["responsePlanID"] = "combat.horde.ack.engage_hesitant",
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
                            ["fallback"] = "If you say so... alright. I'm with you.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.horde.ack.engage_hesitant.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_replies/combat_horde_ack_engage_hesitant.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "If you say so... alright. I'm with you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.ack.engage_hesitant.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "If you say so... alright. I'm with you.",
                        "This is reckless, but I won't abandon you.",
                        "I have a bad feeling about this, but I'm in.",
                        "Watch my back... here we go.",
                        "I hope you know what you're doing. Moving in.",
                        "Not loving these odds, but I'll fight beside you.",
                        "Hesitant, but committed. Stay close.",
                        "Alright... just don't let them flank us.",
                        "Stepping into the meat grinder. Let's make it out alive.",
                        "Okay... I trust your blade. Let's go.",
                    },
                    ["TL"] = {
                        "Kung sinasabi mo... sige. Kasama mo ako.",
                        "Kapusukan ito, pero hindi kita iiwan.",
                        "Masama ang kutob ko rito, pero sasama ako.",
                        "Bantayan mo ang likod ko... heto na tayo.",
                        "Sana alam mo ang ginagawa mo. Susulong na.",
                        "Di maganda ang tsansa, pero lalaban ako sa tabi mo.",
                        "Nag-aalangan, pero sasabak. Dumikit ka.",
                        "Sige... huwag mo lang silang hayaang pumaligid.",
                        "Papasok sa gilingan ng karne. Tiyakin nating makalabas nang buhay.",
                        "Sige... tiwala ako sa talim mo. Tara.",
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
            ["familyID"] = "combat.horde.ack.engage_reserved",
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
                                ["fallback"] = "Alright. Moving.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.horde.ack.engage_reserved.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Alright. Moving.",
                                        "Advancing cautiously.",
                                        "Understood. Engaging the horde.",
                                        "In position. Moving to attack.",
                                        "Weapon drawn. Advancing in formation.",
                                        "Calculated engagement. Let's do this clean.",
                                        "Order received. Stepping up to fight.",
                                        "Keeping rhythm. Engaging targets.",
                                        "Moving into range. Weapons up.",
                                        "Understood. Entering the fray.",
                                    },
                                    ["TL"] = {
                                        "Sige. Galaw.",
                                        "Susulong nang maingat.",
                                        "Naintindihan. Lalabanan ang kawan.",
                                        "Nasa pwesto. Kikilos para umatake.",
                                        "Nakahugot ang armas. Susulong sa pormasyon.",
                                        "Planadong paglusob. Gawin nating malinis.",
                                        "Utos natanggap. Tatayo para lumaban.",
                                        "Panatilihin ang ritmo. Lalabanan ang puntirya.",
                                        "Pumapasok sa sakop. Itaas ang armas.",
                                        "Naiintindihan ko. Papatungo na sa bakbakan.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.horde.ack",
            ["textRoles"] = {
                {
                    ["fallback"] = "Alright. Moving.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.ack.engage_reserved.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Alright. Moving.",
                            "Advancing cautiously.",
                            "Understood. Engaging the horde.",
                            "In position. Moving to attack.",
                            "Weapon drawn. Advancing in formation.",
                            "Calculated engagement. Let's do this clean.",
                            "Order received. Stepping up to fight.",
                            "Keeping rhythm. Engaging targets.",
                            "Moving into range. Weapons up.",
                            "Understood. Entering the fray.",
                        },
                        ["TL"] = {
                            "Sige. Galaw.",
                            "Susulong nang maingat.",
                            "Naintindihan. Lalabanan ang kawan.",
                            "Nasa pwesto. Kikilos para umatake.",
                            "Nakahugot ang armas. Susulong sa pormasyon.",
                            "Planadong paglusob. Gawin nating malinis.",
                            "Utos natanggap. Tatayo para lumaban.",
                            "Panatilihin ang ritmo. Lalabanan ang puntirya.",
                            "Pumapasok sa sakop. Itaas ang armas.",
                            "Naiintindihan ko. Papatungo na sa bakbakan.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.horde.ack.engage_reserved",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "engage_reserved",
            ["sourceId"] = "combat.horde.ack.engage_reserved",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_replies/combat_horde_ack_engage_reserved.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsReplies",
        ["namespace"] = "combat.horde.ack",
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
                                        "Alright. Moving.",
                                        "Advancing cautiously.",
                                        "Understood. Engaging the horde.",
                                        "In position. Moving to attack.",
                                        "Weapon drawn. Advancing in formation.",
                                        "Calculated engagement. Let's do this clean.",
                                        "Order received. Stepping up to fight.",
                                        "Keeping rhythm. Engaging targets.",
                                        "Moving into range. Weapons up.",
                                        "Understood. Entering the fray.",
                                    },
                                    ["TL"] = {
                                        "Sige. Galaw.",
                                        "Susulong nang maingat.",
                                        "Naintindihan. Lalabanan ang kawan.",
                                        "Nasa pwesto. Kikilos para umatake.",
                                        "Nakahugot ang armas. Susulong sa pormasyon.",
                                        "Planadong paglusob. Gawin nating malinis.",
                                        "Utos natanggap. Tatayo para lumaban.",
                                        "Panatilihin ang ritmo. Lalabanan ang puntirya.",
                                        "Pumapasok sa sakop. Itaas ang armas.",
                                        "Naiintindihan ko. Papatungo na sa bakbakan.",
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
            ["responsePlanID"] = "combat.horde.ack.engage_reserved",
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
                            ["fallback"] = "Alright. Moving.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.horde.ack.engage_reserved.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_replies/combat_horde_ack_engage_reserved.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Alright. Moving.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.ack.engage_reserved.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Alright. Moving.",
                        "Advancing cautiously.",
                        "Understood. Engaging the horde.",
                        "In position. Moving to attack.",
                        "Weapon drawn. Advancing in formation.",
                        "Calculated engagement. Let's do this clean.",
                        "Order received. Stepping up to fight.",
                        "Keeping rhythm. Engaging targets.",
                        "Moving into range. Weapons up.",
                        "Understood. Entering the fray.",
                    },
                    ["TL"] = {
                        "Sige. Galaw.",
                        "Susulong nang maingat.",
                        "Naintindihan. Lalabanan ang kawan.",
                        "Nasa pwesto. Kikilos para umatake.",
                        "Nakahugot ang armas. Susulong sa pormasyon.",
                        "Planadong paglusob. Gawin nating malinis.",
                        "Utos natanggap. Tatayo para lumaban.",
                        "Panatilihin ang ritmo. Lalabanan ang puntirya.",
                        "Pumapasok sa sakop. Itaas ang armas.",
                        "Naiintindihan ko. Papatungo na sa bakbakan.",
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
            ["familyID"] = "combat.horde.ack.hold_default",
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
                                ["fallback"] = "Holding for now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.horde.ack.hold_default.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Holding for now.",
                                        "Holding position. Watching the herd.",
                                        "Staying put until you signal.",
                                        "Understood. Standing by.",
                                        "Holding ground right here.",
                                        "Position held. Awaiting order.",
                                        "Holding. Observing threat movement.",
                                        "Steady in place.",
                                        "Maintaining position.",
                                        "Holding. Let's see what they do.",
                                    },
                                    ["TL"] = {
                                        "Hinto muna tayo.",
                                        "Hawak ang pwesto. Binabantayan ang kawan.",
                                        "Dito lang hanggang sumenyas ka.",
                                        "Naiintindihan ko. Nakahanda.",
                                        "Hawak ang lupa dito mismo.",
                                        "Nasa pwesto. Naghihintay ng utos.",
                                        "Hawak muna. Minamasid ang galaw ng banta.",
                                        "Matatag sa pwesto.",
                                        "Pinananatili ang posisyon.",
                                        "Tigil muna. Tingnan natin ang gagawin nila.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.horde.ack",
            ["textRoles"] = {
                {
                    ["fallback"] = "Holding for now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.ack.hold_default.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Holding for now.",
                            "Holding position. Watching the herd.",
                            "Staying put until you signal.",
                            "Understood. Standing by.",
                            "Holding ground right here.",
                            "Position held. Awaiting order.",
                            "Holding. Observing threat movement.",
                            "Steady in place.",
                            "Maintaining position.",
                            "Holding. Let's see what they do.",
                        },
                        ["TL"] = {
                            "Hinto muna tayo.",
                            "Hawak ang pwesto. Binabantayan ang kawan.",
                            "Dito lang hanggang sumenyas ka.",
                            "Naiintindihan ko. Nakahanda.",
                            "Hawak ang lupa dito mismo.",
                            "Nasa pwesto. Naghihintay ng utos.",
                            "Hawak muna. Minamasid ang galaw ng banta.",
                            "Matatag sa pwesto.",
                            "Pinananatili ang posisyon.",
                            "Tigil muna. Tingnan natin ang gagawin nila.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.horde.ack.hold_default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "hold_default",
            ["sourceId"] = "combat.horde.ack.hold_default",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_replies/combat_horde_ack_hold_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsReplies",
        ["namespace"] = "combat.horde.ack",
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
                                        "Holding for now.",
                                        "Holding position. Watching the herd.",
                                        "Staying put until you signal.",
                                        "Understood. Standing by.",
                                        "Holding ground right here.",
                                        "Position held. Awaiting order.",
                                        "Holding. Observing threat movement.",
                                        "Steady in place.",
                                        "Maintaining position.",
                                        "Holding. Let's see what they do.",
                                    },
                                    ["TL"] = {
                                        "Hinto muna tayo.",
                                        "Hawak ang pwesto. Binabantayan ang kawan.",
                                        "Dito lang hanggang sumenyas ka.",
                                        "Naiintindihan ko. Nakahanda.",
                                        "Hawak ang lupa dito mismo.",
                                        "Nasa pwesto. Naghihintay ng utos.",
                                        "Hawak muna. Minamasid ang galaw ng banta.",
                                        "Matatag sa pwesto.",
                                        "Pinananatili ang posisyon.",
                                        "Tigil muna. Tingnan natin ang gagawin nila.",
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
            ["responsePlanID"] = "combat.horde.ack.hold_default",
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
                            ["fallback"] = "Holding for now.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.horde.ack.hold_default.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_replies/combat_horde_ack_hold_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Holding for now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.ack.hold_default.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Holding for now.",
                        "Holding position. Watching the herd.",
                        "Staying put until you signal.",
                        "Understood. Standing by.",
                        "Holding ground right here.",
                        "Position held. Awaiting order.",
                        "Holding. Observing threat movement.",
                        "Steady in place.",
                        "Maintaining position.",
                        "Holding. Let's see what they do.",
                    },
                    ["TL"] = {
                        "Hinto muna tayo.",
                        "Hawak ang pwesto. Binabantayan ang kawan.",
                        "Dito lang hanggang sumenyas ka.",
                        "Naiintindihan ko. Nakahanda.",
                        "Hawak ang lupa dito mismo.",
                        "Nasa pwesto. Naghihintay ng utos.",
                        "Hawak muna. Minamasid ang galaw ng banta.",
                        "Matatag sa pwesto.",
                        "Pinananatili ang posisyon.",
                        "Tigil muna. Tingnan natin ang gagawin nila.",
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
            ["familyID"] = "combat.horde.ack.hold_eager",
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
                                ["fallback"] = "Holding. Say when.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.horde.ack.hold_eager.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Holding. Say when.",
                                        "Ready on your mark! Holding position.",
                                        "Coiled like a spring. Just give the word.",
                                        "Holding fire, but twitching to go.",
                                        "Ready to pounce. Standing by.",
                                        "I'm locked on! Say the word and I strike.",
                                        "Holding here. Don't make me wait too long!",
                                        "Ready and waiting! Give the signal.",
                                        "Poised to attack. Holding ground.",
                                        "Just say the word. I'm ready.",
                                    },
                                    ["TL"] = {
                                        "Hawak muna. Sabihin mo kung kailan.",
                                        "Handa sa hudyat mo! Hawak ang pwesto.",
                                        "Nakahandang sumugod. Sabihin mo lang.",
                                        "Tigil-putok, pero sabik nang sumugod.",
                                        "Handang lumundag. Naghihintay.",
                                        "Nakatutok na! Sabihin mo lang at aatake ako.",
                                        "Dito muna. Huwag mo akong paghintayin nang matagal!",
                                        "Handa at naghihintay! Ibigay ang senyas.",
                                        "Handang sumugod. Hawak ang lupa.",
                                        "Sabihin mo lang. Handa na ako.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.horde.ack",
            ["textRoles"] = {
                {
                    ["fallback"] = "Holding. Say when.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.ack.hold_eager.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Holding. Say when.",
                            "Ready on your mark! Holding position.",
                            "Coiled like a spring. Just give the word.",
                            "Holding fire, but twitching to go.",
                            "Ready to pounce. Standing by.",
                            "I'm locked on! Say the word and I strike.",
                            "Holding here. Don't make me wait too long!",
                            "Ready and waiting! Give the signal.",
                            "Poised to attack. Holding ground.",
                            "Just say the word. I'm ready.",
                        },
                        ["TL"] = {
                            "Hawak muna. Sabihin mo kung kailan.",
                            "Handa sa hudyat mo! Hawak ang pwesto.",
                            "Nakahandang sumugod. Sabihin mo lang.",
                            "Tigil-putok, pero sabik nang sumugod.",
                            "Handang lumundag. Naghihintay.",
                            "Nakatutok na! Sabihin mo lang at aatake ako.",
                            "Dito muna. Huwag mo akong paghintayin nang matagal!",
                            "Handa at naghihintay! Ibigay ang senyas.",
                            "Handang sumugod. Hawak ang lupa.",
                            "Sabihin mo lang. Handa na ako.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.horde.ack.hold_eager",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "hold_eager",
            ["sourceId"] = "combat.horde.ack.hold_eager",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_replies/combat_horde_ack_hold_eager.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsReplies",
        ["namespace"] = "combat.horde.ack",
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
                                        "Holding. Say when.",
                                        "Ready on your mark! Holding position.",
                                        "Coiled like a spring. Just give the word.",
                                        "Holding fire, but twitching to go.",
                                        "Ready to pounce. Standing by.",
                                        "I'm locked on! Say the word and I strike.",
                                        "Holding here. Don't make me wait too long!",
                                        "Ready and waiting! Give the signal.",
                                        "Poised to attack. Holding ground.",
                                        "Just say the word. I'm ready.",
                                    },
                                    ["TL"] = {
                                        "Hawak muna. Sabihin mo kung kailan.",
                                        "Handa sa hudyat mo! Hawak ang pwesto.",
                                        "Nakahandang sumugod. Sabihin mo lang.",
                                        "Tigil-putok, pero sabik nang sumugod.",
                                        "Handang lumundag. Naghihintay.",
                                        "Nakatutok na! Sabihin mo lang at aatake ako.",
                                        "Dito muna. Huwag mo akong paghintayin nang matagal!",
                                        "Handa at naghihintay! Ibigay ang senyas.",
                                        "Handang sumugod. Hawak ang lupa.",
                                        "Sabihin mo lang. Handa na ako.",
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
            ["responsePlanID"] = "combat.horde.ack.hold_eager",
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
                            ["fallback"] = "Holding. Say when.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.horde.ack.hold_eager.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_replies/combat_horde_ack_hold_eager.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Holding. Say when.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.ack.hold_eager.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Holding. Say when.",
                        "Ready on your mark! Holding position.",
                        "Coiled like a spring. Just give the word.",
                        "Holding fire, but twitching to go.",
                        "Ready to pounce. Standing by.",
                        "I'm locked on! Say the word and I strike.",
                        "Holding here. Don't make me wait too long!",
                        "Ready and waiting! Give the signal.",
                        "Poised to attack. Holding ground.",
                        "Just say the word. I'm ready.",
                    },
                    ["TL"] = {
                        "Hawak muna. Sabihin mo kung kailan.",
                        "Handa sa hudyat mo! Hawak ang pwesto.",
                        "Nakahandang sumugod. Sabihin mo lang.",
                        "Tigil-putok, pero sabik nang sumugod.",
                        "Handang lumundag. Naghihintay.",
                        "Nakatutok na! Sabihin mo lang at aatake ako.",
                        "Dito muna. Huwag mo akong paghintayin nang matagal!",
                        "Handa at naghihintay! Ibigay ang senyas.",
                        "Handang sumugod. Hawak ang lupa.",
                        "Sabihin mo lang. Handa na ako.",
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
            ["familyID"] = "combat.horde.ack.hold_hesitant",
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
                                ["fallback"] = "Okay. Holding here.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.horde.ack.hold_hesitant.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Okay. Holding here.",
                                        "Staying put. I hope they don't see us.",
                                        "Holding position... please be quiet.",
                                        "Holding ground. Heart's pounding.",
                                        "I'll wait here, but let's be careful.",
                                        "Staying still. Don't make a sound.",
                                        "Holding... waiting for your call.",
                                        "Keeping low. I hope this works.",
                                        "Holding here. Watching their claws.",
                                        "Understood... staying frozen right here.",
                                    },
                                    ["TL"] = {
                                        "Sige. Dito muna ako.",
                                        "Dito lang ako. Sana di nila tayo makita.",
                                        "Hawak ang pwesto... pakiusap tumahimik.",
                                        "Hawak ang pwesto. Lumalakas ang tibok ng puso ko.",
                                        "Maghihintay ako rito, pero mag-ingat tayo.",
                                        "Walang kikilos. Huwag gagawa ng tunog.",
                                        "Hawak muna... naghihintay sa utos mo.",
                                        "Nakayuko. Sana magtagumpay ito.",
                                        "Hawak dito. Binabantayan ang kuko nila.",
                                        "Naintindihan... di gagalaw dito mismo.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.horde.ack",
            ["textRoles"] = {
                {
                    ["fallback"] = "Okay. Holding here.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.ack.hold_hesitant.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Okay. Holding here.",
                            "Staying put. I hope they don't see us.",
                            "Holding position... please be quiet.",
                            "Holding ground. Heart's pounding.",
                            "I'll wait here, but let's be careful.",
                            "Staying still. Don't make a sound.",
                            "Holding... waiting for your call.",
                            "Keeping low. I hope this works.",
                            "Holding here. Watching their claws.",
                            "Understood... staying frozen right here.",
                        },
                        ["TL"] = {
                            "Sige. Dito muna ako.",
                            "Dito lang ako. Sana di nila tayo makita.",
                            "Hawak ang pwesto... pakiusap tumahimik.",
                            "Hawak ang pwesto. Lumalakas ang tibok ng puso ko.",
                            "Maghihintay ako rito, pero mag-ingat tayo.",
                            "Walang kikilos. Huwag gagawa ng tunog.",
                            "Hawak muna... naghihintay sa utos mo.",
                            "Nakayuko. Sana magtagumpay ito.",
                            "Hawak dito. Binabantayan ang kuko nila.",
                            "Naintindihan... di gagalaw dito mismo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.horde.ack.hold_hesitant",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "hold_hesitant",
            ["sourceId"] = "combat.horde.ack.hold_hesitant",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_replies/combat_horde_ack_hold_hesitant.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsReplies",
        ["namespace"] = "combat.horde.ack",
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
                                        "Okay. Holding here.",
                                        "Staying put. I hope they don't see us.",
                                        "Holding position... please be quiet.",
                                        "Holding ground. Heart's pounding.",
                                        "I'll wait here, but let's be careful.",
                                        "Staying still. Don't make a sound.",
                                        "Holding... waiting for your call.",
                                        "Keeping low. I hope this works.",
                                        "Holding here. Watching their claws.",
                                        "Understood... staying frozen right here.",
                                    },
                                    ["TL"] = {
                                        "Sige. Dito muna ako.",
                                        "Dito lang ako. Sana di nila tayo makita.",
                                        "Hawak ang pwesto... pakiusap tumahimik.",
                                        "Hawak ang pwesto. Lumalakas ang tibok ng puso ko.",
                                        "Maghihintay ako rito, pero mag-ingat tayo.",
                                        "Walang kikilos. Huwag gagawa ng tunog.",
                                        "Hawak muna... naghihintay sa utos mo.",
                                        "Nakayuko. Sana magtagumpay ito.",
                                        "Hawak dito. Binabantayan ang kuko nila.",
                                        "Naintindihan... di gagalaw dito mismo.",
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
            ["responsePlanID"] = "combat.horde.ack.hold_hesitant",
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
                            ["fallback"] = "Okay. Holding here.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.horde.ack.hold_hesitant.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_replies/combat_horde_ack_hold_hesitant.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Okay. Holding here.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.ack.hold_hesitant.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Okay. Holding here.",
                        "Staying put. I hope they don't see us.",
                        "Holding position... please be quiet.",
                        "Holding ground. Heart's pounding.",
                        "I'll wait here, but let's be careful.",
                        "Staying still. Don't make a sound.",
                        "Holding... waiting for your call.",
                        "Keeping low. I hope this works.",
                        "Holding here. Watching their claws.",
                        "Understood... staying frozen right here.",
                    },
                    ["TL"] = {
                        "Sige. Dito muna ako.",
                        "Dito lang ako. Sana di nila tayo makita.",
                        "Hawak ang pwesto... pakiusap tumahimik.",
                        "Hawak ang pwesto. Lumalakas ang tibok ng puso ko.",
                        "Maghihintay ako rito, pero mag-ingat tayo.",
                        "Walang kikilos. Huwag gagawa ng tunog.",
                        "Hawak muna... naghihintay sa utos mo.",
                        "Nakayuko. Sana magtagumpay ito.",
                        "Hawak dito. Binabantayan ang kuko nila.",
                        "Naintindihan... di gagalaw dito mismo.",
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
            ["localId"] = "attack_auto",
            ["sourceId"] = "command.reply.attack_auto",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_replies/command_reply_attack_auto.json",
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
                            ["templateID"] = "psdl.command.reply.attack_auto.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_replies/command_reply_attack_auto.json",
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
            ["localId"] = "attack_melee",
            ["sourceId"] = "command.reply.attack_melee",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_replies/command_reply_attack_melee.json",
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
                            ["templateID"] = "psdl.command.reply.attack_melee.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_replies/command_reply_attack_melee.json",
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
            ["localId"] = "attack_none",
            ["sourceId"] = "command.reply.attack_none",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_replies/command_reply_attack_none.json",
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
                            ["templateID"] = "psdl.command.reply.attack_none.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_replies/command_reply_attack_none.json",
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
            ["localId"] = "attack_ranged",
            ["sourceId"] = "command.reply.attack_ranged",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_replies/command_reply_attack_ranged.json",
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
                            ["templateID"] = "psdl.command.reply.attack_ranged.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_replies/command_reply_attack_ranged.json",
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
            ["localId"] = "camp",
            ["sourceId"] = "command.reply.camp",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_replies/command_reply_camp.json",
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
                            ["templateID"] = "psdl.command.reply.camp.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_replies/command_reply_camp.json",
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
            ["localId"] = "camp_rejected",
            ["sourceId"] = "command.reply.camp_rejected",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_replies/command_reply_camp_rejected.json",
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
                            ["templateID"] = "psdl.command.reply.camp_rejected.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_replies/command_reply_camp_rejected.json",
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
            ["localId"] = "follow",
            ["sourceId"] = "command.reply.follow",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_replies/command_reply_follow.json",
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
                            ["templateID"] = "psdl.command.reply.follow.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_replies/command_reply_follow.json",
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
            ["localId"] = "generic_rejected",
            ["sourceId"] = "command.reply.generic_rejected",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_replies/command_reply_generic_rejected.json",
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
                            ["templateID"] = "psdl.command.reply.generic_rejected.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_replies/command_reply_generic_rejected.json",
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
}
