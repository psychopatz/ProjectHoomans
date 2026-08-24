local T = require "tests/support/test"

local source = T.read("ProjectHoomans", "server", "PNC/Factions/PNC_FactionService.lua")
local prefix = "PNC/Factions/FactionService/"
local providers = {
    "PNC_FactionService_State",
    "PNC_FactionService_RegistryIndexes",
    "PNC_FactionService_RegistryPersistence",
    "PNC_FactionService_Queries",
    "PNC_FactionService_Creation",
    "PNC_FactionService_NPCTransfers",
    "PNC_FactionService_NPCRoles",
    "PNC_FactionService_PlayerLookup",
    "PNC_FactionService_MobileGroups",
    "PNC_FactionService_PlayerMembershipCommands",
    "PNC_FactionService_RefugeeTreaties",
    "PNC_FactionService_PlayerSuccession",
    "PNC_FactionService_Pacification",
    "PNC_FactionService_PlayerFactionLifecycle",
    "PNC_FactionService_PlayerFactionPresentation",
    "PNC_FactionService_Relations",
    "PNC_FactionService_TreatyMutation",
    "PNC_FactionService_TreatyCommands",
    "PNC_FactionService_PlayerAggression",
    "PNC_FactionService_NPCAggression",
    "PNC_FactionService_Lifecycle",
}

local previous = 0
local publicFunctions = {}
local i
for i = 1, #providers do
    local provider = providers[i]
    local needle = 'require "' .. prefix .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
    local providerSource = T.read(
        "ProjectHoomans", "server", prefix .. provider .. ".lua")
    for functionName in providerSource:gmatch(
        "function%s+Factions%.([%w_]+)"
    ) do
        publicFunctions[functionName] = true
    end
end

PNC = {
    Core = { GenerateID = function() return "faction:1" end },
    FactionConstants = {},
    FactionArchetypes = {},
    EntityRef = {},
    FactionTypes = {
        NewFactionRegistry = function()
            return { byID = {}, revision = 0 }
        end,
        NormalizeFactionRegistry = function(value) return value end,
        NormalizeFaction = function(value) return value end,
        NormalizeAffiliation = function(value) return value end,
    },
}
T.load("ProjectHoomans", "server", "PNC/Factions/PNC_FactionService.lua")

local publicCount = 0
for functionName, _ in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.Factions[functionName]), "function",
        "entry point should preserve Factions." .. functionName)
end
T.equal(publicCount, 87, "public function declaration count")
T.equal(type(PNC.Factions.GetDiplomacy), "function", "diplomacy alias")
T.equal(type(PNC.Factions.NormalizeFactionRegistry), "function",
    "registry normalization alias")
T.equal(type(PNC.Factions.NormalizeFaction), "function",
    "faction normalization alias")
T.equal(type(PNC.Factions.NormalizeAffiliation), "function",
    "affiliation normalization alias")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_faction_service_presence_boundary_smoke")
