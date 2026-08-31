-- Canonical entry point for authoritative client-command routing.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

require "PNC/Networking/PNC_ServerCommandRouter"
require "PNC/Networking/Handlers/PNC_ServerInventoryCommandHandler"
require "PNC/Networking/Handlers/PNC_ServerKnowledgeCommandHandler"
require "PNC/Networking/Handlers/PNC_ServerConversationCommandHandler"
require "PNC/Networking/PNC_LLMSocialReactionPolicy"
require "PNC/Networking/Handlers/PNC_ServerLLMSocialReactionCommandHandler"
require "PNC/Networking/Handlers/PNC_ServerCharacterReplicationCommandHandler"
require "PNC/Networking/Handlers/PNC_ServerHealthCombatCommandHandler"
require "PNC/Networking/Handlers/PNC_ServerGameplayRequestCommandHandler"
require "PNC/Networking/Handlers/PNC_ServerDiagnosticQueryCommandHandler"
require "PNC/Networking/Handlers/PNC_ServerAuthorityDiagnosticCommandHandler"
require "PNC/Networking/Handlers/PNC_ServerColonyManagementCommandHandler"
require "PNC/Networking/Handlers/PNC_ServerColonyJournalCommandHandler"
require "PNC/Networking/Handlers/PNC_ServerDebugCommandHandler"

return PNC.ServerCommandRouter
