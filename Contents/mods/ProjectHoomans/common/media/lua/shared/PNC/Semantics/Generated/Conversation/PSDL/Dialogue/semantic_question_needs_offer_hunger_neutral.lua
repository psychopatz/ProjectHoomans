-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_needs",
        ["id"] = "semantic.question.needs.offer.hunger.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.needs.offer.hunger.neutral",
            ["sourcePath"] = "psdl/dialogue/conversation_needs.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_needs_offer_hunger_neutral",
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
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Food would help, but I don't have an exact amount yet.",
                            },
                            ["TL"] = {
                                "Makakatulong ang pagkain, pero wala akong eksaktong dami ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Any food you could spare would make a difference.",
                            },
                            ["TL"] = {
                                "Kahit anong pagkaing maibibigay mo ay malaking tulong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'm definitely hungry. Whatever rations you have would be welcome.",
                            },
                            ["TL"] = {
                                "Gutom na talaga ako. Anumang rasyon mayroon ka ay tatanggapin ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "A meal would be great, even if it's just something small.",
                            },
                            ["TL"] = {
                                "Maganda sanang makakain, kahit kaunti lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I could really use some food right now.",
                            },
                            ["TL"] = {
                                "Kailangang-kailangan ko talaga ng pagkain ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "My stomach is empty. Any edible supplies would help.",
                            },
                            ["TL"] = {
                                "Walang laman ang tiyan ko. Makakatulong ang anumang makakain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Food would keep me on my feet. I'll take whatever you offer.",
                            },
                            ["TL"] = {
                                "Pagkain ang magpapanatili sa akin sa labas. Tatanggapin ko ang iaalok mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Running low on food out here. Appreciate whatever you can share.",
                            },
                            ["TL"] = {
                                "Nauubusan na ako ng pagkain. Salamat sa anumang maibabahagi mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Haven't eaten a decent bite today. Food would go a long way.",
                            },
                            ["TL"] = {
                                "Hindi pa ako kumakain nang maayos ngayon. Malaking tulong ang pagkain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Could use rations soon. Let's see what you've got.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng rasyon agad. Tingnan natin kung anong mayroon ka.",
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
