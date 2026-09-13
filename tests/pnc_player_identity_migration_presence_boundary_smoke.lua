local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans", "server", "PNC/Composition/PNC_ServerComposition.lua")
T.equal(string.find(source, "PNC/Player/PNC_PlayerIdentityMigration", 1, true),
    nil, "server composition does not load removed identity migration")
T.equal(T.read(
    "ProjectHoomans", "shared",
    "PNC/Core/Identity/PNC_PlayerCharacterConstants.lua"
):find("MIGRATION_BACKUP_MODDATA_KEY", 1, true), nil,
    "identity constants do not expose a migration backup key")

T.finish("pnc_player_identity_migration_presence_boundary_smoke")
