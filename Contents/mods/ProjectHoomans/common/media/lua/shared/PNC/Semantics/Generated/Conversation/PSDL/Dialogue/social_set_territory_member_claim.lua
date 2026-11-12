-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_companion_topics",
        ["id"] = "social.set_territory.member.claim",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "social.set_territory.member.claim",
            ["sourcePath"] = "psdl/dialogue/social_companion_topics.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/social_set_territory_member_claim",
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
                    "member",
                },
                ["category"] = "projecthoomans:set_territory",
                ["priority"] = 1000,
                ["runtimeBlockID"] = "projecthoomans:set_territory_member",
                ["textDomain"] = "pnc.psdl.social.territory.member.claim",
                ["textRows"] = {
                    {
                        ["key"] = "locked.base_established",
                        ["text"] = {
                            ["EN"] = "Our territory is already established.",
                            ["TL"] = "Ang aming teritoryo ay naitatag na.",
                        },
                    },
                },
                ["textTarget"] = "psdl/social/territory/member/claim",
            },
            ["response"] = {
                ["act"] = "SET_TERRITORY",
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
                                    ["subject"] = "TERRITORY",
                                    ["topic"] = "territory",
                                },
                                ["id"] = "set_territory",
                                ["label"] = {
                                    ["EN"] = {
                                        "Set Territory",
                                    },
                                    ["TL"] = {
                                        "Itakda ang Teritoryo",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.set_territory",
                                    ["close"] = true,
                                    ["effects"] = {
                                        {
                                            ["type"] = "pnc:open_territory_claim",
                                        },
                                    },
                                    ["responseKey"] = "response.set_territory",
                                    ["responseText"] = {
                                        ["EN"] = "Then let us find ground worth defending. I will help turn it into home.",
                                        ["TL"] = "Then let us find ground worth defending. I will tulong turn it into home.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "Set Territory",
                                    },
                                    ["TL"] = {
                                        "Itakda ang Teritoryo",
                                    },
                                },
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "We have enough people to stop surviving from one night to the next. Pick a place, mark it as ours, and we can start building something that lasts.",
                            },
                            ["TL"] = {
                                "We have enough people to stop surviving from one night to the next. Pick a place, mark it as ours, and we can simulan gusali something that lasts.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "SET_TERRITORY",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.set_territory.member.claim",
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
                                ["subject"] = "TERRITORY",
                                ["topic"] = "territory",
                            },
                            ["id"] = "set_territory",
                            ["labelFallback"] = "Set Territory",
                            ["labelKey"] = "psdl.social.set_territory.member.claim.offer.set_territory.label",
                            ["utteranceFallback"] = "Set Territory",
                            ["utteranceKey"] = "psdl.social.set_territory.member.claim.offer.set_territory.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "We have enough people to stop surviving from one night to the next. Pick a place, mark it as ours, and we can start building something that lasts.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.social.set_territory.member.claim.opening",
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
            ["all"] = {
                {
                    ["op"] = "eq",
                    ["path"] = "conversation.audience",
                    ["value"] = "member",
                },
                {
                    ["op"] = "eq",
                    ["path"] = "scene.baseEstablished",
                    ["value"] = false,
                },
            },
        },
    },
}
