local T = require "tests/support/test"

T.addPackagePaths()

local function list(values)
    return { size = function() return #values end,
        get = function(_, index) return values[index + 1] end }
end

local function item(fullType)
    return { getFullName = function() return fullType end }
end

local function resource(types, amount, options)
    options = options or {}
    local candidates = {}
    for index = 1, #types do candidates[index] = item(types[index]) end
    return {
        isAutomationOnly = function() return false end,
        getPossibleInputItems = function() return list(candidates) end,
        getPossibleResultItems = function() return list(candidates) end,
        getIntAmount = function() return amount end,
        isKeep = function() return options.keep == true end,
        isTool = function() return options.tool == true end,
    }
end

local function recipe(key, outputType, inputType, moduleName)
    return {
        getScriptObjectFullType = function() return key end,
        getName = function() return key end,
        getTranslationName = function() return "Translated " .. key end,
        getModuleName = function() return moduleName or "Base" end,
        getCategory = function() return "Tools" end,
        getInputs = function() return list({
            resource({ inputType }, 2),
            resource({ "Base.Hammer" }, 1, { keep = true, tool = true }),
        }) end,
        getOutputs = function() return list({ resource({ outputType }, 1) }) end,
        getRequiredSkillCount = function() return 1 end,
        getRequiredSkill = function()
            return { getLevel = function() return 2 end,
                getPerk = function() return {
                    getId = function() return "Carpentry" end,
                    getName = function() return "Carpentry" end,
                } end }
        end,
        getTime = function() return 50 end,
    }
end

PNC = { Core = { DeepCopy = function(value)
    if type(value) ~= "table" then return value end
    local output = {}; for key, entry in pairs(value) do
        output[key] = PNC.Core.DeepCopy(entry)
    end
    return output
end } }

local Catalog = require "PNC/Core/Production/PNC_RecipeCatalog"
local base = recipe("Base.MakeWoodenSpear", "Base.SpearCrafted", "Base.Plank", "Base")
local modded = recipe("SomeMod.MakeSuperAxe", "SomeMod.SuperAxe", "Base.Axe", "SomeMod")
-- Mirrors the installed JBLogging normal Build 42 recipe discovered at
-- Workshop item 3381181930; the catalog has no compatibility entry for it.
local installed = recipe("Base.JB_ChopLog", "Base.Firewood", "Base.Log", "Base")
local malformed = { getScriptObjectFullType = function() error("bad addon recipe") end }

local ok, diagnostics = Catalog.Commands.Rebuild(list({ base, malformed, modded,
    installed }))
T.truthy(ok, "catalog rebuild")
T.equal(diagnostics.inspected, 4, "inspected")
T.equal(diagnostics.normalized, 3, "normalized")
T.equal(diagnostics.unsupported, 1, "unsupported")
T.equal(Catalog.Queries.GetProducerKeys("SomeMod.SuperAxe")[1],
    "SomeMod.MakeSuperAxe", "mod producer")
T.equal(Catalog.Queries.GetProducerKeys("Base.Firewood")[1],
    "Base.JB_ChopLog", "installed mod producer")
T.equal(Catalog.Queries.Get("Base.MakeWoodenSpear").inputs[2].consumed,
    false, "kept tool")

local Registry = require "PNC/Core/Production/PNC_RecipeKnowledgeRegistry"
Registry.Commands.Import(nil)
T.equal(Registry.Queries.Diagnostics().persistentRecipeIdCount, 0, "lazy empty")
local spearId = Registry.Commands.GetOrCreateId("Base.MakeWoodenSpear")
local axeId = Registry.Commands.GetOrCreateId("SomeMod.MakeSuperAxe")
T.equal(spearId, 1, "first stable id")
T.equal(axeId, 2, "second stable id")

Catalog.Commands.Rebuild(list({ installed, modded, base }))
T.equal(Registry.Queries.GetId("Base.MakeWoodenSpear"), spearId,
    "enumeration reorder stable")
local saved = Registry.Queries.Export()
Registry.Commands.Import(saved)
T.equal(Registry.Queries.GetId("SomeMod.MakeSuperAxe"), axeId,
    "reverse index rebuilt")

Catalog.Commands.Rebuild(list({ installed, base }))
T.equal(Registry.Queries.Resolve(axeId).status, "KNOWN_BUT_UNAVAILABLE",
    "removed mod unavailable")
Catalog.Commands.Rebuild(list({ installed, modded, base }))
T.equal(Registry.Queries.Resolve(axeId).status, "AVAILABLE",
    "restored mod available")

local ResearchRepository = {}
package.preload["PNC/Production/PNC_ResearchRepository"] = function()
    return ResearchRepository
end
T.finish("pnc_production_foundation_smoke")

T.finish("pnc_production_foundation_smoke")
