-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.camp.queued.friendly",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.camp.queued.friendly",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_camp_queued_friendly",
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
                ["responseTemplateID"] = "semantic.command.camp.queued.friendly",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/camp.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Sure, I'll set up camp there. Sounds cozy.",
                            },
                            ["TL"] = {
                                "Sige, magse-set up ako ng kampo roon. Mukhang maaliwalas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Happy to! Let's get a good fire going.",
                            },
                            ["TL"] = {
                                "Masayang gagawin! Magpaningas tayo ng maayos na apoy.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Good call, friend. I'll get our camp ready.",
                            },
                            ["TL"] = {
                                "Magandang pasya, kaibigan. Ihahanda ko ang kampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Leave it to me! I'll make sure it's safe and comfortable.",
                            },
                            ["TL"] = {
                                "Ipaubaya mo sa akin! Titiyakin kong ligtas at komportable.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Great idea. I'll go set up camp for us.",
                            },
                            ["TL"] = {
                                "Magandang ideya. Pupunta ako para itayo ang kampo natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Right on! Time to get off our feet. Setting up now.",
                            },
                            ["TL"] = {
                                "Aba oo! Oras na para magpahinga. Magtatayo na ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Gladly. I'll have the beds laid out shortly.",
                            },
                            ["TL"] = {
                                "Malugod kong gagawin. Ilalatag ko ang higaan maya-maya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Sounds wonderful. I'll get our shelter squared away.",
                            },
                            ["TL"] = {
                                "Napakaganda. Aayusin ko ang silungan natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Sure thing, partner! Camp will be ready in no time.",
                            },
                            ["TL"] = {
                                "Walang anuman, kasama! Handa na ang kampo agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "On it, friend! Rest easy, I'll handle camp.",
                            },
                            ["TL"] = {
                                "Inaasikaso na, kaibigan! Magpahinga ka, ako na sa kampo.",
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
