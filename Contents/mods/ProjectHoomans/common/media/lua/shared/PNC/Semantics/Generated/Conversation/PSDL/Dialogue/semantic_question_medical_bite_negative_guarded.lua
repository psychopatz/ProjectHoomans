-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.medical_bite.negative.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.medical_bite.negative.guarded",
            ["sourcePath"] = "psdl/dialogue/health_content.json#records[12]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_medical_bite_negative_guarded",
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
                ["responseTemplateID"] = "semantic.question.medical_bite.negative",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/medical_bite.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "No bite. Leave it there.",
                            },
                            ["TL"] = {
                                "Walang kagat. Tama na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "I'm clean. Don't look at me like that.",
                            },
                            ["TL"] = {
                                "Malinis ako. Huwag mo akong tingnan nang ganyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Not bitten. Stop inspecting me.",
                            },
                            ["TL"] = {
                                "Hindi nakagat. Itigil mo ang pagsusuri sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "No teeth touched my skin. Back off.",
                            },
                            ["TL"] = {
                                "Walang ngiping tumama sa balat ko. Lumayo ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "I checked thoroughly. I am not infected.",
                            },
                            ["TL"] = {
                                "Sinuri ko nang maayos. Hindi ako infected.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "No bite marks anywhere. Put your weapon down.",
                            },
                            ["TL"] = {
                                "Walang bakas ng kagat kahit saan. Ibaba mo ang armas mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "I know the protocol. I don't have a bite.",
                            },
                            ["TL"] = {
                                "Alam ko ang patakaran. Wala akong kagat.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Clean skin. Don't jump to conclusions.",
                            },
                            ["TL"] = {
                                "Malinis ang balat ko. Huwag kang magbintang agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Not a single bite mark. Keep your distance regardless.",
                            },
                            ["TL"] = {
                                "Kahit isang bakas ng kagat wala. Lumayo ka pa rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "I am not turning. Drop the interrogation.",
                            },
                            ["TL"] = {
                                "Hindi ako magiging isa sa kanila. Itigil ang pagtatanong.",
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
