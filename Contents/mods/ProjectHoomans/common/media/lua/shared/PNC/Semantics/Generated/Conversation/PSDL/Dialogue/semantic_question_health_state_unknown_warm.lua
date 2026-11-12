-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.health_state.unknown.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.health_state.unknown.warm",
            ["sourcePath"] = "psdl/dialogue/health_content.json#records[11]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_health_state_unknown_warm",
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
                ["responseTemplateID"] = "semantic.question.health_state.unknown",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/health_state.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't confirm it right now, but thanks for asking.",
                            },
                            ["TL"] = {
                                "Hindi ko makumpirma ngayon, pero salamat sa pagtatanong.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Not sure how bad it is yet, but I appreciate your concern.",
                            },
                            ["TL"] = {
                                "Hindi pa sigurado kung gaano kalala, pero salamat sa pag-alala.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Haven't checked properly, but I'll let you know once I do.",
                            },
                            ["TL"] = {
                                "Hindi pa nasusuri nang maayos, pero sasabihin ko sa 'yo kapag nasuri ko na.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Hard to tell right now, friend. Thanks for watching over me.",
                            },
                            ["TL"] = {
                                "Mahirap masabi ngayon, kaibigan. Salamat sa pagbabantay sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "I need to check under the bandages, but I'm grateful you asked.",
                            },
                            ["TL"] = {
                                "Kailangan kong tingnan sa ilalim ng benda, pero salamat sa pagtanong.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Uncertain for now, but your support means everything to me.",
                            },
                            ["TL"] = {
                                "Hindi sigurado sa ngayon, pero mahalaga ang suporta mo sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Could be fine, could be bruised. Thanks for caring enough to check.",
                            },
                            ["TL"] = {
                                "Pwedeng ayos lang, pwedeng may pasa. Salamat sa pagmamalasakit.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'll do a proper check when we're safe. Thank you, truly.",
                            },
                            ["TL"] = {
                                "Magsusuri ako kapag ligtas na tayo. Maraming salamat talaga.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Can't say for sure, but I feel safer with you here.",
                            },
                            ["TL"] = {
                                "Hindi masabi nang tiyak, pero mas panatag ako at nandito ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Not sure yet, but don't worry yourself sick over me.",
                            },
                            ["TL"] = {
                                "Hindi pa sigurado, pero huwag kang magpakapagod mag-alala.",
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
