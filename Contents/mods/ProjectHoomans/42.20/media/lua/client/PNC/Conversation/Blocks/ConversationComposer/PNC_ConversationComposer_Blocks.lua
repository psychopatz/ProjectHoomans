local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Selector = Conversation.Selector
local Internal = Composer.Internal

local dialoguePayload = Internal.DialoguePayload
local ensureBlockText = Internal.EnsureBlockText
local selectedTextKey = Internal.SelectedTextKey

local TopicCatalog = PNC.Semantics and PNC.Semantics.TopicCatalog
if type(TopicCatalog) ~= "table" then
    pcall(require, "PNC/Semantics/PNC_SemanticTopicCatalog")
    TopicCatalog = PNC.Semantics and PNC.Semantics.TopicCatalog
end

local function syncSemanticTopic(spec, topic)
    if not topic or type(spec) ~= "table" then return false end
    local conversation = PsychopatzCore and PsychopatzCore.Conversation
    local view = conversation and conversation.instance or nil
    local viewSpec = view and view.spec or nil
    if not view or not viewSpec
        or tostring(viewSpec.npcID or "") ~= tostring(spec.npcID or "")
    then
        return false, "conversation_unavailable"
    end
    local state = view.session and view.session.semanticDialogueState or nil
    if not state or type(state.SetTopic) ~= "function" then
        return false, "semantic_state_unavailable"
    end
    return state:SetTopic(topic)
end

local function lockedText(block, choice, reason, context)
    local key = choice.lockedReasonKey or reason
    if not key then
        return dialoguePayload(block.textSource, choice.textKey, context)
    end
    local text = PsychopatzCore.Conversation.Text
    local label = text.Resolve(dialoguePayload(
        block.textSource, choice.textKey, context
    ))
    local explanation = text.Resolve(dialoguePayload(
        block.textSource, key, context
    ))
    return { text = label .. " (" .. explanation .. ")" }
end

function Composer.BuildBlockNode(block, nodeID, context)
    local node = block.nodes[nodeID]
    if not node then return nil end
    local choices = {}
    for _, choice in ipairs(node.choices or {}) do
        local passed, reason = Selector.IsChoiceEligible(
            block, nodeID, choice, context
        )
        local mode = choice.lockedMode or "hidden"
        if passed or mode == "disabled" then
            local selectedChoice = choice
            choices[#choices + 1] = {
                id = selectedChoice.id,
                text = passed
                    and dialoguePayload(
                        block.textSource,
                        selectedChoice.textKey,
                        context
                    )
                    or lockedText(block, selectedChoice, reason, context),
                enabled = passed,
                action = passed and function()
                    Composer.RequestChoice(
                        context.npcID,
                        block.id,
                        nodeID,
                        selectedChoice.id
                    )
                end or nil,
            }
        end
    end
    return {
        npc = dialoguePayload(
            block.textSource,
            selectedTextKey(block, nodeID, node, context),
            context
        ),
        choices = choices,
    }
end

function Composer.AttachBlock(spec, block, context)
    local valid, errors = ensureBlockText(block)
    if not valid then return false, errors end
    spec.context.activeConversationBlockID = block.id
    local topic = TopicCatalog
        and type(TopicCatalog.AuthoredTopic) == "function"
        and TopicCatalog.AuthoredTopic(block) or nil
    if topic then
        -- Keep the authored topic in both projections. The presentation
        -- context feeds the provider payload; the block context feeds local
        -- semantic input after a menu-selected block is attached.
        spec.context.conversationTopic = topic
        if type(context) == "table" then
            context.conversationTopic = topic
        end
        syncSemanticTopic(spec, topic)
    end
    for nodeID in pairs(block.nodes) do
        spec.nodes["block:" .. nodeID] = Composer.BuildBlockNode(
            block, nodeID, context
        )
    end
    return true, "block:" .. block.entryNode
end


return Composer
