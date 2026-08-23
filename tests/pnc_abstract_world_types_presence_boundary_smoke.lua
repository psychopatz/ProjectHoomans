local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Director/PNC_AbstractWorldTypes.lua"
)
local prefix =
    "PNC/Core/Director/PNC_AbstractWorldTypes/"
local providers = {
    "PNC_AbstractWorldTypes_Core",
    "PNC_AbstractWorldTypes_Profiles",
    "PNC_AbstractWorldTypes_Group",
    "PNC_AbstractWorldTypes_Location",
    "PNC_AbstractWorldTypes_Population",
    "PNC_AbstractWorldTypes_Registry",
}
local publicFunctions = {
    "SafeID",
    "IDArray",
    "Resources",
    "NormalizeLocationRef",
    "NormalizeCombatProfile",
    "NormalizeBehaviorProfile",
    "NormalizeAction",
    "NormalizeGroup",
    "NormalizeLocation",
    "NormalizePopulation",
    "NewRegistry",
    "NormalizeRegistry",
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
    DirectorConfig = {
        LOCATION_TYPES = { TEMPORARY = true },
        MISSIONS = { IDLE = true },
        GROUP_TYPES = { WANDERER = true },
        STATES = { IDLE = true },
        Population = { COMMITTED_GENERATION_HISTORY_LIMIT = 128 },
        SCHEMA_VERSION = 1,
        RECENT_THREAT_HISTORY_LIMIT = 24,
        ENCOUNTER_HISTORY_LIMIT = 100,
    },
}
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Director/PNC_AbstractWorldTypes.lua"
)
for i = 1, #publicFunctions do
    local functionName = publicFunctions[i]
    T.equal(
        type(PNC.AbstractWorldTypes[functionName]),
        "function",
        "entry point should preserve AbstractWorldTypes." .. functionName
    )
end
for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_abstract_world_types_presence_boundary_smoke")
