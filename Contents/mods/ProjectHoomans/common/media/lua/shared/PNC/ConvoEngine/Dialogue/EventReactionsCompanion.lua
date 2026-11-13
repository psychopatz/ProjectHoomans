-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "event_reactions_companion",
        ["id"] = "semantic.companion.reaction.abandonment",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "abandonment",
            ["sourceId"] = "semantic.companion.reaction.abandonment",
            ["sourcePath"] = "adopters/hoomans/dialogue/event_reactions_companion/companion_reaction_abandonment.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsCompanion",
        ["namespace"] = "semantic.companion.reaction",
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
                ["responseTemplateID"] = "semantic.companion.reaction.abandonment",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/reactions/companion.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Stay with me next time. We watch each other's backs.",
                            },
                            ["TL"] = {
                                "Sumabay ka sa akin sa susunod. Nagbabantayan tayo ng likod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Don't leave me behind like that. We survive together.",
                            },
                            ["TL"] = {
                                "Huwag mo akong iiwan nang gano'n. Sabay tayong mabubuhay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I almost got swarmed when you ran off. Stick close.",
                            },
                            ["TL"] = {
                                "Halos makuyog ako no'ng umalis ka. Dumikit ka lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "We're a team. Don't take off on your own.",
                            },
                            ["TL"] = {
                                "Magkasama tayo. Huwag kang aalis nang mag-isa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Where did you go?! You can't just vanish.",
                            },
                            ["TL"] = {
                                "Saan ka pumunta?! Hindi ka pwedeng mawala na lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Next time, warn me before you leave.",
                            },
                            ["TL"] = {
                                "Sa susunod, sabihan mo ako bago ka umalis.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Thought I was on my own out there. Stay together.",
                            },
                            ["TL"] = {
                                "Akala ko naiwan na akong mag-isa. Magsama tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Leaving your partner gets people killed. Keep near.",
                            },
                            ["TL"] = {
                                "Ang pag-iwan sa kasama ay nakakamatay. Dumikit ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Glad you're back, but don't ditch me again.",
                            },
                            ["TL"] = {
                                "Mabuti at bumalik ka, pero huwag mo na akong iiwan ulit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Stick with me. We're stronger as a pair.",
                            },
                            ["TL"] = {
                                "Sumabay ka sa akin. Mas malakas tayo kapag magkasama.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/event_reactions_companion/companion_reaction_abandonment.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_companion",
        ["id"] = "semantic.companion.reaction.camp_rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "camp_rejected",
            ["sourceId"] = "semantic.companion.reaction.camp_rejected",
            ["sourcePath"] = "adopters/hoomans/dialogue/event_reactions_companion/companion_reaction_camp_rejected.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsCompanion",
        ["namespace"] = "semantic.companion.reaction",
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
                ["responseTemplateID"] = "semantic.companion.reaction.camp_rejected",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/reactions/companion.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't find a safe room or campfire nearby.",
                            },
                            ["TL"] = {
                                "Wala akong makitang ligtas na kwarto o campfire sa malapit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Nowhere safe to rest around here. We need better cover.",
                            },
                            ["TL"] = {
                                "Walang ligtas na pahingahan dito. Kailangan natin ng mas maayos na silungan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Can't camp in the open like this. Too dangerous.",
                            },
                            ["TL"] = {
                                "Hindi pwedeng magkampo sa lantad nang ganito. Masyadong delikado.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "We need walls or a fire before we settle down.",
                            },
                            ["TL"] = {
                                "Kailangan natin ng pader o apoy bago huminto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "This spot isn't secure enough for camp. Keep walking.",
                            },
                            ["TL"] = {
                                "Hindi sapat ang kaligtasan ng pwestong 'to para sa kampo. Lakad pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "No shelter here. Let's find four walls first.",
                            },
                            ["TL"] = {
                                "Walang masisilungan dito. Maghanap muna tayo ng apat na pader.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Can't sleep here. Infected could walk right in.",
                            },
                            ["TL"] = {
                                "Hindi pwedeng matulog dito. Madaling makakapasok ang mga infected.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "We need a barricaded room or a campfire before resting.",
                            },
                            ["TL"] = {
                                "Kailangan natin ng may barikadang kwarto o campfire bago magpahinga.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Not pitching camp here. Let's find a secure building.",
                            },
                            ["TL"] = {
                                "Hindi ako magkakampo rito. Maghanap tayo ng ligtas na gusali.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Too exposed. Find us a real camp spot.",
                            },
                            ["TL"] = {
                                "Masyadong lantad. Hanapan mo tayo ng tunay na matutuluyan.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/event_reactions_companion/companion_reaction_camp_rejected.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_companion",
        ["id"] = "semantic.companion.reaction.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "default",
            ["sourceId"] = "semantic.companion.reaction.default",
            ["sourcePath"] = "adopters/hoomans/dialogue/event_reactions_companion/companion_reaction_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsCompanion",
        ["namespace"] = "semantic.companion.reaction",
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
                ["responseTemplateID"] = "semantic.companion.reaction.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/reactions/companion.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "ACK",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I heard you. We will handle it together.",
                            },
                            ["TL"] = {
                                "Narinig kita. Sabay natin 'yang haharapin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. I'm right here with you.",
                            },
                            ["TL"] = {
                                "Naintindihan ko. Nandito lang ako kasama mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Got your message. Let's get it done.",
                            },
                            ["TL"] = {
                                "Nakuha ko ang sabi mo. Tapusin na natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'm with you. Lead the way.",
                            },
                            ["TL"] = {
                                "Kasama mo ako. Ikaw ang manguna.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Heard. Whatever comes, we take it on.",
                            },
                            ["TL"] = {
                                "Narinig ko. Kahit ano'ng dumating, lalabanan natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Copy that. Staying right by your side.",
                            },
                            ["TL"] = {
                                "Kopya. Dito lang ako sa tabi mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I hear you loud and clear. Let's move.",
                            },
                            ["TL"] = {
                                "Malinaw kong narinig. Kilos na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Count on me. We're in this together.",
                            },
                            ["TL"] = {
                                "Maaasahan mo ako. Magkasama tayo rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Let's keep our heads clear.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Panatilihing malinaw ang isip natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Right behind you. Let's handle this.",
                            },
                            ["TL"] = {
                                "Nasa likod mo lang ako. Asikasuhin natin 'to.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/event_reactions_companion/companion_reaction_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
