-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "quest_content",
        ["id"] = "semantic.quest.clinic_supplies.accept.rejected.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.quest.clinic_supplies.accept.rejected.neutral",
            ["sourcePath"] = "psdl/dialogue/quest_content.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_quest_clinic_supplies_accept_rejected_neutral",
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
                ["category"] = "projecthoomans:quest_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.quest",
                ["responseTemplateID"] = "semantic.quest.clinic_supplies.accept.rejected",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/quest.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't accept that request right now.",
                            },
                            ["TL"] = {
                                "Hindi ko matatanggap ang kahilingang iyon ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not in a position to take that on.",
                            },
                            ["TL"] = {
                                "Wala ako sa posisyong balikatin 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Too much on my plate. Can't accept the clinic run.",
                            },
                            ["TL"] = {
                                "Masyado akong maraming ginagawa. Hindi ko matatanggap ang klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Not right now. I have to pass on that request.",
                            },
                            ["TL"] = {
                                "Hindi muna ngayon. Tatanggihan ko muna ang kahilingang 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I can't commit to gathering clinic supplies today.",
                            },
                            ["TL"] = {
                                "Hindi ako makakapangakong mag-ipon ng suplay sa klinika ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I have to turn that down for now.",
                            },
                            ["TL"] = {
                                "Kailangan ko munang tanggihan 'yan sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Can't help with the clinic run at the moment.",
                            },
                            ["TL"] = {
                                "Hindi makakatulong sa klinika sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I won't be taking that request.",
                            },
                            ["TL"] = {
                                "Hindi ko tatanggapin ang kahilingang 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Sorry, I can't agree to that right now.",
                            },
                            ["TL"] = {
                                "Pasensya na, hindi ako makakapayag diyan ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I must decline that medical supply task.",
                            },
                            ["TL"] = {
                                "Kailangan kong tanggihan ang gawaing medikal na 'yan.",
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
        ["sourceShard"] = "psdl/dialogue/quest_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
