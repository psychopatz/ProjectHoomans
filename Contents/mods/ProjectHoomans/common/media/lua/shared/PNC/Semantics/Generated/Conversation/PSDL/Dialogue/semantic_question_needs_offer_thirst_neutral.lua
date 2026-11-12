-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_needs",
        ["id"] = "semantic.question.needs.offer.thirst.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.needs.offer.thirst.neutral",
            ["sourcePath"] = "psdl/dialogue/conversation_needs.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_needs_offer_thirst_neutral",
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
                ["responseTemplateID"] = "semantic.question.needs.offer.thirst",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/needs.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Water would help, but I don't have an exact amount yet.",
                            },
                            ["TL"] = {
                                "Makakatulong ang tubig, pero wala akong eksaktong dami ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I could really use a clean drink of water.",
                            },
                            ["TL"] = {
                                "Kailangang-kailangan ko talaga ng malinis na maiinom na tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Any spare water you have would be a big relief.",
                            },
                            ["TL"] = {
                                "Anumang sobrang tubig na mayroon ka ay malaking ginhawa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Thirsty as can be. A bottle or canteen would help.",
                            },
                            ["TL"] = {
                                "Uhaw na uhaw ako. Makakatulong ang botelya o lalagyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "My throat is completely parched. Water would do wonders.",
                            },
                            ["TL"] = {
                                "Tuyong-tuyo na ang lalamunan ko. Malaking tulong ang tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Need water soon before dehydration sets in.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng tubig bago ako maubusan ng likido.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "If you've got extra water on you, I'll take it.",
                            },
                            ["TL"] = {
                                "Kung may sobra kang tubig sa bag mo, kukunin ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "A few sips of clean water would keep me walking.",
                            },
                            ["TL"] = {
                                "Ilang lagok ng malinis na tubig ang magpapatuloy sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Desperate for a drink today. Anything you can spare?",
                            },
                            ["TL"] = {
                                "Uhaw na uhaw ako ngayong araw. May maibibigay ka ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Fresh water is life out here. I'd gladly take some.",
                            },
                            ["TL"] = {
                                "Buhay ang malinis na tubig dito. Masaya akong tatanggap.",
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
