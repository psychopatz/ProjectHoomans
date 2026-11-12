-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.weather.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.whats_up.weather.guarded",
            ["sourcePath"] = "psdl/dialogue/conversation_whats_up.json#records[16]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_whats_up_weather_guarded",
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
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
                ["responseTemplateID"] = "semantic.question.whats_up.weather",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/conversation.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Watching the weather. Stay focused.",
                            },
                            ["TL"] = {
                                "Binabantayan ko ang panahon. Manatiling nakatutok.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Storms bring trouble. Don't linger out in the open.",
                            },
                            ["TL"] = {
                                "Bagyo ang nagdadala ng gulo. Huwag kang tumambay sa bukas na lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Sky looks nasty. Get your head in the game.",
                            },
                            ["TL"] = {
                                "Madilim ang langit. Maghanda ka sa anumang darating.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Bad weather makes it easy for them to sneak up. Stay alert.",
                            },
                            ["TL"] = {
                                "Mas madali silang makalapit kapag masama ang panahon. Maging alerto.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Wind is masking noises. Keep your ears open and back off.",
                            },
                            ["TL"] = {
                                "Tinatabunan ng hangin ang mga ingay. Maging mapagmatyag at umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Clouds are gathering. I don't plan on getting caught out here.",
                            },
                            ["TL"] = {
                                "Makulimlim na. Wala akong balak abutan ng ulan dito sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Weather is turning. Stop wasting time chatting.",
                            },
                            ["TL"] = {
                                "Papasama ang panahon. Huwag magsayang ng oras sa pakikipag-usap.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Fog or rain will blind us. Keep your weapon ready.",
                            },
                            ["TL"] = {
                                "Mabubulag tayo sa hamog o ulan. Ihanda ang armas mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Eyeing the clouds. You'd better find cover too.",
                            },
                            ["TL"] = {
                                "Tinitingnan ko ang mga ulap. Mabuti pang maghanap ka na rin ng masisilungan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "A storm is brewing. I'm focusing on shelter.",
                            },
                            ["TL"] = {
                                "May paparating na bagyo. Naghahanap ako ng masisilungan.",
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
        ["sourceShard"] = "psdl/dialogue/conversation_whats_up.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
