-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.busy.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.whats_up.busy.guarded",
            ["sourcePath"] = "psdl/dialogue/conversation_whats_up.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_whats_up_busy_guarded",
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
                ["responseTemplateID"] = "semantic.question.whats_up.busy",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/conversation.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Keeping busy. Don't distract me.",
                            },
                            ["TL"] = {
                                "Abala ako. Huwag mo akong gambalain.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "I've got work to do. Keep moving.",
                            },
                            ["TL"] = {
                                "May trabaho pa ako. Magpatuloy ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Hands are full right now. Leave me to it.",
                            },
                            ["TL"] = {
                                "Marami akong ginagawa ngayon. Hayaan mo muna ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Occupied. Don't crowd my workspace.",
                            },
                            ["TL"] = {
                                "May ginagawa ako. Huwag kang humarang dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Too much to do to stand around chatting.",
                            },
                            ["TL"] = {
                                "Masyadong maraming gagawin para tumambay at makipag-usap.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'm busy with survival. You should be too.",
                            },
                            ["TL"] = {
                                "Abala ako sa pagpapatuloy. Dapat ikaw rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Focusing on my duties. Step back.",
                            },
                            ["TL"] = {
                                "Nakatutok ako sa tungkulin ko. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Work doesn't stop because you want to talk.",
                            },
                            ["TL"] = {
                                "Hindi hihinto ang trabaho dahil lang gusto mong makipag-usap.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Busy here. Come back when I'm done.",
                            },
                            ["TL"] = {
                                "Abala ako rito. Bumalik ka kapag tapos na ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Got critical tasks to finish. Don't get in the way.",
                            },
                            ["TL"] = {
                                "May mahalagang gawain akong tatapusin. Huwag kang humarang.",
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
