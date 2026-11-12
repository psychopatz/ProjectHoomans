-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_needs",
        ["id"] = "semantic.question.needs.quantity.unknown.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.needs.quantity.unknown.neutral",
            ["sourcePath"] = "psdl/dialogue/conversation_needs.json#records[9]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_needs_quantity_unknown_neutral",
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
                ["responseTemplateID"] = "semantic.question.needs.quantity.unknown",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/needs.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't confirm an exact amount yet. Which item do you mean?",
                            },
                            ["TL"] = {
                                "Hindi ko makumpirma ang eksaktong dami. Anong gamit ang tinutukoy mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Tell me what item you're talking about first, then we can talk quantity.",
                            },
                            ["TL"] = {
                                "Sabihin mo muna kung anong gamit, bago natin pag-usapan ang dami.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Depends on what you have. Which supply are we discussing?",
                            },
                            ["TL"] = {
                                "Depende sa mayroon ka. Anong gamit ba ang pinag-uusapan natin?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Hard to give a number without knowing what item you're offering.",
                            },
                            ["TL"] = {
                                "Mahirap magbigay ng bilang nang hindi alam kung ano ang iaalok mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "What specific item do you have in mind to trade or share?",
                            },
                            ["TL"] = {
                                "Anong partikular na gamit ang balak mong ibahagi o ipagpalit?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Let me know what you're holding before I name an amount.",
                            },
                            ["TL"] = {
                                "Ipaalam mo muna kung anong hawak mo bago ako magbigay ng dami.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Which supply are we discussing? I need details first.",
                            },
                            ["TL"] = {
                                "Anong gamit ang tinutukoy natin? Kailangan ko ng detalye muna.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Can't tell you how many until I know what it is.",
                            },
                            ["TL"] = {
                                "Hindi ko masasabi kung ilan hangga't hindi ko alam kung ano 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "What kind of gear or supplies are we talking about here?",
                            },
                            ["TL"] = {
                                "Anong uri ng kagamitan o suplay ang pinag-uusapan natin dito?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Specify the item first, and then I'll let you know how much I need.",
                            },
                            ["TL"] = {
                                "Tukuyin mo muna ang gamit, at sasabihin ko kung gaano karami ang kailangan ko.",
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
        ["sourceShard"] = "psdl/dialogue/conversation_needs.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
