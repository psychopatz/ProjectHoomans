-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_needs",
        ["id"] = "semantic.question.needs.offer.hunger.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.needs.offer.hunger.guarded",
            ["sourcePath"] = "psdl/dialogue/conversation_needs.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_needs_offer_hunger_guarded",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.question.needs.offer.hunger",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/needs.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "I need food. Keep your distance.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng pagkain. Lumayo ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "If that food has strings attached, forget it.",
                            },
                            ["TL"] = {
                                "Kung may kapalit ang pagkaing 'yan, huwag na lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'm hungry, but don't try anything funny.",
                            },
                            ["TL"] = {
                                "Gutom ako, pero huwag kang magtangkang manloko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Put the food down on the ground and step back.",
                            },
                            ["TL"] = {
                                "Ilapag mo ang pagkain sa lupa at umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "I could use rations, but I won't owe you my life.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng rasyon, pero hindi ko ibebenta ang sarili ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Is that sealed? I don't take spoiled or poisoned rations.",
                            },
                            ["TL"] = {
                                "Selyado ba 'yan? Hindi ako kumakain ng panis o may lason.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "I need food, but keep your hands where I can see them.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng pagkain, pero ilagay ang kamay sa kita ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Only take what you're offering freely. No hidden deals.",
                            },
                            ["TL"] = {
                                "Kukunin ko lang kung bukal sa loob. Walang tagong kasunduan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'm starving, but I'm still armed. Remember that.",
                            },
                            ["TL"] = {
                                "Gutom ako, pero may armas pa rin ako. Tandaan mo 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Leave the supplies right there. No sudden moves.",
                            },
                            ["TL"] = {
                                "Iwan mo ang gamit diyan. Walang biglaang galaw.",
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
        ["sourceShard"] = "psdl/dialogue/conversation_needs.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
