-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.injured.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.injured.neutral",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_wellbeing_injured_neutral",
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
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "A little banged up, but I'll manage.",
                            },
                            ["TL"] = {
                                "Medyo may tama ako, pero kakayanin ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Took a hit during the last scrap. Need to bandage up.",
                            },
                            ["TL"] = {
                                "Tinamaan ako noong huling laban. Kailangan kong bendahan ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'm nursing a couple wounds, but nothing fatal.",
                            },
                            ["TL"] = {
                                "May iniinda akong ilang sugat, pero hindi naman nakamamatay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Hurts to move quickly, but I can still walk.",
                            },
                            ["TL"] = {
                                "Masakit kumilos nang mabilis, pero nakakalakad pa ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Got tagged out there. Keeping an eye on the bleeding.",
                            },
                            ["TL"] = {
                                "Tinamaan ako sa labas. Binabantayan ko ang pagdurugo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Bruised and aching all over, but I'll pull through.",
                            },
                            ["TL"] = {
                                "Pasa-pasa at masakit ang buong katawan, pero makakaraos din.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Scraped up pretty bad, but still on two feet.",
                            },
                            ["TL"] = {
                                "Medyo malala ang gasgas ko, pero nakatayo pa rin sa dalawang paa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Need some clean bandages soon, but I'm holding together.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng malinis na benda agad, pero maayos pa naman.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Took a rough fall earlier. Still feeling the sting.",
                            },
                            ["TL"] = {
                                "Medyo napasama ang bagsak ko kanina. Kumikirot pa rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Not in peak shape right now, but I can carry on.",
                            },
                            ["TL"] = {
                                "Hindi ako nasa pinakamagandang kondisyon, pero kaya pang ituloy.",
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
