-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_check_in",
        ["id"] = "social.small_talk.special",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "social.small_talk.special",
            ["sourcePath"] = "psdl/dialogue/social_check_in.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/social_small_talk_special",
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
                ["audience"] = "special",
                ["category"] = "projecthoomans:small_talk",
                ["runtimeBlockID"] = "projecthoomans:small_talk_special",
                ["textDomain"] = "pnc.psdl.social.small_talk.special",
                ["textTarget"] = "psdl/social/small_talk/special",
            },
            ["response"] = {
                ["act"] = "SMALL_TALK",
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
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "WEATHER",
                                    ["topic"] = "small_talk",
                                },
                                ["id"] = "weather",
                                ["label"] = {
                                    ["EN"] = {
                                        "Some weather we're having.",
                                    },
                                    ["TL"] = {
                                        "Ilang panahon ang nararanasan natin.",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.weather",
                                    ["responseKey"] = "response.weather",
                                    ["responseText"] = {
                                        ["EN"] = "I barely noticed. I was watching you.",
                                        ["TL"] = "bahagya kong napansin. pinapanood kita.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "Some weather we're having.",
                                    },
                                    ["TL"] = {
                                        "Ilang panahon ang nararanasan natin.",
                                    },
                                },
                            },
                            {
                                ["consumers"] = {
                                    "participant",
                                },
                                ["frame"] = {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "DAY",
                                    ["topic"] = "small_talk",
                                },
                                ["id"] = "quiet_day",
                                ["label"] = {
                                    ["EN"] = {
                                        "Quiet day so far.",
                                    },
                                    ["TL"] = {
                                        "Tahimik na araw hanggang ngayon.",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.quiet_day",
                                    ["responseKey"] = "response.quiet_day",
                                    ["responseText"] = {
                                        ["EN"] = "Then spend part of it with me.",
                                        ["TL"] = "Kung gayon, gugulin mo ang bahagi nito kasama ako.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "Quiet day so far.",
                                    },
                                    ["TL"] = {
                                        "Tahimik na araw hanggang ngayon.",
                                    },
                                },
                                ["when"] = {
                                    ["op"] = "gte",
                                    ["path"] = "relationship.speakerToAddressee.familiarity",
                                    ["value"] = 1,
                                },
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I always have time for you, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Palagi akong may oras para sa iyo, {addressee.name}.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "SMALL_TALK",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.small_talk.special",
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
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "WEATHER",
                                ["topic"] = "small_talk",
                            },
                            ["id"] = "weather",
                            ["labelFallback"] = "Some weather we're having.",
                            ["labelKey"] = "psdl.social.small_talk.special.offer.weather.label",
                            ["utteranceFallback"] = "Some weather we're having.",
                            ["utteranceKey"] = "psdl.social.small_talk.special.offer.weather.utterance",
                        },
                        {
                            ["constraints"] = {
                                ["op"] = "gte",
                                ["path"] = "relationship.speakerToAddressee.familiarity",
                                ["value"] = 1,
                            },
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "DAY",
                                ["topic"] = "small_talk",
                            },
                            ["id"] = "quiet_day",
                            ["labelFallback"] = "Quiet day so far.",
                            ["labelKey"] = "psdl.social.small_talk.special.offer.quiet_day.label",
                            ["utteranceFallback"] = "Quiet day so far.",
                            ["utteranceKey"] = "psdl.social.small_talk.special.offer.quiet_day.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I always have time for you, {addressee.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.social.small_talk.special.opening",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/social_check_in.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
