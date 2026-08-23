local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Factions/PNC_FactionTypes.lua"
)
local providers = {
    "Base", "Policy", "Diplomacy", "Incidents", "Relations",
    "Affiliations", "Factions", "Registry", "Equality",
}
local publicFunctions = {
    "IsValidFactionID", "IsValidNPCID", "IsValidFactionArchetype",
    "IsValidMembershipStatus", "IsValidFactionRole", "IsValidFactionRank",
    "NormalizeMobileGroup", "NormalizePlayerPacification",
    "NormalizePlayerPacifications", "NormalizePolicy", "NewPolicy",
    "MakeDiplomacyKey", "NormalizeDiplomacy", "NormalizeIncident",
    "NormalizeRelation", "NewRelation", "NormalizeAffiliation",
    "NewAffiliation", "AppendFormerFaction", "NormalizeFaction",
    "NewFaction", "NormalizeFactionRegistry", "NewFactionRegistry",
    "NormalizeTags", "AreEqual",
}

local previous = 0
for i = 1, #providers do
    local provider = providers[i]
    local needle = 'require "PNC/Core/Factions/PNC_FactionTypes/'
        .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
end

PNC = {
    FactionConstants = {}, FactionArchetypes = {}, EntityRef = {},
    FactionDiplomacyMath = {}, FactionIncidentDefinitions = {},
    FactionBalance = {}, FactionEmblems = {},
}
T.load("ProjectHoomans", "shared", "PNC/Core/Factions/PNC_FactionTypes.lua")

for i = 1, #publicFunctions do
    local functionName = publicFunctions[i]
    T.equal(type(PNC.FactionTypes[functionName]), "function",
        "entry point should preserve FactionTypes." .. functionName)
end

T.truthy(type(PNC.FactionTypes.Internal) == "table",
    "providers should share an internal contract")
T.finish("pnc_faction_types_presence_boundary_smoke")
