-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.dataset.getting_by.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.dataset.getting_by.guarded",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[6]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_wellbeing_dataset_getting_by_guarded",
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
                ["responseTemplateID"] = "semantic.question.wellbeing.dataset.getting_by",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/general.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm getting by. Leave it there.",
                            },
                            ["TL"] = {
                                "Kinakaya ko. Tama na iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Surviving. That's all you need to know.",
                            },
                            ["TL"] = {
                                "Nabubuhay pa. Iyon lang ang kailangan mong malaman.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "I manage on my own. Don't worry about it.",
                            },
                            ["TL"] = {
                                "Kaya ko ang sarili ko. Huwag mo nang alalahanin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Still upright. Let's keep it to business.",
                            },
                            ["TL"] = {
                                "Nakatayo pa rin. Manatili tayo sa pakay natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "I'm coping fine. No need to pry.",
                            },
                            ["TL"] = {
                                "Maayos ang lagay ko. Hindi kailangang mag-usisa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Doing what I have to do. That's enough.",
                            },
                            ["TL"] = {
                                "Ginagawa ang dapat gawin. Sapat na 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Still breathing. Nothing more to say about it.",
                            },
                            ["TL"] = {
                                "Huminga pa. Wala nang iba pang sasabihin tungkol doon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'm alright on my own, thanks.",
                            },
                            ["TL"] = {
                                "Ayos lang ako sa sarili ko, salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Managing well enough without interference.",
                            },
                            ["TL"] = {
                                "Kinakaya nang maayos nang walang nangingialam.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Getting by just fine. Let's drop it.",
                            },
                            ["TL"] = {
                                "Kinakaya ko nang maayos. Hayaan na natin.",
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
