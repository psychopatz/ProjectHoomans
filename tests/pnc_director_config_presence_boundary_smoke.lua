local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Director/PNC_DirectorConfig.lua"
)
local providers = {
    "PNC_DirectorConfig_Core",
    "PNC_DirectorConfig_Behavior",
    "PNC_DirectorConfig_Combat",
    "PNC_DirectorConfig_Archetypes",
    "PNC_DirectorConfig_Population",
}
local expectedTables = {
    "GROUP_TYPES",
    "MISSIONS",
    "STATES",
    "Scavenging",
    "ResourceNeeds",
    "Behavior",
    "Intent",
    "CombatResolution",
    "Casualties",
    "Retreat",
    "EncounterQueue",
    "ARCHETYPES",
    "COMBAT",
    "Population",
}

local previous = 0
local i
for i = 1, #providers do
    local provider = providers[i]
    local needle =
        'require "PNC/Core/Director/PNC_DirectorConfig/'
            .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
end

PNC = {}
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Director/PNC_DirectorConfig.lua"
)
for i = 1, #expectedTables do
    local tableName = expectedTables[i]
    T.equal(
        type(PNC.DirectorConfig[tableName]),
        "table",
        "entry point should preserve DirectorConfig." .. tableName
    )
end
T.equal(
    type(PNC.DirectorConfig.GetArchetype),
    "function",
    "entry point should preserve DirectorConfig.GetArchetype"
)
for i = 1, #providers do
    package.loaded[
        "PNC/Core/Director/PNC_DirectorConfig/" .. providers[i]
    ] = nil
end

T.finish("pnc_director_config_presence_boundary_smoke")
