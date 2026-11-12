-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.busy.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.whats_up.busy.warm",
            ["sourcePath"] = "psdl/dialogue/conversation_whats_up.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_whats_up_busy_warm",
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
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm keeping busy and trying to stay useful. There's always something to do.",
                            },
                            ["TL"] = {
                                "Abala ako at sinusubukan kong maging kapaki-pakinabang. Laging may kailangang gawin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Working hard so our camp stays strong. Glad you stopped by!",
                            },
                            ["TL"] = {
                                "Nagsusumikap para sa kampo. Masayang dumaan ka!",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Keeping active, but never too busy for a good word with you.",
                            },
                            ["TL"] = {
                                "Abala man, hindi mawawalan ng oras para kumustahin ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Tending to some chores. Nice to take a quick breather with a friend.",
                            },
                            ["TL"] = {
                                "Gumagawa ng gawain. Masarap magpahinga sandali kasama ang kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Just doing my part for our little community. How are you doing?",
                            },
                            ["TL"] = {
                                "Ginagawa lang ang parte ko sa komunidad. Kumusta ka naman?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Keeping busy helps keep the worry away. Always good to see you.",
                            },
                            ["TL"] = {
                                "Nawawala ang kaba kapag may ginagawa. Laging magandang makita ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Working away! Let me know if you need any help with your own tasks.",
                            },
                            ["TL"] = {
                                "Nagtatrabaho lang! Sabihan mo ako kung kailangan mo ng tulong sa gawain mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Plenty of work, but having good folks around makes it easy.",
                            },
                            ["TL"] = {
                                "Maraming trabaho, pero gumagaan kapag may mabubuting kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Just finishing up a few things. It's lovely seeing you today.",
                            },
                            ["TL"] = {
                                "Tinatapos lang ang ilang bagay. Masarap kang makita ngayong araw.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Doing what I can to pitch in. Thank you for checking in on me.",
                            },
                            ["TL"] = {
                                "Tumutulong sa abot ng makakaya. Salamat sa pangangamusta mo.",
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
