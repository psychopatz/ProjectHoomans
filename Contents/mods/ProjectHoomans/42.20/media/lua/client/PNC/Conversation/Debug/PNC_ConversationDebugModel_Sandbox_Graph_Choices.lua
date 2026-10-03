-- Conversation sandbox choice node provider.

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.ConversationDebugModel = PNC.ConversationDebugModel or {}
PNC.ConversationDebugModelInternal =
    PNC.ConversationDebugModelInternal or {}

local Model = PNC.ConversationDebugModel
local H = PNC.ConversationDebugModelInternal
local Selector = PNC.Conversation.Selector
local SandboxContext = H.SandboxContext
local SandboxChoices = {}

if not SandboxContext then return Model end

function SandboxChoices.Build(block, nodeID, choice, context, categoryNodeID)
    local runtime = {}
    local function eligible()
        return Selector.IsChoiceEligible(block, nodeID, choice, context)
    end
    local function choiceText()
        local passed, reason = eligible()
        if passed then
            return SandboxContext.Text(block, choice.textKey, context)
        end
        local label = PsychopatzCore.Conversation.Text.Resolve(
            SandboxContext.Text(block, choice.textKey, context)
        )
        local reasonKey = choice.lockedReasonKey or reason
        local explanation = reasonKey and PsychopatzCore.Conversation.Text.Resolve(
            SandboxContext.Text(block, reasonKey, context)
        ) or tostring(reason or "gated")
        return { text = label .. " (" .. explanation .. ")" }
    end
    return {
        id = choice.id,
        text = choiceText,
        visible = true,
        enabled = function() return eligible() end,
        action = function(_, _, session)
            local result, reason = Model.ExecuteSandbox(
                block.id,
                nodeID,
                choice.id,
                context
            )
            runtime.result = result
            runtime.reason = reason
            if not result then return end
            context.relationship = H.Copy(result.after.relationship)
            context.historyEntry = context.historyEntry or { useCount = 0 }
            context.historyEntry.useCount =
                (tonumber(context.historyEntry.useCount) or 0) + 1
            context.historyEntry.lastUsedWorldHour = context.worldAgeHours
            context.historyEntry.lastOutcomeID = result.outcomeID
            context.historySlot = context.historyEntry.useCount
            Model.lastSandbox = H.Copy(result)
            SandboxContext.UpdateRelationship(session, context)
        end,
        response = function()
            if runtime.result and runtime.result.responseKey then
                return SandboxContext.Text(
                    block,
                    runtime.result.responseKey,
                    context
                )
            end
            if runtime.reason then
                return { text = "Sandbox rejected: " .. tostring(runtime.reason) }
            end
            return nil
        end,
        next = function()
            if not runtime.result then
                return SandboxContext.BlockNodeID(block.id, nodeID)
            end
            local nextNodeID = runtime.result.nextNodeID
            if nextNodeID and nextNodeID ~= "$root" then
                return SandboxContext.BlockNodeID(block.id, nextNodeID)
            end
            return categoryNodeID
        end,
        close = false,
    }
end

H.SandboxChoices = SandboxChoices

return Model
