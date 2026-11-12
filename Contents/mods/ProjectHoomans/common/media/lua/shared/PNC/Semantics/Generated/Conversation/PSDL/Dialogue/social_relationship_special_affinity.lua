-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_companion_topics",
        ["id"] = "social.relationship.special.affinity",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "social.relationship.special.affinity",
            ["sourcePath"] = "psdl/dialogue/social_companion_topics.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/social_relationship_special_affinity",
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
                ["audiences"] = {
                    "special",
                },
                ["category"] = "projecthoomans:relationship",
                ["runtimeBlockID"] = "projecthoomans:relationship_special",
                ["textDomain"] = "pnc.psdl.social.relationship.special.affinity",
                ["textTarget"] = "psdl/social/relationship/special/affinity",
            },
            ["response"] = {
                ["act"] = "RELATIONSHIP_TOPIC",
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
                                    ["subject"] = "RELATIONSHIP",
                                    ["topic"] = "relationship",
                                },
                                ["id"] = "us",
                                ["label"] = {
                                    ["EN"] = {
                                        "Can we talk about us?",
                                    },
                                    ["TL"] = {
                                        "Maaari ba nating pag-usapan ang tungkol sa atin?",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.us",
                                    ["effects"] = {
                                        {
                                            ["approval"] = 2,
                                            ["familiarity"] = 2,
                                            ["type"] = "pnc:relationship",
                                        },
                                    },
                                    ["responseKey"] = "response.us",
                                    ["responseText"] = {
                                        ["EN"] = "Yes. We probably should.",
                                        ["TL"] = "Oo. Malamang dapat nga.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "Can we talk about us?",
                                    },
                                    ["TL"] = {
                                        "Maaari ba nating pag-usapan ang tungkol sa atin?",
                                    },
                                },
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm listening, {addressee.name}. Say what you need to say.",
                            },
                            ["TL"] = {
                                "Nakikinig ako, {addressee.name}. Sabihin ang kailangan mong sabihin.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "RELATIONSHIP_TOPIC",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.relationship.special.affinity",
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
                                ["subject"] = "RELATIONSHIP",
                                ["topic"] = "relationship",
                            },
                            ["id"] = "us",
                            ["labelFallback"] = "Can we talk about us?",
                            ["labelKey"] = "psdl.social.relationship.special.affinity.offer.us.label",
                            ["utteranceFallback"] = "Can we talk about us?",
                            ["utteranceKey"] = "psdl.social.relationship.special.affinity.offer.us.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I'm listening, {addressee.name}. Say what you need to say.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.social.relationship.special.affinity.opening",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/social_companion_topics.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "gte",
            ["path"] = "relationship.speakerToAddressee.approval",
            ["value"] = 20,
        },
    },
}
