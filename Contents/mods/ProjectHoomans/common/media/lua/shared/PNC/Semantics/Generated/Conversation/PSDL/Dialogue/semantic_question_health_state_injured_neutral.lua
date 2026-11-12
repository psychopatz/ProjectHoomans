-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.health_state.injured.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.health_state.injured.neutral",
            ["sourcePath"] = "psdl/dialogue/health_content.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_health_state_injured_neutral",
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
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm hurt, but I'm managing.",
                            },
                            ["TL"] = {
                                "Nasaktan ako, pero kinakaya ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Took a beating earlier. Bandages are holding for now.",
                            },
                            ["TL"] = {
                                "Medyo napuruhan kanina. Hawak pa naman ng benda sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Nursing a wound here. Trying not to reopen it.",
                            },
                            ["TL"] = {
                                "Inaalagaan ko ang sugat na ito. Iniiwasang bumuka ulit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I've been injured, but nothing that'll take me down.",
                            },
                            ["TL"] = {
                                "Nasugatan ako, pero hindi 'to makakapagpatumba sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Got caught in a bad spot. Dealing with the damage.",
                            },
                            ["TL"] = {
                                "Naipit sa masamang sitwasyon. Tinitiis ang tinamong sugat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Bleeding is mostly stopped, but movement is painful.",
                            },
                            ["TL"] = {
                                "Karamihan sa dugo tumigil na, pero masakit kumilos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Stung pretty bad by an attack earlier.",
                            },
                            ["TL"] = {
                                "Kumikirot pa rin mula sa pag-atake kanina.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Injuries are slowing me down, but I can keep moving.",
                            },
                            ["TL"] = {
                                "Pinapabagal ako ng mga sugat, pero kaya pang lumakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Could use some medical supplies when we find them.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng gamot kapag nakahanap tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I'm hurting right now, but taking it step by step.",
                            },
                            ["TL"] = {
                                "Masakit ang katawan ko ngayon, pero dahan-dahan lang.",
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
