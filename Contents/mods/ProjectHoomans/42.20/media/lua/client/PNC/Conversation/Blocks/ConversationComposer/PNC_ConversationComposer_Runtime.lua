require "PNC/Conversation/Blocks/PNC_ConversationTextLoader"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Conversation = PNC.Conversation
local Composer = Conversation.Composer or {}
Conversation.Composer = Composer
Composer.Internal = Composer.Internal or {}
local Internal = Composer.Internal
local Registry = Conversation.Registry
local Selector = Conversation.Selector
local Rules = Conversation.Rules
local Loader = Conversation.TextLoader
local Relationship = Conversation.Relationship
local Diary = Conversation.Diary
Composer.requestSerial = tonumber(Composer.requestSerial) or 0
Composer.localRequests = Composer.localRequests or {}

local SYSTEM_SOURCE = {
    modID = "ProjectHoomans",
    pathPattern = "media/conversation/system/shared/{language}/categories.json",
    domain = "pnc.system.shared.categories",
}
local function activeView(npcID)
    local view = PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.instance or nil
    if view and tostring(view.spec and view.spec.npcID or "")
        == tostring(npcID or "")
    then return view end
    return nil
end
local function payload(source, key, args)
    return Loader.Payload(source, key, args)
end

local function dialoguePayload(source, key, context, args)
    local merged = {}
    for name, value in pairs(context and context.textArgs or {}) do
        merged[name] = value
    end
    for name, value in pairs(type(args) == "table" and args or {}) do
        merged[name] = value
    end
    return payload(source, key, merged)
end

local function resolvedDialogue(value)
    if not value then return nil end
    local text = PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.Text or nil
    return text and text.Resolve and text.Resolve(value) or tostring(value)
end

local function appendDiary(npcID, entry)
    if Diary and Diary.Append then
        return Diary.Append(npcID, entry)
    end
    return false
end

local function receiveRelationshipAfter(npcID, after, delta, metadata)
    if type(after) ~= "table" then return false end
    local summary = {
        npcID = npcID,
        exists = true,
        approval = after.approval,
        respect = after.respect,
        familiarity = after.familiarity,
        state = after.state,
        previousState = after.previousState,
        revision = after.revision,
    }
    if Relationship and Relationship.ReceivePresentation then
        Relationship.ReceivePresentation(summary, delta, metadata)
    end
    local view = activeView(npcID)
    local context = view and view.spec and view.spec.context
        and view.spec.context.conversationBlockContext or nil
    if context then
        context.relationship = summary
        context.relationshipState = summary.state
    end
    return true
end

local function ensureBlockText(block)
    return Loader.EnsureSource(
        block.textSource,
        Registry.CollectTextKeys(block)
    )
end

local function conversationDebugEnabled()
    return PNC.Client and PNC.Client.CanUseDebug
        and PNC.Client.CanUseDebug() == true
end

local function selectedTextKey(block, nodeID, node, context)
    if node.textKey then return node.textKey end
    local values = node.textKeys or {}
    if #values == 0 then return nil end
    local seed = Selector.Seed(
        context,
        table.concat({ "node_text", block.id, nodeID }, ":")
    )
    return values[seed % #values + 1]
end

local function requestID(prefix)
    Composer.requestSerial = Composer.requestSerial + 1
    return table.concat({ prefix, Composer.requestSerial,
        getTimeInMillis and getTimeInMillis() or 0 }, ":")
end

local function lifecycleState(view)
    return view and view.spec and view.spec.context
        and view.spec.context.conversationLifecycleState or nil
end

local function sendRequest(command, payloadValue)
    if isClient and isClient() == true then
        if not sendClientCommand then return false, "transport_unavailable" end
        sendClientCommand(PNC.Const.MODULE, command, payloadValue)
        return true
    end
    local authority = Conversation.Authority
    local player = getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer() or nil
    if authority then
        Composer.localRequests[#Composer.localRequests + 1] = {
            command = command,
            payload = payloadValue,
            player = player,
        }
        return true
    end
    return false, "authority_unavailable"
end

local function restoreCurrentChoices(view)
    local session = view and view.session
    if session and session.currentNode then
        session:setChoices(session.currentNode.choices or {})
    end
end

local function notifyFailure(view, key, reason)
    if view and view.spec and view.spec.context then
        view.spec.context.lastConversationError = tostring(reason or "unavailable")
    end
    local value = PsychopatzCore.Conversation.Text.Resolve(payload(
        SYSTEM_SOURCE,
        key,
        { reason = tostring(reason or "unavailable") }
    ))
    -- A rejected authoritative request is part of the conversation.  Keep it
    -- in the log as well as the transient halo so a failed recruit, stale
    -- lease, or inventory action is never indistinguishable from a blank UI.
    local session = view and view.session
    if session and session.append then
        session:append("npc", payload(
            SYSTEM_SOURCE,
            key,
            { reason = tostring(reason or "unavailable") }
        ))
    end
    local player = getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer() or nil
    if player and HaloTextHelper and HaloTextHelper.addText then
        HaloTextHelper.addText(player, value)
    end
    if PNC.Core and PNC.Core.LogWarn then
        PNC.Core.LogWarn("Conversation request rejected: "
            .. tostring(reason or "unavailable"))
    end
    restoreCurrentChoices(view)
end

local function rememberCategoryUse(context, categoryID, outcomeID)
    if type(context) ~= "table" or not categoryID then return false end
    local history = PNC.Network and PNC.Network.ClientState
        and PNC.Network.ClientState.conversationHistory or nil
    if type(history) ~= "table" then return false end
    local npcID = tostring(context.npcID or "")
    local subject = "category:" .. tostring(categoryID)
    history[npcID] = history[npcID] or {}
    local previous = history[npcID][subject] or { useCount = 0 }
    previous.useCount = (tonumber(previous.useCount) or 0) + 1
    previous.lastUsedWorldHour = context.worldAgeHours
    previous.lastOutcomeID = outcomeID
    history[npcID][subject] = previous
    return true
end


Internal.SYSTEM_SOURCE = SYSTEM_SOURCE
Internal.ActiveView = activeView
Internal.Payload = payload
Internal.DialoguePayload = dialoguePayload
Internal.ResolvedDialogue = resolvedDialogue
Internal.AppendDiary = appendDiary
Internal.ReceiveRelationshipAfter = receiveRelationshipAfter
Internal.EnsureBlockText = ensureBlockText
Internal.ConversationDebugEnabled = conversationDebugEnabled
Internal.SelectedTextKey = selectedTextKey
Internal.RequestID = requestID
Internal.LifecycleState = lifecycleState
Internal.SendRequest = sendRequest
Internal.RestoreCurrentChoices = restoreCurrentChoices
Internal.NotifyFailure = notifyFailure
Internal.RememberCategoryUse = rememberCategoryUse

return Composer
