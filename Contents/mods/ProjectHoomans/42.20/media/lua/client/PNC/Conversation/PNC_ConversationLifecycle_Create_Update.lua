-- Client-side conversation lifecycle update provider.

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.Lifecycle = PNC.Conversation.Lifecycle or {}
local Lifecycle = PNC.Conversation.Lifecycle
local H = Lifecycle.Internal or {}
local Safety = H.Safety
local currentTime = H.CurrentTime
local isNameplateConversation = H.IsNameplateConversation
local requestNameplateFallback = H.RequestNameplateFallback
local refresh = H.Refresh
local logAvailability = H.LogAvailability
local NAMEPLATE_UNAVAILABLE_GRACE_MS = H.NameplateUnavailableGraceMs

local function update(view, spec, state)
    if not state then return "npc_unavailable" end
    if requestNameplateFallback(
        view,
        spec,
        "hostile_nameplate_fallback"
    ) then
        return "nameplate_fallback"
    end
    local time = currentTime()
    local safetyChecked = false
    if time >= (tonumber(state.nextSafetyCheckAt) or 0) then
        state.nextSafetyCheckAt = time + 180
        state.cachedSafetyReason = Safety.Check(spec)
        safetyChecked = true
    end
    if safetyChecked
        and state.cachedSafetyReason == "npc_unavailable"
        and isNameplateConversation(spec)
    then
        if not state.unavailableSince then
            state.unavailableSince = time
        end
        logAvailability(state, spec, state.cachedSafetyReason)
        if time - state.unavailableSince
            < NAMEPLATE_UNAVAILABLE_GRACE_MS
        then
            state.cachedSafetyReason = nil
            return nil
        end
    elseif safetyChecked and state.unavailableSince then
        logAvailability(state, spec, "recovered")
        state.unavailableSince = nil
        state.lastAvailabilitySignature = nil
    end
    if state.cachedSafetyReason then
        return state.cachedSafetyReason
    end
    if time - (tonumber(state.lastHeartbeatAt) or 0) >= 1000 then
        refresh(state, spec)
        state.lastHeartbeatAt = time
    end
    return nil
end

H.CreateUpdate = update

return Lifecycle
