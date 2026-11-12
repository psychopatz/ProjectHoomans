-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_tool_replies",
        ["id"] = "semantic.tool_reply.queued_apology.2",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.tool_reply.queued_apology.2",
            ["sourcePath"] = "psdl/dialogue/task_tool_replies.json#records[18]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_tool_reply_queued_apology_2",
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
                ["responseTemplateID"] = "semantic.tool_reply.queued_apology.2",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/tool_replies/queued_apology.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "We will talk about it.",
                            },
                            ["TL"] = {
                                "Pag-uusapan natin iyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "We'll discuss it once things calm down.",
                            },
                            ["TL"] = {
                                "Pag-uusapan natin kapag kumalma na ang lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "We will hash this out later.",
                            },
                            ["TL"] = {
                                "Aayusin natin ito mamaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "We'll revisit that when we have a quiet moment.",
                            },
                            ["TL"] = {
                                "Babalikan natin 'yan kapag may tahimik na oras.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "We will talk through that soon.",
                            },
                            ["TL"] = {
                                "Pag-uusapan natin 'yan sa lalong madaling panahon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'll talk to you about it later.",
                            },
                            ["TL"] = {
                                "Kakausapin kita tungkol diyan mamaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "We'll sort that out when we're safe.",
                            },
                            ["TL"] = {
                                "Aayusin natin 'yan kapag ligtas na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "We will clear the air later.",
                            },
                            ["TL"] = {
                                "Lilinawin natin ang lahat mamaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "We'll have a proper conversation about it.",
                            },
                            ["TL"] = {
                                "Mag-uusap tayo nang masinsinan tungkol diyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Talk about it when we reach camp.",
                            },
                            ["TL"] = {
                                "Pag-usapan natin kapag nakarating sa kampo.",
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
