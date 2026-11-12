-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.follow.queued.friendly",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.follow.queued.friendly",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[9]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_follow_queued_friendly",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.follow.queued.friendly",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/follow.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Of course, I'll follow you.",
                            },
                            ["TL"] = {
                                "Siyempre, susundan kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Gladly, friend! Lead the way.",
                            },
                            ["TL"] = {
                                "Malugod, kaibigan! Ituro ang daan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Always happy to travel with you. Let's go!",
                            },
                            ["TL"] = {
                                "Laging masayang maglakbay kasama ka. Tara na!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'm right behind you, partner. Let's do this.",
                            },
                            ["TL"] = {
                                "Nasa likod mo lang ako, kasama. Gawin na natin ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Right with you, friend! Watch your steps.",
                            },
                            ["TL"] = {
                                "Kasabay mo ako, kaibigan! Mag-ingat sa hakbang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Wouldn't rather be following anyone else.",
                            },
                            ["TL"] = {
                                "Wala nang ibang gugustuhin kong sundan kundi ikaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Lead on! I've got your six covered.",
                            },
                            ["TL"] = {
                                "Mauna ka! Hawak ko ang likod mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Sure thing! Sticking like glue to you, friend.",
                            },
                            ["TL"] = {
                                "Walang anuman! Didikit na parang pandikit sa 'yo, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Happy to follow. Keep us safe!",
                            },
                            ["TL"] = {
                                "Masayang sumunod. Panatilihin tayong ligtas!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Right behind you, partner. Onward!",
                            },
                            ["TL"] = {
                                "Nasa likod mo lang, kasama. Pasulong!",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
