-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.gift.completed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.gift.completed",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[20]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_gift_completed",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.gift.completed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/gift.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Thank you for the gift.",
                            },
                            ["TL"] = {
                                "Salamat sa regalo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I appreciate this gesture. Thank you.",
                            },
                            ["TL"] = {
                                "Salamat sa magandang kalooban. Maraming salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "That's generous of you. Thanks.",
                            },
                            ["TL"] = {
                                "Bukas-palad ka. Salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Thank you! This will be put to good use.",
                            },
                            ["TL"] = {
                                "Salamat! Magagamit ito nang maayos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "A welcome surprise. Thank you, friend.",
                            },
                            ["TL"] = {
                                "Magandang sorpresa. Salamat, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Much obliged for the gift.",
                            },
                            ["TL"] = {
                                "Maraming salamat sa regalo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'm grateful for this. Thank you.",
                            },
                            ["TL"] = {
                                "Nagpapasalamat ako rito. Salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "You didn't have to, but thanks a lot.",
                            },
                            ["TL"] = {
                                "Di mo kailangang gawin, pero maraming salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Received with gratitude. Thank you.",
                            },
                            ["TL"] = {
                                "Tinatanggap kalakip ang pasasalamat. Salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks for thinking of me with this gift.",
                            },
                            ["TL"] = {
                                "Salamat sa pag-alala sa akin sa regalong ito.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
