-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_player_assault_reactions",
        ["id"] = "semantic.combat.player_assaulted.aggressive",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.player_assaulted.aggressive",
            ["sourcePath"] = "psdl/dialogue/combat_player_assault_reactions.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CombatPlayerAssaultReactions/Catalog",
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
                ["responseTemplateID"] = "semantic.combat.player_assaulted.aggressive",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/combat/player_assault_reactions.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "You just made a big mistake.",
                            },
                            ["TL"] = {
                                "Malaking pagkakamali ang ginawa mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "All right. You want a fight, you've got one.",
                            },
                            ["TL"] = {
                                "Sige. Gusto mo ng laban, makukuha mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "You hit me? You're going to regret that.",
                            },
                            ["TL"] = {
                                "Sinaktan mo ako? Pagsisisihan mo 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Try that again and see what happens.",
                            },
                            ["TL"] = {
                                "Ulitin mo pa at tignan natin ang mangyayari.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Wrong person to mess with.",
                            },
                            ["TL"] = {
                                "Maling tao ang binangga mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "You want some of this?! Come on then!",
                            },
                            ["TL"] = {
                                "Gusto mo pala ng gulo?! Halika rito!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "That was your last free shot.",
                            },
                            ["TL"] = {
                                "Huling libreng tira mo na 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'll put you in the ground for that.",
                            },
                            ["TL"] = {
                                "Ililibing kita sa ginawa mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "You swung at me? Big mistake.",
                            },
                            ["TL"] = {
                                "Hinataw mo ako? Malaking mali.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "You really want to do this? Let's go.",
                            },
                            ["TL"] = {
                                "Gusto mo talagang gawin 'to? Tara.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/combat_player_assault_reactions.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_player_assault_reactions",
        ["id"] = "semantic.combat.player_assaulted.brave",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.player_assaulted.brave",
            ["sourcePath"] = "psdl/dialogue/combat_player_assault_reactions.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CombatPlayerAssaultReactions/Catalog",
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
                ["responseTemplateID"] = "semantic.combat.player_assaulted.brave",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/combat/player_assault_reactions.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "That's it. You're done.",
                            },
                            ["TL"] = {
                                "Tama na. Tapos ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Bad choice. Defend yourself.",
                            },
                            ["TL"] = {
                                "Maling desisyon. Ipagtanggol mo ang sarili mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "You shouldn't have done that.",
                            },
                            ["TL"] = {
                                "Hindi mo dapat ginawa 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I gave you space. Now defend yourself.",
                            },
                            ["TL"] = {
                                "Binigyan kita ng puwang. Ipagtanggol mo sarili mo ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "That's where this ends.",
                            },
                            ["TL"] = {
                                "Diyan na nagtatapos 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "You made your choice.",
                            },
                            ["TL"] = {
                                "Pumili ka na ng kahihinatnan mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I won't let you hurt me. Stand down or fight.",
                            },
                            ["TL"] = {
                                "Hindi kita hahayaang saktan ako. Sumuko ka o lumaban.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Unacceptable. Drop your weapon.",
                            },
                            ["TL"] = {
                                "Hindi katanggap-tanggap. Ibaba mo ang sandata mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "You crossed the line.",
                            },
                            ["TL"] = {
                                "Lumagpas ka sa linya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Stand down right now, or I finish this.",
                            },
                            ["TL"] = {
                                "Tumigil ka ngayon din, o tatapusin ko 'to.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/combat_player_assault_reactions.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_player_assault_reactions",
        ["id"] = "semantic.combat.player_assaulted.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.player_assaulted.default",
            ["sourcePath"] = "psdl/dialogue/combat_player_assault_reactions.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CombatPlayerAssaultReactions/Catalog",
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
                ["responseTemplateID"] = "semantic.combat.player_assaulted.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/combat/player_assault_reactions.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Why did you do that?!",
                            },
                            ["TL"] = {
                                "Bakit mo ginawa iyon?!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "What the hell is wrong with you?!",
                            },
                            ["TL"] = {
                                "Ano bang problema mo?!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Hey! Watch what you're doing!",
                            },
                            ["TL"] = {
                                "Hoy! Tingnan mo ang ginagawa mo!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Did you just swing at me?!",
                            },
                            ["TL"] = {
                                "Hinataw mo ba ako?!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Are you trying to kill me?!",
                            },
                            ["TL"] = {
                                "Gusto mo ba akong patayin?!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "What are you thinking?! Stop it!",
                            },
                            ["TL"] = {
                                "Ano bang iniisip mo?! Tigil!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Whoa! Back off!",
                            },
                            ["TL"] = {
                                "Teka! Atras!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Don't hit me! What's wrong with you?!",
                            },
                            ["TL"] = {
                                "Huwag mo akong saktan! Ano bang nangyayari sa'yo?!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Stop swinging at me!",
                            },
                            ["TL"] = {
                                "Huwag mo akong pagbantaan!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Back away from me!",
                            },
                            ["TL"] = {
                                "Umatras ka palayo sa akin!",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/combat_player_assault_reactions.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_player_assault_reactions",
        ["id"] = "semantic.combat.player_assaulted.reserved",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.player_assaulted.reserved",
            ["sourcePath"] = "psdl/dialogue/combat_player_assault_reactions.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CombatPlayerAssaultReactions/Catalog",
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
                ["responseTemplateID"] = "semantic.combat.player_assaulted.reserved",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/combat/player_assault_reactions.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Back off. Now.",
                            },
                            ["TL"] = {
                                "Lumayo ka. Ngayon na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Enough. Stay away from me.",
                            },
                            ["TL"] = {
                                "Tama na. Lumayo ka sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Step back.",
                            },
                            ["TL"] = {
                                "Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Do not do that again.",
                            },
                            ["TL"] = {
                                "Huwag mong uulitin 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Don't touch me.",
                            },
                            ["TL"] = {
                                "Huwag mo akong hahawakan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Last warning.",
                            },
                            ["TL"] = {
                                "Huling babala.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Stay back.",
                            },
                            ["TL"] = {
                                "Diyan ka lang sa malayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Drop it.",
                            },
                            ["TL"] = {
                                "Ibaba mo 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your distance.",
                            },
                            ["TL"] = {
                                "Dumistansya ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "One step back. Right now.",
                            },
                            ["TL"] = {
                                "Isang hakbang pabalik. Ngayon na.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/combat_player_assault_reactions.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_player_assault_reactions",
        ["id"] = "semantic.combat.player_assaulted.shaken",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.player_assaulted.shaken",
            ["sourcePath"] = "psdl/dialogue/combat_player_assault_reactions.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CombatPlayerAssaultReactions/Catalog",
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
                ["responseTemplateID"] = "semantic.combat.player_assaulted.shaken",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/combat/player_assault_reactions.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "What the hell?! Stay back!",
                            },
                            ["TL"] = {
                                "Ano ba?! Lumayo ka!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Why are you attacking me?! Get back!",
                            },
                            ["TL"] = {
                                "Bakit mo ako inaatake?! Lumayo ka!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Stop! What are you doing?!",
                            },
                            ["TL"] = {
                                "Tigil! Ano bang ginagawa mo?!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Don't touch me! Are you crazy?!",
                            },
                            ["TL"] = {
                                "Huwag mo akong hawakan! Nababaliw ka na ba?!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Get away from me right now!",
                            },
                            ["TL"] = {
                                "Umalis ka sa harap ko ngayon din!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Jesus, back off! Put that away!",
                            },
                            ["TL"] = {
                                "Diyos ko, atras! Ibaba mo 'yan!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Why would you hit me?! Get back!",
                            },
                            ["TL"] = {
                                "Bakit mo ako sinaktan?! Lumayo ka!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Stay away from me! Don't do this!",
                            },
                            ["TL"] = {
                                "Lumayo ka sa akin! Huwag mong gawin 'to!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Are you out of your mind?! Stop!",
                            },
                            ["TL"] = {
                                "Nawawala ka na ba sa sarili mo?! Tigil!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Back off! Don't come any closer!",
                            },
                            ["TL"] = {
                                "Atras! Huwag kang lalapit pa!",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/combat_player_assault_reactions.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
