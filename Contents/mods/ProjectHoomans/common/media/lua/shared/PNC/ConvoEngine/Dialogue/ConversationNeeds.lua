-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_needs",
        ["domainPath"] = "conversation_needs",
        ["exchangeFamily"] = {
            ["familyID"] = "flow.needs.exchange",
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
                                ["fallback"] = "Do you need anything?",
                                ["id"] = "default",
                                ["templateID"] = "convo.flow.needs.exchange.say.1.default",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "flow.needs",
            ["replies"] = {
                ["completed"] = {
                    ["outcome"] = "completed",
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
                                        ["fallback"] = "Thanks, that helps.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.flow.needs.exchange.reply.completed.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "Do you need anything?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.needs.exchange.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Thanks, that helps.",
                    ["outcome"] = "completed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.flow.needs.exchange.reply.completed.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "flow.needs.exchange",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "exchange",
            ["sourceId"] = "flow.needs.exchange",
            ["sourcePath"] = "dialogue/conversation_needs/flow_needs_exchange.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationNeeds",
        ["namespace"] = "flow.needs",
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
            ["closure"] = {
                ["closureClass"] = "resolved_episode",
                ["episodeId"] = "needs_exchange",
            },
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["inputPolicy"] = "typed_parity",
            ["metadata"] = {
                ["flow"] = {
                    ["id"] = "needs",
                    ["initial"] = "await_player_quantity",
                    ["nodes"] = {
                        ["await_player_quantity"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "QUESTION",
                                    ["subject"] = "QUANTITY",
                                },
                                {
                                    ["intent"] = "CLARIFY",
                                    ["speechAct"] = "CLARIFY",
                                    ["subject"] = "NEEDS",
                                },
                            },
                            ["onClarify"] = "clarification",
                            ["onMatch"] = "quantity_answer",
                            ["onRefuse"] = "cancel",
                            ["onUnrelated"] = "suspend",
                            ["requiredSlots"] = {
                                "quantity",
                            },
                            ["responsePool"] = "semantic.question.needs.offer",
                            ["sourceFactRefs"] = {
                                "npc.needs",
                            },
                        },
                        ["clarification"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "QUESTION",
                                    ["subject"] = "QUANTITY",
                                },
                                {
                                    ["intent"] = "CLARIFY",
                                    ["speechAct"] = "CLARIFY",
                                    ["subject"] = "NEEDS",
                                },
                            },
                            ["onClarify"] = "clarification",
                            ["onMatch"] = "quantity_answer",
                            ["onRefuse"] = "cancel",
                            ["onUnrelated"] = "suspend",
                            ["requiredSlots"] = {
                                "quantity",
                            },
                            ["responsePool"] = "semantic.question.needs.quantity",
                            ["sourceFactRefs"] = {
                                "npc.needs",
                            },
                        },
                        ["complete"] = {
                            ["responsePool"] = "semantic.question.needs.proposal",
                            ["terminal"] = true,
                        },
                        ["proposal_pending"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "ACCEPT",
                                },
                                {
                                    ["intent"] = "AGREE",
                                },
                            },
                            ["onMatch"] = "complete",
                            ["onRefuse"] = "cancel",
                            ["onUnrelated"] = "suspend",
                            ["pendingKind"] = "PROPOSAL",
                            ["requiredSlots"] = {
                                "confirmation",
                            },
                            ["responsePool"] = "semantic.question.needs.proposal",
                            ["sourceFactRefs"] = {
                                "npc.needs",
                            },
                        },
                        ["quantity_answer"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "PROMISE",
                                    ["speechAct"] = "PROMISE",
                                    ["subject"] = "NEEDS",
                                },
                            },
                            ["onMatch"] = "proposal_pending",
                            ["onRefuse"] = "cancel",
                            ["onUnrelated"] = "suspend",
                            ["pendingKind"] = "PROPOSAL",
                            ["requiredSlots"] = {
                                "offer",
                            },
                            ["responsePool"] = "semantic.question.needs.quantity",
                            ["sourceFactRefs"] = {
                                "npc.needs",
                            },
                        },
                    },
                    ["owner"] = "ProjectHoomans",
                    ["version"] = 1,
                },
                ["triggers"] = {
                    {
                        ["intent"] = "QUESTION",
                        ["subject"] = "NEEDS",
                    },
                },
            },
            ["postconditions"] = {
                "needs.exchange_closed",
            },
            ["repeatPolicy"] = "state_retired",
            ["reply"] = {
                ["completed"] = {
                    ["outcome"] = "completed",
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
                                        ["fallback"] = "Thanks, that helps.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
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
                                ["fallback"] = "Do you need anything?",
                                ["id"] = "default",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["statePolicy"] = {
                {
                    ["admission"] = "dispatch",
                    ["id"] = "needs_proposal_accepted",
                    ["outcome"] = "actionable",
                    ["reason"] = "proposal_complete",
                    ["replyOutcome"] = "completed",
                    ["when"] = {
                        ["op"] = "eq",
                        ["path"] = "flow.nodeId",
                        ["value"] = "proposal_pending",
                    },
                },
                {
                    ["admission"] = "dispatch",
                    ["id"] = "needs_inquiry_ready",
                    ["outcome"] = "actionable",
                    ["reason"] = "ready",
                },
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "flow.needs.exchange",
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
                            ["fallback"] = "Do you need anything?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.flow.needs.exchange.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/conversation_needs/flow_needs_exchange.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Do you need anything?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.needs.exchange.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Thanks, that helps.",
                ["outcome"] = "completed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.flow.needs.exchange.reply.completed.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_needs",
        ["domainPath"] = "conversation_needs",
        ["exchangeFamily"] = {
            ["familyID"] = "question.needs.offer",
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
                                ["fallback"] = "A little rest would help, but this isn't something I can count.",
                                ["id"] = "fatigue",
                                ["templateID"] = "convo.question.needs.offer.say.1.fatigue",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Food would help, but I don't have an exact amount yet.",
                                ["id"] = "hunger",
                                ["templateID"] = "convo.question.needs.offer.say.1.hunger",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I need food. Keep your distance.",
                                ["id"] = "hunger.guarded",
                                ["templateID"] = "convo.question.needs.offer.say.1.hunger.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I need food.",
                                ["id"] = "hunger.terse",
                                ["templateID"] = "convo.question.needs.offer.say.1.hunger.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Food would help, if you can spare it.",
                                ["id"] = "hunger.warm",
                                ["templateID"] = "convo.question.needs.offer.say.1.hunger.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Water would help, but I don't have an exact amount yet.",
                                ["id"] = "thirst",
                                ["templateID"] = "convo.question.needs.offer.say.1.thirst",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I don't know what I need right now.",
                                ["id"] = "unknown",
                                ["templateID"] = "convo.question.needs.offer.say.1.unknown",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.needs",
            ["textRoles"] = {
                {
                    ["fallback"] = "A little rest would help, but this isn't something I can count.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.needs.offer.say.1.fatigue",
                    ["variantID"] = "fatigue",
                },
                {
                    ["fallback"] = "Food would help, but I don't have an exact amount yet.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.needs.offer.say.1.hunger",
                    ["variantID"] = "hunger",
                },
                {
                    ["fallback"] = "I need food. Keep your distance.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.needs.offer.say.1.hunger.guarded",
                    ["variantID"] = "hunger.guarded",
                },
                {
                    ["fallback"] = "I need food.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.needs.offer.say.1.hunger.terse",
                    ["variantID"] = "hunger.terse",
                },
                {
                    ["fallback"] = "Food would help, if you can spare it.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.needs.offer.say.1.hunger.warm",
                    ["variantID"] = "hunger.warm",
                },
                {
                    ["fallback"] = "Water would help, but I don't have an exact amount yet.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.needs.offer.say.1.thirst",
                    ["variantID"] = "thirst",
                },
                {
                    ["fallback"] = "I don't know what I need right now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.needs.offer.say.1.unknown",
                    ["variantID"] = "unknown",
                },
            },
        },
        ["id"] = "question.needs.offer",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "offer",
            ["sourceId"] = "question.needs.offer",
            ["sourcePath"] = "dialogue/conversation_needs/question_needs_offer.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationNeeds",
        ["namespace"] = "question.needs",
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
            ["domains"] = {
                {
                    ["domain"] = "needs",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "REACT",
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
                                ["fallback"] = "A little rest would help, but this isn't something I can count.",
                                ["id"] = "fatigue",
                            },
                            {
                                ["fallback"] = "Food would help, but I don't have an exact amount yet.",
                                ["id"] = "hunger",
                            },
                            {
                                ["fallback"] = "I need food. Keep your distance.",
                                ["id"] = "hunger.guarded",
                            },
                            {
                                ["fallback"] = "I need food.",
                                ["id"] = "hunger.terse",
                            },
                            {
                                ["fallback"] = "Food would help, if you can spare it.",
                                ["id"] = "hunger.warm",
                            },
                            {
                                ["fallback"] = "Water would help, but I don't have an exact amount yet.",
                                ["id"] = "thirst",
                            },
                            {
                                ["fallback"] = "I don't know what I need right now.",
                                ["id"] = "unknown",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "needs",
                    ["id"] = "needs",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.needs.offer",
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
                            ["fallback"] = "A little rest would help, but this isn't something I can count.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.needs.offer.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/conversation_needs/question_needs_offer.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "A little rest would help, but this isn't something I can count.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.needs.offer.say.1.fatigue",
                ["variantID"] = "fatigue",
            },
            {
                ["fallback"] = "Food would help, but I don't have an exact amount yet.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.needs.offer.say.1.hunger",
                ["variantID"] = "hunger",
            },
            {
                ["fallback"] = "I need food. Keep your distance.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.needs.offer.say.1.hunger.guarded",
                ["variantID"] = "hunger.guarded",
            },
            {
                ["fallback"] = "I need food.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.needs.offer.say.1.hunger.terse",
                ["variantID"] = "hunger.terse",
            },
            {
                ["fallback"] = "Food would help, if you can spare it.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.needs.offer.say.1.hunger.warm",
                ["variantID"] = "hunger.warm",
            },
            {
                ["fallback"] = "Water would help, but I don't have an exact amount yet.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.needs.offer.say.1.thirst",
                ["variantID"] = "thirst",
            },
            {
                ["fallback"] = "I don't know what I need right now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.needs.offer.say.1.unknown",
                ["variantID"] = "unknown",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_needs",
        ["domainPath"] = "conversation_needs",
        ["exchangeFamily"] = {
            ["familyID"] = "question.needs.proposal",
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
                                ["fallback"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                                ["id"] = "hunger",
                                ["templateID"] = "convo.question.needs.proposal.say.1.hunger",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                                ["id"] = "thirst",
                                ["templateID"] = "convo.question.needs.proposal.say.1.thirst",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I can keep that as a proposal, but I need to confirm the item and amount before I record a commitment.",
                                ["id"] = "unknown",
                                ["templateID"] = "convo.question.needs.proposal.say.1.unknown",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                                ["id"] = "default",
                                ["templateID"] = "convo.question.needs.proposal.say.1.default",
                                ["textRole"] = "spoken_action",
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
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.needs",
            ["textRoles"] = {
                {
                    ["fallback"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.needs.proposal.say.1.hunger",
                    ["variantID"] = "hunger",
                },
                {
                    ["fallback"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.needs.proposal.say.1.thirst",
                    ["variantID"] = "thirst",
                },
                {
                    ["fallback"] = "I can keep that as a proposal, but I need to confirm the item and amount before I record a commitment.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.needs.proposal.say.1.unknown",
                    ["variantID"] = "unknown",
                },
                {
                    ["fallback"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.needs.proposal.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "question.needs.proposal",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "proposal",
            ["sourceId"] = "question.needs.proposal",
            ["sourcePath"] = "dialogue/conversation_needs/question_needs_proposal.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationNeeds",
        ["namespace"] = "question.needs",
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
            ["domains"] = {
                {
                    ["domain"] = "needs",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "REACT",
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
                                ["fallback"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                                ["id"] = "hunger",
                            },
                            {
                                ["fallback"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                                ["id"] = "thirst",
                            },
                            {
                                ["fallback"] = "I can keep that as a proposal, but I need to confirm the item and amount before I record a commitment.",
                                ["id"] = "unknown",
                            },
                            {
                                ["fallback"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                                ["id"] = "default",
                                ["metadata"] = {
                                    ["fallback"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                                    ["plan"] = {
                                        ["dialogueAct"] = "PROMISE_ACKNOWLEDGEMENT",
                                        ["groundedFactRefs"] = {
                                            "npc.needs.thirst",
                                        },
                                        ["sourcePoolID"] = "semantic.question.needs.proposal",
                                        ["tone"] = "direct",
                                        ["topic"] = "NEEDS",
                                        ["turns"] = {
                                            {
                                                ["continuation"] = "continue",
                                                ["id"] = "dataset_proposal_acknowledged",
                                                ["segments"] = {
                                                    {
                                                        ["fallback"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                                                        ["kind"] = "translation",
                                                        ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetNeedsPromiseThirst",
                                                    },
                                                },
                                            },
                                        },
                                        ["uncertainty"] = "pending",
                                    },
                                    ["priority"] = 4,
                                    ["reviewed"] = true,
                                    ["sourceRefs"] = {
                                        "MASSIVE",
                                        "SGD",
                                    },
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetNeedsPromiseThirst",
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
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "needs",
                    ["id"] = "needs",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.needs.proposal",
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
                            ["fallback"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.needs.proposal.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/conversation_needs/question_needs_proposal.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.needs.proposal.say.1.hunger",
                ["variantID"] = "hunger",
            },
            {
                ["fallback"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.needs.proposal.say.1.thirst",
                ["variantID"] = "thirst",
            },
            {
                ["fallback"] = "I can keep that as a proposal, but I need to confirm the item and amount before I record a commitment.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.needs.proposal.say.1.unknown",
                ["variantID"] = "unknown",
            },
            {
                ["fallback"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.needs.proposal.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_needs",
        ["domainPath"] = "conversation_needs",
        ["exchangeFamily"] = {
            ["familyID"] = "question.needs.quantity",
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
                                ["fallback"] = "I know food is what I need, but I can't give you an exact amount yet.",
                                ["id"] = "hunger",
                                ["templateID"] = "convo.question.needs.quantity.say.1.hunger",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I know water is what I need, but I can't give you an exact amount yet.",
                                ["id"] = "thirst",
                                ["templateID"] = "convo.question.needs.quantity.say.1.thirst",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I can't confirm an exact amount yet. Which item do you mean?",
                                ["id"] = "unknown",
                                ["templateID"] = "convo.question.needs.quantity.say.1.unknown",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I can confirm water is a need, but which item do you mean?",
                                ["id"] = "default",
                                ["templateID"] = "convo.question.needs.quantity.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.lastIntent",
                                            ["value"] = "CLARIFY",
                                        },
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.needType",
                                            ["value"] = "thirst",
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.needs",
            ["textRoles"] = {
                {
                    ["fallback"] = "I know food is what I need, but I can't give you an exact amount yet.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.needs.quantity.say.1.hunger",
                    ["variantID"] = "hunger",
                },
                {
                    ["fallback"] = "I know water is what I need, but I can't give you an exact amount yet.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.needs.quantity.say.1.thirst",
                    ["variantID"] = "thirst",
                },
                {
                    ["fallback"] = "I can't confirm an exact amount yet. Which item do you mean?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.needs.quantity.say.1.unknown",
                    ["variantID"] = "unknown",
                },
                {
                    ["fallback"] = "I can confirm water is a need, but which item do you mean?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.needs.quantity.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "question.needs.quantity",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "quantity",
            ["sourceId"] = "question.needs.quantity",
            ["sourcePath"] = "dialogue/conversation_needs/question_needs_quantity.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationNeeds",
        ["namespace"] = "question.needs",
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
            ["domains"] = {
                {
                    ["domain"] = "needs",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "REACT",
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
                                ["fallback"] = "I know food is what I need, but I can't give you an exact amount yet.",
                                ["id"] = "hunger",
                            },
                            {
                                ["fallback"] = "I know water is what I need, but I can't give you an exact amount yet.",
                                ["id"] = "thirst",
                            },
                            {
                                ["fallback"] = "I can't confirm an exact amount yet. Which item do you mean?",
                                ["id"] = "unknown",
                            },
                            {
                                ["fallback"] = "I can confirm water is a need, but which item do you mean?",
                                ["id"] = "default",
                                ["metadata"] = {
                                    ["fallback"] = "I can confirm water is a need, but which item do you mean?",
                                    ["plan"] = {
                                        ["dialogueAct"] = "ASK_CLARIFICATION",
                                        ["groundedFactRefs"] = {
                                            "npc.needs.thirst",
                                        },
                                        ["sourcePoolID"] = "semantic.question.needs.quantity",
                                        ["tone"] = "clarifying",
                                        ["topic"] = "NEEDS",
                                        ["turns"] = {
                                            {
                                                ["continuation"] = "continue",
                                                ["id"] = "dataset_needs_clarification",
                                                ["segments"] = {
                                                    {
                                                        ["fallback"] = "I can confirm water is a need, but which item do you mean?",
                                                        ["kind"] = "translation",
                                                        ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetNeedsClarifyThirst",
                                                    },
                                                },
                                            },
                                        },
                                        ["uncertainty"] = "ambiguous",
                                    },
                                    ["priority"] = 4,
                                    ["reviewed"] = true,
                                    ["sourceRefs"] = {
                                        "MASSIVE",
                                        "SGD",
                                    },
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetNeedsClarifyThirst",
                                },
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.lastIntent",
                                            ["value"] = "CLARIFY",
                                        },
                                        {
                                            ["op"] = "eq",
                                            ["path"] = "conversation.needType",
                                            ["value"] = "thirst",
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "needs",
                    ["id"] = "needs",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.needs.quantity",
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
                            ["fallback"] = "I know food is what I need, but I can't give you an exact amount yet.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.needs.quantity.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/conversation_needs/question_needs_quantity.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I know food is what I need, but I can't give you an exact amount yet.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.needs.quantity.say.1.hunger",
                ["variantID"] = "hunger",
            },
            {
                ["fallback"] = "I know water is what I need, but I can't give you an exact amount yet.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.needs.quantity.say.1.thirst",
                ["variantID"] = "thirst",
            },
            {
                ["fallback"] = "I can't confirm an exact amount yet. Which item do you mean?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.needs.quantity.say.1.unknown",
                ["variantID"] = "unknown",
            },
            {
                ["fallback"] = "I can confirm water is a need, but which item do you mean?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.needs.quantity.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
}
