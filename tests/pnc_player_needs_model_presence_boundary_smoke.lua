local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Needs/PNC_PlayerNeedsModel.lua"
)
local prefix = "PNC/Core/Needs/PNC_PlayerNeedsModel/"
local providers = {
    "PNC_PlayerNeedsModel_Constants",
    "PNC_PlayerNeedsModel_Generation",
    "PNC_PlayerNeedsModel_Traits",
    "PNC_PlayerNeedsModel_Rates",
}
local publicFunctions = {
    "NormalizeTraits", "GenerateTraits", "ResolveInitialTraits",
    "GetTraitDefinitions", "GetActiveTraitIDs", "GetTraitLabelKey",
    "GetTraits", "SetTraits", "EnsureTraits", "HasTrait",
    "AppetiteMultiplier", "GetRateModifiers", "GetInitialWeight",
    "ThirstMultiplier", "FatigueGainMultiplier",
    "SleepRecoveryMultiplier", "GetRates",
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

PNC = { NeedsDefinitions = {
    NUTRITION = { defaultWeight = 80, calorieBurnPerHour = 100 },
    VANILLA_RATES_PER_HOUR = {
        hunger = 1, hungerSleeping = 1, hungerRunning = 1,
        hungerFighting = 1, thirst = 1, fatigue = 1,
    },
    INDIVIDUAL_RATE_SCALE = { hunger = 1, thirst = 1, fatigue = 1 },
} }
T.load("ProjectHoomans", "shared", "PNC/Core/Needs/PNC_PlayerNeedsModel.lua")
T.equal(PNC.PlayerNeedsModel.GENERATION_VERSION, 1, "generation version")
for i = 1, #publicFunctions do
    local functionName = publicFunctions[i]
    T.equal(type(PNC.PlayerNeedsModel[functionName]), "function",
        "entry point should preserve PlayerNeedsModel." .. functionName)
end
for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_player_needs_model_presence_boundary_smoke")
