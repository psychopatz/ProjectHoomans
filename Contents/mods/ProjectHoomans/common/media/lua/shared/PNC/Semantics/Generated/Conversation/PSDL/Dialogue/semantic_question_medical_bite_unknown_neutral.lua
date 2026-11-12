-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.medical_bite.unknown.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.medical_bite.unknown.neutral",
            ["sourcePath"] = "psdl/dialogue/health_content.json#records[21]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_medical_bite_unknown_neutral",
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
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't confirm whether I've been bitten.",
                            },
                            ["TL"] = {
                                "Hindi ko makumpirma kung nakagat ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Haven't had a chance to strip down and check properly.",
                            },
                            ["TL"] = {
                                "Hindi pa ako nagkakaroon ng oras para maghubad at suriin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "There were too many hands grabbing at me to be certain.",
                            },
                            ["TL"] = {
                                "Masyadong maraming humawak sa akin para makasiguro.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Felt teeth scrape, but can't see if it broke the skin.",
                            },
                            ["TL"] = {
                                "Naramdaman ko ang ngipin, pero hindi kita kung bumaon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Need someone with good light to inspect my back.",
                            },
                            ["TL"] = {
                                "Kailangan ng may maayos na ilaw para tingnan ang likod ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Not sure yet. The wound is covered in dirt and blood.",
                            },
                            ["TL"] = {
                                "Hindi pa sigurado. Balot ng dumi at dugo ang sugat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Could be a scratch, could be teeth. Can't tell yet.",
                            },
                            ["TL"] = {
                                "Pwedeng gasgas, pwedeng ngipin. Hindi pa masabi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I haven't checked every spot yet. Need a minute.",
                            },
                            ["TL"] = {
                                "Hindi ko pa nasusuri ang bawat parte. Bigyan mo ako ng sandali.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Cloth is torn, but not sure if the skin is punctured.",
                            },
                            ["TL"] = {
                                "Punit ang damit, pero hindi sigurado kung bumaon sa balat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Bite status is unknown right now. Waiting to check.",
                            },
                            ["TL"] = {
                                "Hindi pa alam kung nakagat. Naghihintay masuri.",
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
