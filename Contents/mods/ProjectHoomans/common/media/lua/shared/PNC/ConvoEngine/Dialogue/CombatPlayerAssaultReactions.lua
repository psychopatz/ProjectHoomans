-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_player_assault_reactions",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.player_assaulted.aggressive",
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
                                ["fallback"] = "You just made a big mistake.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.player_assaulted.aggressive.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "You just made a big mistake.",
                                        "All right. You want a fight, you've got one.",
                                        "You hit me? You're going to regret that.",
                                        "Try that again and see what happens.",
                                        "Wrong person to mess with.",
                                        "You want some of this?! Come on then!",
                                        "That was your last free shot.",
                                        "I'll put you in the ground for that.",
                                        "You swung at me? Big mistake.",
                                        "You really want to do this? Let's go.",
                                    },
                                    ["TL"] = {
                                        "Malaking pagkakamali ang ginawa mo.",
                                        "Sige. Gusto mo ng laban, makukuha mo.",
                                        "Sinaktan mo ako? Pagsisisihan mo 'yan.",
                                        "Ulitin mo pa at tignan natin ang mangyayari.",
                                        "Maling tao ang binangga mo.",
                                        "Gusto mo pala ng gulo?! Halika rito!",
                                        "Huling libreng tira mo na 'yon.",
                                        "Ililibing kita sa ginawa mo.",
                                        "Hinataw mo ako? Malaking mali.",
                                        "Gusto mo talagang gawin 'to? Tara.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.player_assaulted",
            ["textRoles"] = {
                {
                    ["fallback"] = "You just made a big mistake.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.player_assaulted.aggressive.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "You just made a big mistake.",
                            "All right. You want a fight, you've got one.",
                            "You hit me? You're going to regret that.",
                            "Try that again and see what happens.",
                            "Wrong person to mess with.",
                            "You want some of this?! Come on then!",
                            "That was your last free shot.",
                            "I'll put you in the ground for that.",
                            "You swung at me? Big mistake.",
                            "You really want to do this? Let's go.",
                        },
                        ["TL"] = {
                            "Malaking pagkakamali ang ginawa mo.",
                            "Sige. Gusto mo ng laban, makukuha mo.",
                            "Sinaktan mo ako? Pagsisisihan mo 'yan.",
                            "Ulitin mo pa at tignan natin ang mangyayari.",
                            "Maling tao ang binangga mo.",
                            "Gusto mo pala ng gulo?! Halika rito!",
                            "Huling libreng tira mo na 'yon.",
                            "Ililibing kita sa ginawa mo.",
                            "Hinataw mo ako? Malaking mali.",
                            "Gusto mo talagang gawin 'to? Tara.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.player_assaulted.aggressive",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "aggressive",
            ["sourceId"] = "combat.player_assaulted.aggressive",
            ["sourcePath"] = "adopters/hoomans/dialogue/combat_player_assault_reactions/combat_player_assaulted_aggressive.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatPlayerAssaultReactions",
        ["namespace"] = "combat.player_assaulted",
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
                ["category"] = "projecthoomans:combat_kill",
                ["contentOwner"] = "projecthoomans.dialogue_content.combat",
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
                                        "You just made a big mistake.",
                                        "All right. You want a fight, you've got one.",
                                        "You hit me? You're going to regret that.",
                                        "Try that again and see what happens.",
                                        "Wrong person to mess with.",
                                        "You want some of this?! Come on then!",
                                        "That was your last free shot.",
                                        "I'll put you in the ground for that.",
                                        "You swung at me? Big mistake.",
                                        "You really want to do this? Let's go.",
                                    },
                                    ["TL"] = {
                                        "Malaking pagkakamali ang ginawa mo.",
                                        "Sige. Gusto mo ng laban, makukuha mo.",
                                        "Sinaktan mo ako? Pagsisisihan mo 'yan.",
                                        "Ulitin mo pa at tignan natin ang mangyayari.",
                                        "Maling tao ang binangga mo.",
                                        "Gusto mo pala ng gulo?! Halika rito!",
                                        "Huling libreng tira mo na 'yon.",
                                        "Ililibing kita sa ginawa mo.",
                                        "Hinataw mo ako? Malaking mali.",
                                        "Gusto mo talagang gawin 'to? Tara.",
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
            ["responsePlanID"] = "combat.player_assaulted.aggressive",
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
                            ["fallback"] = "You just made a big mistake.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.player_assaulted.aggressive.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/combat_player_assault_reactions/combat_player_assaulted_aggressive.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "You just made a big mistake.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.player_assaulted.aggressive.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "You just made a big mistake.",
                        "All right. You want a fight, you've got one.",
                        "You hit me? You're going to regret that.",
                        "Try that again and see what happens.",
                        "Wrong person to mess with.",
                        "You want some of this?! Come on then!",
                        "That was your last free shot.",
                        "I'll put you in the ground for that.",
                        "You swung at me? Big mistake.",
                        "You really want to do this? Let's go.",
                    },
                    ["TL"] = {
                        "Malaking pagkakamali ang ginawa mo.",
                        "Sige. Gusto mo ng laban, makukuha mo.",
                        "Sinaktan mo ako? Pagsisisihan mo 'yan.",
                        "Ulitin mo pa at tignan natin ang mangyayari.",
                        "Maling tao ang binangga mo.",
                        "Gusto mo pala ng gulo?! Halika rito!",
                        "Huling libreng tira mo na 'yon.",
                        "Ililibing kita sa ginawa mo.",
                        "Hinataw mo ako? Malaking mali.",
                        "Gusto mo talagang gawin 'to? Tara.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_player_assault_reactions",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.player_assaulted.brave",
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
                                ["fallback"] = "That's it. You're done.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.player_assaulted.brave.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "That's it. You're done.",
                                        "Bad choice. Defend yourself.",
                                        "You shouldn't have done that.",
                                        "I gave you space. Now defend yourself.",
                                        "That's where this ends.",
                                        "You made your choice.",
                                        "I won't let you hurt me. Stand down or fight.",
                                        "Unacceptable. Drop your weapon.",
                                        "You crossed the line.",
                                        "Stand down right now, or I finish this.",
                                    },
                                    ["TL"] = {
                                        "Tama na. Tapos ka na.",
                                        "Maling desisyon. Ipagtanggol mo ang sarili mo.",
                                        "Hindi mo dapat ginawa 'yon.",
                                        "Binigyan kita ng puwang. Ipagtanggol mo sarili mo ngayon.",
                                        "Diyan na nagtatapos 'to.",
                                        "Pumili ka na ng kahihinatnan mo.",
                                        "Hindi kita hahayaang saktan ako. Sumuko ka o lumaban.",
                                        "Hindi katanggap-tanggap. Ibaba mo ang sandata mo.",
                                        "Lumagpas ka sa linya.",
                                        "Tumigil ka ngayon din, o tatapusin ko 'to.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.player_assaulted",
            ["textRoles"] = {
                {
                    ["fallback"] = "That's it. You're done.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.player_assaulted.brave.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "That's it. You're done.",
                            "Bad choice. Defend yourself.",
                            "You shouldn't have done that.",
                            "I gave you space. Now defend yourself.",
                            "That's where this ends.",
                            "You made your choice.",
                            "I won't let you hurt me. Stand down or fight.",
                            "Unacceptable. Drop your weapon.",
                            "You crossed the line.",
                            "Stand down right now, or I finish this.",
                        },
                        ["TL"] = {
                            "Tama na. Tapos ka na.",
                            "Maling desisyon. Ipagtanggol mo ang sarili mo.",
                            "Hindi mo dapat ginawa 'yon.",
                            "Binigyan kita ng puwang. Ipagtanggol mo sarili mo ngayon.",
                            "Diyan na nagtatapos 'to.",
                            "Pumili ka na ng kahihinatnan mo.",
                            "Hindi kita hahayaang saktan ako. Sumuko ka o lumaban.",
                            "Hindi katanggap-tanggap. Ibaba mo ang sandata mo.",
                            "Lumagpas ka sa linya.",
                            "Tumigil ka ngayon din, o tatapusin ko 'to.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.player_assaulted.brave",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "brave",
            ["sourceId"] = "combat.player_assaulted.brave",
            ["sourcePath"] = "adopters/hoomans/dialogue/combat_player_assault_reactions/combat_player_assaulted_brave.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatPlayerAssaultReactions",
        ["namespace"] = "combat.player_assaulted",
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
                ["category"] = "projecthoomans:combat_kill",
                ["contentOwner"] = "projecthoomans.dialogue_content.combat",
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
                                        "That's it. You're done.",
                                        "Bad choice. Defend yourself.",
                                        "You shouldn't have done that.",
                                        "I gave you space. Now defend yourself.",
                                        "That's where this ends.",
                                        "You made your choice.",
                                        "I won't let you hurt me. Stand down or fight.",
                                        "Unacceptable. Drop your weapon.",
                                        "You crossed the line.",
                                        "Stand down right now, or I finish this.",
                                    },
                                    ["TL"] = {
                                        "Tama na. Tapos ka na.",
                                        "Maling desisyon. Ipagtanggol mo ang sarili mo.",
                                        "Hindi mo dapat ginawa 'yon.",
                                        "Binigyan kita ng puwang. Ipagtanggol mo sarili mo ngayon.",
                                        "Diyan na nagtatapos 'to.",
                                        "Pumili ka na ng kahihinatnan mo.",
                                        "Hindi kita hahayaang saktan ako. Sumuko ka o lumaban.",
                                        "Hindi katanggap-tanggap. Ibaba mo ang sandata mo.",
                                        "Lumagpas ka sa linya.",
                                        "Tumigil ka ngayon din, o tatapusin ko 'to.",
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
            ["responsePlanID"] = "combat.player_assaulted.brave",
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
                            ["fallback"] = "That's it. You're done.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.player_assaulted.brave.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/combat_player_assault_reactions/combat_player_assaulted_brave.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That's it. You're done.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.player_assaulted.brave.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "That's it. You're done.",
                        "Bad choice. Defend yourself.",
                        "You shouldn't have done that.",
                        "I gave you space. Now defend yourself.",
                        "That's where this ends.",
                        "You made your choice.",
                        "I won't let you hurt me. Stand down or fight.",
                        "Unacceptable. Drop your weapon.",
                        "You crossed the line.",
                        "Stand down right now, or I finish this.",
                    },
                    ["TL"] = {
                        "Tama na. Tapos ka na.",
                        "Maling desisyon. Ipagtanggol mo ang sarili mo.",
                        "Hindi mo dapat ginawa 'yon.",
                        "Binigyan kita ng puwang. Ipagtanggol mo sarili mo ngayon.",
                        "Diyan na nagtatapos 'to.",
                        "Pumili ka na ng kahihinatnan mo.",
                        "Hindi kita hahayaang saktan ako. Sumuko ka o lumaban.",
                        "Hindi katanggap-tanggap. Ibaba mo ang sandata mo.",
                        "Lumagpas ka sa linya.",
                        "Tumigil ka ngayon din, o tatapusin ko 'to.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_player_assault_reactions",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.player_assaulted.default",
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
                                ["fallback"] = "Why did you do that?!",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.player_assaulted.default.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Why did you do that?!",
                                        "What the hell is wrong with you?!",
                                        "Hey! Watch what you're doing!",
                                        "Did you just swing at me?!",
                                        "Are you trying to kill me?!",
                                        "What are you thinking?! Stop it!",
                                        "Whoa! Back off!",
                                        "Don't hit me! What's wrong with you?!",
                                        "Stop swinging at me!",
                                        "Back away from me!",
                                    },
                                    ["TL"] = {
                                        "Bakit mo ginawa iyon?!",
                                        "Ano bang problema mo?!",
                                        "Hoy! Tingnan mo ang ginagawa mo!",
                                        "Hinataw mo ba ako?!",
                                        "Gusto mo ba akong patayin?!",
                                        "Ano bang iniisip mo?! Tigil!",
                                        "Teka! Atras!",
                                        "Huwag mo akong saktan! Ano bang nangyayari sa'yo?!",
                                        "Huwag mo akong pagbantaan!",
                                        "Umatras ka palayo sa akin!",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.player_assaulted",
            ["textRoles"] = {
                {
                    ["fallback"] = "Why did you do that?!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.player_assaulted.default.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Why did you do that?!",
                            "What the hell is wrong with you?!",
                            "Hey! Watch what you're doing!",
                            "Did you just swing at me?!",
                            "Are you trying to kill me?!",
                            "What are you thinking?! Stop it!",
                            "Whoa! Back off!",
                            "Don't hit me! What's wrong with you?!",
                            "Stop swinging at me!",
                            "Back away from me!",
                        },
                        ["TL"] = {
                            "Bakit mo ginawa iyon?!",
                            "Ano bang problema mo?!",
                            "Hoy! Tingnan mo ang ginagawa mo!",
                            "Hinataw mo ba ako?!",
                            "Gusto mo ba akong patayin?!",
                            "Ano bang iniisip mo?! Tigil!",
                            "Teka! Atras!",
                            "Huwag mo akong saktan! Ano bang nangyayari sa'yo?!",
                            "Huwag mo akong pagbantaan!",
                            "Umatras ka palayo sa akin!",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.player_assaulted.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "default",
            ["sourceId"] = "combat.player_assaulted.default",
            ["sourcePath"] = "adopters/hoomans/dialogue/combat_player_assault_reactions/combat_player_assaulted_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatPlayerAssaultReactions",
        ["namespace"] = "combat.player_assaulted",
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
                ["category"] = "projecthoomans:combat_kill",
                ["contentOwner"] = "projecthoomans.dialogue_content.combat",
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
                                        "Why did you do that?!",
                                        "What the hell is wrong with you?!",
                                        "Hey! Watch what you're doing!",
                                        "Did you just swing at me?!",
                                        "Are you trying to kill me?!",
                                        "What are you thinking?! Stop it!",
                                        "Whoa! Back off!",
                                        "Don't hit me! What's wrong with you?!",
                                        "Stop swinging at me!",
                                        "Back away from me!",
                                    },
                                    ["TL"] = {
                                        "Bakit mo ginawa iyon?!",
                                        "Ano bang problema mo?!",
                                        "Hoy! Tingnan mo ang ginagawa mo!",
                                        "Hinataw mo ba ako?!",
                                        "Gusto mo ba akong patayin?!",
                                        "Ano bang iniisip mo?! Tigil!",
                                        "Teka! Atras!",
                                        "Huwag mo akong saktan! Ano bang nangyayari sa'yo?!",
                                        "Huwag mo akong pagbantaan!",
                                        "Umatras ka palayo sa akin!",
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
            ["responsePlanID"] = "combat.player_assaulted.default",
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
                            ["fallback"] = "Why did you do that?!",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.player_assaulted.default.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/combat_player_assault_reactions/combat_player_assaulted_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Why did you do that?!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.player_assaulted.default.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Why did you do that?!",
                        "What the hell is wrong with you?!",
                        "Hey! Watch what you're doing!",
                        "Did you just swing at me?!",
                        "Are you trying to kill me?!",
                        "What are you thinking?! Stop it!",
                        "Whoa! Back off!",
                        "Don't hit me! What's wrong with you?!",
                        "Stop swinging at me!",
                        "Back away from me!",
                    },
                    ["TL"] = {
                        "Bakit mo ginawa iyon?!",
                        "Ano bang problema mo?!",
                        "Hoy! Tingnan mo ang ginagawa mo!",
                        "Hinataw mo ba ako?!",
                        "Gusto mo ba akong patayin?!",
                        "Ano bang iniisip mo?! Tigil!",
                        "Teka! Atras!",
                        "Huwag mo akong saktan! Ano bang nangyayari sa'yo?!",
                        "Huwag mo akong pagbantaan!",
                        "Umatras ka palayo sa akin!",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_player_assault_reactions",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.player_assaulted.reserved",
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
                                ["fallback"] = "Back off. Now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.player_assaulted.reserved.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Back off. Now.",
                                        "Enough. Stay away from me.",
                                        "Step back.",
                                        "Do not do that again.",
                                        "Don't touch me.",
                                        "Last warning.",
                                        "Stay back.",
                                        "Drop it.",
                                        "Keep your distance.",
                                        "One step back. Right now.",
                                    },
                                    ["TL"] = {
                                        "Lumayo ka. Ngayon na.",
                                        "Tama na. Lumayo ka sa akin.",
                                        "Umatras ka.",
                                        "Huwag mong uulitin 'yon.",
                                        "Huwag mo akong hahawakan.",
                                        "Huling babala.",
                                        "Diyan ka lang sa malayo.",
                                        "Ibaba mo 'yan.",
                                        "Dumistansya ka.",
                                        "Isang hakbang pabalik. Ngayon na.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.player_assaulted",
            ["textRoles"] = {
                {
                    ["fallback"] = "Back off. Now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.player_assaulted.reserved.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Back off. Now.",
                            "Enough. Stay away from me.",
                            "Step back.",
                            "Do not do that again.",
                            "Don't touch me.",
                            "Last warning.",
                            "Stay back.",
                            "Drop it.",
                            "Keep your distance.",
                            "One step back. Right now.",
                        },
                        ["TL"] = {
                            "Lumayo ka. Ngayon na.",
                            "Tama na. Lumayo ka sa akin.",
                            "Umatras ka.",
                            "Huwag mong uulitin 'yon.",
                            "Huwag mo akong hahawakan.",
                            "Huling babala.",
                            "Diyan ka lang sa malayo.",
                            "Ibaba mo 'yan.",
                            "Dumistansya ka.",
                            "Isang hakbang pabalik. Ngayon na.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.player_assaulted.reserved",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "reserved",
            ["sourceId"] = "combat.player_assaulted.reserved",
            ["sourcePath"] = "adopters/hoomans/dialogue/combat_player_assault_reactions/combat_player_assaulted_reserved.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatPlayerAssaultReactions",
        ["namespace"] = "combat.player_assaulted",
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
                ["category"] = "projecthoomans:combat_kill",
                ["contentOwner"] = "projecthoomans.dialogue_content.combat",
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
                                        "Back off. Now.",
                                        "Enough. Stay away from me.",
                                        "Step back.",
                                        "Do not do that again.",
                                        "Don't touch me.",
                                        "Last warning.",
                                        "Stay back.",
                                        "Drop it.",
                                        "Keep your distance.",
                                        "One step back. Right now.",
                                    },
                                    ["TL"] = {
                                        "Lumayo ka. Ngayon na.",
                                        "Tama na. Lumayo ka sa akin.",
                                        "Umatras ka.",
                                        "Huwag mong uulitin 'yon.",
                                        "Huwag mo akong hahawakan.",
                                        "Huling babala.",
                                        "Diyan ka lang sa malayo.",
                                        "Ibaba mo 'yan.",
                                        "Dumistansya ka.",
                                        "Isang hakbang pabalik. Ngayon na.",
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
            ["responsePlanID"] = "combat.player_assaulted.reserved",
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
                            ["fallback"] = "Back off. Now.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.player_assaulted.reserved.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/combat_player_assault_reactions/combat_player_assaulted_reserved.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Back off. Now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.player_assaulted.reserved.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Back off. Now.",
                        "Enough. Stay away from me.",
                        "Step back.",
                        "Do not do that again.",
                        "Don't touch me.",
                        "Last warning.",
                        "Stay back.",
                        "Drop it.",
                        "Keep your distance.",
                        "One step back. Right now.",
                    },
                    ["TL"] = {
                        "Lumayo ka. Ngayon na.",
                        "Tama na. Lumayo ka sa akin.",
                        "Umatras ka.",
                        "Huwag mong uulitin 'yon.",
                        "Huwag mo akong hahawakan.",
                        "Huling babala.",
                        "Diyan ka lang sa malayo.",
                        "Ibaba mo 'yan.",
                        "Dumistansya ka.",
                        "Isang hakbang pabalik. Ngayon na.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_player_assault_reactions",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.player_assaulted.shaken",
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
                                ["fallback"] = "What the hell?! Stay back!",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.player_assaulted.shaken.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "What the hell?! Stay back!",
                                        "Why are you attacking me?! Get back!",
                                        "Stop! What are you doing?!",
                                        "Don't touch me! Are you crazy?!",
                                        "Get away from me right now!",
                                        "Jesus, back off! Put that away!",
                                        "Why would you hit me?! Get back!",
                                        "Stay away from me! Don't do this!",
                                        "Are you out of your mind?! Stop!",
                                        "Back off! Don't come any closer!",
                                    },
                                    ["TL"] = {
                                        "Ano ba?! Lumayo ka!",
                                        "Bakit mo ako inaatake?! Lumayo ka!",
                                        "Tigil! Ano bang ginagawa mo?!",
                                        "Huwag mo akong hawakan! Nababaliw ka na ba?!",
                                        "Umalis ka sa harap ko ngayon din!",
                                        "Diyos ko, atras! Ibaba mo 'yan!",
                                        "Bakit mo ako sinaktan?! Lumayo ka!",
                                        "Lumayo ka sa akin! Huwag mong gawin 'to!",
                                        "Nawawala ka na ba sa sarili mo?! Tigil!",
                                        "Atras! Huwag kang lalapit pa!",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.player_assaulted",
            ["textRoles"] = {
                {
                    ["fallback"] = "What the hell?! Stay back!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.player_assaulted.shaken.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "What the hell?! Stay back!",
                            "Why are you attacking me?! Get back!",
                            "Stop! What are you doing?!",
                            "Don't touch me! Are you crazy?!",
                            "Get away from me right now!",
                            "Jesus, back off! Put that away!",
                            "Why would you hit me?! Get back!",
                            "Stay away from me! Don't do this!",
                            "Are you out of your mind?! Stop!",
                            "Back off! Don't come any closer!",
                        },
                        ["TL"] = {
                            "Ano ba?! Lumayo ka!",
                            "Bakit mo ako inaatake?! Lumayo ka!",
                            "Tigil! Ano bang ginagawa mo?!",
                            "Huwag mo akong hawakan! Nababaliw ka na ba?!",
                            "Umalis ka sa harap ko ngayon din!",
                            "Diyos ko, atras! Ibaba mo 'yan!",
                            "Bakit mo ako sinaktan?! Lumayo ka!",
                            "Lumayo ka sa akin! Huwag mong gawin 'to!",
                            "Nawawala ka na ba sa sarili mo?! Tigil!",
                            "Atras! Huwag kang lalapit pa!",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.player_assaulted.shaken",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "shaken",
            ["sourceId"] = "combat.player_assaulted.shaken",
            ["sourcePath"] = "adopters/hoomans/dialogue/combat_player_assault_reactions/combat_player_assaulted_shaken.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatPlayerAssaultReactions",
        ["namespace"] = "combat.player_assaulted",
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
                ["category"] = "projecthoomans:combat_kill",
                ["contentOwner"] = "projecthoomans.dialogue_content.combat",
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
                                        "What the hell?! Stay back!",
                                        "Why are you attacking me?! Get back!",
                                        "Stop! What are you doing?!",
                                        "Don't touch me! Are you crazy?!",
                                        "Get away from me right now!",
                                        "Jesus, back off! Put that away!",
                                        "Why would you hit me?! Get back!",
                                        "Stay away from me! Don't do this!",
                                        "Are you out of your mind?! Stop!",
                                        "Back off! Don't come any closer!",
                                    },
                                    ["TL"] = {
                                        "Ano ba?! Lumayo ka!",
                                        "Bakit mo ako inaatake?! Lumayo ka!",
                                        "Tigil! Ano bang ginagawa mo?!",
                                        "Huwag mo akong hawakan! Nababaliw ka na ba?!",
                                        "Umalis ka sa harap ko ngayon din!",
                                        "Diyos ko, atras! Ibaba mo 'yan!",
                                        "Bakit mo ako sinaktan?! Lumayo ka!",
                                        "Lumayo ka sa akin! Huwag mong gawin 'to!",
                                        "Nawawala ka na ba sa sarili mo?! Tigil!",
                                        "Atras! Huwag kang lalapit pa!",
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
            ["responsePlanID"] = "combat.player_assaulted.shaken",
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
                            ["fallback"] = "What the hell?! Stay back!",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.player_assaulted.shaken.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/combat_player_assault_reactions/combat_player_assaulted_shaken.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "What the hell?! Stay back!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.player_assaulted.shaken.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "What the hell?! Stay back!",
                        "Why are you attacking me?! Get back!",
                        "Stop! What are you doing?!",
                        "Don't touch me! Are you crazy?!",
                        "Get away from me right now!",
                        "Jesus, back off! Put that away!",
                        "Why would you hit me?! Get back!",
                        "Stay away from me! Don't do this!",
                        "Are you out of your mind?! Stop!",
                        "Back off! Don't come any closer!",
                    },
                    ["TL"] = {
                        "Ano ba?! Lumayo ka!",
                        "Bakit mo ako inaatake?! Lumayo ka!",
                        "Tigil! Ano bang ginagawa mo?!",
                        "Huwag mo akong hawakan! Nababaliw ka na ba?!",
                        "Umalis ka sa harap ko ngayon din!",
                        "Diyos ko, atras! Ibaba mo 'yan!",
                        "Bakit mo ako sinaktan?! Lumayo ka!",
                        "Lumayo ka sa akin! Huwag mong gawin 'to!",
                        "Nawawala ka na ba sa sarili mo?! Tigil!",
                        "Atras! Huwag kang lalapit pa!",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
