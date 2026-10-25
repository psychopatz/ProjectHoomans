-- Needs response pools and proposal acknowledgements.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.ResponseCatalog
Catalog.Register("semantic.question.needs.offer", {
    variants = {
        {
            id = "semantic.question.needs.offer.hunger",
            templateID = "semantic.question.needs.offer.hunger",
            fallback = "Food would help, but I don't have an exact amount yet.",
            when = {
                needType = "hunger",
                needUrgency = { "moderate", "severe", "emergency", "critical" },
            },
            priority = 3,
            plan = {
                dialogueAct = "NEEDS_REPORT",
                sourcePoolID = "semantic.question.needs.offer",
                topic = "NEEDS",
                groundedFactRefs = { "npc.needs.hunger" },
                uncertainty = "known",
                tone = "direct",
                turns = {
                    {
                        id = "needs_report",
                        continuation = "continue",
                        segments = {
                            {
                                kind = "translation",
                                templateID = "semantic.question.needs.offer.hunger",
                                fallback = "Food would help, but I don't have an exact amount yet.",
                            },
                        },
                    },
                },
            },
        },
        {
            id = "semantic.question.needs.offer.thirst",
            templateID = "semantic.question.needs.offer.thirst",
            fallback = "Water would help, but I don't have an exact amount yet.",
            when = {
                needType = "thirst",
                needUrgency = { "moderate", "severe", "emergency", "critical" },
            },
            priority = 3,
            plan = {
                dialogueAct = "NEEDS_REPORT",
                sourcePoolID = "semantic.question.needs.offer",
                topic = "NEEDS",
                groundedFactRefs = { "npc.needs.thirst" },
                uncertainty = "known",
                tone = "direct",
                turns = {
                    {
                        id = "needs_report",
                        continuation = "continue",
                        segments = {
                            {
                                kind = "translation",
                                templateID = "semantic.question.needs.offer.thirst",
                                fallback = "Water would help, but I don't have an exact amount yet.",
                            },
                        },
                    },
                },
            },
        },
        {
            id = "semantic.question.needs.offer.fatigue",
            templateID = "semantic.question.needs.offer.fatigue",
            fallback = "A little rest would help, but this isn't something I can count.",
            when = {
                needType = "fatigue",
                needUrgency = { "moderate", "severe", "emergency", "critical" },
            },
            priority = 2,
            plan = {
                dialogueAct = "NEEDS_REPORT",
                sourcePoolID = "semantic.question.needs.offer",
                topic = "NEEDS",
                groundedFactRefs = { "npc.needs.fatigue" },
                uncertainty = "known",
                tone = "direct",
                turns = {
                    {
                        id = "needs_report",
                        continuation = "continue",
                        segments = {
                            {
                                kind = "translation",
                                templateID = "semantic.question.needs.offer.fatigue",
                                fallback = "A little rest would help, but this isn't something I can count.",
                            },
                        },
                    },
                },
            },
        },
        {
            id = "semantic.question.needs.offer.unknown",
            templateID = "semantic.question.needs.offer.unknown",
            fallback = "I don't know what I need right now.",
            priority = 0,
            plan = {
                dialogueAct = "NEEDS_REPORT",
                sourcePoolID = "semantic.question.needs.offer",
                topic = "NEEDS",
                uncertainty = "unknown",
                tone = "uncertain",
                turns = {
                    {
                        id = "needs_report",
                        continuation = "continue",
                        segments = {
                            {
                                kind = "translation",
                                templateID = "semantic.question.needs.offer.unknown",
                                fallback = "I don't know what I need right now.",
                            },
                        },
                    },
                },
            },
        },
    },
})

Catalog.Register("semantic.question.needs.quantity", {
    variants = {
        {
            id = "semantic.question.needs.quantity.hunger",
            templateID = "semantic.question.needs.quantity.hunger",
            fallback = "I know food is what I need, but I can't give you an exact amount yet.",
            when = {
                needType = "hunger",
                needUrgency = { "moderate", "severe", "emergency", "critical" },
            },
            priority = 3,
            plan = {
                dialogueAct = "NEEDS_QUANTITY",
                sourcePoolID = "semantic.question.needs.quantity",
                topic = "NEEDS",
                groundedFactRefs = { "npc.needs.hunger" },
                uncertainty = "pending",
                tone = "direct",
                turns = {
                    {
                        id = "needs_quantity",
                        continuation = "end",
                        segments = {
                            {
                                kind = "translation",
                                templateID = "semantic.question.needs.quantity.hunger",
                                fallback = "I know food is what I need, but I can't give you an exact amount yet.",
                            },
                        },
                    },
                },
            },
        },
        {
            id = "semantic.question.needs.quantity.thirst",
            templateID = "semantic.question.needs.quantity.thirst",
            fallback = "I know water is what I need, but I can't give you an exact amount yet.",
            when = {
                needType = "thirst",
                needUrgency = { "moderate", "severe", "emergency", "critical" },
            },
            priority = 3,
            plan = {
                dialogueAct = "NEEDS_QUANTITY",
                sourcePoolID = "semantic.question.needs.quantity",
                topic = "NEEDS",
                groundedFactRefs = { "npc.needs.thirst" },
                uncertainty = "pending",
                tone = "direct",
                turns = {
                    {
                        id = "needs_quantity",
                        continuation = "end",
                        segments = {
                            {
                                kind = "translation",
                                templateID = "semantic.question.needs.quantity.thirst",
                                fallback = "I know water is what I need, but I can't give you an exact amount yet.",
                            },
                        },
                    },
                },
            },
        },
        {
            id = "semantic.question.needs.quantity.unknown",
            templateID = "semantic.question.needs.quantity.unknown",
            fallback = "I can't confirm an exact amount yet. Which item do you mean?",
            priority = 0,
            plan = {
                dialogueAct = "ASK_CLARIFICATION",
                sourcePoolID = "semantic.question.needs.quantity",
                topic = "NEEDS",
                groundedFactRefs = {},
                uncertainty = "ambiguous",
                tone = "clarifying",
                turns = {
                    {
                        id = "needs_quantity_clarification",
                        continuation = "end",
                        segments = {
                            {
                                kind = "translation",
                                templateID = "semantic.question.needs.quantity.unknown",
                                fallback = "I can't confirm an exact amount yet. Which item do you mean?",
                            },
                        },
                    },
                },
            },
        },
    },
})

Catalog.Register("semantic.question.needs.proposal", {
    variants = {
        {
            id = "semantic.question.needs.proposal.hunger",
            templateID = "semantic.question.needs.proposal.hunger",
            fallback = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
            when = {
                needType = "hunger",
                needUrgency = { "moderate", "severe", "emergency", "critical" },
            },
            priority = 3,
            plan = {
                dialogueAct = "PROMISE_ACKNOWLEDGEMENT",
                sourcePoolID = "semantic.question.needs.proposal",
                topic = "NEEDS",
                groundedFactRefs = { "npc.needs.hunger" },
                uncertainty = "pending",
                tone = "direct",
                turns = {
                    {
                        id = "proposal_acknowledged",
                        continuation = "continue",
                        segments = {
                            {
                                kind = "translation",
                                templateID = "semantic.question.needs.proposal.hunger",
                                fallback = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                            },
                        },
                    },
                },
            },
        },
        {
            id = "semantic.question.needs.proposal.thirst",
            templateID = "semantic.question.needs.proposal.thirst",
            fallback = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
            when = {
                needType = "thirst",
                needUrgency = { "moderate", "severe", "emergency", "critical" },
            },
            priority = 3,
            plan = {
                dialogueAct = "PROMISE_ACKNOWLEDGEMENT",
                sourcePoolID = "semantic.question.needs.proposal",
                topic = "NEEDS",
                groundedFactRefs = { "npc.needs.thirst" },
                uncertainty = "pending",
                tone = "direct",
                turns = {
                    {
                        id = "proposal_acknowledged",
                        continuation = "continue",
                        segments = {
                            {
                                kind = "translation",
                                templateID = "semantic.question.needs.proposal.thirst",
                                fallback = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                            },
                        },
                    },
                },
            },
        },
        {
            id = "semantic.question.needs.proposal.unknown",
            templateID = "semantic.question.needs.proposal.unknown",
            fallback = "I can keep that as a proposal, but I need to confirm the item and amount before I record a commitment.",
            priority = 0,
            plan = {
                dialogueAct = "PROMISE_ACKNOWLEDGEMENT",
                sourcePoolID = "semantic.question.needs.proposal",
                topic = "NEEDS",
                groundedFactRefs = {},
                uncertainty = "pending",
                tone = "clarifying",
                turns = {
                    {
                        id = "proposal_acknowledged",
                        continuation = "continue",
                        segments = {
                            {
                                kind = "translation",
                                templateID = "semantic.question.needs.proposal.unknown",
                                fallback = "I can keep that as a proposal, but I need to confirm the item and amount before I record a commitment.",
                            },
                        },
                    },
                },
            },
        },
    },
})

-- Keep an unsupported wellbeing snapshot out of the normal response pool.
-- That pool already includes the bounded generated response variants; this
-- separate pool makes uncertainty explicit without expanding its limit.

return true
