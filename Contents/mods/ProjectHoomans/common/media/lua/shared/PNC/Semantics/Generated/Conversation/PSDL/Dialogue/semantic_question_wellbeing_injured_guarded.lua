-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.injured.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.injured.guarded",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_wellbeing_injured_guarded",
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
                ["responseTemplateID"] = "semantic.question.wellbeing.injured",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/emotional.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm hurt. That's all I can say.",
                            },
                            ["TL"] = {
                                "Nasaktan ako. Iyon lang ang masasabi ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Took some damage. I'll patch it myself, don't worry.",
                            },
                            ["TL"] = {
                                "Tinamaan ako. Ako na ang gagamot dito, huwag kang mag-alala.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Bleeding a little, but I can still defend myself.",
                            },
                            ["TL"] = {
                                "Dumudugo nang kaunti, pero kaya ko pa ring lumaban.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "It's just a flesh wound. Keep your distance.",
                            },
                            ["TL"] = {
                                "Daplis lang ito. Lumayo ka muna.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "I'm wounded, but I don't need charity.",
                            },
                            ["TL"] = {
                                "May sugat ako, pero hindi ko kailangan ng awa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Hurts like hell, but I'm holding my ground.",
                            },
                            ["TL"] = {
                                "Sobrang sakit, pero hindi ako aatras.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Got scraped up. Mind your own injuries.",
                            },
                            ["TL"] = {
                                "Nagasgasan lang. Asikasuhin mo ang sarili mong sugat.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Don't stare at the bandages. I'm still functional.",
                            },
                            ["TL"] = {
                                "Huwag mong titigan ang benda ko. Kaya ko pang kumilos.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "A rough encounter, but I survived it. Back off.",
                            },
                            ["TL"] = {
                                "Medyo magulo ang engkuwentro, pero nakaligtas ako. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "I'll manage the pain on my own, thanks.",
                            },
                            ["TL"] = {
                                "Kakayanin ko ang sakit mag-isa, salamat.",
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
