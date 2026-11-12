-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.busy.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.whats_up.busy.neutral",
            ["sourcePath"] = "psdl/dialogue/conversation_whats_up.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_whats_up_busy_neutral",
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
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm keeping busy and trying to stay useful.",
                            },
                            ["TL"] = {
                                "Abala ako at sinusubukan kong maging kapaki-pakinabang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Just working through my checklist for the day.",
                            },
                            ["TL"] = {
                                "Inaayos ko lang ang mga kailangan kong gawin ngayong araw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Plenty of chores to keep my mind off the dead.",
                            },
                            ["TL"] = {
                                "Maraming gawain para hindi maisip ang mga patay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Taking care of camp business. Always something to fix.",
                            },
                            ["TL"] = {
                                "Inaasikaso ang mga kailangan sa kampo. Laging may aayusin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Putting in work so we all stay safe.",
                            },
                            ["TL"] = {
                                "Nagtatrabaho para manatiling ligtas tayong lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Staying occupied. It helps pass the hours.",
                            },
                            ["TL"] = {
                                "Pinananatiling abala ang sarili. Nakatutulong magpalipas ng oras.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Tending to tasks. What about you?",
                            },
                            ["TL"] = {
                                "Gumagawa ng mga gawain. Kumusta naman ikaw?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Got a few projects on my plate today.",
                            },
                            ["TL"] = {
                                "May ilang proyekto akong inaasikaso ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Just getting things organized around here.",
                            },
                            ["TL"] = {
                                "Inaayos lang ang mga gamit dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Keeping my hands moving. Idleness gets people killed.",
                            },
                            ["TL"] = {
                                "Gumagalaw palagi. Ang kawalan ng gawa ang nagpapahamak sa tao.",
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
