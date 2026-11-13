-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_companion_topics",
        ["id"] = "social.personal.special.trust",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "social.personal.special.trust",
            ["sourcePath"] = "psdl/dialogue/social_companion_topics.json#records[0]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialCompanionTopics",
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
    {
        ["domain"] = "social_companion_topics",
        ["id"] = "social.relationship.special.affinity",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "social.relationship.special.affinity",
            ["sourcePath"] = "psdl/dialogue/social_companion_topics.json#records[1]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialCompanionTopics",
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
    {
        ["domain"] = "social_companion_topics",
        ["id"] = "social.set_territory.member.claim",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "social.set_territory.member.claim",
            ["sourcePath"] = "psdl/dialogue/social_companion_topics.json#records[2]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialCompanionTopics",
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
    {
        ["domain"] = "social_companion_topics",
        ["id"] = "work_orders.member.status",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "work_orders.member.status",
            ["sourcePath"] = "psdl/dialogue/social_companion_topics.json#records[3]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialCompanionTopics",
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
                ["category"] = "projecthoomans:work_orders",
                ["runtimeBlockID"] = "projecthoomans:work_orders_member",
                ["textDomain"] = "pnc.psdl.work_orders.member.status",
                ["textTarget"] = "psdl/work_orders/member/status",
            },
            ["response"] = {
                ["act"] = "WORK_ORDERS",
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
                                    ["subject"] = "WORK",
                                    ["topic"] = "work_orders",
                                },
                                ["id"] = "orders",
                                ["label"] = {
                                    ["EN"] = {
                                        "I have work for you.",
                                    },
                                    ["TL"] = {
                                        "may trabaho ako sayo.",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.orders",
                                    ["responseKey"] = "response.orders",
                                    ["responseText"] = {
                                        ["EN"] = "Tell me what needs doing.",
                                        ["TL"] = "Sabihin mo sa akin kung ano ang kailangang gawin.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "I have work for you.",
                                    },
                                    ["TL"] = {
                                        "may trabaho ako sayo.",
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
                                    ["subject"] = "WORK",
                                    ["topic"] = "work_orders",
                                },
                                ["id"] = "status",
                                ["label"] = {
                                    ["EN"] = {
                                        "Report on your current work.",
                                    },
                                    ["TL"] = {
                                        "Mag-ulat sa iyong kasalukuyang gawain.",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.status",
                                    ["responseKey"] = "response.status",
                                    ["responseText"] = {
                                        ["EN"] = "Everything is on track for now.",
                                        ["TL"] = "Ang lahat ay nasa track sa ngayon.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "Report on your current work.",
                                    },
                                    ["TL"] = {
                                        "Mag-ulat sa iyong kasalukuyang gawain.",
                                    },
                                },
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm ready. What needs doing?",
                            },
                            ["TL"] = {
                                "handa na ako. Ano ang kailangang gawin?",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "WORK_ORDERS",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "work_orders.member.status",
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
                                ["subject"] = "WORK",
                                ["topic"] = "work_orders",
                            },
                            ["id"] = "orders",
                            ["labelFallback"] = "I have work for you.",
                            ["labelKey"] = "psdl.work_orders.member.status.offer.orders.label",
                            ["utteranceFallback"] = "I have work for you.",
                            ["utteranceKey"] = "psdl.work_orders.member.status.offer.orders.utterance",
                        },
                        {
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "WORK",
                                ["topic"] = "work_orders",
                            },
                            ["id"] = "status",
                            ["labelFallback"] = "Report on your current work.",
                            ["labelKey"] = "psdl.work_orders.member.status.offer.status.label",
                            ["utteranceFallback"] = "Report on your current work.",
                            ["utteranceKey"] = "psdl.work_orders.member.status.offer.status.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I'm ready. What needs doing?",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.work_orders.member.status.opening",
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
        ["when"] = nil,
    },
}
