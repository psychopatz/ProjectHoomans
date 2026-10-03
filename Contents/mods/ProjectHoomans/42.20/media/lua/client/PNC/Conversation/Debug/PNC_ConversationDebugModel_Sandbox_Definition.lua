-- Conversation sandbox definition and presentation provider.

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.ConversationDebugModel = PNC.ConversationDebugModel or {}
PNC.ConversationDebugModelInternal =
    PNC.ConversationDebugModelInternal or {}

local Model = PNC.ConversationDebugModel
local H = PNC.ConversationDebugModelInternal
local copy = H.Copy
local Selector = PNC.Conversation.Selector
local SandboxDefinition = {}

if not copy then return Model end

function SandboxDefinition.Build(state, graph)
    local context = state.context
    local selectedBlock = state.selectedBlock
    local extensions = {}
    if PNC.Conversation.CreateRelationshipPanel then
        extensions[#extensions + 1] = {
            partID = "relationship",
            factory = PNC.Conversation.CreateRelationshipPanel,
            relationship = copy(context.relationship),
            visible = true,
            title = {
                key = "panel.current_relation",
                domain = "pnc.system.shared.categories",
            },
            editLabel = {
                key = "panel.current_relation_edit",
                domain = "pnc.system.shared.categories",
            },
        }
    end
    local fakeEntry = {
        id = context.npcID,
        snapshot = {
            tacticalClass = context.audiences.hostile and "hostile" or "neutral",
        },
    }
    return {
        namespace = "ProjectHoomansConversationSandbox",
        npcID = "sandbox:registry",
        characterUUID = "sandbox-character",
        persistHistory = false,
        portrait = {
            id = "sandbox:registry",
            identitySeed = Selector.Seed(
                context,
                "sandbox_portrait:" .. selectedBlock.id
            ),
            isFemale = false,
            faceOnly = true,
            preferDescriptor = true,
            appearance = {},
            equipment = { worn = {} },
        },
        backgroundID = PNC.Conversation.Backgrounds
            and PNC.Conversation.Backgrounds.Get("twilight") or "twilight",
        theme = PNC.NPCTypePalette
            and PNC.NPCTypePalette.BuildConversationTheme(fakeEntry) or nil,
        context = context,
        extensionParts = extensions,
        start = "sandbox:category:" .. tostring(selectedBlock.category),
        nodes = graph.nodes,
        lifecycle = {
            begin = function() return {} end,
            finish = function(_, _, _, reason)
                if PNC.Core and PNC.Core.LogInfo then
                    PNC.Core.LogInfo("Conversation sandbox closed reason="
                        .. tostring(reason or "closed"))
                end
            end,
        },
    }
end

H.SandboxDefinition = SandboxDefinition

return Model
