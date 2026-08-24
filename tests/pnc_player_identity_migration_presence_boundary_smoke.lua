local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans", "server", "PNC/Player/PNC_PlayerIdentityMigration.lua")
local prefix = "PNC/Player/PlayerIdentityMigration/"
local providers = {
    "PNC_PlayerIdentityMigration_Context",
    "PNC_PlayerIdentityMigration_Candidates",
    "PNC_PlayerIdentityMigration_Knowledge",
    "PNC_PlayerIdentityMigration_Relationships",
    "PNC_PlayerIdentityMigration_Conduct",
    "PNC_PlayerIdentityMigration_Factions",
    "PNC_PlayerIdentityMigration_Backup",
    "PNC_PlayerIdentityMigration_Workflow",
}

local previous = 0
local i
for i = 1, #providers do
    local provider = providers[i]
    local needle = 'require "' .. prefix .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
    T.read("ProjectHoomans", "server", prefix .. provider .. ".lua")
end

PNC = {}
T.load("ProjectHoomans", "server", "PNC/Player/PNC_PlayerIdentityMigration.lua")
T.equal(type(PNC.PlayerIdentityMigration.RunForPlayer), "function",
    "entry point preserves PlayerIdentityMigration.RunForPlayer")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_player_identity_migration_presence_boundary_smoke")
