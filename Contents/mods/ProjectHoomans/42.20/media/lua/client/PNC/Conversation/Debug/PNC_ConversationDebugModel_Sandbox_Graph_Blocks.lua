-- Conversation sandbox block graph provider.

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.ConversationDebugModel = PNC.ConversationDebugModel or {}
PNC.ConversationDebugModelInternal =
    PNC.ConversationDebugModelInternal or {}

local Model = PNC.ConversationDebugModel
local H = PNC.ConversationDebugModelInternal
local Registry = PNC.Conversation.Registry
local Loader = PNC.Conversation.TextLoader
local SandboxContext = H.SandboxContext
local SandboxChoices = H.SandboxChoices
local SandboxBlocks = {}

if not SandboxContext or not SandboxChoices then return Model end

function SandboxBlocks.Build(context)
    local nodes = {}
    local blocksByCategory = {}
    local runnableBlocks = 0
    for _, block in ipairs(Registry.ListBlocks()) do
        local categoryNodeID = SandboxContext.CategoryNodeID(block.category)
        local textValid = Loader.EnsureSource(
            block.textSource,
            Registry.CollectTextKeys(block)
        )
        local blockEntry = {
            block = block,
            textValid = textValid == true,
        }
        blocksByCategory[block.category] = blocksByCategory[block.category]
            or {}
        blocksByCategory[block.category][#blocksByCategory[block.category] + 1]
            = blockEntry
        if textValid then
            runnableBlocks = runnableBlocks + 1
            for nodeID, node in pairs(block.nodes or {}) do
                local choices = {}
                for _, choice in ipairs(node.choices or {}) do
                    choices[#choices + 1] = SandboxChoices.Build(
                        block,
                        nodeID,
                        choice,
                        context,
                        categoryNodeID
                    )
                end
                choices[#choices + 1] = {
                    id = "sandbox_back_to_blocks",
                    text = SandboxContext.DebugText("sandbox.back_to_blocks"),
                    log = false,
                    next = categoryNodeID,
                }
                nodes[SandboxContext.BlockNodeID(block.id, nodeID)] = {
                    npc = SandboxContext.Text(
                        block,
                        SandboxContext.NodeTextKey(
                            block,
                            nodeID,
                            node,
                            context
                        ),
                        context
                    ),
                    choices = choices,
                }
            end
        end
    end
    return {
        nodes = nodes,
        blocksByCategory = blocksByCategory,
        runnableBlocks = runnableBlocks,
    }
end

H.SandboxBlocks = SandboxBlocks

return Model
