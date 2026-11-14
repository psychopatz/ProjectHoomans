-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_combat",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.horde.choice.avoid",
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
                                ["fallback"] = "Go around.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.horde.choice.avoid.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Go around.",
                                        "Bypass them. Stay quiet.",
                                        "Find another route. Don't draw them.",
                                        "Circle wide. Keep in the shadows.",
                                        "Not worth the ammo. Move around.",
                                        "Detour through the alley. Quietly.",
                                        "We sneak past. Crouch and move.",
                                        "Leave them be. Take the back way.",
                                        "Avoid contact. Step carefully.",
                                        "Back out and take the alternate street.",
                                    },
                                    ["TL"] = {
                                        "Umikot tayo.",
                                        "Lalagpasan natin sila. Huwag mag-ingay.",
                                        "Maghanap ng ibang ruta. Huwag silang akitin.",
                                        "Umikot nang malayo. Manatili sa dilim.",
                                        "Sayang ang bala. Umiwas na lang.",
                                        "Daan tayo sa eskinita. Nang tahimik.",
                                        "Lulusot tayo nang lihim. Yumuko at lumakad.",
                                        "Hayaan sila roon. Daan tayo sa likod.",
                                        "Iwasan ang engkwentro. Mag-ingat sa bawat hakbang.",
                                        "Atras muna at dumaan sa kabilang kalsada.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.horde.choice",
            ["textRoles"] = {
                {
                    ["fallback"] = "Go around.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.choice.avoid.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Go around.",
                            "Bypass them. Stay quiet.",
                            "Find another route. Don't draw them.",
                            "Circle wide. Keep in the shadows.",
                            "Not worth the ammo. Move around.",
                            "Detour through the alley. Quietly.",
                            "We sneak past. Crouch and move.",
                            "Leave them be. Take the back way.",
                            "Avoid contact. Step carefully.",
                            "Back out and take the alternate street.",
                        },
                        ["TL"] = {
                            "Umikot tayo.",
                            "Lalagpasan natin sila. Huwag mag-ingay.",
                            "Maghanap ng ibang ruta. Huwag silang akitin.",
                            "Umikot nang malayo. Manatili sa dilim.",
                            "Sayang ang bala. Umiwas na lang.",
                            "Daan tayo sa eskinita. Nang tahimik.",
                            "Lulusot tayo nang lihim. Yumuko at lumakad.",
                            "Hayaan sila roon. Daan tayo sa likod.",
                            "Iwasan ang engkwentro. Mag-ingat sa bawat hakbang.",
                            "Atras muna at dumaan sa kabilang kalsada.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.horde.choice.avoid",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "avoid",
            ["sourceId"] = "combat.horde.choice.avoid",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_combat/combat_horde_choice_avoid.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsCombat",
        ["namespace"] = "combat.horde.choice",
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
                                        "Go around.",
                                        "Bypass them. Stay quiet.",
                                        "Find another route. Don't draw them.",
                                        "Circle wide. Keep in the shadows.",
                                        "Not worth the ammo. Move around.",
                                        "Detour through the alley. Quietly.",
                                        "We sneak past. Crouch and move.",
                                        "Leave them be. Take the back way.",
                                        "Avoid contact. Step carefully.",
                                        "Back out and take the alternate street.",
                                    },
                                    ["TL"] = {
                                        "Umikot tayo.",
                                        "Lalagpasan natin sila. Huwag mag-ingay.",
                                        "Maghanap ng ibang ruta. Huwag silang akitin.",
                                        "Umikot nang malayo. Manatili sa dilim.",
                                        "Sayang ang bala. Umiwas na lang.",
                                        "Daan tayo sa eskinita. Nang tahimik.",
                                        "Lulusot tayo nang lihim. Yumuko at lumakad.",
                                        "Hayaan sila roon. Daan tayo sa likod.",
                                        "Iwasan ang engkwentro. Mag-ingat sa bawat hakbang.",
                                        "Atras muna at dumaan sa kabilang kalsada.",
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
            ["responsePlanID"] = "combat.horde.choice.avoid",
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
                            ["fallback"] = "Go around.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.horde.choice.avoid.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_combat/combat_horde_choice_avoid.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Go around.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.choice.avoid.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Go around.",
                        "Bypass them. Stay quiet.",
                        "Find another route. Don't draw them.",
                        "Circle wide. Keep in the shadows.",
                        "Not worth the ammo. Move around.",
                        "Detour through the alley. Quietly.",
                        "We sneak past. Crouch and move.",
                        "Leave them be. Take the back way.",
                        "Avoid contact. Step carefully.",
                        "Back out and take the alternate street.",
                    },
                    ["TL"] = {
                        "Umikot tayo.",
                        "Lalagpasan natin sila. Huwag mag-ingay.",
                        "Maghanap ng ibang ruta. Huwag silang akitin.",
                        "Umikot nang malayo. Manatili sa dilim.",
                        "Sayang ang bala. Umiwas na lang.",
                        "Daan tayo sa eskinita. Nang tahimik.",
                        "Lulusot tayo nang lihim. Yumuko at lumakad.",
                        "Hayaan sila roon. Daan tayo sa likod.",
                        "Iwasan ang engkwentro. Mag-ingat sa bawat hakbang.",
                        "Atras muna at dumaan sa kabilang kalsada.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_combat",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.horde.choice.engage",
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
                                ["fallback"] = "Take them.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.horde.choice.engage.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Take them.",
                                        "We fight. Weapons up.",
                                        "Engage. Clear them all.",
                                        "Stand and fight. Don't break line.",
                                        "Let's take them down right here.",
                                        "Strike now. Watch each other's sides.",
                                        "We're clearing this herd. Let's go.",
                                        "Cut them down one by one.",
                                        "Fight through them. Forward.",
                                        "Take the fight to them.",
                                    },
                                    ["TL"] = {
                                        "Sugurin natin.",
                                        "Lalaban tayo. Itaas ang sandata.",
                                        "Sugod. Ubusin silang lahat.",
                                        "Tumayo at lumaban. Huwag sirain ang linya.",
                                        "Itumba na natin sila rito mismo.",
                                        "Tira na ngayon. Bantayan ang gilid ng isa't isa.",
                                        "Lilinisin natin ang kuyog na 'to. Tara.",
                                        "Hiwain sila isa-isa.",
                                        "Lusubin natin sila. Pasulong.",
                                        "Harapin natin ang laban.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.horde.choice",
            ["textRoles"] = {
                {
                    ["fallback"] = "Take them.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.choice.engage.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Take them.",
                            "We fight. Weapons up.",
                            "Engage. Clear them all.",
                            "Stand and fight. Don't break line.",
                            "Let's take them down right here.",
                            "Strike now. Watch each other's sides.",
                            "We're clearing this herd. Let's go.",
                            "Cut them down one by one.",
                            "Fight through them. Forward.",
                            "Take the fight to them.",
                        },
                        ["TL"] = {
                            "Sugurin natin.",
                            "Lalaban tayo. Itaas ang sandata.",
                            "Sugod. Ubusin silang lahat.",
                            "Tumayo at lumaban. Huwag sirain ang linya.",
                            "Itumba na natin sila rito mismo.",
                            "Tira na ngayon. Bantayan ang gilid ng isa't isa.",
                            "Lilinisin natin ang kuyog na 'to. Tara.",
                            "Hiwain sila isa-isa.",
                            "Lusubin natin sila. Pasulong.",
                            "Harapin natin ang laban.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.horde.choice.engage",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "engage",
            ["sourceId"] = "combat.horde.choice.engage",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_combat/combat_horde_choice_engage.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsCombat",
        ["namespace"] = "combat.horde.choice",
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
                                        "Take them.",
                                        "We fight. Weapons up.",
                                        "Engage. Clear them all.",
                                        "Stand and fight. Don't break line.",
                                        "Let's take them down right here.",
                                        "Strike now. Watch each other's sides.",
                                        "We're clearing this herd. Let's go.",
                                        "Cut them down one by one.",
                                        "Fight through them. Forward.",
                                        "Take the fight to them.",
                                    },
                                    ["TL"] = {
                                        "Sugurin natin.",
                                        "Lalaban tayo. Itaas ang sandata.",
                                        "Sugod. Ubusin silang lahat.",
                                        "Tumayo at lumaban. Huwag sirain ang linya.",
                                        "Itumba na natin sila rito mismo.",
                                        "Tira na ngayon. Bantayan ang gilid ng isa't isa.",
                                        "Lilinisin natin ang kuyog na 'to. Tara.",
                                        "Hiwain sila isa-isa.",
                                        "Lusubin natin sila. Pasulong.",
                                        "Harapin natin ang laban.",
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
            ["responsePlanID"] = "combat.horde.choice.engage",
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
                            ["fallback"] = "Take them.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.horde.choice.engage.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_combat/combat_horde_choice_engage.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Take them.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.choice.engage.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Take them.",
                        "We fight. Weapons up.",
                        "Engage. Clear them all.",
                        "Stand and fight. Don't break line.",
                        "Let's take them down right here.",
                        "Strike now. Watch each other's sides.",
                        "We're clearing this herd. Let's go.",
                        "Cut them down one by one.",
                        "Fight through them. Forward.",
                        "Take the fight to them.",
                    },
                    ["TL"] = {
                        "Sugurin natin.",
                        "Lalaban tayo. Itaas ang sandata.",
                        "Sugod. Ubusin silang lahat.",
                        "Tumayo at lumaban. Huwag sirain ang linya.",
                        "Itumba na natin sila rito mismo.",
                        "Tira na ngayon. Bantayan ang gilid ng isa't isa.",
                        "Lilinisin natin ang kuyog na 'to. Tara.",
                        "Hiwain sila isa-isa.",
                        "Lusubin natin sila. Pasulong.",
                        "Harapin natin ang laban.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_combat",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.horde.choice.hold",
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
                                ["fallback"] = "Hold for now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.horde.choice.hold.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Hold for now.",
                                        "Stay put. Watch their movement.",
                                        "Hold position and let them pass.",
                                        "Wait here. Don't make a sound.",
                                        "Hold up. See which way they drift.",
                                        "Freeze. Don't reveal our position.",
                                        "Keep low and hold here.",
                                        "Stay behind cover for a moment.",
                                        "Hold the line. Wait for the signal.",
                                        "Wait and observe before moving.",
                                    },
                                    ["TL"] = {
                                        "Hinto muna.",
                                        "Diyan lang. Bantayan ang galaw nila.",
                                        "Hawakan ang pwesto at hayaang lumampas sila.",
                                        "Maghintay rito. Huwag gagawa ng tunog.",
                                        "Tigil muna. Tignan kung saan sila papunta.",
                                        "Huwag gagalaw. Huwag ilantad ang pwesto natin.",
                                        "Yumuko at manatili rito.",
                                        "Manatili sa kublihan sandali.",
                                        "Hawakan ang linya. Hintayin ang senyas.",
                                        "Maghintay at magmasid bago kumilos.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.horde.choice",
            ["textRoles"] = {
                {
                    ["fallback"] = "Hold for now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.choice.hold.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Hold for now.",
                            "Stay put. Watch their movement.",
                            "Hold position and let them pass.",
                            "Wait here. Don't make a sound.",
                            "Hold up. See which way they drift.",
                            "Freeze. Don't reveal our position.",
                            "Keep low and hold here.",
                            "Stay behind cover for a moment.",
                            "Hold the line. Wait for the signal.",
                            "Wait and observe before moving.",
                        },
                        ["TL"] = {
                            "Hinto muna.",
                            "Diyan lang. Bantayan ang galaw nila.",
                            "Hawakan ang pwesto at hayaang lumampas sila.",
                            "Maghintay rito. Huwag gagawa ng tunog.",
                            "Tigil muna. Tignan kung saan sila papunta.",
                            "Huwag gagalaw. Huwag ilantad ang pwesto natin.",
                            "Yumuko at manatili rito.",
                            "Manatili sa kublihan sandali.",
                            "Hawakan ang linya. Hintayin ang senyas.",
                            "Maghintay at magmasid bago kumilos.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.horde.choice.hold",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "hold",
            ["sourceId"] = "combat.horde.choice.hold",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_combat/combat_horde_choice_hold.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsCombat",
        ["namespace"] = "combat.horde.choice",
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
                                        "Hold for now.",
                                        "Stay put. Watch their movement.",
                                        "Hold position and let them pass.",
                                        "Wait here. Don't make a sound.",
                                        "Hold up. See which way they drift.",
                                        "Freeze. Don't reveal our position.",
                                        "Keep low and hold here.",
                                        "Stay behind cover for a moment.",
                                        "Hold the line. Wait for the signal.",
                                        "Wait and observe before moving.",
                                    },
                                    ["TL"] = {
                                        "Hinto muna.",
                                        "Diyan lang. Bantayan ang galaw nila.",
                                        "Hawakan ang pwesto at hayaang lumampas sila.",
                                        "Maghintay rito. Huwag gagawa ng tunog.",
                                        "Tigil muna. Tignan kung saan sila papunta.",
                                        "Huwag gagalaw. Huwag ilantad ang pwesto natin.",
                                        "Yumuko at manatili rito.",
                                        "Manatili sa kublihan sandali.",
                                        "Hawakan ang linya. Hintayin ang senyas.",
                                        "Maghintay at magmasid bago kumilos.",
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
            ["responsePlanID"] = "combat.horde.choice.hold",
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
                            ["fallback"] = "Hold for now.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.horde.choice.hold.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_combat/combat_horde_choice_hold.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Hold for now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.choice.hold.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Hold for now.",
                        "Stay put. Watch their movement.",
                        "Hold position and let them pass.",
                        "Wait here. Don't make a sound.",
                        "Hold up. See which way they drift.",
                        "Freeze. Don't reveal our position.",
                        "Keep low and hold here.",
                        "Stay behind cover for a moment.",
                        "Hold the line. Wait for the signal.",
                        "Wait and observe before moving.",
                    },
                    ["TL"] = {
                        "Hinto muna.",
                        "Diyan lang. Bantayan ang galaw nila.",
                        "Hawakan ang pwesto at hayaang lumampas sila.",
                        "Maghintay rito. Huwag gagawa ng tunog.",
                        "Tigil muna. Tignan kung saan sila papunta.",
                        "Huwag gagalaw. Huwag ilantad ang pwesto natin.",
                        "Yumuko at manatili rito.",
                        "Manatili sa kublihan sandali.",
                        "Hawakan ang linya. Hintayin ang senyas.",
                        "Maghintay at magmasid bago kumilos.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_combat",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.horde.deescalated",
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
                                ["fallback"] = "They're thinning out. Don't relax yet.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.horde.deescalated.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "They're thinning out. Don't relax yet.",
                                        "Most of the swarm is down. Check stragglers.",
                                        "The main wave is broken. Keep scanning.",
                                        "Fewer coming through now. Catch your breath.",
                                        "Herd's scattered. Clear the remaining few.",
                                        "We weathered the bulk of them. Stay focused.",
                                        "Numbers are dropping. Keep the pressure on.",
                                        "They're losing momentum. Finish them off.",
                                        "Only a handful left. Watch your spacing.",
                                        "The rush is slowing down. Good work.",
                                    },
                                    ["TL"] = {
                                        "Kumokonti sila. Huwag munang kampante.",
                                        "Bagsak na karamihan sa kuyog. Tignan ang mga naiwan.",
                                        "Nawasak na ang bulto. Tuloy sa pagmamasid.",
                                        "Kakaunti na lang ang dumarating. Huminga muna.",
                                        "Kalat na ang kuyog. Ubusin ang natitira.",
                                        "Nalagpasan natin ang pinakamarami. Manatiling nakatutok.",
                                        "Bumaba na ang bilang nila. Tuloy ang laban.",
                                        "Nawawalan na sila ng pwersa. Tapusin na natin sila.",
                                        "Ilan-ilan na lang ang natitira. Bantayan ang distansya.",
                                        "Bumagal na ang pagdagsa. Maganda ang ginawa natin.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.horde",
            ["textRoles"] = {
                {
                    ["fallback"] = "They're thinning out. Don't relax yet.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.deescalated.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "They're thinning out. Don't relax yet.",
                            "Most of the swarm is down. Check stragglers.",
                            "The main wave is broken. Keep scanning.",
                            "Fewer coming through now. Catch your breath.",
                            "Herd's scattered. Clear the remaining few.",
                            "We weathered the bulk of them. Stay focused.",
                            "Numbers are dropping. Keep the pressure on.",
                            "They're losing momentum. Finish them off.",
                            "Only a handful left. Watch your spacing.",
                            "The rush is slowing down. Good work.",
                        },
                        ["TL"] = {
                            "Kumokonti sila. Huwag munang kampante.",
                            "Bagsak na karamihan sa kuyog. Tignan ang mga naiwan.",
                            "Nawasak na ang bulto. Tuloy sa pagmamasid.",
                            "Kakaunti na lang ang dumarating. Huminga muna.",
                            "Kalat na ang kuyog. Ubusin ang natitira.",
                            "Nalagpasan natin ang pinakamarami. Manatiling nakatutok.",
                            "Bumaba na ang bilang nila. Tuloy ang laban.",
                            "Nawawalan na sila ng pwersa. Tapusin na natin sila.",
                            "Ilan-ilan na lang ang natitira. Bantayan ang distansya.",
                            "Bumagal na ang pagdagsa. Maganda ang ginawa natin.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.horde.deescalated",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "deescalated",
            ["sourceId"] = "combat.horde.deescalated",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_combat/combat_horde_deescalated.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsCombat",
        ["namespace"] = "combat.horde",
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
                                        "They're thinning out. Don't relax yet.",
                                        "Most of the swarm is down. Check stragglers.",
                                        "The main wave is broken. Keep scanning.",
                                        "Fewer coming through now. Catch your breath.",
                                        "Herd's scattered. Clear the remaining few.",
                                        "We weathered the bulk of them. Stay focused.",
                                        "Numbers are dropping. Keep the pressure on.",
                                        "They're losing momentum. Finish them off.",
                                        "Only a handful left. Watch your spacing.",
                                        "The rush is slowing down. Good work.",
                                    },
                                    ["TL"] = {
                                        "Kumokonti sila. Huwag munang kampante.",
                                        "Bagsak na karamihan sa kuyog. Tignan ang mga naiwan.",
                                        "Nawasak na ang bulto. Tuloy sa pagmamasid.",
                                        "Kakaunti na lang ang dumarating. Huminga muna.",
                                        "Kalat na ang kuyog. Ubusin ang natitira.",
                                        "Nalagpasan natin ang pinakamarami. Manatiling nakatutok.",
                                        "Bumaba na ang bilang nila. Tuloy ang laban.",
                                        "Nawawalan na sila ng pwersa. Tapusin na natin sila.",
                                        "Ilan-ilan na lang ang natitira. Bantayan ang distansya.",
                                        "Bumagal na ang pagdagsa. Maganda ang ginawa natin.",
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
            ["responsePlanID"] = "combat.horde.deescalated",
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
                            ["fallback"] = "They're thinning out. Don't relax yet.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.horde.deescalated.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_combat/combat_horde_deescalated.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "They're thinning out. Don't relax yet.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.deescalated.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "They're thinning out. Don't relax yet.",
                        "Most of the swarm is down. Check stragglers.",
                        "The main wave is broken. Keep scanning.",
                        "Fewer coming through now. Catch your breath.",
                        "Herd's scattered. Clear the remaining few.",
                        "We weathered the bulk of them. Stay focused.",
                        "Numbers are dropping. Keep the pressure on.",
                        "They're losing momentum. Finish them off.",
                        "Only a handful left. Watch your spacing.",
                        "The rush is slowing down. Good work.",
                    },
                    ["TL"] = {
                        "Kumokonti sila. Huwag munang kampante.",
                        "Bagsak na karamihan sa kuyog. Tignan ang mga naiwan.",
                        "Nawasak na ang bulto. Tuloy sa pagmamasid.",
                        "Kakaunti na lang ang dumarating. Huminga muna.",
                        "Kalat na ang kuyog. Ubusin ang natitira.",
                        "Nalagpasan natin ang pinakamarami. Manatiling nakatutok.",
                        "Bumaba na ang bilang nila. Tuloy ang laban.",
                        "Nawawalan na sila ng pwersa. Tapusin na natin sila.",
                        "Ilan-ilan na lang ang natitira. Bantayan ang distansya.",
                        "Bumagal na ang pagdagsa. Maganda ang ginawa natin.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_combat",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.horde.default",
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
                                ["fallback"] = "Horde nearby. Keep your eyes up.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.horde.default.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Horde nearby. Keep your eyes up.",
                                        "Large group in the vicinity. Tread quietly.",
                                        "There's a swarm around here. Stay cautious.",
                                        "I hear heavy movement outside. Watch yourself.",
                                        "Pack of infected close by. Stay alert.",
                                        "We're near a wandering horde. Keep low.",
                                        "Too much shuffling out there. Keep weapons ready.",
                                        "Dead are gathering nearby. Stay on your toes.",
                                        "Horde in the area. Pick your steps carefully.",
                                        "Infected swarm close. Don't make unnecessary noise.",
                                    },
                                    ["TL"] = {
                                        "May kuyog na malapit. Magmatyag tayo.",
                                        "Malaking grupo sa paligid. Huwag gumawa ng ingay.",
                                        "May kuyog sa lugar na 'to. Mag-ingat.",
                                        "May naririnig akong maraming yabag sa labas. Mag-ingat.",
                                        "Grupo ng infected malapit dito. Maging alerto.",
                                        "Malapit tayo sa palakad-lakad na kuyog. Yumuko.",
                                        "Masyadong maraming kaluskos sa labas. Ihanda ang sandata.",
                                        "Nagtitipon ang mga patay malapit dito. Maging handa.",
                                        "May kuyog sa paligid. Piliin nang maigi ang bawat hakbang.",
                                        "Malapit ang kuyog ng infected. Huwag gumawa ng ingay.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.horde",
            ["textRoles"] = {
                {
                    ["fallback"] = "Horde nearby. Keep your eyes up.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.default.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Horde nearby. Keep your eyes up.",
                            "Large group in the vicinity. Tread quietly.",
                            "There's a swarm around here. Stay cautious.",
                            "I hear heavy movement outside. Watch yourself.",
                            "Pack of infected close by. Stay alert.",
                            "We're near a wandering horde. Keep low.",
                            "Too much shuffling out there. Keep weapons ready.",
                            "Dead are gathering nearby. Stay on your toes.",
                            "Horde in the area. Pick your steps carefully.",
                            "Infected swarm close. Don't make unnecessary noise.",
                        },
                        ["TL"] = {
                            "May kuyog na malapit. Magmatyag tayo.",
                            "Malaking grupo sa paligid. Huwag gumawa ng ingay.",
                            "May kuyog sa lugar na 'to. Mag-ingat.",
                            "May naririnig akong maraming yabag sa labas. Mag-ingat.",
                            "Grupo ng infected malapit dito. Maging alerto.",
                            "Malapit tayo sa palakad-lakad na kuyog. Yumuko.",
                            "Masyadong maraming kaluskos sa labas. Ihanda ang sandata.",
                            "Nagtitipon ang mga patay malapit dito. Maging handa.",
                            "May kuyog sa paligid. Piliin nang maigi ang bawat hakbang.",
                            "Malapit ang kuyog ng infected. Huwag gumawa ng ingay.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.horde.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "default",
            ["sourceId"] = "combat.horde.default",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_combat/combat_horde_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsCombat",
        ["namespace"] = "combat.horde",
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
                                        "Horde nearby. Keep your eyes up.",
                                        "Large group in the vicinity. Tread quietly.",
                                        "There's a swarm around here. Stay cautious.",
                                        "I hear heavy movement outside. Watch yourself.",
                                        "Pack of infected close by. Stay alert.",
                                        "We're near a wandering horde. Keep low.",
                                        "Too much shuffling out there. Keep weapons ready.",
                                        "Dead are gathering nearby. Stay on your toes.",
                                        "Horde in the area. Pick your steps carefully.",
                                        "Infected swarm close. Don't make unnecessary noise.",
                                    },
                                    ["TL"] = {
                                        "May kuyog na malapit. Magmatyag tayo.",
                                        "Malaking grupo sa paligid. Huwag gumawa ng ingay.",
                                        "May kuyog sa lugar na 'to. Mag-ingat.",
                                        "May naririnig akong maraming yabag sa labas. Mag-ingat.",
                                        "Grupo ng infected malapit dito. Maging alerto.",
                                        "Malapit tayo sa palakad-lakad na kuyog. Yumuko.",
                                        "Masyadong maraming kaluskos sa labas. Ihanda ang sandata.",
                                        "Nagtitipon ang mga patay malapit dito. Maging handa.",
                                        "May kuyog sa paligid. Piliin nang maigi ang bawat hakbang.",
                                        "Malapit ang kuyog ng infected. Huwag gumawa ng ingay.",
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
            ["responsePlanID"] = "combat.horde.default",
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
                            ["fallback"] = "Horde nearby. Keep your eyes up.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.horde.default.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_combat/combat_horde_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Horde nearby. Keep your eyes up.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.default.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Horde nearby. Keep your eyes up.",
                        "Large group in the vicinity. Tread quietly.",
                        "There's a swarm around here. Stay cautious.",
                        "I hear heavy movement outside. Watch yourself.",
                        "Pack of infected close by. Stay alert.",
                        "We're near a wandering horde. Keep low.",
                        "Too much shuffling out there. Keep weapons ready.",
                        "Dead are gathering nearby. Stay on your toes.",
                        "Horde in the area. Pick your steps carefully.",
                        "Infected swarm close. Don't make unnecessary noise.",
                    },
                    ["TL"] = {
                        "May kuyog na malapit. Magmatyag tayo.",
                        "Malaking grupo sa paligid. Huwag gumawa ng ingay.",
                        "May kuyog sa lugar na 'to. Mag-ingat.",
                        "May naririnig akong maraming yabag sa labas. Mag-ingat.",
                        "Grupo ng infected malapit dito. Maging alerto.",
                        "Malapit tayo sa palakad-lakad na kuyog. Yumuko.",
                        "Masyadong maraming kaluskos sa labas. Ihanda ang sandata.",
                        "Nagtitipon ang mga patay malapit dito. Maging handa.",
                        "May kuyog sa paligid. Piliin nang maigi ang bawat hakbang.",
                        "Malapit ang kuyog ng infected. Huwag gumawa ng ingay.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_combat",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.horde.escalated",
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
                                ["fallback"] = "More are piling in. This is getting bad.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.horde.escalated.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "More are piling in. This is getting bad.",
                                        "They keep coming! We're losing ground.",
                                        "The herd just doubled. We need a plan.",
                                        "Too many to push through! Fall back a step.",
                                        "The swarm's thickening. Watch your flanks!",
                                        "Every window is shaking. They're surrounding us.",
                                        "They're pouring through the gaps. Steady!",
                                        "This isn't thinning out, it's growing!",
                                        "More rottens behind the first wave!",
                                        "We're getting boxed in. Don't stop swinging.",
                                    },
                                    ["TL"] = {
                                        "Dumarami sila. Lumalala ito.",
                                        "Patuloy silang dumarami! Nawawalan tayo ng espasyo.",
                                        "Doble na ang dami nila. Kailangan natin ng plano.",
                                        "Masyadong marami para lusubin! Umatras nang kaunti.",
                                        "Kumakapal ang kuyog. Bantayan ang gilid mo!",
                                        "Nanginginig ang bawat bintana. Pinalilibutan nila tayo.",
                                        "Bumubuhos sila sa mga butas. Magpakatatag!",
                                        "Hindi sila kumokonti, lalo pang dumarami!",
                                        "May mga bulok pa sa likod ng unang grupo!",
                                        "Naiipit na tayo. Huwag titigil sa paghataw.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.horde",
            ["textRoles"] = {
                {
                    ["fallback"] = "More are piling in. This is getting bad.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.escalated.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "More are piling in. This is getting bad.",
                            "They keep coming! We're losing ground.",
                            "The herd just doubled. We need a plan.",
                            "Too many to push through! Fall back a step.",
                            "The swarm's thickening. Watch your flanks!",
                            "Every window is shaking. They're surrounding us.",
                            "They're pouring through the gaps. Steady!",
                            "This isn't thinning out, it's growing!",
                            "More rottens behind the first wave!",
                            "We're getting boxed in. Don't stop swinging.",
                        },
                        ["TL"] = {
                            "Dumarami sila. Lumalala ito.",
                            "Patuloy silang dumarami! Nawawalan tayo ng espasyo.",
                            "Doble na ang dami nila. Kailangan natin ng plano.",
                            "Masyadong marami para lusubin! Umatras nang kaunti.",
                            "Kumakapal ang kuyog. Bantayan ang gilid mo!",
                            "Nanginginig ang bawat bintana. Pinalilibutan nila tayo.",
                            "Bumubuhos sila sa mga butas. Magpakatatag!",
                            "Hindi sila kumokonti, lalo pang dumarami!",
                            "May mga bulok pa sa likod ng unang grupo!",
                            "Naiipit na tayo. Huwag titigil sa paghataw.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.horde.escalated",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "escalated",
            ["sourceId"] = "combat.horde.escalated",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_combat/combat_horde_escalated.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsCombat",
        ["namespace"] = "combat.horde",
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
                                        "More are piling in. This is getting bad.",
                                        "They keep coming! We're losing ground.",
                                        "The herd just doubled. We need a plan.",
                                        "Too many to push through! Fall back a step.",
                                        "The swarm's thickening. Watch your flanks!",
                                        "Every window is shaking. They're surrounding us.",
                                        "They're pouring through the gaps. Steady!",
                                        "This isn't thinning out, it's growing!",
                                        "More rottens behind the first wave!",
                                        "We're getting boxed in. Don't stop swinging.",
                                    },
                                    ["TL"] = {
                                        "Dumarami sila. Lumalala ito.",
                                        "Patuloy silang dumarami! Nawawalan tayo ng espasyo.",
                                        "Doble na ang dami nila. Kailangan natin ng plano.",
                                        "Masyadong marami para lusubin! Umatras nang kaunti.",
                                        "Kumakapal ang kuyog. Bantayan ang gilid mo!",
                                        "Nanginginig ang bawat bintana. Pinalilibutan nila tayo.",
                                        "Bumubuhos sila sa mga butas. Magpakatatag!",
                                        "Hindi sila kumokonti, lalo pang dumarami!",
                                        "May mga bulok pa sa likod ng unang grupo!",
                                        "Naiipit na tayo. Huwag titigil sa paghataw.",
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
            ["responsePlanID"] = "combat.horde.escalated",
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
                            ["fallback"] = "More are piling in. This is getting bad.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.horde.escalated.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_combat/combat_horde_escalated.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "More are piling in. This is getting bad.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.escalated.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "More are piling in. This is getting bad.",
                        "They keep coming! We're losing ground.",
                        "The herd just doubled. We need a plan.",
                        "Too many to push through! Fall back a step.",
                        "The swarm's thickening. Watch your flanks!",
                        "Every window is shaking. They're surrounding us.",
                        "They're pouring through the gaps. Steady!",
                        "This isn't thinning out, it's growing!",
                        "More rottens behind the first wave!",
                        "We're getting boxed in. Don't stop swinging.",
                    },
                    ["TL"] = {
                        "Dumarami sila. Lumalala ito.",
                        "Patuloy silang dumarami! Nawawalan tayo ng espasyo.",
                        "Doble na ang dami nila. Kailangan natin ng plano.",
                        "Masyadong marami para lusubin! Umatras nang kaunti.",
                        "Kumakapal ang kuyog. Bantayan ang gilid mo!",
                        "Nanginginig ang bawat bintana. Pinalilibutan nila tayo.",
                        "Bumubuhos sila sa mga butas. Magpakatatag!",
                        "Hindi sila kumokonti, lalo pang dumarami!",
                        "May mga bulok pa sa likod ng unang grupo!",
                        "Naiipit na tayo. Huwag titigil sa paghataw.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_combat",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.horde.prompt.default",
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
                                ["fallback"] = "That's a lot of them. We fighting or going around?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.horde.prompt.default.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "That's a lot of them. We fighting or going around?",
                                        "Big swarm ahead. What's the plan?",
                                        "Whole herd in our way. Do we push through or find another path?",
                                        "Look at the street. Are we engaging or avoiding?",
                                        "Infected group is large. How do you want to handle this?",
                                        "Crowd ahead of us. Should we fight or sneak past?",
                                        "There's quite a crowd. What are we doing?",
                                        "They're blocking the lane. Do we clear them or detour?",
                                        "Horde right in front. What do you want to do?",
                                        "That's more than a few. Engage or back off?",
                                    },
                                    ["TL"] = {
                                        "Ang dami nila. Lalaban ba tayo o iiwas?",
                                        "Malaking kuyog sa unahan. Ano'ng plano?",
                                        "Buong kawan ang nakaharang. Susugod ba tayo o maghahanap ng ibang daan?",
                                        "Tingnan mo ang kalsada. Lalabanan ba natin o iiwasan?",
                                        "Malaki ang grupo ng infected. Paano mo gustong harapin 'to?",
                                        "May mga patay sa harap natin. Lalaban ba tayo o lulusot nang tahimik?",
                                        "Medyo marami sila. Ano'ng gagawin natin?",
                                        "Harang sila sa daan. Lilinisin ba natin o iikot tayo?",
                                        "Kuyog mismo sa harap. Ano'ng gusto mong gawin?",
                                        "Higit pa sa iilan 'yan. Susugod o aatras?",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.horde.prompt",
            ["textRoles"] = {
                {
                    ["fallback"] = "That's a lot of them. We fighting or going around?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.prompt.default.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "That's a lot of them. We fighting or going around?",
                            "Big swarm ahead. What's the plan?",
                            "Whole herd in our way. Do we push through or find another path?",
                            "Look at the street. Are we engaging or avoiding?",
                            "Infected group is large. How do you want to handle this?",
                            "Crowd ahead of us. Should we fight or sneak past?",
                            "There's quite a crowd. What are we doing?",
                            "They're blocking the lane. Do we clear them or detour?",
                            "Horde right in front. What do you want to do?",
                            "That's more than a few. Engage or back off?",
                        },
                        ["TL"] = {
                            "Ang dami nila. Lalaban ba tayo o iiwas?",
                            "Malaking kuyog sa unahan. Ano'ng plano?",
                            "Buong kawan ang nakaharang. Susugod ba tayo o maghahanap ng ibang daan?",
                            "Tingnan mo ang kalsada. Lalabanan ba natin o iiwasan?",
                            "Malaki ang grupo ng infected. Paano mo gustong harapin 'to?",
                            "May mga patay sa harap natin. Lalaban ba tayo o lulusot nang tahimik?",
                            "Medyo marami sila. Ano'ng gagawin natin?",
                            "Harang sila sa daan. Lilinisin ba natin o iikot tayo?",
                            "Kuyog mismo sa harap. Ano'ng gusto mong gawin?",
                            "Higit pa sa iilan 'yan. Susugod o aatras?",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.horde.prompt.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "default",
            ["sourceId"] = "combat.horde.prompt.default",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_combat/combat_horde_prompt_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsCombat",
        ["namespace"] = "combat.horde.prompt",
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
                                        "That's a lot of them. We fighting or going around?",
                                        "Big swarm ahead. What's the plan?",
                                        "Whole herd in our way. Do we push through or find another path?",
                                        "Look at the street. Are we engaging or avoiding?",
                                        "Infected group is large. How do you want to handle this?",
                                        "Crowd ahead of us. Should we fight or sneak past?",
                                        "There's quite a crowd. What are we doing?",
                                        "They're blocking the lane. Do we clear them or detour?",
                                        "Horde right in front. What do you want to do?",
                                        "That's more than a few. Engage or back off?",
                                    },
                                    ["TL"] = {
                                        "Ang dami nila. Lalaban ba tayo o iiwas?",
                                        "Malaking kuyog sa unahan. Ano'ng plano?",
                                        "Buong kawan ang nakaharang. Susugod ba tayo o maghahanap ng ibang daan?",
                                        "Tingnan mo ang kalsada. Lalabanan ba natin o iiwasan?",
                                        "Malaki ang grupo ng infected. Paano mo gustong harapin 'to?",
                                        "May mga patay sa harap natin. Lalaban ba tayo o lulusot nang tahimik?",
                                        "Medyo marami sila. Ano'ng gagawin natin?",
                                        "Harang sila sa daan. Lilinisin ba natin o iikot tayo?",
                                        "Kuyog mismo sa harap. Ano'ng gusto mong gawin?",
                                        "Higit pa sa iilan 'yan. Susugod o aatras?",
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
            ["responsePlanID"] = "combat.horde.prompt.default",
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
                            ["fallback"] = "That's a lot of them. We fighting or going around?",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.horde.prompt.default.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_combat/combat_horde_prompt_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That's a lot of them. We fighting or going around?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.prompt.default.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "That's a lot of them. We fighting or going around?",
                        "Big swarm ahead. What's the plan?",
                        "Whole herd in our way. Do we push through or find another path?",
                        "Look at the street. Are we engaging or avoiding?",
                        "Infected group is large. How do you want to handle this?",
                        "Crowd ahead of us. Should we fight or sneak past?",
                        "There's quite a crowd. What are we doing?",
                        "They're blocking the lane. Do we clear them or detour?",
                        "Horde right in front. What do you want to do?",
                        "That's more than a few. Engage or back off?",
                    },
                    ["TL"] = {
                        "Ang dami nila. Lalaban ba tayo o iiwas?",
                        "Malaking kuyog sa unahan. Ano'ng plano?",
                        "Buong kawan ang nakaharang. Susugod ba tayo o maghahanap ng ibang daan?",
                        "Tingnan mo ang kalsada. Lalabanan ba natin o iiwasan?",
                        "Malaki ang grupo ng infected. Paano mo gustong harapin 'to?",
                        "May mga patay sa harap natin. Lalaban ba tayo o lulusot nang tahimik?",
                        "Medyo marami sila. Ano'ng gagawin natin?",
                        "Harang sila sa daan. Lilinisin ba natin o iikot tayo?",
                        "Kuyog mismo sa harap. Ano'ng gusto mong gawin?",
                        "Higit pa sa iilan 'yan. Susugod o aatras?",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_combat",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.horde.prompt.eager",
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
                                ["fallback"] = "That's a hell of a crowd. We taking them?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.horde.prompt.eager.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "That's a hell of a crowd. We taking them?",
                                        "Big group ahead. Let's carve right through them.",
                                        "Look at all those targets. You ready to swing?",
                                        "We can take this pack. What's the call?",
                                        "I say we clear them out right here. Ready?",
                                        "They're packed together nicely. Time to strike.",
                                        "I've got plenty of energy. Let's drop them.",
                                        "Crowd of dead ahead. Give the word and I charge.",
                                        "We've got weapons and room. Let's do this.",
                                        "Let's crack some skulls. We fighting or what?",
                                    },
                                    ["TL"] = {
                                        "Ang dami nila. Susugod ba tayo?",
                                        "Malaking grupo sa unahan. Biyakin na natin sila.",
                                        "Tingnan mo ang dami ng target. Handa ka na bang humataw?",
                                        "Kaya natin ang grupong 'to. Ano'ng desisyon?",
                                        "Linisin na natin sila rito mismo. Handa ka na?",
                                        "Magkakadikit sila nang maayos. Oras na para sumugod.",
                                        "Marami pa akong lakas. Itumba na natin sila.",
                                        "Kuyog ng mga patay sa unahan. Sabihin mo lang at susugod ako.",
                                        "May sandata at espasyo tayo. Labanan na natin.",
                                        "Magbasag tayo ng bungo. Lalaban ba tayo o ano?",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.horde.prompt",
            ["textRoles"] = {
                {
                    ["fallback"] = "That's a hell of a crowd. We taking them?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.prompt.eager.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "That's a hell of a crowd. We taking them?",
                            "Big group ahead. Let's carve right through them.",
                            "Look at all those targets. You ready to swing?",
                            "We can take this pack. What's the call?",
                            "I say we clear them out right here. Ready?",
                            "They're packed together nicely. Time to strike.",
                            "I've got plenty of energy. Let's drop them.",
                            "Crowd of dead ahead. Give the word and I charge.",
                            "We've got weapons and room. Let's do this.",
                            "Let's crack some skulls. We fighting or what?",
                        },
                        ["TL"] = {
                            "Ang dami nila. Susugod ba tayo?",
                            "Malaking grupo sa unahan. Biyakin na natin sila.",
                            "Tingnan mo ang dami ng target. Handa ka na bang humataw?",
                            "Kaya natin ang grupong 'to. Ano'ng desisyon?",
                            "Linisin na natin sila rito mismo. Handa ka na?",
                            "Magkakadikit sila nang maayos. Oras na para sumugod.",
                            "Marami pa akong lakas. Itumba na natin sila.",
                            "Kuyog ng mga patay sa unahan. Sabihin mo lang at susugod ako.",
                            "May sandata at espasyo tayo. Labanan na natin.",
                            "Magbasag tayo ng bungo. Lalaban ba tayo o ano?",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.horde.prompt.eager",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "eager",
            ["sourceId"] = "combat.horde.prompt.eager",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_combat/combat_horde_prompt_eager.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsCombat",
        ["namespace"] = "combat.horde.prompt",
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
                                        "That's a hell of a crowd. We taking them?",
                                        "Big group ahead. Let's carve right through them.",
                                        "Look at all those targets. You ready to swing?",
                                        "We can take this pack. What's the call?",
                                        "I say we clear them out right here. Ready?",
                                        "They're packed together nicely. Time to strike.",
                                        "I've got plenty of energy. Let's drop them.",
                                        "Crowd of dead ahead. Give the word and I charge.",
                                        "We've got weapons and room. Let's do this.",
                                        "Let's crack some skulls. We fighting or what?",
                                    },
                                    ["TL"] = {
                                        "Ang dami nila. Susugod ba tayo?",
                                        "Malaking grupo sa unahan. Biyakin na natin sila.",
                                        "Tingnan mo ang dami ng target. Handa ka na bang humataw?",
                                        "Kaya natin ang grupong 'to. Ano'ng desisyon?",
                                        "Linisin na natin sila rito mismo. Handa ka na?",
                                        "Magkakadikit sila nang maayos. Oras na para sumugod.",
                                        "Marami pa akong lakas. Itumba na natin sila.",
                                        "Kuyog ng mga patay sa unahan. Sabihin mo lang at susugod ako.",
                                        "May sandata at espasyo tayo. Labanan na natin.",
                                        "Magbasag tayo ng bungo. Lalaban ba tayo o ano?",
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
            ["responsePlanID"] = "combat.horde.prompt.eager",
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
                            ["fallback"] = "That's a hell of a crowd. We taking them?",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.horde.prompt.eager.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_combat/combat_horde_prompt_eager.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That's a hell of a crowd. We taking them?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.prompt.eager.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "That's a hell of a crowd. We taking them?",
                        "Big group ahead. Let's carve right through them.",
                        "Look at all those targets. You ready to swing?",
                        "We can take this pack. What's the call?",
                        "I say we clear them out right here. Ready?",
                        "They're packed together nicely. Time to strike.",
                        "I've got plenty of energy. Let's drop them.",
                        "Crowd of dead ahead. Give the word and I charge.",
                        "We've got weapons and room. Let's do this.",
                        "Let's crack some skulls. We fighting or what?",
                    },
                    ["TL"] = {
                        "Ang dami nila. Susugod ba tayo?",
                        "Malaking grupo sa unahan. Biyakin na natin sila.",
                        "Tingnan mo ang dami ng target. Handa ka na bang humataw?",
                        "Kaya natin ang grupong 'to. Ano'ng desisyon?",
                        "Linisin na natin sila rito mismo. Handa ka na?",
                        "Magkakadikit sila nang maayos. Oras na para sumugod.",
                        "Marami pa akong lakas. Itumba na natin sila.",
                        "Kuyog ng mga patay sa unahan. Sabihin mo lang at susugod ako.",
                        "May sandata at espasyo tayo. Labanan na natin.",
                        "Magbasag tayo ng bungo. Lalaban ba tayo o ano?",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_combat",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.horde.prompt.reserved",
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
                                ["fallback"] = "Horde ahead. Engage or go around?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.horde.prompt.reserved.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Horde ahead. Engage or go around?",
                                        "Crowd spotted. Call it.",
                                        "Massed dead. Fight or bypass?",
                                        "Swarm blocking route. Your call.",
                                        "Large group. Stand and fight or slip past?",
                                        "Herd ahead. Make a choice.",
                                        "Horde present. Direct us.",
                                        "Too many in the open. Do we push or turn?",
                                        "Mass contacts. Decision?",
                                        "Herd in path. Fight or avoid?",
                                    },
                                    ["TL"] = {
                                        "May kuyog sa unahan. Lalaban o iiwas?",
                                        "May nakitang grupo. Desisyunan mo.",
                                        "Nagtitipong mga patay. Lalabanan o lalagpasan?",
                                        "Harang ang kuyog sa daan. Ikaw ang masusunod.",
                                        "Malaking grupo. Tatayo at lalaban o lulusot?",
                                        "Kawan sa harap. Pumili ka.",
                                        "May kuyog dito. Pangunahan mo kami.",
                                        "Masyadong marami sa bukas na lugar. Susulong o liliko?",
                                        "Maraming kalaban. Ano'ng pasya?",
                                        "May kuyog sa dinaraanan. Laban o iwas?",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.horde.prompt",
            ["textRoles"] = {
                {
                    ["fallback"] = "Horde ahead. Engage or go around?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.prompt.reserved.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Horde ahead. Engage or go around?",
                            "Crowd spotted. Call it.",
                            "Massed dead. Fight or bypass?",
                            "Swarm blocking route. Your call.",
                            "Large group. Stand and fight or slip past?",
                            "Herd ahead. Make a choice.",
                            "Horde present. Direct us.",
                            "Too many in the open. Do we push or turn?",
                            "Mass contacts. Decision?",
                            "Herd in path. Fight or avoid?",
                        },
                        ["TL"] = {
                            "May kuyog sa unahan. Lalaban o iiwas?",
                            "May nakitang grupo. Desisyunan mo.",
                            "Nagtitipong mga patay. Lalabanan o lalagpasan?",
                            "Harang ang kuyog sa daan. Ikaw ang masusunod.",
                            "Malaking grupo. Tatayo at lalaban o lulusot?",
                            "Kawan sa harap. Pumili ka.",
                            "May kuyog dito. Pangunahan mo kami.",
                            "Masyadong marami sa bukas na lugar. Susulong o liliko?",
                            "Maraming kalaban. Ano'ng pasya?",
                            "May kuyog sa dinaraanan. Laban o iwas?",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.horde.prompt.reserved",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "reserved",
            ["sourceId"] = "combat.horde.prompt.reserved",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_combat/combat_horde_prompt_reserved.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsCombat",
        ["namespace"] = "combat.horde.prompt",
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
                                        "Horde ahead. Engage or go around?",
                                        "Crowd spotted. Call it.",
                                        "Massed dead. Fight or bypass?",
                                        "Swarm blocking route. Your call.",
                                        "Large group. Stand and fight or slip past?",
                                        "Herd ahead. Make a choice.",
                                        "Horde present. Direct us.",
                                        "Too many in the open. Do we push or turn?",
                                        "Mass contacts. Decision?",
                                        "Herd in path. Fight or avoid?",
                                    },
                                    ["TL"] = {
                                        "May kuyog sa unahan. Lalaban o iiwas?",
                                        "May nakitang grupo. Desisyunan mo.",
                                        "Nagtitipong mga patay. Lalabanan o lalagpasan?",
                                        "Harang ang kuyog sa daan. Ikaw ang masusunod.",
                                        "Malaking grupo. Tatayo at lalaban o lulusot?",
                                        "Kawan sa harap. Pumili ka.",
                                        "May kuyog dito. Pangunahan mo kami.",
                                        "Masyadong marami sa bukas na lugar. Susulong o liliko?",
                                        "Maraming kalaban. Ano'ng pasya?",
                                        "May kuyog sa dinaraanan. Laban o iwas?",
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
            ["responsePlanID"] = "combat.horde.prompt.reserved",
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
                            ["fallback"] = "Horde ahead. Engage or go around?",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.horde.prompt.reserved.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_combat/combat_horde_prompt_reserved.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Horde ahead. Engage or go around?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.prompt.reserved.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Horde ahead. Engage or go around?",
                        "Crowd spotted. Call it.",
                        "Massed dead. Fight or bypass?",
                        "Swarm blocking route. Your call.",
                        "Large group. Stand and fight or slip past?",
                        "Herd ahead. Make a choice.",
                        "Horde present. Direct us.",
                        "Too many in the open. Do we push or turn?",
                        "Mass contacts. Decision?",
                        "Herd in path. Fight or avoid?",
                    },
                    ["TL"] = {
                        "May kuyog sa unahan. Lalaban o iiwas?",
                        "May nakitang grupo. Desisyunan mo.",
                        "Nagtitipong mga patay. Lalabanan o lalagpasan?",
                        "Harang ang kuyog sa daan. Ikaw ang masusunod.",
                        "Malaking grupo. Tatayo at lalaban o lulusot?",
                        "Kawan sa harap. Pumili ka.",
                        "May kuyog dito. Pangunahan mo kami.",
                        "Masyadong marami sa bukas na lugar. Susulong o liliko?",
                        "Maraming kalaban. Ano'ng pasya?",
                        "May kuyog sa dinaraanan. Laban o iwas?",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_combat",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.horde.prompt.shaken",
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
                                ["fallback"] = "God... that's a lot. Are we really fighting all of them?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.horde.prompt.shaken.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "God... that's a lot. Are we really fighting all of them?",
                                        "Look at the size of that crowd... can we go around?",
                                        "They'll swarm us if we step out there. Please, let's retreat.",
                                        "There are way too many... my hands are shaking.",
                                        "We can't handle this many at once. Can we slip away?",
                                        "Jesus, don't shoot... they'll tear us apart.",
                                        "Are we seriously thinking of fighting that horde?",
                                        "I don't think we survive that fight. Let's run.",
                                        "Too many rottens... what do you want to do?",
                                        "That swarm is terrifying. Tell me we're bypassing it.",
                                    },
                                    ["TL"] = {
                                        "Diyos ko... ang dami nila. Lalabanan talaga natin lahat 'yan?",
                                        "Tingnan mo ang laki ng kuyog... pwede ba tayong umikot?",
                                        "Kukuyugin nila tayo kapag lumabas tayo. Pakiusap, umatras tayo.",
                                        "Masyado silang marami... nanginginig ang mga kamay ko.",
                                        "Hindi natin kaya ang ganyan karami nang sabay. Pwede bang tumakas?",
                                        "Diyos ko, huwag kang puputok... pupunitin nila tayo.",
                                        "Seryoso ba tayong lalabanan ang kuyog na 'yan?",
                                        "Sa tingin ko hindi tayo mabubuhay sa laban na 'yan. Tumakbo na tayo.",
                                        "Masyadong maraming bulok... ano'ng gusto mong gawin?",
                                        "Nakakatakot ang kuyog na 'yan. Sabihin mong iiwasan natin.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.horde.prompt",
            ["textRoles"] = {
                {
                    ["fallback"] = "God... that's a lot. Are we really fighting all of them?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.prompt.shaken.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "God... that's a lot. Are we really fighting all of them?",
                            "Look at the size of that crowd... can we go around?",
                            "They'll swarm us if we step out there. Please, let's retreat.",
                            "There are way too many... my hands are shaking.",
                            "We can't handle this many at once. Can we slip away?",
                            "Jesus, don't shoot... they'll tear us apart.",
                            "Are we seriously thinking of fighting that horde?",
                            "I don't think we survive that fight. Let's run.",
                            "Too many rottens... what do you want to do?",
                            "That swarm is terrifying. Tell me we're bypassing it.",
                        },
                        ["TL"] = {
                            "Diyos ko... ang dami nila. Lalabanan talaga natin lahat 'yan?",
                            "Tingnan mo ang laki ng kuyog... pwede ba tayong umikot?",
                            "Kukuyugin nila tayo kapag lumabas tayo. Pakiusap, umatras tayo.",
                            "Masyado silang marami... nanginginig ang mga kamay ko.",
                            "Hindi natin kaya ang ganyan karami nang sabay. Pwede bang tumakas?",
                            "Diyos ko, huwag kang puputok... pupunitin nila tayo.",
                            "Seryoso ba tayong lalabanan ang kuyog na 'yan?",
                            "Sa tingin ko hindi tayo mabubuhay sa laban na 'yan. Tumakbo na tayo.",
                            "Masyadong maraming bulok... ano'ng gusto mong gawin?",
                            "Nakakatakot ang kuyog na 'yan. Sabihin mong iiwasan natin.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.horde.prompt.shaken",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "shaken",
            ["sourceId"] = "combat.horde.prompt.shaken",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_combat/combat_horde_prompt_shaken.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsCombat",
        ["namespace"] = "combat.horde.prompt",
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
                                        "God... that's a lot. Are we really fighting all of them?",
                                        "Look at the size of that crowd... can we go around?",
                                        "They'll swarm us if we step out there. Please, let's retreat.",
                                        "There are way too many... my hands are shaking.",
                                        "We can't handle this many at once. Can we slip away?",
                                        "Jesus, don't shoot... they'll tear us apart.",
                                        "Are we seriously thinking of fighting that horde?",
                                        "I don't think we survive that fight. Let's run.",
                                        "Too many rottens... what do you want to do?",
                                        "That swarm is terrifying. Tell me we're bypassing it.",
                                    },
                                    ["TL"] = {
                                        "Diyos ko... ang dami nila. Lalabanan talaga natin lahat 'yan?",
                                        "Tingnan mo ang laki ng kuyog... pwede ba tayong umikot?",
                                        "Kukuyugin nila tayo kapag lumabas tayo. Pakiusap, umatras tayo.",
                                        "Masyado silang marami... nanginginig ang mga kamay ko.",
                                        "Hindi natin kaya ang ganyan karami nang sabay. Pwede bang tumakas?",
                                        "Diyos ko, huwag kang puputok... pupunitin nila tayo.",
                                        "Seryoso ba tayong lalabanan ang kuyog na 'yan?",
                                        "Sa tingin ko hindi tayo mabubuhay sa laban na 'yan. Tumakbo na tayo.",
                                        "Masyadong maraming bulok... ano'ng gusto mong gawin?",
                                        "Nakakatakot ang kuyog na 'yan. Sabihin mong iiwasan natin.",
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
            ["responsePlanID"] = "combat.horde.prompt.shaken",
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
                            ["fallback"] = "God... that's a lot. Are we really fighting all of them?",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.horde.prompt.shaken.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_combat/combat_horde_prompt_shaken.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "God... that's a lot. Are we really fighting all of them?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.prompt.shaken.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "God... that's a lot. Are we really fighting all of them?",
                        "Look at the size of that crowd... can we go around?",
                        "They'll swarm us if we step out there. Please, let's retreat.",
                        "There are way too many... my hands are shaking.",
                        "We can't handle this many at once. Can we slip away?",
                        "Jesus, don't shoot... they'll tear us apart.",
                        "Are we seriously thinking of fighting that horde?",
                        "I don't think we survive that fight. Let's run.",
                        "Too many rottens... what do you want to do?",
                        "That swarm is terrifying. Tell me we're bypassing it.",
                    },
                    ["TL"] = {
                        "Diyos ko... ang dami nila. Lalabanan talaga natin lahat 'yan?",
                        "Tingnan mo ang laki ng kuyog... pwede ba tayong umikot?",
                        "Kukuyugin nila tayo kapag lumabas tayo. Pakiusap, umatras tayo.",
                        "Masyado silang marami... nanginginig ang mga kamay ko.",
                        "Hindi natin kaya ang ganyan karami nang sabay. Pwede bang tumakas?",
                        "Diyos ko, huwag kang puputok... pupunitin nila tayo.",
                        "Seryoso ba tayong lalabanan ang kuyog na 'yan?",
                        "Sa tingin ko hindi tayo mabubuhay sa laban na 'yan. Tumakbo na tayo.",
                        "Masyadong maraming bulok... ano'ng gusto mong gawin?",
                        "Nakakatakot ang kuyog na 'yan. Sabihin mong iiwasan natin.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_combat",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.horde.started",
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
                                ["fallback"] = "That's a lot of them. Stay sharp.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.horde.started.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "That's a lot of them. Stay sharp.",
                                        "We've got a whole crowd moving in. Eyes open.",
                                        "Horde spotted! Check your exits.",
                                        "Too many bodies out there. Watch the perimeter.",
                                        "They're grouping up. Form a line.",
                                        "Sound drew a swarm. Get ready.",
                                        "Look at that herd. Stay close.",
                                        "Mass contacts coming from down the street.",
                                        "Here they come. Don't let them flank us.",
                                        "Big group incoming. Watch each other's backs.",
                                    },
                                    ["TL"] = {
                                        "Ang dami nila. Mag-ingat tayo.",
                                        "May malaking grupo na paparating. Magmatyag.",
                                        "May kuyog! Tignan ang mga labasan.",
                                        "Masyado silang marami sa labas. Bantayan ang paligid.",
                                        "Nagsasama-sama sila. Ayusin ang hanay.",
                                        "Nakaakit ng kuyog ang ingay. Humanda.",
                                        "Tingnan mo ang kawan na 'yan. Dumikit ka.",
                                        "Napakaraming papalapit mula sa kalsada.",
                                        "Heto na sila. Huwag silang hayaang pumaligid.",
                                        "Malaking grupo ang dumarating. Bantayan ang likod ng bawat isa.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.horde",
            ["textRoles"] = {
                {
                    ["fallback"] = "That's a lot of them. Stay sharp.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.started.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "That's a lot of them. Stay sharp.",
                            "We've got a whole crowd moving in. Eyes open.",
                            "Horde spotted! Check your exits.",
                            "Too many bodies out there. Watch the perimeter.",
                            "They're grouping up. Form a line.",
                            "Sound drew a swarm. Get ready.",
                            "Look at that herd. Stay close.",
                            "Mass contacts coming from down the street.",
                            "Here they come. Don't let them flank us.",
                            "Big group incoming. Watch each other's backs.",
                        },
                        ["TL"] = {
                            "Ang dami nila. Mag-ingat tayo.",
                            "May malaking grupo na paparating. Magmatyag.",
                            "May kuyog! Tignan ang mga labasan.",
                            "Masyado silang marami sa labas. Bantayan ang paligid.",
                            "Nagsasama-sama sila. Ayusin ang hanay.",
                            "Nakaakit ng kuyog ang ingay. Humanda.",
                            "Tingnan mo ang kawan na 'yan. Dumikit ka.",
                            "Napakaraming papalapit mula sa kalsada.",
                            "Heto na sila. Huwag silang hayaang pumaligid.",
                            "Malaking grupo ang dumarating. Bantayan ang likod ng bawat isa.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.horde.started",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "started",
            ["sourceId"] = "combat.horde.started",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_combat/combat_horde_started.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsCombat",
        ["namespace"] = "combat.horde",
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
                                        "That's a lot of them. Stay sharp.",
                                        "We've got a whole crowd moving in. Eyes open.",
                                        "Horde spotted! Check your exits.",
                                        "Too many bodies out there. Watch the perimeter.",
                                        "They're grouping up. Form a line.",
                                        "Sound drew a swarm. Get ready.",
                                        "Look at that herd. Stay close.",
                                        "Mass contacts coming from down the street.",
                                        "Here they come. Don't let them flank us.",
                                        "Big group incoming. Watch each other's backs.",
                                    },
                                    ["TL"] = {
                                        "Ang dami nila. Mag-ingat tayo.",
                                        "May malaking grupo na paparating. Magmatyag.",
                                        "May kuyog! Tignan ang mga labasan.",
                                        "Masyado silang marami sa labas. Bantayan ang paligid.",
                                        "Nagsasama-sama sila. Ayusin ang hanay.",
                                        "Nakaakit ng kuyog ang ingay. Humanda.",
                                        "Tingnan mo ang kawan na 'yan. Dumikit ka.",
                                        "Napakaraming papalapit mula sa kalsada.",
                                        "Heto na sila. Huwag silang hayaang pumaligid.",
                                        "Malaking grupo ang dumarating. Bantayan ang likod ng bawat isa.",
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
            ["responsePlanID"] = "combat.horde.started",
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
                            ["fallback"] = "That's a lot of them. Stay sharp.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.combat.horde.started.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_combat/combat_horde_started.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That's a lot of them. Stay sharp.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.started.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "That's a lot of them. Stay sharp.",
                        "We've got a whole crowd moving in. Eyes open.",
                        "Horde spotted! Check your exits.",
                        "Too many bodies out there. Watch the perimeter.",
                        "They're grouping up. Form a line.",
                        "Sound drew a swarm. Get ready.",
                        "Look at that herd. Stay close.",
                        "Mass contacts coming from down the street.",
                        "Here they come. Don't let them flank us.",
                        "Big group incoming. Watch each other's backs.",
                    },
                    ["TL"] = {
                        "Ang dami nila. Mag-ingat tayo.",
                        "May malaking grupo na paparating. Magmatyag.",
                        "May kuyog! Tignan ang mga labasan.",
                        "Masyado silang marami sa labas. Bantayan ang paligid.",
                        "Nagsasama-sama sila. Ayusin ang hanay.",
                        "Nakaakit ng kuyog ang ingay. Humanda.",
                        "Tingnan mo ang kawan na 'yan. Dumikit ka.",
                        "Napakaraming papalapit mula sa kalsada.",
                        "Heto na sila. Huwag silang hayaang pumaligid.",
                        "Malaking grupo ang dumarating. Bantayan ang likod ng bawat isa.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
