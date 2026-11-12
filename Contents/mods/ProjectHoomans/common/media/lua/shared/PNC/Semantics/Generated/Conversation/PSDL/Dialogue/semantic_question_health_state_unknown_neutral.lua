-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.health_state.unknown.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.health_state.unknown.neutral",
            ["sourcePath"] = "psdl/dialogue/health_content.json#records[9]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_health_state_unknown_neutral",
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
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't confirm my health status right now.",
                            },
                            ["TL"] = {
                                "Hindi ko makumpirma ang kalagayan ko ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Haven't had a chance to inspect myself thoroughly.",
                            },
                            ["TL"] = {
                                "Hindi pa ako nagkakaroon ng pagkakataong suriin ang sarili ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Not entirely sure how bad it is under the gear.",
                            },
                            ["TL"] = {
                                "Hindi ako sigurado kung gaano kalala sa ilalim ng suot ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Could be bleeding, could just be a bruise. Hard to tell.",
                            },
                            ["TL"] = {
                                "Pwedeng dumudugo, pwedeng pasa lang. Mahirap masabi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Need a quiet moment to check over my condition.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng tahimik na sandali para masuri ang katawan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Uncertain right now. Adrenaline is masking the pain.",
                            },
                            ["TL"] = {
                                "Hindi sigurado ngayon. Natatakpan ng adrenaline ang sakit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Hard to tell without a mirror or better light.",
                            },
                            ["TL"] = {
                                "Mahirap malaman kung walang salamin o mas maayos na ilaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I feel sore all over, but can't verify the specifics.",
                            },
                            ["TL"] = {
                                "Masakit ang buong katawan ko, pero hindi ko matukoy ang dahilan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Can't confirm if anything is broken or sprained yet.",
                            },
                            ["TL"] = {
                                "Hindi pa makumpirma kung may bali o pilay ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "My condition is uncertain at the moment.",
                            },
                            ["TL"] = {
                                "Hindi tiyak ang kalagayan ko sa mga sandaling ito.",
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
