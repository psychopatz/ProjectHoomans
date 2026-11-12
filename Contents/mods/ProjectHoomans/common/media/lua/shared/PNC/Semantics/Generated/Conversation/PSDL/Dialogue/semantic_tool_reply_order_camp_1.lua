-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_tool_replies",
        ["id"] = "semantic.tool_reply.order_camp.1",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.tool_reply.order_camp.1",
            ["sourcePath"] = "psdl/dialogue/task_tool_replies.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_tool_reply_order_camp_1",
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
                ["category"] = "projecthoomans:tool_replies",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.tool_reply.order_camp.1",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/tool_replies/order_camp.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "All right. We will make camp here.",
                            },
                            ["TL"] = {
                                "Sige. Magkakampo tayo rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Setting up camp right in this spot.",
                            },
                            ["TL"] = {
                                "Magtatayo ng kampo sa mismong pwestong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Establishing camp.",
                            },
                            ["TL"] = {
                                "Naintindihan. Itatayo ang kampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Camp order received. Pitching shelter.",
                            },
                            ["TL"] = {
                                "Natanggap ang utos magkampo. Maglalatag ng silong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Good place to bed down. Making camp.",
                            },
                            ["TL"] = {
                                "Magandang tulugan ito. Magkakampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Securing the campsite.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Seselyuhan ang kampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Right. Making camp here.",
                            },
                            ["TL"] = {
                                "Sige. Magtatayo ng kampo rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "On it. Setting up our camp.",
                            },
                            ["TL"] = {
                                "Inaasikaso na. Itatayo ang kampo natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Camp routine initiated.",
                            },
                            ["TL"] = {
                                "Sinisimulan na ang pagtatayo ng kampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Copy that. We camp here.",
                            },
                            ["TL"] = {
                                "Kopyado. Dito tayo magkakampo.",
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
        ["sourceShard"] = "psdl/dialogue/task_tool_replies.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
