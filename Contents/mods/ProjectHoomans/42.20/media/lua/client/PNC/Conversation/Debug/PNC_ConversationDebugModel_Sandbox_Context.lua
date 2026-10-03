-- Conversation sandbox context and authored-text provider.

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.ConversationDebugModel = PNC.ConversationDebugModel or {}
PNC.ConversationDebugModelInternal =
    PNC.ConversationDebugModelInternal or {}

local Model = PNC.ConversationDebugModel
local H = PNC.ConversationDebugModelInternal
local copy = H.Copy
local Registry = PNC.Conversation.Registry
local Selector = PNC.Conversation.Selector
local Loader = PNC.Conversation.TextLoader
local SandboxContext = {}

if not copy then return Model end

local DEBUG_SOURCE = {
    modID = "ProjectHoomans",
    pathPattern = "media/conversation/system/shared/{language}/debugger.json",
    domain = "pnc.system.shared.debugger",
}

local function sandboxText(block, key, context)
    return Loader.Payload(block.textSource, key, context.textArgs)
end

local function debugText(key, args)
    Loader.EnsureSource(DEBUG_SOURCE, { key })
    return Loader.Payload(DEBUG_SOURCE, key, args)
end

local function sandboxCategoryNodeID(categoryID)
    return "sandbox:category:" .. tostring(categoryID)
end

local function sandboxBlockNodeID(blockID, nodeID)
    return table.concat({ "sandbox:block", blockID, nodeID }, ":")
end

local function sandboxNodeTextKey(block, nodeID, node, context)
    if node.textKey then return node.textKey end
    local keys = node.textKeys or {}
    if #keys == 0 then return nil end
    local seed = Selector.Seed(
        context,
        table.concat({ "sandbox_node", block.id, nodeID }, ":")
    )
    return keys[seed % #keys + 1]
end

function SandboxContext.Build(blockID, input)
    local selectedBlock = Registry.GetBlock(blockID)
    if not selectedBlock then return nil, "block_not_found" end
    local context = Model.NormalizeContext(input)
    context.relationship = type(context.relationship) == "table"
        and context.relationship or {}
    context.relationship.exists = true
    context.playerName = context.playerName or "Sandbox Player"
    context.playerFullName = context.playerFullName or context.playerName
    context.playerFirstName = context.playerFirstName or "Sandbox"
    context.playerLastName = context.playerLastName or "Player"
    context.npcName = context.npcName or "Sandbox NPC"
    context.npcFullName = context.npcFullName or context.npcName
    context.npcFirstName = context.npcFirstName or "Sandbox"
    context.npcLastName = context.npcLastName or "NPC"
    context.textArgs = {
        playerName = context.playerName,
        playerFullName = context.playerFullName,
        playerFirstName = context.playerFirstName,
        playerLastName = context.playerLastName,
        npcName = context.npcName,
        npcFullName = context.npcFullName,
        npcFirstName = context.npcFirstName,
        npcLastName = context.npcLastName,
    }
    context.sandbox = true
    context.sandboxBlockID = selectedBlock.id
    return {
        selectedBlock = selectedBlock,
        context = context,
    }
end

function SandboxContext.Text(block, key, context)
    return sandboxText(block, key, context)
end

function SandboxContext.DebugText(key, args)
    return debugText(key, args)
end

function SandboxContext.CategoryNodeID(categoryID)
    return sandboxCategoryNodeID(categoryID)
end

function SandboxContext.BlockNodeID(blockID, nodeID)
    return sandboxBlockNodeID(blockID, nodeID)
end

function SandboxContext.NodeTextKey(block, nodeID, node, context)
    return sandboxNodeTextKey(block, nodeID, node, context)
end

function SandboxContext.UpdateRelationship(session, context)
    local panel = session and session.view and session.view.extensionParts
        and session.view.extensionParts.relationship or nil
    if panel and panel.setRelationship then
        local summary = copy(context.relationship)
        summary.exists = true
        panel:setRelationship(summary)
    end
end

H.SandboxContext = SandboxContext

return Model
