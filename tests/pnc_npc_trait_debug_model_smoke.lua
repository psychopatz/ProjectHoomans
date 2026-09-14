local T = require "tests/support/test"

local Registry = T.load(
    "ProjectHoomans", "shared", "PNC/Core/Traits/PNC_NPCTraitRegistry.lua")
T.load(
    "ProjectHoomans", "shared", "PNC/Core/Traits/PNC_NPCTraitDefinitions.lua")
local Model = T.load(
    "ProjectHoomans", "client", "PNC/UI/PNC_NPCTraitDebugModel.lua")

local items = Model.BuildItems()
T.truthy(#items >= 14, "debug model lists all built-in NPC traits")
local friendly
for _, item in ipairs(items) do
    if item.id == "pnc_friendly" then friendly = item end
end
T.truthy(friendly, "debug model includes friendly trait")
T.contains(friendly.detail, "Behavior", "list shows effect channels")

local rows = Model.BuildRows(friendly.definition)
local rendered = {}
for _, row in ipairs(rows) do
    rendered[#rendered + 1] = row.label .. "=" .. row.value
end
local detail = table.concat(rendered, "\n")
T.contains(detail, "ID=pnc_friendly", "detail view shows canonical ID")
T.contains(detail, "Personality / Forgiveness=+0.10",
    "detail view shows readable personality contribution")
T.contains(detail, "Behavior / Social Interaction=+0.20",
    "detail view shows readable behavior contribution")

local triggerHappy
for _, item in ipairs(items) do
    if item.id == "pnc_trigger_happy" then triggerHappy = item end
end
T.truthy(triggerHappy, "debug model includes trigger happy trait")
local firearmRows = {}
for _, row in ipairs(Model.BuildRows(triggerHappy.definition)) do
    firearmRows[#firearmRows + 1] = row.label .. "=" .. row.value
end
T.contains(table.concat(firearmRows, "\n"),
    "Combat / Firearm / Fire rate=x1.25 (+25%)",
    "detail view explains firearm cadence")
T.contains(table.concat(firearmRows, "\n"),
    "Combat / Firearm / Hit chance=-8.00 percentage points",
    "detail view explains firearm accuracy")

local lightSleeper
for _, item in ipairs(items) do
    if item.id == "pnc_light_sleeper" then lightSleeper = item end
end
local sleepRows = {}
for _, row in ipairs(Model.BuildRows(lightSleeper.definition)) do
    sleepRows[#sleepRows + 1] = row.label .. "=" .. row.value
end
T.contains(table.concat(sleepRows, "\n"),
    "Sleep policy / Action threshold=x1.10 (+10%)",
    "detail view explains sleep threshold multipliers")

local ok = Registry.Register({
    id = "debugmod:registered",
    labelKey = "UI_DebugMod_Trait_Registered",
    source = "debugmod",
    effects = { needs = { fatigue = { awakeMultiplier = 0.5 } } },
})
T.truthy(ok, "debug trait registration succeeds")
local found
for _, item in ipairs(Model.BuildItems()) do
    if item.id == "debugmod:registered" then found = item end
end
T.truthy(found, "debug model updates for third-party registration")
T.contains(Model.BuildRows(found.definition)[1].value,
    "debugmod:registered", "registered trait detail uses canonical ID")

T.finish("pnc_npc_trait_debug_model_smoke")
