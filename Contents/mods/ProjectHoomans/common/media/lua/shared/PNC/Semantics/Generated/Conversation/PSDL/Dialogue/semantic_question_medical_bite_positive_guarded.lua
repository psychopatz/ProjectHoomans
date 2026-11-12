-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.medical_bite.positive.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.medical_bite.positive.guarded",
            ["sourcePath"] = "psdl/dialogue/health_content.json#records[16]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_medical_bite_positive_guarded",
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
                ["responseTemplateID"] = "semantic.question.medical_bite.positive",
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
                                "Yes. I've been bitten. That's all.",
                            },
                            ["TL"] = {
                                "Oo. Nakagat ako. Tama na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "They got me. Don't make a scene.",
                            },
                            ["TL"] = {
                                "Nakuha nila ako. Huwag kang magsisigaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "I was bitten. Keep your gun ready if you must.",
                            },
                            ["TL"] = {
                                "Nakagat ako. Ihanda mo ang baril mo kung kinakailangan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Yes, it happened. Stay back from me.",
                            },
                            ["TL"] = {
                                "Oo, nangyari. Lumayo ka sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Got teeth in my arm. I know what that means.",
                            },
                            ["TL"] = {
                                "May kagat sa braso ko. Alam ko ang ibig sabihin niyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Bitten. Don't touch me.",
                            },
                            ["TL"] = {
                                "Nakagat. Huwag mo akong hawakan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "It's true. I don't want your sympathy.",
                            },
                            ["TL"] = {
                                "Totoo. Hindi ko kailangan ang awa mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "One of them bit me. Step away.",
                            },
                            ["TL"] = {
                                "Kinagat ako ng isa sa kanila. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'm marked. Do what you have to do.",
                            },
                            ["TL"] = {
                                "May marka na ako. Gawin mo ang dapat mong gawin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Yes. I won't let myself become a danger to you.",
                            },
                            ["TL"] = {
                                "Oo. Hindi ko hahayaang maging panganib ako sa 'yo.",
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
