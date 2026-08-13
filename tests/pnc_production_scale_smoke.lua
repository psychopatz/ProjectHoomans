local Paths = dofile("tests/pnc_test_paths.lua")
local ROOT = Paths.modRoot("ProjectHoomans") .. "media/lua/"
package.path = ROOT .. "shared/?.lua;" .. ROOT .. "server/?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then error((label or "value") .. " expected="
        .. tostring(expected) .. " actual=" .. tostring(actual), 2) end
end

local function deepCopy(value)
    if type(value) ~= "table" then return value end
    local output = {}; for key, entry in pairs(value) do output[key] = deepCopy(entry) end
    return output
end

PNC = { Core = { DeepCopy = deepCopy }, RecipeCatalog = {
    Queries = { Get = function() return nil end },
} }
ModData = nil

local Registry = require "PNC/Core/Production/PNC_RecipeKnowledgeRegistry"
Registry.Commands.Import(nil)
for id = 1, 5000 do
    equal(Registry.Commands.GetOrCreateId("ScaleMod.Recipe" .. tostring(id)),
        id, "monotonic id")
end
equal(Registry.Queries.Diagnostics().persistentRecipeIdCount, 5000,
    "registry unique references")

local Repository = require "PNC/Production/PNC_ResearchRepository"
Repository.Loaded = true
Repository.ByColony, Repository.Runtime = {}, {}
for colony = 1, 50 do
    local state = Repository.Get("colony:" .. tostring(colony))
    for recipeId = 1, 2000 do state.learnedRecipeIds[recipeId] = recipeId end
    state.knowledgeRevision = 2000
end
Repository.RebuildRuntime()

local learnedCount = 0
for _, state in pairs(Repository.ByColony) do
    learnedCount = learnedCount + #state.learnedRecipeIds
    equal(state.learnedRecipeSet, nil, "runtime set not persisted on state")
    assert(Repository.Runtime[state.colonyId].learnedRecipeSet[2000] == true,
        "runtime O(1) membership missing")
end
equal(learnedCount, 100000, "compact learned ids")
equal(Registry.Queries.Diagnostics().persistentRecipeIdCount, 5000,
    "registry not multiplied by colony count")

local approximateBytes = 0
for _, state in pairs(Repository.ByColony) do
    approximateBytes = approximateBytes + #state.learnedRecipeIds * 8
end
assert(approximateBytes < 1000000,
    "dense numeric knowledge proxy unexpectedly large")

print("pnc_production_scale_smoke: OK registry=5000 colonies=50 learned=100000 proxyBytes="
    .. tostring(approximateBytes))
