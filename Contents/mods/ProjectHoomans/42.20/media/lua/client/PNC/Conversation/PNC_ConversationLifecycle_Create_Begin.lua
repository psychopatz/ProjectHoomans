-- Client-side conversation lifecycle begin provider.

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.Lifecycle = PNC.Conversation.Lifecycle or {}
local Lifecycle = PNC.Conversation.Lifecycle
local H = Lifecycle.Internal or {}
local Safety = H.Safety
local currentTime = H.CurrentTime
local isNetworkClient = H.IsNetworkClient
local isNameplateConversation = H.IsNameplateConversation
local requestNameplateFallback = H.RequestNameplateFallback
local refresh = H.Refresh
local logAvailability = H.LogAvailability

local function begin(view, spec)
    if requestNameplateFallback(
        view,
        spec,
        "hostile_nameplate_fallback"
    ) then
        return false, "nameplate_fallback"
    end
    local reason = Safety.Check(spec)
    if reason then
        if reason == "npc_unavailable"
            and isNameplateConversation(spec)
        then
            logAvailability(nil, spec, reason)
        end
        return false, reason
    end
    local _, _, _, npcID = Safety.ResolveActors(spec)
    local state = {
        npcID = npcID,
        token = tostring(npcID)
            .. ":"
            .. tostring(currentTime())
            .. ":"
            .. tostring(ZombRand and ZombRand(1000000) or 0),
        lastHeartbeatAt = 0,
        nextSafetyCheckAt = 0,
        cachedSafetyReason = nil,
        allowHostileParley = spec and spec.context
            and spec.context.allowHostileParley == true,
        enforceDistance = not isNameplateConversation(spec),
        guardThreats = Safety.GuardsThreats(spec),
        started = false,
    }
    local started, startReason = refresh(state, spec)
    if not isNetworkClient() and started ~= true then
        return false, startReason or "npc_unavailable"
    end
    state.started = true
    state.lastHeartbeatAt = currentTime()
    spec.context.conversationLifecycleState = state
    return state
end

H.CreateBegin = begin

return Lifecycle
