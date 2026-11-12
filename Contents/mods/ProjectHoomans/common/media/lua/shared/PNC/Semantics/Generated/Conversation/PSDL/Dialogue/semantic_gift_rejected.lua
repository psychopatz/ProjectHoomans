-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.gift.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.gift.rejected",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[23]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_gift_rejected",
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
                ["responseTemplateID"] = "semantic.gift.rejected",
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
                                "I can't accept that gift right now.",
                            },
                            ["TL"] = {
                                "Hindi ko matanggap ang regalong iyan ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Keep it. You need it more than I do.",
                            },
                            ["TL"] = {
                                "Itabi mo. Mas kailangan mo 'yan kaysa sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I have no room for gifts in my pack.",
                            },
                            ["TL"] = {
                                "Wala nang espasyo sa bag ko para sa mga regalo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I don't feel comfortable taking this from you.",
                            },
                            ["TL"] = {
                                "Hindi magaan sa loob ko na tanggapin ito sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Refusing this gift. We're not there yet.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ang regalo. Di pa tayo ganoon kalapit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Save your supplies. Don't waste them on me.",
                            },
                            ["TL"] = {
                                "Itabi ang gamit mo. Huwag mong sayangin sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I cannot take that offering.",
                            },
                            ["TL"] = {
                                "Di ko matatanggap ang alay na 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "No thanks. I carry my own weight.",
                            },
                            ["TL"] = {
                                "Hindi salamat. Kaya kong dalhin ang sarili ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Gift rejected. Keep your belongings.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ang regalo. Itago ang pag-aari mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I won't accept that from you today.",
                            },
                            ["TL"] = {
                                "Di ko tatanggapin 'yan mula sa 'yo ngayong araw.",
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
