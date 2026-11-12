-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.fatigue_alt.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.fatigue_alt.neutral",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[15]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_wellbeing_fatigue_alt_neutral",
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
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseTemplateID"] = "semantic.question.wellbeing.fatigue_alt",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/needs.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm tired. A little rest would help.",
                            },
                            ["TL"] = {
                                "Pagod ako. Makakatulong ang kaunting pahinga.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Hard to keep my eyes open right now.",
                            },
                            ["TL"] = {
                                "Hirap na akong idilat ang mga mata ko ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Been pushing hard all day. Need to rest soon.",
                            },
                            ["TL"] = {
                                "Masyadong napagod maghapon. Kailangang magpahinga maya-maya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Sleep would be a luxury right about now.",
                            },
                            ["TL"] = {
                                "Napakasarap sanang makatulog sa mga oras na ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Feeling slow and sluggish from lack of rest.",
                            },
                            ["TL"] = {
                                "Mabagal ang kilos ko dahil sa kakulangan sa pahinga.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "My reflexes aren't what they should be right now.",
                            },
                            ["TL"] = {
                                "Medyo mabagal ang reaksyon ko dahil sa pagod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Tired down to the bone, but still standing.",
                            },
                            ["TL"] = {
                                "Tagos sa buto ang pagod, pero nakatayo pa rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "If we find a safe corner, I need a minute.",
                            },
                            ["TL"] = {
                                "Kapag nakahanap tayo ng ligtas na sulok, pahinga muna ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Could fall asleep right where I'm standing.",
                            },
                            ["TL"] = {
                                "Kaya kong makatulog kahit saan ako nakatayo ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Just need an hour of shut-eye to reset.",
                            },
                            ["TL"] = {
                                "Kailangan ko lang ng kahit isang oras na tulog para makabawi.",
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
        ["sourceShard"] = "psdl/dialogue/wellbeing_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
