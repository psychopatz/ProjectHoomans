-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.medical_bite.unknown.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.medical_bite.unknown.warm",
            ["sourcePath"] = "psdl/dialogue/health_content.json#records[23]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_medical_bite_unknown_warm",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseTemplateID"] = "semantic.question.medical_bite.unknown",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/medical_bite.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't confirm it, but thanks for checking.",
                            },
                            ["TL"] = {
                                "Hindi ko makumpirma, pero salamat sa pagsuri.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not sure yet, friend. I'll check carefully in a safe spot.",
                            },
                            ["TL"] = {
                                "Hindi pa ako sigurado, kaibigan. Titingnan ko nang maayos sa ligtas na lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Haven't had a proper look, but thank you for looking out for me.",
                            },
                            ["TL"] = {
                                "Hindi ko pa natingnan nang maigi, pero salamat sa pagbabantay sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Hard to see back there. Mind helping me take a look soon?",
                            },
                            ["TL"] = {
                                "Mahirap makita sa likod. Pwede mo ba akong tulungang tingnan mamaya?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Unsure right now, but I promise I'll be honest with you.",
                            },
                            ["TL"] = {
                                "Hindi sigurado ngayon, pero nangangako akong magiging tapat ako sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "I pray it's just a tear in my jacket. Thanks for asking gently.",
                            },
                            ["TL"] = {
                                "Sana punit lang sa jacket. Salamat sa maingat na pagtatanong.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Not certain yet, but let's find shelter before we inspect.",
                            },
                            ["TL"] = {
                                "Hindi pa tiyak, pero maghanap muna tayo ng masisilungan bago sumuri.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Could be nothing, could be bad. Thank you for staying calm.",
                            },
                            ["TL"] = {
                                "Pwedeng wala lang, pwedeng masama. Salamat sa pananatiling kalmado.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "I haven't checked every scratch, but your concern warms my heart.",
                            },
                            ["TL"] = {
                                "Hindi ko pa nasusuri ang bawat gasgas, pero nagpapasalamat ako sa pag-alala mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "I'll let you know the moment I check. Thank you for your care.",
                            },
                            ["TL"] = {
                                "Sasabihin ko agad pagkatapos kong masuri. Salamat sa malasakit mo.",
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
        ["sourceShard"] = "psdl/dialogue/health_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
