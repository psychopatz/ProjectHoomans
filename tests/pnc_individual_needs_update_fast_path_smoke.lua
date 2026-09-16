local T = require "tests/support/test"

-- The passive update path should reuse the state acquired by AdvanceTo instead
-- of re-entering the public Ensure/Get/Set stack for every need.

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local eventCount = 0
local ensureTraitsCalls = 0
local repositoryGetCalls = 0
local dirtyCalls = 0
local evaluatedAt = 0
local eventName = "NPC_NEED_SEVERITY_CHANGED"
local entry = {
    needs = { hunger = 0.49, thirst = 0.20, fatigue = 0.20 },
    hungerOverflow = 0.05,
}
local definitions = {
    DEBUG_HISTORY_LIMIT = 20,
    MAX_CATCHUP_HOURS = 168,
    INDIVIDUAL_ACTIVITY = { idle = true },
    TYPES = { "hunger", "thirst", "fatigue" },
}
local needDefinitions = {
    hunger = { minimum = 0, maximum = 1, default = 0,
        thresholds = { 0.5 } },
    thirst = { minimum = 0, maximum = 1, default = 0,
        thresholds = { 0.5 } },
    fatigue = { minimum = 0, maximum = 1, default = 0,
        thresholds = { 0.5 } },
}

function definitions.Get(needType)
    return needDefinitions[needType]
end

function definitions.Clamp(needType, value)
    local definition = needDefinitions[needType]
    value = tonumber(value) or definition.default
    return math.max(definition.minimum,
        math.min(definition.maximum, value))
end

function definitions.GetLevel(needType, value)
    local definition = needDefinitions[needType]
    return value < definition.thresholds[1] and "GOOD" or "CRITICAL"
end

package.preload["PsychopatzCore/Events/PC_EventBus"] = function()
    return {
        emit = function(name)
            if name == eventName then eventCount = eventCount + 1 end
        end,
    }
end

PNC = {
    EventTypes = { NPC_NEED_SEVERITY_CHANGED = eventName },
    NeedsDefinitions = definitions,
    NeedsUtils = {
        WorldAgeHours = function() return 12 end,
        CopyState = function(value)
            local copy = {}
            for key, item in pairs(value or {}) do copy[key] = item end
            return copy
        end,
    },
    PlayerNeedsModel = {
        EnsureTraits = function()
            ensureTraitsCalls = ensureTraitsCalls + 1
        end,
        GetRates = function()
            return { hunger = 0.10, thirst = 0.20, fatigue = 0 }
        end,
    },
    NeedsRepository = {
        Get = function()
            repositoryGetCalls = repositoryGetCalls + 1
            return entry
        end,
        GetEvaluatedAt = function() return evaluatedAt end,
        SetEvaluatedAt = function(_, value) evaluatedAt = value end,
        MarkDirty = function() dirtyCalls = dirtyCalls + 1 end,
    },
    IndividualNeeds = { Internal = {} },
}

local root = T.path("ProjectHoomans", "root", "")
T.load(root .. "server/PNC/Needs/IndividualNeeds/PNC_IndividualNeeds_Core.lua")
T.load(root .. "server/PNC/Needs/IndividualNeeds/PNC_IndividualNeeds_Evolution.lua")

local record = { id = "fast-path", recruited = true, alive = true }
local updated = PNC.IndividualNeeds.AdvanceTo(record, 1, "fast_path")

T.truthy(updated, "AdvanceTo updates the needs state")
T.near(entry.needs.hunger, 0.54, 0.000001,
    "passive hunger consumes overflow before increasing hunger")
T.near(entry.needs.thirst, 0.40, 0.000001,
    "passive thirst updates the acquired state")
T.near(entry.needs.fatigue, 0.20, 0.000001,
    "zero-rate fatigue remains stable")
T.near(entry.hungerOverflow, 0, 0.000001,
    "passive hunger consumes the overflow reserve")
T.equal(ensureTraitsCalls, 1,
    "AdvanceTo initializes traits once for the whole update")
T.equal(repositoryGetCalls, 1,
    "AdvanceTo acquires the repository entry once for the whole update")
T.equal(dirtyCalls, 1,
    "passive update coalesces repository dirty marking")
T.equal(eventCount, 1,
    "severity transition still emits the normal event")
T.equal(evaluatedAt, 1, "AdvanceTo records the requested evaluation time")

T.finish("pnc_individual_needs_update_fast_path_smoke")
