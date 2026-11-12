-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_needs",
        ["id"] = "semantic.question.needs.quantity.hunger.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.needs.quantity.hunger.neutral",
            ["sourcePath"] = "psdl/dialogue/conversation_needs.json#records[7]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_needs_quantity_hunger_neutral",
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
                ["responseTemplateID"] = "semantic.question.needs.quantity.hunger",
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
                                "I know food is what I need, but I can't give you an exact amount yet.",
                            },
                            ["TL"] = {
                                "Alam kong pagkain ang kailangan ko, pero hindi ko pa masabi ang eksaktong dami.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Whatever you can spare to eat would be plenty.",
                            },
                            ["TL"] = {
                                "Kahit anong maibibigay mong makakain ay sapat na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Even one can or a couple rations would keep me going.",
                            },
                            ["TL"] = {
                                "Kahit isang de-lata o dalawang rasyon ay malaking tulong na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not picky about the portion size, just need food.",
                            },
                            ["TL"] = {
                                "Hindi ako mapili sa dami, basta may makakain lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "A small portion or a full meal, anything helps.",
                            },
                            ["TL"] = {
                                "Maliit man o buong pagkain, lahat 'yon makakatulong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Just enough food to fill the hollow feeling in my gut.",
                            },
                            ["TL"] = {
                                "Sapat lang na pagkain para mapawi ang gutom ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Don't need a banquet, just whatever food you're willing to share.",
                            },
                            ["TL"] = {
                                "Hindi kailangan ng marami, kung ano lang ang kaya mong ibahagi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "A couple bites would buy me a few more hours of strength.",
                            },
                            ["TL"] = {
                                "Ilang subo lang ay magbibigay sa akin ng ilang oras na lakas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Hard to name a count. Just give me what you don't need.",
                            },
                            ["TL"] = {
                                "Mahirap magbilang. Ibigay mo lang kung anong hindi mo kailangan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Any amount of food is better than nothing right now.",
                            },
                            ["TL"] = {
                                "Anumang dami ng pagkain ay mas maganda kaysa sa wala ngayon.",
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
