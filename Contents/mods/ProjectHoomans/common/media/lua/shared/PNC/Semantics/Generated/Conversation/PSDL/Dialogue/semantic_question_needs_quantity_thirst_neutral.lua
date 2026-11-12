-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_needs",
        ["id"] = "semantic.question.needs.quantity.thirst.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.needs.quantity.thirst.neutral",
            ["sourcePath"] = "psdl/dialogue/conversation_needs.json#records[8]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_needs_quantity_thirst_neutral",
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
                ["responseTemplateID"] = "semantic.question.needs.quantity.thirst",
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
                                "I know water is what I need, but I can't give you an exact amount yet.",
                            },
                            ["TL"] = {
                                "Alam kong tubig ang kailangan ko, pero hindi ko pa masabi ang eksaktong dami.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Even half a bottle of water would make a difference.",
                            },
                            ["TL"] = {
                                "Kahit kalahating botelya ng tubig ay malaking tulong na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Just enough clean water to wet my throat, please.",
                            },
                            ["TL"] = {
                                "Sapat lang na malinis na tubig pambasa ng lalamunan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "A single flask or a few gulps would be fantastic.",
                            },
                            ["TL"] = {
                                "Kahit isang lagayan o ilang lagok ay napakaganda na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I'm parched. Any amount of safe water would help.",
                            },
                            ["TL"] = {
                                "Uhaw ako. Anumang dami ng ligtas na tubig ay makakatulong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Don't need a whole gallon, just enough to stay hydrated.",
                            },
                            ["TL"] = {
                                "Hindi kailangan ng galon, sapat lang para mawala ang uhaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Whatever water you can afford to part with right now.",
                            },
                            ["TL"] = {
                                "Anumang tubig na kaya mong ibigay sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "A cup or a bottle, I won't turn it down.",
                            },
                            ["TL"] = {
                                "Kahit tasa o botelya, hindi ko tatanggihan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Enough water to get through the afternoon would be great.",
                            },
                            ["TL"] = {
                                "Sapat na tubig para maitawid ang hapon ay ayos na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Just a small sip or two to keep my strength up.",
                            },
                            ["TL"] = {
                                "Kahit isa o dalawang lagok lang para manatili ang lakas.",
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
