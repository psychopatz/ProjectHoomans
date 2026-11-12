-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "event_reactions_corpse",
        ["id"] = "semantic.corpse.reaction.revenge",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.corpse.reaction.revenge",
            ["sourcePath"] = "psdl/dialogue/event_reactions_corpse.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_corpse_reaction_revenge",
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
                ["responseTemplateID"] = "semantic.corpse.reaction.revenge",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/reactions/corpse.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Someone is going to answer for this.",
                            },
                            ["TL"] = {
                                "May mananagot para rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "They didn't deserve this. Whoever did it will pay.",
                            },
                            ["TL"] = {
                                "Hindi nila nararapat 'to. Pagbabayaran 'to ng may gawa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "This wasn't rottens, this was murder. They'll bleed for it.",
                            },
                            ["TL"] = {
                                "Hindi 'to gawa ng infected, patayan 'to. Dudugo sila para rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'll find whoever did this and make them regret it.",
                            },
                            ["TL"] = {
                                "Hahanapin ko ang may gawa nito at pagsisisihan nila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "They slaughtered them. There's no forgiving this.",
                            },
                            ["TL"] = {
                                "Pinaslang nila sila. Walang kapatawaran ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Mark my words, retribution is coming for them.",
                            },
                            ["TL"] = {
                                "Tandaan mo, darating ang ganti para sa kanila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Whoever left this body won't walk away clean.",
                            },
                            ["TL"] = {
                                "Ang nag-iwan ng bangkay na 'to ay hindi makakatakas nang buo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Cold-blooded. I won't forget this sight.",
                            },
                            ["TL"] = {
                                "Walang awang pagpatay. Hindi ko makakalimutan ang nakita ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Blood demands blood. We settle this score.",
                            },
                            ["TL"] = {
                                "Dugo ang kabayaran ng dugo. Tutuldukan natin 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "They butchered one of our own. They will pay.",
                            },
                            ["TL"] = {
                                "Kinatay nila ang isa sa atin. Pagbabayaran nila.",
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
        ["sourceShard"] = "psdl/dialogue/event_reactions_corpse.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
