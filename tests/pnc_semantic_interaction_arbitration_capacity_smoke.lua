local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}

local Providers = require "PNC/Semantics/PNC_SemanticInteractionProviders"
local Catalog = require "PNC/Semantics/PNC_SemanticInteractionCatalog"
local Arbitration = require "PNC/Semantics/PNC_SemanticInteractionArbitration"

Catalog.ResetDraftOverlay()

local function add(id, wanted)
    local ok, reason = Catalog.Behaviors.RegisterDraft({
        id = id,
        owner = "CapacityTest",
        act = "ACKNOWLEDGE",
        mode = "one_shot",
        stimuli = { "TASK_EVENT" },
        requiredCapabilities = {},
        outputs = {},
        when = {
            path = "stimulus.semantic.intent",
            op = "eq",
            value = wanted,
        },
        baseRelevance = 1,
        modifiers = {},
    })
    T.truthy(ok, reason or id)
end

for index = 1, 24 do
    add(
        string.format("behavior.capacity.ineligible_%02d", index),
        "NOT_THE_CURRENT_INTENT_" .. tostring(index)
    )
end
add("behavior.capacity.valid_last", "CAPACITY_MATCH")

local root = {
    stimulus = {
        type = "TASK_EVENT",
        semantic = {
            intent = "CAPACITY_MATCH",
        },
    },
    actor = Providers.NormalizeActor({
        id = "npc-capacity",
        capabilities = {},
        disposition = {},
        condition = {},
        activity = {},
    }, "capacity.test"),
}

local rows = Arbitration.OneShotBehaviorRows(root)
T.truthy(#rows <= Arbitration.MAX_ONE_SHOT_CANDIDATES,
    "one-shot arbitration output remains bounded")

local selected = Arbitration.SelectedBehavior(rows)
T.truthy(selected, "eligible behavior survives catalog growth")
T.equal(selected.id, "behavior.capacity.valid_last",
    "registration order cannot starve later eligible behavior")
T.truthy(selected.eligible,
    "retained late behavior passed its semantic predicate")

Catalog.ResetDraftOverlay()
T.finish("pnc_semantic_interaction_arbitration_capacity_smoke")
