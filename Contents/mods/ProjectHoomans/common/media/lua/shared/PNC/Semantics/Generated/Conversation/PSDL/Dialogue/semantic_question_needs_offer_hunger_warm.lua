-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_needs",
        ["id"] = "semantic.question.needs.offer.hunger.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.needs.offer.hunger.warm",
            ["sourcePath"] = "psdl/dialogue/conversation_needs.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_needs_offer_hunger_warm",
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
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "Food would help, if you can spare it.",
                            },
                            ["TL"] = {
                                "Makakatulong ang pagkain, kung may maibibigay ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "I'd truly appreciate a bite to eat, friend, if you have extra.",
                            },
                            ["TL"] = {
                                "Lubos kong pasasalamatan ang makakain, kaibigan, kung may sobra ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "You're very kind to offer. Some food would really lift my spirits.",
                            },
                            ["TL"] = {
                                "Napakabait mong mag-alok. Talagang magpapagaan ng loob ko ang pagkain.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "I could definitely use a meal. Thank you for thinking of me.",
                            },
                            ["TL"] = {
                                "Kailangan ko nga ng makakain. Salamat sa pag-alala sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Sharing rations is generous out here. I'd be grateful for anything.",
                            },
                            ["TL"] = {
                                "Napakabuting magbahagi ng rasyon dito. Masaya ako sa kahit ano.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "A bit of food would mean the world right now, thank you.",
                            },
                            ["TL"] = {
                                "Napakalaking bagay ng kahit kaunting pagkain ngayon, salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "If you've got food to share, I won't say no. You're a lifesaver.",
                            },
                            ["TL"] = {
                                "Kung may maibabahagi kang pagkain, tatanggapin ko. Ligtas ako sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'm hungry, and your generosity means a lot. Thank you.",
                            },
                            ["TL"] = {
                                "Gutom ako, at malaking bagay ang kabaitan mo. Salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Happy to accept any food you can spare. Let's eat together.",
                            },
                            ["TL"] = {
                                "Masayang tatanggapin ang anumang sobra mo. Sabay tayong kumain.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Thank you for asking. A warm meal or small ration would be wonderful.",
                            },
                            ["TL"] = {
                                "Salamat sa pagtatanong. Napakaganda sana ng kahit simpleng pagkain.",
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
