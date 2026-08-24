-- Server-authoritative persistent faction identity and affiliation entry.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}
PNC.Factions = PNC.Factions or {}
PNC.Factions.Internal = PNC.Factions.Internal or {}

require "PNC/Factions/FactionService/PNC_FactionService_State"
require "PNC/Factions/FactionService/PNC_FactionService_RegistryIndexes"
require "PNC/Factions/FactionService/PNC_FactionService_RegistryPersistence"
require "PNC/Factions/FactionService/PNC_FactionService_Queries"
require "PNC/Factions/FactionService/PNC_FactionService_Creation"
require "PNC/Factions/FactionService/PNC_FactionService_NPCTransfers"
require "PNC/Factions/FactionService/PNC_FactionService_NPCRoles"
require "PNC/Factions/FactionService/PNC_FactionService_PlayerLookup"
require "PNC/Factions/FactionService/PNC_FactionService_MobileGroups"
require "PNC/Factions/FactionService/PNC_FactionService_PlayerMembershipCommands"
require "PNC/Factions/FactionService/PNC_FactionService_RefugeeTreaties"
require "PNC/Factions/FactionService/PNC_FactionService_PlayerSuccession"
require "PNC/Factions/FactionService/PNC_FactionService_Pacification"
require "PNC/Factions/FactionService/PNC_FactionService_PlayerFactionLifecycle"
require "PNC/Factions/FactionService/PNC_FactionService_PlayerFactionPresentation"
require "PNC/Factions/FactionService/PNC_FactionService_Relations"
require "PNC/Factions/FactionService/PNC_FactionService_TreatyMutation"
require "PNC/Factions/FactionService/PNC_FactionService_TreatyCommands"
require "PNC/Factions/FactionService/PNC_FactionService_PlayerAggression"
require "PNC/Factions/FactionService/PNC_FactionService_NPCAggression"
require "PNC/Factions/FactionService/PNC_FactionService_Lifecycle"

return PNC.Factions
