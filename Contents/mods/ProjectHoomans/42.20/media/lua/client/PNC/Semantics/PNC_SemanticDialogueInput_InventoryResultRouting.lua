-- Route inventory results to a live dialogue and retain bounded late results.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input

local InventoryResultRouting = {}

function InventoryResultRouting.ActiveView(payload)
    local candidates = {}
    local active = Input.ActiveView
    local activeGroup = active and active.groupConversation or nil
    if activeGroup and payload and payload.npcID
        and type(activeGroup.ViewFor) == "function"
    then
        local memberView = activeGroup:ViewFor(payload.npcID)
        if memberView and memberView.session
            and memberView.closed ~= true
            and memberView.lifecycleFinished ~= true
        then
            return memberView
        end
    end
    if active then candidates[#candidates + 1] = active end
    local conversation = PsychopatzCore and PsychopatzCore.Conversation
    local visible = conversation and conversation.instance or nil
    if visible and visible ~= active then
        candidates[#candidates + 1] = visible
    end
    for index = 1, #candidates do
        local view = candidates[index]
        local session = view and view.session or nil
        if view and session and view.closed ~= true
            and view.lifecycleFinished ~= true
        then
            if not payload or not payload.npcID
                or tostring(view.spec and view.spec.npcID or "")
                    == tostring(payload.npcID)
            then
                return view
            end
        end
    end
    return nil
end

local function copyValue(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 5 then return nil end
    local output = {}
    local key
    local item
    for key, item in pairs(value) do
        if type(key) ~= "function" and type(item) ~= "function" then
            output[key] = copyValue(item, depth + 1)
        end
    end
    return output
end

function InventoryResultRouting.CacheUnmatched(payload)
    local state = PNC.Network and PNC.Network.ClientState or nil
    if not state then return end
    state.semanticInventoryQueryResults =
        state.semanticInventoryQueryResults or {}
    state.semanticInventoryQueryResultOrder =
        state.semanticInventoryQueryResultOrder or {}
    local requestID = tostring(payload and payload.requestID or "")
    if requestID == "" then return end
    if state.semanticInventoryQueryResults[requestID] == nil then
        state.semanticInventoryQueryResultOrder[
            #state.semanticInventoryQueryResultOrder + 1] = requestID
    end
    state.semanticInventoryQueryResults[requestID] = copyValue(payload)
    while #state.semanticInventoryQueryResultOrder > 16 do
        local old = table.remove(state.semanticInventoryQueryResultOrder, 1)
        state.semanticInventoryQueryResults[old] = nil
    end
end

return InventoryResultRouting
