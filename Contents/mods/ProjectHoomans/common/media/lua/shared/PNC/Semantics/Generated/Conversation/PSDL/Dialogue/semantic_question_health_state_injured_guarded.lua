-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.health_state.injured.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.health_state.injured.guarded",
            ["sourcePath"] = "psdl/dialogue/health_content.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_health_state_injured_guarded",
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
                ["responseTemplateID"] = "semantic.question.health_state.injured",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/health_state.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm hurt. Give me space.",
                            },
                            ["TL"] = {
                                "Nasaktan ako. Bigyan mo ako ng espasyo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Took some damage. I don't need your pity.",
                            },
                            ["TL"] = {
                                "May tama ako. Hindi ko kailangan ang awa mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Got injured, but I'm still dangerous. Step back.",
                            },
                            ["TL"] = {
                                "Nasugatan ako, pero mapanganib pa rin ako. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Bleeding, but it's under control. Don't hover.",
                            },
                            ["TL"] = {
                                "Dumudugo, pero kontrolado ko. Huwag kang mag-aligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "I'm wounded. That doesn't mean I'm helpless.",
                            },
                            ["TL"] = {
                                "Sugatan ako. Hindi ibig sabihing wala na akong magagawa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "I can bandage my own wounds, thank you.",
                            },
                            ["TL"] = {
                                "Kaya kong bendahan ang sarili kong sugat, salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "It hurts, but you don't need to pry into it.",
                            },
                            ["TL"] = {
                                "Masakit, pero hindi mo kailangang mag-usisa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Just a bad cut. Keep your hands where I can see them.",
                            },
                            ["TL"] = {
                                "Malalim na sugat lang. Ipakita mo ang mga kamay mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'm dealing with the pain. Leave me be.",
                            },
                            ["TL"] = {
                                "Inaayos ko ang iniinda ko. Hayaan mo muna ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Injured, yes. Vulnerable, no. Back off.",
                            },
                            ["TL"] = {
                                "Sugatan, oo. Mahina, hindi. Lumayo ka.",
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
