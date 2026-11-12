-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_memory",
        ["id"] = "semantic.interaction.memory.followup.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.memory.followup.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_memory.json#records[8]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_memory_followup_neutral",
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
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "You did? What happened after that?",
                            },
                            ["TL"] = {
                                "Talaga? Ano ang nangyari pagkatapos noon?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "How did you manage to get through it?",
                            },
                            ["TL"] = {
                                "Paano mo nagawang malusutan iyon?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Did anyone else make it out with you?",
                            },
                            ["TL"] = {
                                "May iba pa bang nakaligtas kasama mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Where did you go once that went down?",
                            },
                            ["TL"] = {
                                "Saan ka pumunta nang mangyari iyon?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "What made you think of that just now?",
                            },
                            ["TL"] = {
                                "Bakit mo biglang naisip iyon ngayon?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "How long ago was that?",
                            },
                            ["TL"] = {
                                "Gaano na katagal mula noon?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Were there many casualties back then?",
                            },
                            ["TL"] = {
                                "Marami bang nasawi noong panahong iyon?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "What did you end up doing about it?",
                            },
                            ["TL"] = {
                                "Ano ang naging aksyon mo tungkol doon?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "That sounds intense. What came next?",
                            },
                            ["TL"] = {
                                "Matindi 'yon. Ano ang sumunod?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Did you ever go back to that place?",
                            },
                            ["TL"] = {
                                "Bumalik ka pa ba sa lugar na iyon kailanman?",
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
