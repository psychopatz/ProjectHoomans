-- Active-view refresh callbacks for asynchronous conversation receipts.

local Conversation = PNC.Conversation
local Relationship = Conversation.Relationship
local Composer = Conversation.Composer
local Registry = Conversation.Registry

local Internal = Conversation.DefinitionLifecycleInternal
    or {}
Conversation.DefinitionLifecycleInternal = Internal

local function refreshForNPC(npcID)
    local view = PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.instance or nil
    if not view or tostring(npcID or "") ~= tostring(view.spec and view.spec.npcID) then
        return false
    end
    local context = view.spec and view.spec.context or {}
    if not context.entry then return false end
    -- Headless Semantic Lab sessions provide the same live session contract
    -- but intentionally omit the native UI definition builder. The receipt
    -- still records the authoritative disclosure and knowledge snapshot;
    -- refreshing a missing UI definition must not turn that receipt into a
    -- client error.
    if type(Conversation.BuildDefinition) ~= "function" then return false end
    local updated = Conversation.BuildDefinition(
        context.entry, context.player, context.conversationTimeID
    )
    local updatedContext = updated.context or {}
    for _, key in ipairs({
        "conversationLifecycleState",
        "pendingConversationRequest",
        "pendingConversationAutoChoice",
        "activeConversationBlockID",
        "lastConversationError",
        "semanticSuggestionGroupID",
    }) do
        if context[key] ~= nil then updatedContext[key] = context[key] end
    end
    updated.context = updatedContext
    updated.lifecycle = view.spec.lifecycle or updated.lifecycle
    local activeBlockID = context.activeConversationBlockID
    local activeBlock = activeBlockID and Registry.GetBlock(activeBlockID) or nil
    if activeBlock then
        Composer.AttachBlock(
            updated,
            activeBlock,
            updatedContext.conversationBlockContext
        )
    end
    if not view.refreshConversationSpec
        or view:refreshConversationSpec(updated) ~= true
    then
        return false
    end
    local input = PNC.Semantics and PNC.Semantics.DialogueInput or nil
    local internal = input and input.Internal or nil
    if internal and type(internal.RefreshRootSuggestions) == "function" then
        internal.RefreshRootSuggestions(view)
    end
    -- Core refreshes the session and portrait, while extension parts are
    -- owned by this integration. Keep the live relationship graph in sync
    -- when its authoritative presentation arrives after the window opened.
    for _, extension in ipairs(updated.extensionParts or {}) do
        local part = view.extensionParts
            and view.extensionParts[extension.partID] or nil
        if part and extension.partID == "relationship"
            and part.setRelationship
        then
            part:setRelationship(extension.relationship)
        end
    end
    return true
end

Internal.RefreshForNPC = refreshForNPC

-- Relationship receipt is composed before this definition. Register the
-- narrow active-view refresh callback so receipt does not call back into the
-- whole Conversation definition module.
if type(Relationship.SetConversationRefreshHandler) == "function" then
    Relationship.SetConversationRefreshHandler(refreshForNPC)
end

function Conversation.ReceiveKnowledgeSnapshot(snapshot)
    return snapshot and refreshForNPC(snapshot.npcID) or false
end

function Conversation.ReceiveIdentityPresentation(presentation)
    return presentation and refreshForNPC(presentation.npcID) or false
end
