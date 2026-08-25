local T = require "tests/support/test"

T.addPackagePaths()

local function item(fullType)
    return { getFullName = function() return fullType end }
end

local function resource(fullType, amount, consumed)
    return {
        getPossibleInputItems = function() return { item(fullType) } end,
        getPossibleResultItems = function() return { item(fullType) } end,
        getIntAmount = function() return amount or 1 end,
        isKeep = function() return consumed == false end,
        isTool = function() return false end,
        isAutomationOnly = function() return false end,
    }
end

local weldingPerk = { getId = function() return "MetalWelding" end }
local recipe = {
    getScriptObjectFullType = function() return "Base.TestForgeRecipe" end,
    getName = function() return "Test Forge Recipe" end,
    getTranslationName = function() return "Test Forge Recipe" end,
    getModuleName = function() return "Base" end,
    getCategory = function() return "Metalwork" end,
    getInputs = function() return { resource("Base.Iron", 1, true) } end,
    getOutputs = function() return { resource("Base.Knife", 1, true) } end,
    getRequiredSkillCount = function() return 0 end,
    getTags = function() return { "forge" } end,
    getXPAwardCount = function() return 1 end,
    getXPAward = function() return {
        getPerk = function() return weldingPerk end,
        getAmount = function() return 5 end,
    } end,
    getTime = function() return 100 end,
    needToBeLearn = function() return true end,
}

PNC = { Core = { DeepCopy = function(value) return value end } }
local Catalog = require "PNC/Core/Production/PNC_RecipeCatalog"
local ok, diagnostics = Catalog.Commands.Rebuild({ recipe })
T.truthy(ok, "recipe catalog rebuild")
T.equal(diagnostics.normalized, 1, "recipe catalog count")
local descriptor = Catalog.Queries.Get("Base.TestForgeRecipe")
T.truthy(descriptor, "recipe descriptor")
T.equal(descriptor.productionSkillId, "Welding",
    "vanilla XP skill is normalized to the crafting skill catalog")
T.equal(descriptor.xpAwards[1].skillId, "Welding", "XP award skill")

local Definitions = require "PNC/Core/Production/PNC_WorkDefinitions"
local station = Definitions.GetStationForRecipe(descriptor, "CRAFT")
T.equal(station.id, "forge", "forge tag routes to direct workstation")
local profile = Definitions.GetStationSkillProfile("forge")
T.equal(profile[1], "Welding", "station profile follows recipe XP")

PNC.Skills = { GetLevel = function(record, skillId)
    return tonumber(record.skills and record.skills[skillId]) or 0
end }
PNC.Registry = { Data = {} }
function PNC.Registry.ForEach(callback)
    for _, record in pairs(PNC.Registry.Data) do callback(record) end
end
PNC.WorkService = { ClaimsByWorker = {}, Internal = {} }
require "PNC/Production/WorkService/PNC_WorkService_Core"
PNC.Registry.Data.low = { id = "low", alive = true, factionId = "f1",
    communityId = "c1", skills = { Welding = 1 }, runtime = {} }
PNC.Registry.Data.high = { id = "high", alive = true, factionId = "f1",
    communityId = "c1", skills = { Welding = 6 }, runtime = {} }
local worker = PNC.WorkService.Internal.findWorker({
    operation = "CRAFT", factionId = "f1", colonyId = "c1", baseId = "b1",
    requiredSkills = {}, productionSkillId = "Welding",
})
T.equal(worker.id, "high", "worker selection prefers the XP specialization")

return T.finish("pnc_production_skill_specialization_smoke")
