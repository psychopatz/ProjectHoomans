-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_companion_topics",
        ["id"] = "social.personal.special.trust",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "social.personal.special.trust",
            ["sourcePath"] = "psdl/dialogue/social_companion_topics.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/social_personal_special_trust",
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
                ["category"] = "projecthoomans:personal",
                ["runtimeBlockID"] = "projecthoomans:personal_special",
                ["textDomain"] = "pnc.psdl.social.personal.special.trust",
                ["textTarget"] = "psdl/social/personal/special/trust",
            },
            ["response"] = {
                ["act"] = "PERSONAL_TOPIC",
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
                                    ["subject"] = "TRUST",
                                    ["topic"] = "personal",
                                },
                                ["id"] = "trust",
                                ["label"] = {
                                    ["EN"] = {
                                        "You can trust me.",
                                    },
                                    ["TL"] = {
                                        "Maaari kang magtiwala sa akin.",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.trust",
                                    ["effects"] = {
                                        {
                                            ["approval"] = 2,
                                            ["familiarity"] = 2,
                                            ["type"] = "pnc:relationship",
                                        },
                                    },
                                    ["responseKey"] = "response.trust",
                                    ["responseText"] = {
                                        ["EN"] = "I know. That still means more than I can say.",
                                        ["TL"] = "alam ko. Nangangahulugan pa rin iyon ng higit pa sa masasabi ko.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "You can trust me.",
                                    },
                                    ["TL"] = {
                                        "Maaari kang magtiwala sa akin.",
                                    },
                                },
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "All right, {addressee.name}. We can talk about us.",
                            },
                            ["TL"] = {
                                "Sige, {addressee.name}. Maaari naming pag-usapan ang tungkol sa amin.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "PERSONAL_TOPIC",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.personal.special.trust",
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
                                ["subject"] = "TRUST",
                                ["topic"] = "personal",
                            },
                            ["id"] = "trust",
                            ["labelFallback"] = "You can trust me.",
                            ["labelKey"] = "psdl.social.personal.special.trust.offer.trust.label",
                            ["utteranceFallback"] = "You can trust me.",
                            ["utteranceKey"] = "psdl.social.personal.special.trust.offer.trust.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "All right, {addressee.name}. We can talk about us.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.social.personal.special.trust.opening",
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
            ["path"] = "relationship.speakerToAddressee.familiarity",
            ["value"] = 10,
        },
    },
}
