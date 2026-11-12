-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_greetings",
        ["id"] = "social.greetings.hostile.parley",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "social.greetings.hostile.parley",
            ["sourcePath"] = "psdl/dialogue/social_greetings.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/social_greetings_hostile_parley",
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
                ["audience"] = "hostile",
                ["category"] = "projecthoomans:greetings",
                ["priority"] = 100,
                ["runtimeBlockID"] = "projecthoomans:hostile_parley",
                ["textDomain"] = "pnc.psdl.social.greetings.hostile.parley",
                ["textRows"] = {
                    {
                        ["key"] = "result.accepted",
                        ["text"] = {
                            ["EN"] = "Ceasefire accepted for one hour.",
                            ["TL"] = "Tinanggap ang tigil-putukan sa loob ng isang oras.",
                        },
                    },
                    {
                        ["key"] = "result.rejected",
                        ["text"] = {
                            ["EN"] = "Ceasefire refused.",
                            ["TL"] = "Tumanggi ang tigil-putukan.",
                        },
                    },
                },
                ["textTarget"] = "psdl/social/greetings/hostile/parley",
                ["weight"] = 100,
            },
            ["response"] = {
                ["act"] = "PARLEY",
                ["turns"] = {
                    {
                        ["id"] = "opening",
                        ["metadata"] = {
                            ["textKey"] = "opening",
                        },
                        ["offers"] = {
                            {
                                ["consumers"] = {
                                    "participant",
                                },
                                ["frame"] = {
                                    ["intent"] = "REQUEST",
                                    ["speechAct"] = "REQUEST",
                                    ["subject"] = "CEASEFIRE",
                                    ["topic"] = "parley",
                                },
                                ["id"] = "ceasefire",
                                ["label"] = {
                                    ["EN"] = {
                                        "Ceasefire. Stand down for now.",
                                    },
                                    ["TL"] = {
                                        "Ceasefire. Tumayo sa ngayon.",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.ceasefire",
                                    ["close"] = true,
                                    ["effects"] = {
                                        {
                                            ["type"] = "pnc:ceasefire",
                                        },
                                    },
                                    ["responseKey"] = "response.ceasefire",
                                    ["responseText"] = {
                                        ["EN"] = "You ask for a short ceasefire.",
                                        ["TL"] = "Humihingi ka ng maikling tigil-putukan.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "Ceasefire. Stand down for now.",
                                    },
                                    ["TL"] = {
                                        "Ceasefire. Tumayo sa ngayon.",
                                    },
                                },
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The survivor watches you carefully, ready to fight.",
                            },
                            ["TL"] = {
                                "Maingat kang pinagmamasdan ng survivor, handang lumaban.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "PARLEY",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.greetings.hostile.parley",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "opening",
                    ["offers"] = {
                        {
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "REQUEST",
                                ["speechAct"] = "REQUEST",
                                ["subject"] = "CEASEFIRE",
                                ["topic"] = "parley",
                            },
                            ["id"] = "ceasefire",
                            ["labelFallback"] = "Ceasefire. Stand down for now.",
                            ["labelKey"] = "psdl.social.greetings.hostile.parley.offer.ceasefire.label",
                            ["utteranceFallback"] = "Ceasefire. Stand down for now.",
                            ["utteranceKey"] = "psdl.social.greetings.hostile.parley.offer.ceasefire.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "The survivor watches you carefully, ready to fight.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.social.greetings.hostile.parley.opening",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/social_greetings.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
