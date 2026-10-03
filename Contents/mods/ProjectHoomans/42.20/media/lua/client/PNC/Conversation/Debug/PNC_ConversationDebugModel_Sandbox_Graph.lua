-- Conversation sandbox graph composition root.

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.ConversationDebugModel = PNC.ConversationDebugModel or {}
PNC.ConversationDebugModelInternal =
    PNC.ConversationDebugModelInternal or {}

local Model = PNC.ConversationDebugModel
local H = PNC.ConversationDebugModelInternal
local SandboxGraph = {}

require "PNC/Conversation/Debug/PNC_ConversationDebugModel_Sandbox_Graph_Choices"
require "PNC/Conversation/Debug/PNC_ConversationDebugModel_Sandbox_Graph_Blocks"
require "PNC/Conversation/Debug/PNC_ConversationDebugModel_Sandbox_Graph_Categories"

local SandboxBlocks = H.SandboxBlocks
local SandboxCategories = H.SandboxCategories
if not SandboxBlocks or not SandboxCategories then return Model end

function SandboxGraph.Build(state)
    local graph = SandboxBlocks.Build(state.context)
    SandboxCategories.Append(graph, state.context)
    state.context.sandboxBlockCount = graph.runnableBlocks
    return graph
end

H.SandboxGraph = SandboxGraph

return Model
