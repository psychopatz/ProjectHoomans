-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_greeting",
        ["id"] = "semantic.flow.greeting.opening.question.default.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.flow.greeting.opening.question.default.neutral",
            ["sourcePath"] = "psdl/dialogue/conversation_greeting.json#records[10]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_flow_greeting_opening_question_default_neutral",
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
                ["responseTemplateID"] = "semantic.flow.greeting.opening.question.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/greeting.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "How have you been?",
                            },
                            ["TL"] = {
                                "Kumusta ka na?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "How are you holding up?",
                            },
                            ["TL"] = {
                                "Paano mo nakakayanan ang sitwasyon?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Everything all right with you?",
                            },
                            ["TL"] = {
                                "Maayos ba ang lahat sa iyo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "How's your day going so far?",
                            },
                            ["TL"] = {
                                "Kumusta ang araw mo hanggang ngayon?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Staying safe out there?",
                            },
                            ["TL"] = {
                                "Ligtas ka ba sa labas?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "How are things treating you today?",
                            },
                            ["TL"] = {
                                "Kumusta ang takbo ng mga bagay ngayon?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Feeling alright today?",
                            },
                            ["TL"] = {
                                "Maayos ba ang pakiramdam mo ngayon?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Any trouble on the road?",
                            },
                            ["TL"] = {
                                "May gulo ba sa daan?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "How are you managing out here?",
                            },
                            ["TL"] = {
                                "Paano ka nakakaraos dito sa labas?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Everything quiet on your end?",
                            },
                            ["TL"] = {
                                "Tahimik ba ang lahat sa parte mo?",
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
        ["sourceShard"] = "psdl/dialogue/conversation_greeting.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
