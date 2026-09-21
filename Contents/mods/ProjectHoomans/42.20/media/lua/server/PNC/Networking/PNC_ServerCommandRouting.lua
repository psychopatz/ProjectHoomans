-- Canonical entry point for authoritative client-command routing.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

require "PNC/Networking/PNC_ServerCommandRouter"
require "PNC/PuppetOpera/PNC_PuppetOpera_Authority"
require "PNC/Networking/Handlers/PNC_ServerInventoryCommandHandler"
require "PNC/Networking/Handlers/PNC_ServerKnowledgeCommandHandler"
require "PNC/Networking/Handlers/PNC_ServerSemanticCognitionCommandHandler"
require "PNC/Networking/Handlers/PNC_ServerSemanticTaskCommandHandler"
require "PNC/Networking/Handlers/PNC_ServerSemanticInventoryQueryCommandHandler"
require "PNC/Networking/Handlers/PNC_ServerSemanticSocialInteractionCommandHandler"
require "PNC/Networking/Handlers/PNC_ServerConversationCommandHandler"
require "PNC/Networking/Handlers/PNC_ServerPresentationAnimationCommandHandler"
require "PNC/Networking/PNC_LLMSocialReactionPolicy"
require "PNC/Networking/Handlers/PNC_ServerLLMSocialReactionCommandHandler"
require "PNC/Networking/Handlers/PNC_ServerPlayerEmoteInteractionCommandHandler"
require "PNC/Networking/Handlers/PNC_ServerCharacterReplicationCommandHandler"
require "PNC/Networking/Handlers/PNC_ServerHealthCombatCommandHandler"
require "PNC/Networking/Handlers/PNC_ServerNecroaDamageCommandHandler"
require "PNC/Networking/Handlers/PNC_ServerGameplayRequestCommandHandler"
require "PNC/Networking/Handlers/PNC_ServerDiagnosticQueryCommandHandler"
require "PNC/Networking/Handlers/PNC_ServerAuthorityDiagnosticCommandHandler"
require "PNC/Networking/Handlers/PNC_ServerColonyManagementCommandHandler"
require "PNC/Networking/Handlers/PNC_ServerColonyJournalCommandHandler"
require "PNC/Networking/Handlers/PNC_ServerDebugCommandHandler"

return PNC.ServerCommandRouter
