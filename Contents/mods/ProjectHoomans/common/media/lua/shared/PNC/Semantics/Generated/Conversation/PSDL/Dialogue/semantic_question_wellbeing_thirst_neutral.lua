-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.thirst.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.thirst.neutral",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[18]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_wellbeing_thirst_neutral",
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
                ["responseTemplateID"] = "semantic.question.wellbeing.thirst",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/needs.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm pretty thirsty. Could you spare some water?",
                            },
                            ["TL"] = {
                                "Uhaw na uhaw ako. Maaari ba akong makahingi ng tubig?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "My throat feels parched. Got any clean water?",
                            },
                            ["TL"] = {
                                "Tuyong-tuyo ang lalamunan ko. May malinis ka bang tubig?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Really need a drink soon. Starting to feel dehydrated.",
                            },
                            ["TL"] = {
                                "Kailangan ko na talagang uminom. Nauuhaw na ako nang husto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Could use a sip of water if you've got any to share.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng kahit kaunting lagok ng tubig kung mayroon ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Thirst is really slowing me down today.",
                            },
                            ["TL"] = {
                                "Pinapabagal talaga ako ng uhaw ngayong araw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "My canteen ran dry a while back. Got any water?",
                            },
                            ["TL"] = {
                                "Natuyo na ang lalagyan ko kanina pa. May tubig ka ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Desperate for a drink of fresh water right now.",
                            },
                            ["TL"] = {
                                "Kailangang-kailangan ko ng maiinom na sariwang tubig ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "My mouth is bone dry. Can you spare a few drops?",
                            },
                            ["TL"] = {
                                "Tuyot na tuyot ang bibig ko. Makakahingi ba ng kaunting tubig?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Need water before my headache gets any worse.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng tubig bago pa sumakit ang ulo ko sa uhaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Any spare water bottle on you? I'm drying up.",
                            },
                            ["TL"] = {
                                "May sobra ka bang botelya ng tubig? Uhaw na uhaw na ako.",
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
