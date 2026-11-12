-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_argument",
        ["id"] = "semantic.interaction.argument.deescalate.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.argument.deescalate.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_argument.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionArgument/Catalog",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.argument.deescalate",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/argument/deescalate.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Fine. Just lower your voice.",
                            },
                            ["TL"] = {
                                "Sige. Hinaan mo lang ang boses mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Lower your tone before you draw attention.",
                            },
                            ["TL"] = {
                                "Hinaan mo ang tono mo bago ka makahatak ng pansin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Stop yelling. You want every dead head hearing this?",
                            },
                            ["TL"] = {
                                "Huwag kang sumigaw. Gusto mo bang marinig tayo ng mga patay?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "All right. Keep it down and back off.",
                            },
                            ["TL"] = {
                                "Sige. Hinaan ang boses at umatras.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Enough. Lower the volume right now.",
                            },
                            ["TL"] = {
                                "Sapat na. Hinaan mo ang boses mo ngayon din.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "I heard you. Now drop the shouting.",
                            },
                            ["TL"] = {
                                "Narinig kita. Ngayon tigilan mo ang pagsigaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Shh! Keep your voice down.",
                            },
                            ["TL"] = {
                                "Shh! Hinaan mo ang boses mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Keep it civil and quiet. We're in danger.",
                            },
                            ["TL"] = {
                                "Maging maayos at tahimik. Nasa panganib tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Lower your voice. I'm not deaf.",
                            },
                            ["TL"] = {
                                "Hinaan mo ang boses. Hindi ako bingi.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Fine. Just tone it down.",
                            },
                            ["TL"] = {
                                "Sige. Hinaan mo lang.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_argument.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_argument",
        ["id"] = "semantic.interaction.argument.deescalate.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.argument.deescalate.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_argument.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionArgument/Catalog",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.argument.deescalate",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/argument/deescalate.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Easy. We don't need to make this worse.",
                            },
                            ["TL"] = {
                                "Dahan-dahan. Hindi natin kailangang palalain pa ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Let's calm down and talk this through reasonably.",
                            },
                            ["TL"] = {
                                "Kumalma tayo at pag-usapan ito nang maayos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Take a breath. Bickering won't fix anything.",
                            },
                            ["TL"] = {
                                "Huminga ka nang malalim. Walang maaayos ang bangayan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "No need for tempers to flare. Let's settle it.",
                            },
                            ["TL"] = {
                                "Di kailangang mag-init ang ulo. Ayusin natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Easy does it. We're on the same side here.",
                            },
                            ["TL"] = {
                                "Dahan-dahan lang. Magkasama tayo rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Let's step back and look at the situation calmly.",
                            },
                            ["TL"] = {
                                "Umatras muna tayo at tingnan ang sitwasyon nang mahinahon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "We can resolve this without shouting.",
                            },
                            ["TL"] = {
                                "Maaayos natin ito nang hindi sumisigaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Keep cool. Let's find a workable solution.",
                            },
                            ["TL"] = {
                                "Kumalma ka lang. Maghanap tayo ng maayos na solusyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Easy now. Don't lose your head over this.",
                            },
                            ["TL"] = {
                                "Dahan-dahan lang. Huwag mawalan ng katinuan dahil dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Hold on. Let's de-escalate before someone gets hurt.",
                            },
                            ["TL"] = {
                                "Teka muna. Huminahon tayo bago may masaktan.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_argument.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_argument",
        ["id"] = "semantic.interaction.argument.deescalate.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.argument.deescalate.terse",
            ["sourcePath"] = "psdl/dialogue/social_interaction_argument.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionArgument/Catalog",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.argument.deescalate",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/argument/deescalate.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Easy.",
                            },
                            ["TL"] = {
                                "Dahan-dahan.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Calm down.",
                            },
                            ["TL"] = {
                                "Kumalma ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Drop it.",
                            },
                            ["TL"] = {
                                "Tama na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Quiet.",
                            },
                            ["TL"] = {
                                "Tahimik.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Breathe.",
                            },
                            ["TL"] = {
                                "Huminga ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Cool off.",
                            },
                            ["TL"] = {
                                "Palamig ka muna.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Steady.",
                            },
                            ["TL"] = {
                                "Magpakatatag.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Enough.",
                            },
                            ["TL"] = {
                                "Sapat na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Hold up.",
                            },
                            ["TL"] = {
                                "Teka lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Stop.",
                            },
                            ["TL"] = {
                                "Tigil.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_argument.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_argument",
        ["id"] = "semantic.interaction.argument.deescalate.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.argument.deescalate.warm",
            ["sourcePath"] = "psdl/dialogue/social_interaction_argument.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionArgument/Catalog",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.argument.deescalate",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/argument/deescalate.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "Calm down. This isn't helping either of us.",
                            },
                            ["TL"] = {
                                "Kumalma ka. Walang naitutulong ito sa atin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Hey, look at me. We're friends, remember?",
                            },
                            ["TL"] = {
                                "Huy, tingnan mo ako. Magkaibigan tayo, tandaan mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Take a breath. I'm right here with you. Let's work it out.",
                            },
                            ["TL"] = {
                                "Huminga ka muna. Narito lang ako kasama mo. Aayusin natin 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "I know you're stressed. Let's pause and decompress.",
                            },
                            ["TL"] = {
                                "Alam kong pagod ka. Huminto muna tayo at magpahinga.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Don't let the anger take over. We care about each other.",
                            },
                            ["TL"] = {
                                "Huwag mong hayaang lamunin ka ng galit. May malasakit tayo sa isa't isa.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "We're going to get through this, I promise. Calm down.",
                            },
                            ["TL"] = {
                                "Malalampasan natin ito, pangako. Kumalma ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "I hear your pain. Let's talk gently.",
                            },
                            ["TL"] = {
                                "Naririnig ko ang hirap mo. Mag-usap tayo nang mahinahon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "It's all right. I'm listening. Just bring the energy down.",
                            },
                            ["TL"] = {
                                "Ayos lang. Nakikinig ako. Ibaba mo lang ang init ng ulo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "We've survived too much together to fight like this.",
                            },
                            ["TL"] = {
                                "Masyado na tayong maraming pinagdaanan para mag-away nang ganito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Peace, friend. We are stronger together.",
                            },
                            ["TL"] = {
                                "Kapayapaan, kaibigan. Mas malakas tayo kapag magkasama.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_argument.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_argument",
        ["id"] = "semantic.interaction.argument.retaliate.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.argument.retaliate.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_argument.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionArgument/Catalog",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.argument.retaliate",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/argument/retaliate.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Say that again and see how far it gets you.",
                            },
                            ["TL"] = {
                                "Sabihin mo ulit at tingnan natin kung saan ka aabot.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "You want to push this? I will push back harder.",
                            },
                            ["TL"] = {
                                "Gusto mong isagad ito? Mas malakas akong gaganti.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Don't make threats you can't survive.",
                            },
                            ["TL"] = {
                                "Huwag kang magbanta ng hindi mo kayang maligtasan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Try me. See what happens to you.",
                            },
                            ["TL"] = {
                                "Subukan mo ako. Tingnan mo kung anong mangyayari sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "You're digging your own grave with that talk.",
                            },
                            ["TL"] = {
                                "Hinuhukay mo ang sarili mong libingan sa salitang 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Keep running that mouth and find out.",
                            },
                            ["TL"] = {
                                "Sige, magpatuloy ka sa kadadaldal at nang malaman mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not the one to mess with out here.",
                            },
                            ["TL"] = {
                                "Hindi ako ang taong dapat mong ginagalit dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Push one more inch and we have bloodshed.",
                            },
                            ["TL"] = {
                                "Sumulong ka pa nang isang pulgada at magkakadugo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Say it one more time. I dare you.",
                            },
                            ["TL"] = {
                                "Ulitin mo pa nang isang beses. Hinahamon kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "You will regret crossing me.",
                            },
                            ["TL"] = {
                                "Pagsisisihan mo ang pagbangga sa akin.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_argument.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_argument",
        ["id"] = "semantic.interaction.argument.retaliate.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.argument.retaliate.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_argument.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionArgument/Catalog",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.argument.retaliate",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/argument/retaliate.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "You're really testing me right now.",
                            },
                            ["TL"] = {
                                "Talagang sinusubok mo ang pasensya ko ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Don't push your luck any further.",
                            },
                            ["TL"] = {
                                "Huwag mo nang isugal pa ang suwerte mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "You're out of line, and I won't stand for it.",
                            },
                            ["TL"] = {
                                "Sumusobra ka na, at hindi ako papayag diyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "You started this, but I'll finish it if I have to.",
                            },
                            ["TL"] = {
                                "Ikaw ang nagsimula, pero tatapusin ko kung kailangan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "You're making a massive mistake talking to me like that.",
                            },
                            ["TL"] = {
                                "Napakalaking pagkakamali ang kausapin ako nang ganyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Think very carefully about what you say next.",
                            },
                            ["TL"] = {
                                "Pag-isipan mong mabuti ang susunod mong sasabihin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I've had about enough of your disrespect.",
                            },
                            ["TL"] = {
                                "Sapat na ang pambabastos mo sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "You're crossing a boundary you can't walk back.",
                            },
                            ["TL"] = {
                                "Tumatawid ka sa hangganang hindi mo na mababawi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Back down before this escalates completely.",
                            },
                            ["TL"] = {
                                "Umatras ka bago pa tuluyang magkagulo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I'm answering in kind: knock it off.",
                            },
                            ["TL"] = {
                                "Sasagutin kita nang patas: itigil mo na 'yan.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_argument.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_argument",
        ["id"] = "semantic.interaction.argument.retaliate.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.argument.retaliate.terse",
            ["sourcePath"] = "psdl/dialogue/social_interaction_argument.json#records[6]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionArgument/Catalog",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.argument.retaliate",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/argument/retaliate.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Keep talking.",
                            },
                            ["TL"] = {
                                "Sige, magsalita ka pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Try it.",
                            },
                            ["TL"] = {
                                "Subukan mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Dare you.",
                            },
                            ["TL"] = {
                                "Hamon ko sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Push me.",
                            },
                            ["TL"] = {
                                "Itulak mo ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Wrong move.",
                            },
                            ["TL"] = {
                                "Maling hakbang.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Big mistake.",
                            },
                            ["TL"] = {
                                "Malaking pagkakamali.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Last chance.",
                            },
                            ["TL"] = {
                                "Huling pagkakataon.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Bring it.",
                            },
                            ["TL"] = {
                                "Sige, ilabas mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Don't test me.",
                            },
                            ["TL"] = {
                                "Huwag mo akong subukan.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Watch yourself.",
                            },
                            ["TL"] = {
                                "Mag-ingat ka.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_argument.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_argument",
        ["id"] = "semantic.interaction.argument.retaliate.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.argument.retaliate.warm",
            ["sourcePath"] = "psdl/dialogue/social_interaction_argument.json#records[7]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionArgument/Catalog",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.argument.retaliate",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/argument/retaliate.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "You're pushing this too far.",
                            },
                            ["TL"] = {
                                "Sobra na ang ginagawa mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "I've been patient with you, but you're crossing the line.",
                            },
                            ["TL"] = {
                                "Matiisin ako sa 'yo, pero lumalagpas ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Don't make me treat you like a stranger.",
                            },
                            ["TL"] = {
                                "Huwag mo akong piliting tratuhin ka na parang estranghero.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "I didn't think you would turn on me like this.",
                            },
                            ["TL"] = {
                                "Di ko akalaing kakalabanin mo ako nang ganito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "You're hurting someone who actually cared about you.",
                            },
                            ["TL"] = {
                                "Sinasaktan mo ang taong may tunay na malasakit sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Stop pushing me away with this cruelty.",
                            },
                            ["TL"] = {
                                "Tigilan mo ang pagtataboy sa akin gamit ang lupit na 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "If you keep attacking me, I will protect myself.",
                            },
                            ["TL"] = {
                                "Kung patuloy mo akong aatakihin, ipagtatanggol ko ang sarili ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "You're throwing our bond away right in front of me.",
                            },
                            ["TL"] = {
                                "Itinatapon mo ang samahan natin mismo sa harap ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "I expected better from you. Don't push me further.",
                            },
                            ["TL"] = {
                                "Umasa ako ng mas maayos sa 'yo. Huwag mo na akong itulak.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Check yourself. I won't just stand here and take abuse.",
                            },
                            ["TL"] = {
                                "Ayusin mo sarili mo. Di ako tatayo lang dito para magpaabuso.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_argument.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
