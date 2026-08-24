-- Server-authoritative sparse NPC knowledge entry.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}
PNC.NPCKnowledge = PNC.NPCKnowledge or {}
PNC.NPCKnowledge.Internal = PNC.NPCKnowledge.Internal or {}

require "PNC/Knowledge/NPCKnowledgeService/PNC_NPCKnowledgeService_Core"
require "PNC/Knowledge/NPCKnowledgeService/PNC_NPCKnowledgeService_Normalization"
require "PNC/Knowledge/NPCKnowledgeService/PNC_NPCKnowledgeService_Persistence"
require "PNC/Knowledge/NPCKnowledgeService/PNC_NPCKnowledgeService_Resolution"
require "PNC/Knowledge/NPCKnowledgeService/PNC_NPCKnowledgeService_Evidence"
require "PNC/Knowledge/NPCKnowledgeService/PNC_NPCKnowledgeService_JournalsAndDisclosure"
require "PNC/Knowledge/NPCKnowledgeService/PNC_NPCKnowledgeService_PlayerSnapshots"
require "PNC/Knowledge/NPCKnowledgeService/PNC_NPCKnowledgeService_DebugSnapshots"
require "PNC/Knowledge/NPCKnowledgeService/PNC_NPCKnowledgeService_Discovery"
require "PNC/Knowledge/NPCKnowledgeService/PNC_NPCKnowledgeService_DebugCommands"
require "PNC/Knowledge/NPCKnowledgeService/PNC_NPCKnowledgeService_Hooks"

return PNC.NPCKnowledge
