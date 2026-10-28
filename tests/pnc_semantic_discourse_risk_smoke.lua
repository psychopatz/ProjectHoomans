local T = require "tests/support/test"
T.addPackagePaths()

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Risk = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueRiskPolicy.lua"
)

local conversation = {
    intent = "DISAGREE",
    speechAct = "DISAGREE",
    confidence = 0.72,
    extensions = {
        discourseFrame = {
            contextualConfidence = 0.82,
        },
    },
}
local result = Risk.Assess(conversation, {}, {})
T.equal(result.accepted, true, "medium-confidence conversation is admitted")
T.equal(
    result.riskClass,
    "conversation",
    "conversation risk class"
)
T.equal(
    result.reason,
    "context_reinforced_conversation",
    "context can reinforce safe conversation"
)

local lowConversation = {
    intent = "DISAGREE",
    speechAct = "DISAGREE",
    confidence = 0.55,
    extensions = {
        discourseFrame = {
            contextualConfidence = 0.67,
        },
    },
}
result = Risk.Assess(lowConversation, {}, {})
T.equal(
    result.accepted,
    true,
    "context may lift safe conversation over medium threshold"
)
T.equal(
    result.reason,
    "context_supported_conversation",
    "context-supported conversation reason"
)

local mutation = {
    intent = "REQUEST",
    speechAct = "REQUEST",
    action = "FOLLOW",
    confidence = 0.82,
    diagnostics = {},
    extensions = {
        discourseFrame = {
            contextualConfidence = 1.0,
        },
    },
}
result = Risk.Assess(mutation, {}, {})
T.equal(result.accepted, false, "context cannot lift mutation")
T.equal(
    result.reason,
    "action_confidence_below_high_threshold",
    "mutation keeps high-confidence requirement"
)

local deferred = {
    intent = "REQUEST",
    speechAct = "REQUEST",
    action = "GIVE",
    confidence = 0.97,
    object = {
        unresolved = true,
        text = "apple",
    },
    provenance = {
        candidatePass = "exact",
    },
    diagnostics = {
        unresolvedEntity = true,
        candidateSelection = {
            rejections = {},
        },
    },
}
result = Risk.Assess(deferred, {}, {})
T.equal(
    result.accepted,
    true,
    "exact open-text item binding may defer to authoritative selectors"
)
T.equal(
    result.reason,
    "strict_mutation_deferred_resolution",
    "deferred exact binding is explicit"
)

local suspicious = {
    intent = "REQUEST",
    speechAct = "REQUEST",
    action = "GIVE",
    confidence = 0.89,
    object = {
        unresolved = true,
        text = "waterr",
    },
    provenance = {
        candidatePass = "exact",
    },
    diagnostics = {
        unresolvedEntity = true,
        candidateSelection = {
            rejections = {
                {
                    reason = "fuzzy_mutating_action",
                    patternID = "pnc.request.give",
                },
            },
        },
    },
}
result = Risk.Assess(suspicious, {}, {})
T.equal(result.accepted, false, "typo-like unresolved mutation is rejected")
T.equal(
    result.reason,
    "unresolved_action_reference",
    "typo-like unresolved mutation reason"
)

local recovered = {
    intent = "REQUEST",
    speechAct = "REQUEST",
    action = "GO",
    confidence = 0.99,
    provenance = {
        surfaceRecovery = {
            kind = "segmentation",
        },
    },
    diagnostics = {
        recoveredMatch = true,
    },
}
result = Risk.Assess(recovered, {}, {})
T.equal(result.accepted, false, "recovered mutation is rejected")
T.equal(
    result.reason,
    "recovered_action_requires_confirmation",
    "recovered mutation reason"
)

local identity = {
    intent = "INFORM",
    speechAct = "INFORM",
    confidence = 0.81,
    socialContext = {
        identityClaim = true,
    },
}
result = Risk.Assess(identity, {}, {})
T.equal(result.accepted, false, "identity mutation stays strict")
T.equal(result.riskClass, "identity_mutation", "identity risk class")
T.equal(
    result.reason,
    "action_confidence_below_high_threshold",
    "identity mutation keeps high-confidence requirement"
)

T.finish("pnc_semantic_discourse_risk_smoke")
