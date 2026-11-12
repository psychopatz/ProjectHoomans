-- Conversation sandbox category graph provider.

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.ConversationDebugModel = PNC.ConversationDebugModel or {}
PNC.ConversationDebugModelInternal =
    PNC.ConversationDebugModelInternal or {}

local Model = PNC.ConversationDebugModel
local H = PNC.ConversationDebugModelInternal
local Registry = PsychopatzCore.Conversation.Registry
local Selector = PNC.Conversation.Selector
local Loader = PsychopatzCore.Conversation.TextCatalog
local SandboxContext = H.SandboxContext
local SandboxCategories = {}

if not SandboxContext then return Model end

function SandboxCategories.Append(graph, context)
    local categoryChoices = {}
    for _, category in ipairs(Registry.ListCategories()) do
        local entries = graph.blocksByCategory[category.id] or {}
        if #entries > 0 then
            Loader.ValidateSource(category.textSource, { category.labelKey })
            local categoryLabel = Loader.Payload(
                category.textSource,
                category.labelKey
            )
            categoryChoices[#categoryChoices + 1] = {
                id = category.id,
                text = categoryLabel,
                log = false,
                next = SandboxContext.CategoryNodeID(category.id),
            }
            local blockChoices = {}
            for _, entry in ipairs(entries) do
                local eligible, reason = Selector.IsBlockEligible(
                    entry.block,
                    context
                )
                blockChoices[#blockChoices + 1] = {
                    id = entry.block.id,
                    text = SandboxContext.DebugText("UI_PsychopatzConversation_Debugger_Sandbox_BlockChoice", {
                        id = entry.block.id,
                        audiences = table.concat(
                            entry.block.audiences or {},
                            ","
                        ),
                        status = not entry.textValid
                            and "missing translation"
                            or eligible and "eligible"
                            or "gated: " .. tostring(reason or "unknown"),
                    }),
                    log = false,
                    enabled = entry.textValid,
                    next = entry.textValid and SandboxContext.BlockNodeID(
                        entry.block.id,
                        entry.block.entryNode
                    ) or nil,
                }
            end
            blockChoices[#blockChoices + 1] = {
                id = "sandbox_back_to_categories",
                text = SandboxContext.DebugText(
                    "UI_PsychopatzConversation_Debugger_Sandbox_BackToCategories"
                ),
                log = false,
                next = "sandbox:categories",
            }
            graph.nodes[SandboxContext.CategoryNodeID(category.id)] = {
                npc = SandboxContext.DebugText("UI_PsychopatzConversation_Debugger_Sandbox_CategoryPrompt", {
                    category = PsychopatzCore.Conversation.Text.Resolve(
                        categoryLabel
                    ),
                    count = #entries,
                }),
                choices = blockChoices,
            }
        end
    end
    graph.nodes["sandbox:categories"] = {
        npc = SandboxContext.DebugText("UI_PsychopatzConversation_Debugger_Sandbox_CategoriesPrompt", {
            count = graph.runnableBlocks,
        }),
        choices = categoryChoices,
    }
end

H.SandboxCategories = SandboxCategories

return Model
