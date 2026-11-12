-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_check_in",
        ["id"] = "social.small_talk.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "social.small_talk.neutral",
            ["sourcePath"] = "psdl/dialogue/social_check_in.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/social_small_talk_neutral",
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
                ["audience"] = "neutral",
                ["category"] = "projecthoomans:small_talk",
                ["runtimeBlockID"] = "projecthoomans:small_talk_neutral",
                ["textDomain"] = "pnc.psdl.social.small_talk.neutral",
                ["textTarget"] = "psdl/social/small_talk/neutral",
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
                                        ["EN"] = "At least the rain covers our footsteps.",
                                        ["TL"] = "At least natatakpan ng ulan ang mga yapak namin.",
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
                                        ["EN"] = "Do not tempt fate, but I'll take it.",
                                        ["TL"] = "Huwag tuksuhin ang kapalaran, ngunit kukunin ko ito.",
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
                                "All right. We can talk for a minute.",
                            },
                            ["TL"] = {
                                "Sige. Maaari tayong mag-usap sandali.",
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
            ["responsePlanID"] = "social.small_talk.neutral",
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
                            ["labelKey"] = "psdl.social.small_talk.neutral.offer.weather.label",
                            ["utteranceFallback"] = "Some weather we're having.",
                            ["utteranceKey"] = "psdl.social.small_talk.neutral.offer.weather.utterance",
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
                            ["labelKey"] = "psdl.social.small_talk.neutral.offer.quiet_day.label",
                            ["utteranceFallback"] = "Quiet day so far.",
                            ["utteranceKey"] = "psdl.social.small_talk.neutral.offer.quiet_day.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "All right. We can talk for a minute.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.social.small_talk.neutral.opening",
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
