return function()
local T = require "tests/support/test"

T.addPackagePaths()
ZombRand = function(maximum) return math.min(7, (maximum or 7) - 1) end

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, child in pairs(value) do
        output[copy(key)] = copy(child)
    end
    return output
end

PNC = {
    Core = { DeepCopy = copy },
    Identity = {},
    Inventory = { Queries = {} },
    SkillCatalog = { Find = function() return nil end },
    NPCTraits = {
        NormalizeID = function(id) return tostring(id or "steady") end,
        ResolveSet = function(source) return source, {} end,
    },
    UniqueNPCs = {},
}

PNC.Inventory.Queries.ToDefinitionSpec = function(item, key)
    local output = copy(item)
    output.key = key
    return output
end

package.preload["PNC/Core/Identity/PNC_UniqueNPCs"] =
    function() return PNC.UniqueNPCs end
package.preload["PNC/Core/Inventory/PNC_Inventory"] =
    function() return PNC.Inventory end

T.load("ProjectHoomans", "shared", "PNC/Core/Identity/PNC_Identity.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Identity/PNC_Identity_Appearance.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Relationships/PNC_SocialProfileConstants.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Relationships/PNC_SocialProfileTypes.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Relationships/PNC_SocialTraits.lua")

local StartingTraits = require "PNC/Core/Traits/PNC_StartingCompanionTraits"
local Session = require "PNC/CharacterCreation/PNC_StartingCompanionSession"
local Adapter = require
    "PNC/CharacterCreation/PNC_StartingCompanionAuthoringAdapter"
local Authoring = require "PNC/Core/Identity/PNC_NPCAuthoring"
local Blueprint = Authoring.Blueprint
local Model = require "PNC/Identity/PNC_UniqueNPCDraft"
local TID = StartingTraits.IDS

local function context(surname, female, orientation)
    return {
        playerSurname = surname,
        playerFemale = female,
        orientation = orientation,
        playerAppearance = {
            skinTexture = "FemaleBody03",
            skinColor = { r = 0.4, g = 0.3, b = 0.2 },
            hairColor = { r = 0.1, g = 0.1, b = 0.1 },
        },
    }
end


return { T = T, StartingTraits = StartingTraits, Session = Session, Adapter = Adapter, Authoring = Authoring, Blueprint = Blueprint, Model = Model, TID = TID, context = context, copy = copy }
end
