-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "quest_content",
        ["id"] = "semantic.quest.clinic_supplies.offer.queued.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.quest.clinic_supplies.offer.queued.neutral",
            ["sourcePath"] = "psdl/dialogue/quest_content.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_quest_clinic_supplies_offer_queued_neutral",
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
                ["category"] = "projecthoomans:quest_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.quest",
                ["responseTemplateID"] = "semantic.quest.clinic_supplies.offer.queued",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/quest.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can help with the clinic supplies.",
                            },
                            ["TL"] = {
                                "Matutulungan kita sa mga suplay ng klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I'm ready to lend a hand with those medical goods.",
                            },
                            ["TL"] = {
                                "Handa akong tumulong sa mga medikal na gamit na 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Put me down for the clinic supply run.",
                            },
                            ["TL"] = {
                                "Ilista mo ako para sa pagkuha ng suplay sa klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'm available to help gather medical gear.",
                            },
                            ["TL"] = {
                                "Available ako para tumulong mag-ipon ng gamot.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I can assist with securing what the clinic needs.",
                            },
                            ["TL"] = {
                                "Makatutulong ako sa pagkuha ng kailangan ng klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Count me in for the clinic supplies.",
                            },
                            ["TL"] = {
                                "Isama mo ako sa suplay para sa klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'll pitch in on that medical supply run.",
                            },
                            ["TL"] = {
                                "Tutulong ako sa pagkuha ng medikal na suplay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I can offer my help for the clinic task.",
                            },
                            ["TL"] = {
                                "Maaari kong ialok ang tulong ko sa gawaing ito sa klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Glad to help get those supplies to the clinic.",
                            },
                            ["TL"] = {
                                "Masaya akong makatulong maihatid ang mga suplay sa klinika.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I can take on part of that clinic effort.",
                            },
                            ["TL"] = {
                                "Kaya kong gampanan ang bahagi ng gawaing 'yan sa klinika.",
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
        ["sourceShard"] = "psdl/dialogue/quest_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
