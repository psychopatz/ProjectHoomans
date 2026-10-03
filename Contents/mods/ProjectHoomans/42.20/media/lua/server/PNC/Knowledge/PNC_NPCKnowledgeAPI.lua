-- Server-authoritative knowledge API composition root.
-- Context and read access load before disclosure policy and mutating endpoints.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.API = PNC.API or {}
PNC.NPCKnowledgeAPI = PNC.NPCKnowledgeAPI or {}
PNC.API.Knowledge = PNC.NPCKnowledgeAPI

local API = PNC.NPCKnowledgeAPI

require "PNC/Knowledge/NPCKnowledgeAPI/PNC_NPCKnowledgeAPI_Context"
require "PNC/Knowledge/NPCKnowledgeAPI/PNC_NPCKnowledgeAPI_Disclosure"
require "PNC/Knowledge/NPCKnowledgeAPI/PNC_NPCKnowledgeAPI_Mutations"

return API
