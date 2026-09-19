-- Stable entry point for the player-to-managed-NPC damage boundary.

PNC = PNC or {}
PNC.PlayerDamage = PNC.PlayerDamage or {}
PNC.PlayerDamage.Internal = PNC.PlayerDamage.Internal or {}
PNC.PlayerDamage.LastReportAt = PNC.PlayerDamage.LastReportAt or {}

require "PNC/Core/Health/PlayerDamage/PNC_PlayerDamage_Runtime"
require "PNC/Core/Health/PlayerDamage/PNC_PlayerDamage_Diagnostics"
require "PNC/Core/Health/PlayerDamage/PNC_PlayerDamage_ReportContract"
require "PNC/Core/Health/PlayerDamage/PNC_PlayerDamage_Policy"
require "PNC/Core/Health/PlayerDamage/PNC_PlayerDamage_Application"
require "PNC/Core/Health/PlayerDamage/PNC_PlayerDamage_RateLimit"
require "PNC/Core/Health/PlayerDamage/PNC_PlayerDamage_ServerAdmission"
require "PNC/Core/Health/PlayerDamage/PNC_PlayerDamage_ClientAdapter"
