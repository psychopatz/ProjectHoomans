-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_combat",
        ["domainPath"] = "companion_commands_combat",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.horde.choice",
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
                                ["id"] = "avoid",
                                ["templateID"] = "convo.combat.horde.choice.say.1.avoid",
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
                            {
                                ["fallback"] = "Take them.",
                                ["id"] = "engage",
                                ["templateID"] = "convo.combat.horde.choice.say.1.engage",
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
                            {
                                ["fallback"] = "Hold for now.",
                                ["id"] = "hold",
                                ["templateID"] = "convo.combat.horde.choice.say.1.hold",
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
            ["namespace"] = "combat.horde",
            ["slots"] = {
                ["threat"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.threat",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "Go around.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.choice.say.1.avoid",
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
                    ["variantID"] = "avoid",
                },
                {
                    ["fallback"] = "Take them.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.choice.say.1.engage",
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
                    ["variantID"] = "engage",
                },
                {
                    ["fallback"] = "Hold for now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.horde.choice.say.1.hold",
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
                    ["variantID"] = "hold",
                },
            },
        },
        ["id"] = "combat.horde.choice",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "choice",
            ["sourceId"] = "combat.horde.choice",
            ["sourcePath"] = "dialogue/companion_commands_combat/combat_horde_choice.json",
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
            ["domains"] = {
                {
                    ["domain"] = "combat",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["events"] = {
                {
                    ["id"] = "horde_detected",
                    ["kind"] = "world_event",
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
                                ["id"] = "avoid",
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
                            {
                                ["id"] = "engage",
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
                            {
                                ["id"] = "hold",
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
            ["topics"] = {
                {
                    ["domain"] = "combat",
                    ["id"] = "horde_threat",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REPLY",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "combat.horde.choice",
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
                            ["templateID"] = "convo.combat.horde.choice.say_1",
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
            ["threat"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.threat",
            },
        },
        ["sourceShard"] = "dialogue/companion_commands_combat/combat_horde_choice.json",
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
                ["templateID"] = "convo.combat.horde.choice.say.1.avoid",
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
                ["variantID"] = "avoid",
            },
            {
                ["fallback"] = "Take them.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.choice.say.1.engage",
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
                ["variantID"] = "engage",
            },
            {
                ["fallback"] = "Hold for now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.horde.choice.say.1.hold",
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
                ["variantID"] = "hold",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_combat",
        ["domainPath"] = "companion_commands_combat",
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
            ["slots"] = {
                ["threat"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.threat",
                },
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
        },
        ["id"] = "combat.horde.deescalated",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "deescalated",
            ["sourceId"] = "combat.horde.deescalated",
            ["sourcePath"] = "dialogue/companion_commands_combat/combat_horde_deescalated.json",
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
            ["domains"] = {
                {
                    ["domain"] = "combat",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["events"] = {
                {
                    ["id"] = "horde_detected",
                    ["kind"] = "world_event",
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
            ["topics"] = {
                {
                    ["domain"] = "combat",
                    ["id"] = "horde_threat",
                },
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
                            ["templateID"] = "convo.combat.horde.deescalated.say_1",
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
            ["threat"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.threat",
            },
        },
        ["sourceShard"] = "dialogue/companion_commands_combat/combat_horde_deescalated.json",
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
        ["domainPath"] = "companion_commands_combat",
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
            ["slots"] = {
                ["threat"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.threat",
                },
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
        },
        ["id"] = "combat.horde.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "default",
            ["sourceId"] = "combat.horde.default",
            ["sourcePath"] = "dialogue/companion_commands_combat/combat_horde_default.json",
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
            ["domains"] = {
                {
                    ["domain"] = "combat",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["events"] = {
                {
                    ["id"] = "horde_detected",
                    ["kind"] = "world_event",
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
            ["topics"] = {
                {
                    ["domain"] = "combat",
                    ["id"] = "horde_threat",
                },
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
                            ["templateID"] = "convo.combat.horde.default.say_1",
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
            ["threat"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.threat",
            },
        },
        ["sourceShard"] = "dialogue/companion_commands_combat/combat_horde_default.json",
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
        ["domainPath"] = "companion_commands_combat",
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
            ["slots"] = {
                ["threat"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.threat",
                },
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
        },
        ["id"] = "combat.horde.escalated",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "escalated",
            ["sourceId"] = "combat.horde.escalated",
            ["sourcePath"] = "dialogue/companion_commands_combat/combat_horde_escalated.json",
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
            ["domains"] = {
                {
                    ["domain"] = "combat",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["events"] = {
                {
                    ["id"] = "horde_detected",
                    ["kind"] = "world_event",
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
            ["topics"] = {
                {
                    ["domain"] = "combat",
                    ["id"] = "horde_threat",
                },
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
                            ["templateID"] = "convo.combat.horde.escalated.say_1",
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
            ["threat"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.threat",
            },
        },
        ["sourceShard"] = "dialogue/companion_commands_combat/combat_horde_escalated.json",
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
        ["domainPath"] = "companion_commands_combat",
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
            ["slots"] = {
                ["threat"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.threat",
                },
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
        },
        ["id"] = "combat.horde.started",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "started",
            ["sourceId"] = "combat.horde.started",
            ["sourcePath"] = "dialogue/companion_commands_combat/combat_horde_started.json",
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
            ["domains"] = {
                {
                    ["domain"] = "combat",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["events"] = {
                {
                    ["id"] = "horde_detected",
                    ["kind"] = "world_event",
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
            ["topics"] = {
                {
                    ["domain"] = "combat",
                    ["id"] = "horde_threat",
                },
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
                            ["templateID"] = "convo.combat.horde.started.say_1",
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
            ["threat"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.threat",
            },
        },
        ["sourceShard"] = "dialogue/companion_commands_combat/combat_horde_started.json",
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
