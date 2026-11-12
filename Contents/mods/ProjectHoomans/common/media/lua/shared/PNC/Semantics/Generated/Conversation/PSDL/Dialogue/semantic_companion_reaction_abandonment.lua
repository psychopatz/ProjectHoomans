-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "event_reactions_companion",
        ["id"] = "semantic.companion.reaction.abandonment",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.companion.reaction.abandonment",
            ["sourcePath"] = "psdl/dialogue/event_reactions_companion.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_companion_reaction_abandonment",
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
        ["sourceShard"] = "psdl/dialogue/event_reactions_companion.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
