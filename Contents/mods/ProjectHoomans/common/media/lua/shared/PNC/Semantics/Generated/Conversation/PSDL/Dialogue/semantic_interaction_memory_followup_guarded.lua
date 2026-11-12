-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_memory",
        ["id"] = "semantic.interaction.memory.followup.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.memory.followup.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_memory.json#records[11]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_memory_followup_guarded",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.memory.followup",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/memory/followup.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Why are you telling me that?",
                            },
                            ["TL"] = {
                                "Bakit mo sinasabi sa akin iyan?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "What's the point of bringing that up now?",
                            },
                            ["TL"] = {
                                "Anong layunin sa pagbubukas niyan ngayon?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Are you testing my reaction?",
                            },
                            ["TL"] = {
                                "Sinusubukan mo ba ang magiging reaksyon ko?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Who else knows about that story?",
                            },
                            ["TL"] = {
                                "Sino pa ang nakakaalam ng kuwentong 'yan?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Why share something so personal with me?",
                            },
                            ["TL"] = {
                                "Bakit mo ibinabahagi ang ganyang personal na bagay sa akin?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Sounds like an angle. What do you really want?",
                            },
                            ["TL"] = {
                                "Mukhang may pakay ka. Ano ba talaga ang gusto mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Does that story have anything to do with our safety here?",
                            },
                            ["TL"] = {
                                "May kinalaman ba ang kuwentong 'yan sa kaligtasan natin dito?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Be careful what details you hand out to people.",
                            },
                            ["TL"] = {
                                "Mag-ingat ka sa mga detalyeng ipinamamahagi mo sa iba.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Are you trying to gauge where my loyalties lie?",
                            },
                            ["TL"] = {
                                "Sinusubukan mo bang alamin kung kanino ako tapat?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your personal history to yourself.",
                            },
                            ["TL"] = {
                                "Itago mo na lang sa sarili mo ang sarili mong nakaraan.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_memory.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
