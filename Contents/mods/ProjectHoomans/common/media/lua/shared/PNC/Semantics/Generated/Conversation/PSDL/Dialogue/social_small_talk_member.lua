-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_check_in",
        ["id"] = "social.small_talk.member",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "social.small_talk.member",
            ["sourcePath"] = "psdl/dialogue/social_check_in.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/social_small_talk_member",
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
                ["audience"] = "member",
                ["category"] = "projecthoomans:small_talk",
                ["runtimeBlockID"] = "projecthoomans:small_talk_member",
                ["textDomain"] = "pnc.psdl.social.small_talk.member",
                ["textTarget"] = "psdl/social/small_talk/member",
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
                                        ["EN"] = "Could be worse. We've worked through worse.",
                                        ["TL"] = "Maaaring mas masahol pa. Mas malala ang pinagdaanan namin.",
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
                                        ["EN"] = "The crew earned one.",
                                        ["TL"] = "Karapat-dapat iyon ng grupo.",
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
                                "A quiet conversation sounds good right now.",
                            },
                            ["TL"] = {
                                "Ang isang tahimik na pag-uusap ay pakinggan ngayon.",
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
            ["responsePlanID"] = "social.small_talk.member",
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
                            ["labelKey"] = "psdl.social.small_talk.member.offer.weather.label",
                            ["utteranceFallback"] = "Some weather we're having.",
                            ["utteranceKey"] = "psdl.social.small_talk.member.offer.weather.utterance",
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
                            ["labelKey"] = "psdl.social.small_talk.member.offer.quiet_day.label",
                            ["utteranceFallback"] = "Quiet day so far.",
                            ["utteranceKey"] = "psdl.social.small_talk.member.offer.quiet_day.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "A quiet conversation sounds good right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.social.small_talk.member.opening",
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
