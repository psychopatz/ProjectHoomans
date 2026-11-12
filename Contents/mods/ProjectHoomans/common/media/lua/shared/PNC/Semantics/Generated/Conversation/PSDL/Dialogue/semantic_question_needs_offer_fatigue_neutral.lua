-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_needs",
        ["id"] = "semantic.question.needs.offer.fatigue.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.needs.offer.fatigue.neutral",
            ["sourcePath"] = "psdl/dialogue/conversation_needs.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_needs_offer_fatigue_neutral",
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
                ["responseTemplateID"] = "semantic.question.needs.offer.fatigue",
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
                                "A little rest would help, but this isn't something I can count.",
                            },
                            ["TL"] = {
                                "Makakatulong ang kaunting pahinga, pero hindi ito mabibilang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "What I really need is a safe place to shut my eyes.",
                            },
                            ["TL"] = {
                                "Ang kailangan ko talaga ay ligtas na lugar para makatulog.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Just need some downtime to recover my energy.",
                            },
                            ["TL"] = {
                                "Kailangan ko lang ng kaunting pahinga para bumalik ang lakas ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Rest is the only cure for this exhaustion right now.",
                            },
                            ["TL"] = {
                                "Pahinga lang ang makakapagpagaling sa pagod na ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "If we can find a secure spot, a nap would do me good.",
                            },
                            ["TL"] = {
                                "Kung makakahanap tayo ng ligtas na sulok, makakatulong ang idlip.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Fatigue is catching up. I just need a safe corner to rest.",
                            },
                            ["TL"] = {
                                "Inaabutan na ako ng antok. Kailangan ko lang ng ligtas na sulok.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "No item can fix this tiredness. I just need to sleep.",
                            },
                            ["TL"] = {
                                "Walang gamit ang makakagamot sa pagod na 'to. Tulog lang kailangan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Could use a couple hours off my feet, honestly.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng ilang oras na hindi nakatayo, sa totoo lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Need to recharge my batteries before we do anything risky.",
                            },
                            ["TL"] = {
                                "Kailangang makabawi ng lakas bago tayo gumawa ng mapanganib.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Time to rest would be the greatest gift right now.",
                            },
                            ["TL"] = {
                                "Oras para magpahinga ang pinakamagandang maitutulong ngayon.",
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
