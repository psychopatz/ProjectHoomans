-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.traveling.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.whats_up.traveling.warm",
            ["sourcePath"] = "psdl/dialogue/conversation_whats_up.json#records[15]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_whats_up_traveling_warm",
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
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
                ["responseTemplateID"] = "semantic.question.whats_up.traveling",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/conversation.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm keeping moving and watching what is ahead. Come along if you want.",
                            },
                            ["TL"] = {
                                "Patuloy akong gumagalaw at binabantayan ang nasa unahan. Sumama ka kung gusto mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "On the trail today! It's always safer and nicer walking together.",
                            },
                            ["TL"] = {
                                "Nasa daan ngayon! Laging mas ligtas at masaya kapag may kasamang maglakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Traveling light. Feel free to tag along if you're headed that way.",
                            },
                            ["TL"] = {
                                "Magaan ang dala. Sumabay ka kung papunta ka rin doon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Making my way down the road. Glad I crossed paths with you today.",
                            },
                            ["TL"] = {
                                "Bumabagtas sa daan. Masaya akong nakasalubong kita ngayong araw.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Covering ground, but always happy to pause and say hello to a friend.",
                            },
                            ["TL"] = {
                                "Nagmamadali man, masaya pa ring huminto para kumustahin ang kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Walking between camps. Safe travels on your end, my friend.",
                            },
                            ["TL"] = {
                                "Naglalakad patungo sa kabilang kampo. Ingat sa biyahe mo, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Heading out for a bit. Watch your step, and maybe we'll meet again soon.",
                            },
                            ["TL"] = {
                                "Aalis lang sandali. Mag-ingat sa paghakbang, at magkikita rin tayo mamaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "The road feels a lot less lonely whenever I see you around.",
                            },
                            ["TL"] = {
                                "Hindi nakakalungkot ang daan kapag nakakasalubong kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Moving along, but I'm glad our paths crossed. Stay safe out there.",
                            },
                            ["TL"] = {
                                "Lumalakad, pero masayang nagkasalubong tayo. Mag-ingat ka palagi sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Traveling to check on our boundaries. Good to see you in high spirits.",
                            },
                            ["TL"] = {
                                "Tinitingnan ang hangganan ng kampo. Masarap kang makitang nasa maayos na lagay.",
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
        ["sourceShard"] = "psdl/dialogue/conversation_whats_up.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
