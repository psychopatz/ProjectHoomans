-- Client-side conversation sandbox composition root.

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.ConversationDebugModel = PNC.ConversationDebugModel or {}
PNC.ConversationDebugModelInternal =
    PNC.ConversationDebugModelInternal or {}

local Model = PNC.ConversationDebugModel
local H = PNC.ConversationDebugModelInternal
if not H.Copy then return Model end

require "PNC/Conversation/Debug/PNC_ConversationDebugModel_Sandbox_Context"
require "PNC/Conversation/Debug/PNC_ConversationDebugModel_Sandbox_Graph"
require "PNC/Conversation/Debug/PNC_ConversationDebugModel_Sandbox_Definition"

local SandboxContext = H.SandboxContext
local SandboxGraph = H.SandboxGraph
local SandboxDefinition = H.SandboxDefinition
if not SandboxContext or not SandboxGraph or not SandboxDefinition then
    return Model
end

function Model.BuildSandboxDefinition(blockID, context)
    local state, reason = SandboxContext.Build(blockID, context)
    if not state then return nil, reason end
    local graph = SandboxGraph.Build(state)
    return SandboxDefinition.Build(state, graph)
end

return Model
