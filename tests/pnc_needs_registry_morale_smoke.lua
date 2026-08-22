local T = require "tests/support/test"

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, entry in pairs(value) do output[key] = copy(entry) end
    return output
end

PsychopatzCore = { RuntimeRole = { AllowsServerCode = function() return true end } }
PNC = { Core = { DeepCopy = copy }, NeedsUtils = {
    WorldAgeHours = function() return 240 end,
} }
local Definitions = T.load("ProjectHoomans", "shared",
    "PNC/Core/Needs/PNC_NeedsDefinitions.lua")
local Modifiers = T.load("ProjectHoomans", "shared",
    "PNC/Core/Needs/PNC_MoraleModifierDefinitions.lua")
local Codec = T.load("ProjectHoomans", "shared",
    "PNC/Core/Needs/PNC_NeedsStateCodec.lua")

T.equal(#Definitions.List(), 3, "physiological needs are registry-driven")
T.equal(Definitions.Get("thirst").task.kind, "DRINK",
    "need definition exposes self-care metadata")
T.truthy(Modifiers.Get("housing"), "quality-of-life modifier is registered")

local records = {}
PNC.NeedsRepository = {
    Get = function(record)
        records[record.id] = records[record.id] or {
            needs = { hunger = 0, thirst = 0, fatigue = 0 },
            nutrition = { calories = 0, weight = 80 },
            morale = { conditions = {}, lastDay = 9 },
        }
        return records[record.id]
    end,
    MarkDirty = function() end,
}
PNC.IndividualNeeds = { Get = function(_, id)
    return id == "thirst" and 0.8 or 0.1
end }
local Evaluator = T.load("ProjectHoomans", "server",
    "PNC/Needs/PNC_NeedsEvaluator.lua")
local record = { id = "npc", runtime = { homeBaseId = "base" },
    allowedJobs = { Farmer = true }, health = { state = "healthy" } }
T.truthy(Evaluator.Commands.SetCondition(record, "recreation", -0.2,
    "NO_RECREATION"), "domain condition command mutates compact state")
T.truthy(Evaluator.Commands.Reconcile(record, 240),
    "command refreshes known conditions and daily progression")
local view = Evaluator.Queries.BuildView(record)
T.truthy(view.score >= 0 and view.score <= 100, "morale aggregate is derived")
T.truthy(#view.modifiers >= 3, "view model derives registered modifier rows")
local needsView = Evaluator.Queries.BuildNeedsView(record)
T.equal(needsView[2].severity, "SEVERE",
    "generic needs view derives severity from the registry")

local packed = Codec.Encode(records, 240)
local decoded = Codec.Decode(packed)
T.near(decoded.npc.morale.conditions.recreation.value, -0.2, 0.001,
    "compact codec persists modifier value")
T.equal(decoded.npc.morale.conditions.recreation.days, 1,
    "unresolved time-based modifier advances by day")

T.finish("pnc_needs_registry_morale_smoke")
