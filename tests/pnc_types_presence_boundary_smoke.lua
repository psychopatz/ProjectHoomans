local T = require "tests/support/test"

local source = T.read("ProjectHoomans", "shared", "PNC/Core/Base/PNC_Types.lua")
local prefix = "PNC/Core/Base/PNC_Types/"
local providers = {
    "PNC_Types_Normalization",
    "PNC_Types_Factions",
    "PNC_Types_Definition",
    "PNC_Types_Record",
}
local publicFunctions = {
    "NormalizeAttackType", "NormalizeFaction", "IsColonist",
    "DefaultHostility", "NormalizeHostility", "NormalizeDefinition",
    "NewRecord",
}

local previous = 0
local i
for i = 1, #providers do
    local provider = providers[i]
    local needle = 'require "' .. prefix .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
end

PNC = {
    Core = { DeepCopy = function(value) return value end,
        Now = function() return 0 end, GenerateID = function() return "npc:1" end },
    Const = { DEFAULT_HP_MAX = 100, PRESENCE_ABSTRACT = "abstract" },
}
T.load("ProjectHoomans", "shared", "PNC/Core/Base/PNC_Types.lua")
for i = 1, #publicFunctions do
    local functionName = publicFunctions[i]
    T.equal(type(PNC.Types[functionName]), "function",
        "entry point should preserve Types." .. functionName)
end
for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_types_presence_boundary_smoke")
