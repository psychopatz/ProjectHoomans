-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_greeting",
        ["id"] = "semantic.flow.greeting.opening.default.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.flow.greeting.opening.default.guarded",
            ["sourcePath"] = "psdl/dialogue/conversation_greeting.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_flow_greeting_opening_default_guarded",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.flow.greeting.opening.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/greeting.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "State your business. Keep your distance.",
                            },
                            ["TL"] = {
                                "Sabihin mo ang pakay mo. Lumayo ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Hold it right there. What do you want?",
                            },
                            ["TL"] = {
                                "Diyan ka lang. Anong gusto mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Hands where I can see them. Who are you?",
                            },
                            ["TL"] = {
                                "Itaas ang mga kamay. Sino ka?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Don't come any closer until I know your business.",
                            },
                            ["TL"] = {
                                "Huwag kang lalapit hangga't hindi ko alam ang pakay mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your hands clear. Talk from there.",
                            },
                            ["TL"] = {
                                "Ilayo mo ang mga kamay mo. Magsalita ka riyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'm watching you. What brings you here?",
                            },
                            ["TL"] = {
                                "Binabantayan kita. Anong nagdala sa 'yo rito?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Easy now. Step back and speak your piece.",
                            },
                            ["TL"] = {
                                "Dahan-dahan lang. Umatras ka at sabihin mo ang sasabihin mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your distance. Times are too dangerous for strangers.",
                            },
                            ["TL"] = {
                                "Lumayo ka. Masyadong mapanganib ang panahon para sa mga estranghero.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "That's close enough. What are you looking for?",
                            },
                            ["TL"] = {
                                "Tama na ang lapit na 'yan. Anong hinahanap mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Stay where you are. I don't know you yet.",
                            },
                            ["TL"] = {
                                "Diyan ka lang. Hindi pa kita kilala.",
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
        ["sourceShard"] = "psdl/dialogue/conversation_greeting.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
