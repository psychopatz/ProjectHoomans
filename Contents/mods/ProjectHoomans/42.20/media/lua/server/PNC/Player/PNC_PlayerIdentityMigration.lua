-- Stable entry point for legacy single-player identity migration.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PlayerIdentityMigration = PNC.PlayerIdentityMigration or {}

require "PNC/Player/PlayerIdentityMigration/PNC_PlayerIdentityMigration_Context"
require "PNC/Player/PlayerIdentityMigration/PNC_PlayerIdentityMigration_Candidates"
require "PNC/Player/PlayerIdentityMigration/PNC_PlayerIdentityMigration_Knowledge"
require "PNC/Player/PlayerIdentityMigration/PNC_PlayerIdentityMigration_Relationships"
require "PNC/Player/PlayerIdentityMigration/PNC_PlayerIdentityMigration_Conduct"
require "PNC/Player/PlayerIdentityMigration/PNC_PlayerIdentityMigration_Factions"
require "PNC/Player/PlayerIdentityMigration/PNC_PlayerIdentityMigration_Backup"
require "PNC/Player/PlayerIdentityMigration/PNC_PlayerIdentityMigration_Workflow"

return PNC.PlayerIdentityMigration
