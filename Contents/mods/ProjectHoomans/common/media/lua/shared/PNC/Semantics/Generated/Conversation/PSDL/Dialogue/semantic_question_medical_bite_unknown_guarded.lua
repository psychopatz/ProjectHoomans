-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.medical_bite.unknown.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.medical_bite.unknown.guarded",
            ["sourcePath"] = "psdl/dialogue/health_content.json#records[20]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_medical_bite_unknown_guarded",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't confirm that. Don't press me.",
                            },
                            ["TL"] = {
                                "Hindi ko makumpirma. Huwag mo nang ipilit.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Haven't checked yet. Keep your distance until I do.",
                            },
                            ["TL"] = {
                                "Hindi pa ako nakakatingin. Lumayo ka muna hangga't hindi pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "I don't know for sure. Back off and let me look.",
                            },
                            ["TL"] = {
                                "Hindi ako sigurado. Umatras ka at hayaan mo akong tingnan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Can't tell through this armor. Don't jump to conclusions.",
                            },
                            ["TL"] = {
                                "Hindi masabi dahil sa suot ko. Huwag kang magbintang.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Too much blood to tell whose it is. Back away.",
                            },
                            ["TL"] = {
                                "Masyadong maraming dugo para malaman kung kanino. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "I need a mirror first. Stop staring at me.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng salamin muna. Huwag mo akong titigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Unsure. I'll inspect myself in private.",
                            },
                            ["TL"] = {
                                "Hindi sigurado. Magsusuri ako nang mag-isa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Can't confirm. Keep your weapon holstered.",
                            },
                            ["TL"] = {
                                "Hindi makumpirma. Huwag mong ilabas ang armas mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "I don't know yet. Don't treat me like an infected.",
                            },
                            ["TL"] = {
                                "Hindi ko pa alam. Huwag mo akong itrato na parang infected.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Unknown. Stay where you are until I know.",
                            },
                            ["TL"] = {
                                "Hindi alam. Diyan ka lang hangga't hindi ko nasisiguro.",
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
