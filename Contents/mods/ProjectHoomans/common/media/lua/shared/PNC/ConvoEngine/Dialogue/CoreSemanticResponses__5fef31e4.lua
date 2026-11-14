-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "question.wellbeing",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "I'm hanging in there. Thanks for asking.",
                                ["id"] = "question.wellbeing.dataset.hanging_in",
                                ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.hanging_in",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'm hanging in there. Thanks for asking.",
                                    },
                                    ["TL"] = {
                                        "I'm hanging in there. Thanks for asking.",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "Doing okay, all things considered.",
                                ["id"] = "question.wellbeing.dataset.all_things_considered",
                                ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.all_things_considered",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Doing okay, all things considered.",
                                    },
                                    ["TL"] = {
                                        "Doing okay, all things considered.",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "I'm getting by, one day at a time. How about you?",
                                ["id"] = "question.wellbeing.dataset.getting_by",
                                ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.getting_by",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'm getting by, one day at a time. How about you?",
                                    },
                                    ["TL"] = {
                                        "I'm getting by, one day at a time. How about you?",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "I'm hungry, but I'll manage. If you have food to spare, I'd appreciate it.",
                                ["id"] = "question.wellbeing.dataset.hungry",
                                ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.hungry",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'm hungry, but I'll manage. If you have food to spare, I'd appreciate it.",
                                    },
                                    ["TL"] = {
                                        "I'm hungry, but I'll manage. If you have food to spare, I'd appreciate it.",
                                    },
                                },
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.needType",
                                            ["value"] = "hunger",
                                        },
                                        {
                                            ["op"] = "in",
                                            ["path"] = "conversation.needUrgency",
                                            ["values"] = {
                                                "moderate",
                                                "severe",
                                                "emergency",
                                                "critical",
                                            },
                                        },
                                    },
                                },
                            },
                            {
                                ["fallback"] = "I'm pretty thirsty. If you have water, could you spare some?",
                                ["id"] = "question.wellbeing.dataset.thirsty",
                                ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.thirsty",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'm pretty thirsty. If you have water, could you spare some?",
                                    },
                                    ["TL"] = {
                                        "I'm pretty thirsty. If you have water, could you spare some?",
                                    },
                                },
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.needType",
                                            ["value"] = "thirst",
                                        },
                                        {
                                            ["op"] = "in",
                                            ["path"] = "conversation.needUrgency",
                                            ["values"] = {
                                                "moderate",
                                                "severe",
                                                "emergency",
                                                "critical",
                                            },
                                        },
                                    },
                                },
                            },
                            {
                                ["fallback"] = "I'm tired, though I can manage for now.",
                                ["id"] = "question.wellbeing.dataset.tired",
                                ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.tired",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'm tired, though I can manage for now.",
                                    },
                                    ["TL"] = {
                                        "I'm tired, though I can manage for now.",
                                    },
                                },
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.needType",
                                            ["value"] = "fatigue",
                                        },
                                        {
                                            ["op"] = "in",
                                            ["path"] = "conversation.needUrgency",
                                            ["values"] = {
                                                "moderate",
                                                "severe",
                                                "emergency",
                                                "critical",
                                            },
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm hanging in there. Thanks for asking.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.hanging_in",
                    ["translations"] = {
                        ["EN"] = {
                            "I'm hanging in there. Thanks for asking.",
                        },
                        ["TL"] = {
                            "I'm hanging in there. Thanks for asking.",
                        },
                    },
                    ["variantID"] = "question.wellbeing.dataset.hanging_in",
                },
                {
                    ["fallback"] = "Doing okay, all things considered.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.all_things_considered",
                    ["translations"] = {
                        ["EN"] = {
                            "Doing okay, all things considered.",
                        },
                        ["TL"] = {
                            "Doing okay, all things considered.",
                        },
                    },
                    ["variantID"] = "question.wellbeing.dataset.all_things_considered",
                },
                {
                    ["fallback"] = "I'm getting by, one day at a time. How about you?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.getting_by",
                    ["translations"] = {
                        ["EN"] = {
                            "I'm getting by, one day at a time. How about you?",
                        },
                        ["TL"] = {
                            "I'm getting by, one day at a time. How about you?",
                        },
                    },
                    ["variantID"] = "question.wellbeing.dataset.getting_by",
                },
                {
                    ["fallback"] = "I'm hungry, but I'll manage. If you have food to spare, I'd appreciate it.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.hungry",
                    ["translations"] = {
                        ["EN"] = {
                            "I'm hungry, but I'll manage. If you have food to spare, I'd appreciate it.",
                        },
                        ["TL"] = {
                            "I'm hungry, but I'll manage. If you have food to spare, I'd appreciate it.",
                        },
                    },
                    ["variantID"] = "question.wellbeing.dataset.hungry",
                },
                {
                    ["fallback"] = "I'm pretty thirsty. If you have water, could you spare some?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.thirsty",
                    ["translations"] = {
                        ["EN"] = {
                            "I'm pretty thirsty. If you have water, could you spare some?",
                        },
                        ["TL"] = {
                            "I'm pretty thirsty. If you have water, could you spare some?",
                        },
                    },
                    ["variantID"] = "question.wellbeing.dataset.thirsty",
                },
                {
                    ["fallback"] = "I'm tired, though I can manage for now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.tired",
                    ["translations"] = {
                        ["EN"] = {
                            "I'm tired, though I can manage for now.",
                        },
                        ["TL"] = {
                            "I'm tired, though I can manage for now.",
                        },
                    },
                    ["variantID"] = "question.wellbeing.dataset.tired",
                },
            },
        },
        ["id"] = "question.wellbeing",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "wellbeing",
            ["sourceId"] = "question.wellbeing",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_wellbeing.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses__5fef31e4",
        ["namespace"] = "question",
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
                ["responseAct"] = "WELLBEING",
                ["responsePoolID"] = "question.wellbeing",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "question.wellbeing.dataset.hanging_in",
                                ["metadata"] = {
                                    ["fallback"] = "I'm hanging in there. Thanks for asking.",
                                    ["templateID"] = "question.wellbeing.dataset.hanging_in",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "I'm hanging in there. Thanks for asking.",
                                    },
                                    ["TL"] = {
                                        "I'm hanging in there. Thanks for asking.",
                                    },
                                },
                            },
                            {
                                ["id"] = "question.wellbeing.dataset.all_things_considered",
                                ["metadata"] = {
                                    ["fallback"] = "Doing okay, all things considered.",
                                    ["templateID"] = "question.wellbeing.dataset.all_things_considered",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "Doing okay, all things considered.",
                                    },
                                    ["TL"] = {
                                        "Doing okay, all things considered.",
                                    },
                                },
                            },
                            {
                                ["id"] = "question.wellbeing.dataset.getting_by",
                                ["metadata"] = {
                                    ["fallback"] = "I'm getting by, one day at a time. How about you?",
                                    ["templateID"] = "question.wellbeing.dataset.getting_by",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "I'm getting by, one day at a time. How about you?",
                                    },
                                    ["TL"] = {
                                        "I'm getting by, one day at a time. How about you?",
                                    },
                                },
                            },
                            {
                                ["id"] = "question.wellbeing.dataset.hungry",
                                ["metadata"] = {
                                    ["fallback"] = "I'm hungry, but I'll manage. If you have food to spare, I'd appreciate it.",
                                    ["priority"] = 2,
                                    ["templateID"] = "question.wellbeing.dataset.hungry",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "I'm hungry, but I'll manage. If you have food to spare, I'd appreciate it.",
                                    },
                                    ["TL"] = {
                                        "I'm hungry, but I'll manage. If you have food to spare, I'd appreciate it.",
                                    },
                                },
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.needType",
                                            ["value"] = "hunger",
                                        },
                                        {
                                            ["op"] = "in",
                                            ["path"] = "conversation.needUrgency",
                                            ["values"] = {
                                                "moderate",
                                                "severe",
                                                "emergency",
                                                "critical",
                                            },
                                        },
                                    },
                                },
                            },
                            {
                                ["id"] = "question.wellbeing.dataset.thirsty",
                                ["metadata"] = {
                                    ["fallback"] = "I'm pretty thirsty. If you have water, could you spare some?",
                                    ["priority"] = 3,
                                    ["templateID"] = "question.wellbeing.dataset.thirsty",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "I'm pretty thirsty. If you have water, could you spare some?",
                                    },
                                    ["TL"] = {
                                        "I'm pretty thirsty. If you have water, could you spare some?",
                                    },
                                },
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.needType",
                                            ["value"] = "thirst",
                                        },
                                        {
                                            ["op"] = "in",
                                            ["path"] = "conversation.needUrgency",
                                            ["values"] = {
                                                "moderate",
                                                "severe",
                                                "emergency",
                                                "critical",
                                            },
                                        },
                                    },
                                },
                            },
                            {
                                ["id"] = "question.wellbeing.dataset.tired",
                                ["metadata"] = {
                                    ["fallback"] = "I'm tired, though I can manage for now.",
                                    ["priority"] = 2,
                                    ["templateID"] = "question.wellbeing.dataset.tired",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "I'm tired, though I can manage for now.",
                                    },
                                    ["TL"] = {
                                        "I'm tired, though I can manage for now.",
                                    },
                                },
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.needType",
                                            ["value"] = "fatigue",
                                        },
                                        {
                                            ["op"] = "in",
                                            ["path"] = "conversation.needUrgency",
                                            ["values"] = {
                                                "moderate",
                                                "severe",
                                                "emergency",
                                                "critical",
                                            },
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "WELLBEING",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.wellbeing",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I'm hanging in there. Thanks for asking.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.question.wellbeing.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_wellbeing.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm hanging in there. Thanks for asking.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.hanging_in",
                ["translations"] = {
                    ["EN"] = {
                        "I'm hanging in there. Thanks for asking.",
                    },
                    ["TL"] = {
                        "I'm hanging in there. Thanks for asking.",
                    },
                },
                ["variantID"] = "question.wellbeing.dataset.hanging_in",
            },
            {
                ["fallback"] = "Doing okay, all things considered.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.all_things_considered",
                ["translations"] = {
                    ["EN"] = {
                        "Doing okay, all things considered.",
                    },
                    ["TL"] = {
                        "Doing okay, all things considered.",
                    },
                },
                ["variantID"] = "question.wellbeing.dataset.all_things_considered",
            },
            {
                ["fallback"] = "I'm getting by, one day at a time. How about you?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.getting_by",
                ["translations"] = {
                    ["EN"] = {
                        "I'm getting by, one day at a time. How about you?",
                    },
                    ["TL"] = {
                        "I'm getting by, one day at a time. How about you?",
                    },
                },
                ["variantID"] = "question.wellbeing.dataset.getting_by",
            },
            {
                ["fallback"] = "I'm hungry, but I'll manage. If you have food to spare, I'd appreciate it.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.hungry",
                ["translations"] = {
                    ["EN"] = {
                        "I'm hungry, but I'll manage. If you have food to spare, I'd appreciate it.",
                    },
                    ["TL"] = {
                        "I'm hungry, but I'll manage. If you have food to spare, I'd appreciate it.",
                    },
                },
                ["variantID"] = "question.wellbeing.dataset.hungry",
            },
            {
                ["fallback"] = "I'm pretty thirsty. If you have water, could you spare some?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.thirsty",
                ["translations"] = {
                    ["EN"] = {
                        "I'm pretty thirsty. If you have water, could you spare some?",
                    },
                    ["TL"] = {
                        "I'm pretty thirsty. If you have water, could you spare some?",
                    },
                },
                ["variantID"] = "question.wellbeing.dataset.thirsty",
            },
            {
                ["fallback"] = "I'm tired, though I can manage for now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.say.1.question.wellbeing.dataset.tired",
                ["translations"] = {
                    ["EN"] = {
                        "I'm tired, though I can manage for now.",
                    },
                    ["TL"] = {
                        "I'm tired, though I can manage for now.",
                    },
                },
                ["variantID"] = "question.wellbeing.dataset.tired",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "question.wellbeing.unknown",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "I can tell something is off, but I do not know what caused it yet.",
                                ["id"] = "question.wellbeing.unknown.dataset.causal_followup",
                                ["templateID"] = "convo.question.wellbeing.unknown.say.1.question.wellbeing.unknown.dataset.causal_followup",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I can tell something is off, but I do not know what caused it yet.",
                                    },
                                    ["TL"] = {
                                        "Alam kong may hindi tama, pero hindi ko pa alam kung ano ang sanhi nito.",
                                    },
                                },
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.healthState",
                                            ["value"] = "unknown",
                                        },
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.pattern",
                                            ["value"] = "pnc.dataset.question.wellbeing.what_is_going_on_with_you",
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.wellbeing",
            ["textRoles"] = {
                {
                    ["fallback"] = "I can tell something is off, but I do not know what caused it yet.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.unknown.say.1.question.wellbeing.unknown.dataset.causal_followup",
                    ["translations"] = {
                        ["EN"] = {
                            "I can tell something is off, but I do not know what caused it yet.",
                        },
                        ["TL"] = {
                            "Alam kong may hindi tama, pero hindi ko pa alam kung ano ang sanhi nito.",
                        },
                    },
                    ["variantID"] = "question.wellbeing.unknown.dataset.causal_followup",
                },
            },
        },
        ["id"] = "question.wellbeing.unknown",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "unknown",
            ["sourceId"] = "question.wellbeing.unknown",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_wellbeing_unknown.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses__5fef31e4",
        ["namespace"] = "question.wellbeing",
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
                ["responseAct"] = "UNKNOWN",
                ["responsePoolID"] = "question.wellbeing.unknown",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "question.wellbeing.unknown.dataset.causal_followup",
                                ["metadata"] = {
                                    ["fallback"] = "I can tell something is off, but I do not know what caused it yet.",
                                    ["plan"] = {
                                        ["dialogueAct"] = "ASK_CLARIFICATION",
                                        ["groundedFactRefs"] = {
                                        },
                                        ["personalityStyle"] = "truthful",
                                        ["sourcePoolID"] = "semantic.question.wellbeing.unknown",
                                        ["tone"] = "clarifying",
                                        ["topic"] = "WELLBEING",
                                        ["turns"] = {
                                            {
                                                ["continuation"] = "continue",
                                                ["id"] = "dataset_causal_wellbeing_unknown",
                                                ["segments"] = {
                                                    {
                                                        ["fallback"] = "I can tell something is off, but I do not know what caused it yet.",
                                                        ["kind"] = "translation",
                                                        ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetWellbeingCausalUnknown",
                                                        ["translations"] = {
                                                            ["EN"] = "I can tell something is off, but I do not know what caused it yet.",
                                                            ["TL"] = "Alam kong may hindi tama, pero hindi ko pa alam kung ano ang sanhi nito.",
                                                        },
                                                    },
                                                },
                                            },
                                        },
                                        ["uncertainty"] = "unknown",
                                    },
                                    ["priority"] = 4,
                                    ["reviewed"] = true,
                                    ["sourceRefs"] = {
                                        "MASSIVE",
                                        "SGD",
                                    },
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetWellbeingCausalUnknown",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "I can tell something is off, but I do not know what caused it yet.",
                                    },
                                    ["TL"] = {
                                        "Alam kong may hindi tama, pero hindi ko pa alam kung ano ang sanhi nito.",
                                    },
                                },
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.healthState",
                                            ["value"] = "unknown",
                                        },
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.pattern",
                                            ["value"] = "pnc.dataset.question.wellbeing.what_is_going_on_with_you",
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "UNKNOWN",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.wellbeing.unknown",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I can tell something is off, but I do not know what caused it yet.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.question.wellbeing.unknown.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_wellbeing_unknown.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I can tell something is off, but I do not know what caused it yet.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.unknown.say.1.question.wellbeing.unknown.dataset.causal_followup",
                ["translations"] = {
                    ["EN"] = {
                        "I can tell something is off, but I do not know what caused it yet.",
                    },
                    ["TL"] = {
                        "Alam kong may hindi tama, pero hindi ko pa alam kung ano ang sanhi nito.",
                    },
                },
                ["variantID"] = "question.wellbeing.unknown.dataset.causal_followup",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "refuse",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "I can't take that on right now.",
                                ["id"] = "refuse.dataset.pending_unavailable",
                                ["templateID"] = "convo.refuse.say.1.refuse.dataset.pending_unavailable",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I can't take that on right now.",
                                    },
                                    ["TL"] = {
                                        "I can't take that on right now.",
                                    },
                                },
                                ["when"] = {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.hasPendingRequest",
                                    ["value"] = true,
                                },
                            },
                            {
                                ["fallback"] = "Not this time. I have enough to manage.",
                                ["id"] = "refuse.dataset.pending_enough",
                                ["templateID"] = "convo.refuse.say.1.refuse.dataset.pending_enough",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Not this time. I have enough to manage.",
                                    },
                                    ["TL"] = {
                                        "Not this time. I have enough to manage.",
                                    },
                                },
                                ["when"] = {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.hasPendingRequest",
                                    ["value"] = true,
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "I can't take that on right now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.refuse.say.1.refuse.dataset.pending_unavailable",
                    ["translations"] = {
                        ["EN"] = {
                            "I can't take that on right now.",
                        },
                        ["TL"] = {
                            "I can't take that on right now.",
                        },
                    },
                    ["variantID"] = "refuse.dataset.pending_unavailable",
                },
                {
                    ["fallback"] = "Not this time. I have enough to manage.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.refuse.say.1.refuse.dataset.pending_enough",
                    ["translations"] = {
                        ["EN"] = {
                            "Not this time. I have enough to manage.",
                        },
                        ["TL"] = {
                            "Not this time. I have enough to manage.",
                        },
                    },
                    ["variantID"] = "refuse.dataset.pending_enough",
                },
            },
        },
        ["id"] = "refuse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "refuse",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/refuse.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses__5fef31e4",
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
                ["responseAct"] = "REFUSE",
                ["responsePoolID"] = "refuse",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "refuse.dataset.pending_unavailable",
                                ["metadata"] = {
                                    ["fallback"] = "I can't take that on right now.",
                                    ["priority"] = 1,
                                    ["templateID"] = "refuse.dataset.pending_unavailable",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "I can't take that on right now.",
                                    },
                                    ["TL"] = {
                                        "I can't take that on right now.",
                                    },
                                },
                                ["when"] = {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.hasPendingRequest",
                                    ["value"] = true,
                                },
                            },
                            {
                                ["id"] = "refuse.dataset.pending_enough",
                                ["metadata"] = {
                                    ["fallback"] = "Not this time. I have enough to manage.",
                                    ["priority"] = 1,
                                    ["templateID"] = "refuse.dataset.pending_enough",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "Not this time. I have enough to manage.",
                                    },
                                    ["TL"] = {
                                        "Not this time. I have enough to manage.",
                                    },
                                },
                                ["when"] = {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.hasPendingRequest",
                                    ["value"] = true,
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REFUSE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "refuse",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I can't take that on right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.refuse.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/refuse.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I can't take that on right now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.refuse.say.1.refuse.dataset.pending_unavailable",
                ["translations"] = {
                    ["EN"] = {
                        "I can't take that on right now.",
                    },
                    ["TL"] = {
                        "I can't take that on right now.",
                    },
                },
                ["variantID"] = "refuse.dataset.pending_unavailable",
            },
            {
                ["fallback"] = "Not this time. I have enough to manage.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.refuse.say.1.refuse.dataset.pending_enough",
                ["translations"] = {
                    ["EN"] = {
                        "Not this time. I have enough to manage.",
                    },
                    ["TL"] = {
                        "Not this time. I have enough to manage.",
                    },
                },
                ["variantID"] = "refuse.dataset.pending_enough",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "response_pool.question.identity",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "I keep my name to myself until I know someone better. What should I call you?",
                                ["id"] = "question.identity.dataset.stranger_alt_1",
                                ["templateID"] = "convo.response_pool.question.identity.say.1.question.identity.dataset.stranger_alt_1",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I keep my name to myself until I know someone better. What should I call you?",
                                    },
                                    ["TL"] = {
                                        "I keep my name to myself until I know someone better. What should I call you?",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "Let's get to know each other first. What do people call you?",
                                ["id"] = "question.identity.dataset.stranger_alt_2",
                                ["templateID"] = "convo.response_pool.question.identity.say.1.question.identity.dataset.stranger_alt_2",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Let's get to know each other first. What do people call you?",
                                    },
                                    ["TL"] = {
                                        "Let's get to know each other first. What do people call you?",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "I don't trust you enough to share my name. Who are you, really?",
                                ["id"] = "question.identity.dataset.wary_alt_1",
                                ["templateID"] = "convo.response_pool.question.identity.say.1.question.identity.dataset.wary_alt_1",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I don't trust you enough to share my name. Who are you, really?",
                                    },
                                    ["TL"] = {
                                        "I don't trust you enough to share my name. Who are you, really?",
                                    },
                                },
                                ["when"] = {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.identityTrust",
                                    ["value"] = "untrustworthy",
                                },
                            },
                            {
                                ["fallback"] = "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                                ["id"] = "question.identity.dataset.wary_alt_2",
                                ["templateID"] = "convo.response_pool.question.identity.say.1.question.identity.dataset.wary_alt_2",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                                    },
                                    ["TL"] = {
                                        "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                                    },
                                },
                                ["when"] = {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.identityTrust",
                                    ["value"] = "untrustworthy",
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "response_pool.question",
            ["textRoles"] = {
                {
                    ["fallback"] = "I keep my name to myself until I know someone better. What should I call you?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response_pool.question.identity.say.1.question.identity.dataset.stranger_alt_1",
                    ["translations"] = {
                        ["EN"] = {
                            "I keep my name to myself until I know someone better. What should I call you?",
                        },
                        ["TL"] = {
                            "I keep my name to myself until I know someone better. What should I call you?",
                        },
                    },
                    ["variantID"] = "question.identity.dataset.stranger_alt_1",
                },
                {
                    ["fallback"] = "Let's get to know each other first. What do people call you?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response_pool.question.identity.say.1.question.identity.dataset.stranger_alt_2",
                    ["translations"] = {
                        ["EN"] = {
                            "Let's get to know each other first. What do people call you?",
                        },
                        ["TL"] = {
                            "Let's get to know each other first. What do people call you?",
                        },
                    },
                    ["variantID"] = "question.identity.dataset.stranger_alt_2",
                },
                {
                    ["fallback"] = "I don't trust you enough to share my name. Who are you, really?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response_pool.question.identity.say.1.question.identity.dataset.wary_alt_1",
                    ["translations"] = {
                        ["EN"] = {
                            "I don't trust you enough to share my name. Who are you, really?",
                        },
                        ["TL"] = {
                            "I don't trust you enough to share my name. Who are you, really?",
                        },
                    },
                    ["variantID"] = "question.identity.dataset.wary_alt_1",
                },
                {
                    ["fallback"] = "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response_pool.question.identity.say.1.question.identity.dataset.wary_alt_2",
                    ["translations"] = {
                        ["EN"] = {
                            "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                        },
                        ["TL"] = {
                            "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                        },
                    },
                    ["variantID"] = "question.identity.dataset.wary_alt_2",
                },
            },
        },
        ["id"] = "response_pool.question.identity",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "identity",
            ["sourceId"] = "response_pool.question.identity",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_identity.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses__5fef31e4",
        ["namespace"] = "response_pool.question",
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
                ["responseAct"] = "IDENTITY",
                ["responsePoolID"] = "question.identity",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "question.identity.dataset.stranger_alt_1",
                                ["metadata"] = {
                                    ["fallback"] = "I keep my name to myself until I know someone better. What should I call you?",
                                    ["templateID"] = "question.identity.stranger_alt_1",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "I keep my name to myself until I know someone better. What should I call you?",
                                    },
                                    ["TL"] = {
                                        "I keep my name to myself until I know someone better. What should I call you?",
                                    },
                                },
                            },
                            {
                                ["id"] = "question.identity.dataset.stranger_alt_2",
                                ["metadata"] = {
                                    ["fallback"] = "Let's get to know each other first. What do people call you?",
                                    ["templateID"] = "question.identity.stranger_alt_2",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "Let's get to know each other first. What do people call you?",
                                    },
                                    ["TL"] = {
                                        "Let's get to know each other first. What do people call you?",
                                    },
                                },
                            },
                            {
                                ["id"] = "question.identity.dataset.wary_alt_1",
                                ["metadata"] = {
                                    ["fallback"] = "I don't trust you enough to share my name. Who are you, really?",
                                    ["priority"] = 2,
                                    ["templateID"] = "question.identity.wary_alt_1",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "I don't trust you enough to share my name. Who are you, really?",
                                    },
                                    ["TL"] = {
                                        "I don't trust you enough to share my name. Who are you, really?",
                                    },
                                },
                                ["when"] = {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.identityTrust",
                                    ["value"] = "untrustworthy",
                                },
                            },
                            {
                                ["id"] = "question.identity.dataset.wary_alt_2",
                                ["metadata"] = {
                                    ["fallback"] = "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                                    ["priority"] = 2,
                                    ["templateID"] = "question.identity.wary_alt_2",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                                    },
                                    ["TL"] = {
                                        "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                                    },
                                },
                                ["when"] = {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.identityTrust",
                                    ["value"] = "untrustworthy",
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "IDENTITY",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "response_pool.question.identity",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I keep my name to myself until I know someone better. What should I call you?",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.response_pool.question.identity.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_identity.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I keep my name to myself until I know someone better. What should I call you?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response_pool.question.identity.say.1.question.identity.dataset.stranger_alt_1",
                ["translations"] = {
                    ["EN"] = {
                        "I keep my name to myself until I know someone better. What should I call you?",
                    },
                    ["TL"] = {
                        "I keep my name to myself until I know someone better. What should I call you?",
                    },
                },
                ["variantID"] = "question.identity.dataset.stranger_alt_1",
            },
            {
                ["fallback"] = "Let's get to know each other first. What do people call you?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response_pool.question.identity.say.1.question.identity.dataset.stranger_alt_2",
                ["translations"] = {
                    ["EN"] = {
                        "Let's get to know each other first. What do people call you?",
                    },
                    ["TL"] = {
                        "Let's get to know each other first. What do people call you?",
                    },
                },
                ["variantID"] = "question.identity.dataset.stranger_alt_2",
            },
            {
                ["fallback"] = "I don't trust you enough to share my name. Who are you, really?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response_pool.question.identity.say.1.question.identity.dataset.wary_alt_1",
                ["translations"] = {
                    ["EN"] = {
                        "I don't trust you enough to share my name. Who are you, really?",
                    },
                    ["TL"] = {
                        "I don't trust you enough to share my name. Who are you, really?",
                    },
                },
                ["variantID"] = "question.identity.dataset.wary_alt_1",
            },
            {
                ["fallback"] = "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response_pool.question.identity.say.1.question.identity.dataset.wary_alt_2",
                ["translations"] = {
                    ["EN"] = {
                        "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                    },
                    ["TL"] = {
                        "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                    },
                },
                ["variantID"] = "question.identity.dataset.wary_alt_2",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["exchangeFamily"] = {
            ["familyID"] = "thanks",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "No problem at all.",
                                ["id"] = "thanks.dataset.no_problem",
                                ["templateID"] = "convo.thanks.say.1.thanks.dataset.no_problem",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "No problem at all.",
                                    },
                                    ["TL"] = {
                                        "No problem at all.",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "Anytime.",
                                ["id"] = "thanks.dataset.anytime",
                                ["templateID"] = "convo.thanks.say.1.thanks.dataset.anytime",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Anytime.",
                                    },
                                    ["TL"] = {
                                        "Anytime.",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "Glad I could help.",
                                ["id"] = "thanks.dataset.glady",
                                ["templateID"] = "convo.thanks.say.1.thanks.dataset.glady",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Glad I could help.",
                                    },
                                    ["TL"] = {
                                        "Glad I could help.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "No problem at all.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.thanks.say.1.thanks.dataset.no_problem",
                    ["translations"] = {
                        ["EN"] = {
                            "No problem at all.",
                        },
                        ["TL"] = {
                            "No problem at all.",
                        },
                    },
                    ["variantID"] = "thanks.dataset.no_problem",
                },
                {
                    ["fallback"] = "Anytime.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.thanks.say.1.thanks.dataset.anytime",
                    ["translations"] = {
                        ["EN"] = {
                            "Anytime.",
                        },
                        ["TL"] = {
                            "Anytime.",
                        },
                    },
                    ["variantID"] = "thanks.dataset.anytime",
                },
                {
                    ["fallback"] = "Glad I could help.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.thanks.say.1.thanks.dataset.glady",
                    ["translations"] = {
                        ["EN"] = {
                            "Glad I could help.",
                        },
                        ["TL"] = {
                            "Glad I could help.",
                        },
                    },
                    ["variantID"] = "thanks.dataset.glady",
                },
            },
        },
        ["id"] = "thanks",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "thanks",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/thanks.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses__5fef31e4",
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
                ["responseAct"] = "THANKS",
                ["responsePoolID"] = "thanks",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "thanks.dataset.no_problem",
                                ["metadata"] = {
                                    ["fallback"] = "No problem at all.",
                                    ["templateID"] = "thanks.dataset.no_problem",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "No problem at all.",
                                    },
                                    ["TL"] = {
                                        "No problem at all.",
                                    },
                                },
                            },
                            {
                                ["id"] = "thanks.dataset.anytime",
                                ["metadata"] = {
                                    ["fallback"] = "Anytime.",
                                    ["templateID"] = "thanks.dataset.anytime",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "Anytime.",
                                    },
                                    ["TL"] = {
                                        "Anytime.",
                                    },
                                },
                            },
                            {
                                ["id"] = "thanks.dataset.glady",
                                ["metadata"] = {
                                    ["fallback"] = "Glad I could help.",
                                    ["templateID"] = "thanks.dataset.glady",
                                },
                                ["text"] = {
                                    ["EN"] = {
                                        "Glad I could help.",
                                    },
                                    ["TL"] = {
                                        "Glad I could help.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "THANKS",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "thanks",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "No problem at all.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.thanks.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/thanks.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "No problem at all.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.thanks.say.1.thanks.dataset.no_problem",
                ["translations"] = {
                    ["EN"] = {
                        "No problem at all.",
                    },
                    ["TL"] = {
                        "No problem at all.",
                    },
                },
                ["variantID"] = "thanks.dataset.no_problem",
            },
            {
                ["fallback"] = "Anytime.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.thanks.say.1.thanks.dataset.anytime",
                ["translations"] = {
                    ["EN"] = {
                        "Anytime.",
                    },
                    ["TL"] = {
                        "Anytime.",
                    },
                },
                ["variantID"] = "thanks.dataset.anytime",
            },
            {
                ["fallback"] = "Glad I could help.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.thanks.say.1.thanks.dataset.glady",
                ["translations"] = {
                    ["EN"] = {
                        "Glad I could help.",
                    },
                    ["TL"] = {
                        "Glad I could help.",
                    },
                },
                ["variantID"] = "thanks.dataset.glady",
            },
        },
        ["when"] = nil,
    },
}
