require "PNC/Conversation/PNC_ConversationSafety"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Lifecycle = PNC.Conversation.Lifecycle or {}
PNC.Conversation.Lifecycle = Lifecycle
local Safety = PNC.Conversation.Safety
local Scene = PNC.ConversationScene

local function currentTime()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now()
        or getTimeInMillis and getTimeInMillis()
        or 0
end

local function isNetworkClient()
    return isClient and isClient() == true
end

local function send(command, state, reason, extra)
    if not sendClientCommand or not Scene then return false end
    local payload = {
        id = state.npcID,
        token = state.token,
        reason = reason,
        maximumDistance = Safety.GetMaximumDistance(),
        dangerRadius = Safety.GetDangerRadius(),
        allowHostileParley = state.allowHostileParley == true,
    }
    if type(extra) == "table" then
        for key, value in pairs(extra) do
            payload[key] = value
        end
    end
    sendClientCommand(
        PNC.Const and PNC.Const.MODULE or "PNC",
        command,
        payload
    )
    return true
end

local function refresh(state, spec)
    local player, zombie, record = Safety.ResolveActors(spec)
    if isNetworkClient() then
        return send(Scene.CMD_BEGIN, state)
    end
    return Scene and Scene.Begin
        and Scene.Begin(
            record,
            zombie,
            player,
            state.token,
            {
                maximumDistance = Safety.GetMaximumDistance(),
                dangerRadius = Safety.GetDangerRadius(),
            }
        )
        or false
end

function Lifecycle.Create()
    return {
        begin = function(_, spec)
            local reason = Safety.Check(spec)
            if reason then return false, reason end
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
            }
            local started, startReason = refresh(state, spec)
            if not isNetworkClient() and started ~= true then
                return false, startReason or "npc_unavailable"
            end
            state.lastHeartbeatAt = currentTime()
            spec.context.conversationLifecycleState = state
            return state
        end,
        update = function(_, spec, state)
            if not state then return "npc_unavailable" end
            local time = currentTime()
            if time >= (tonumber(state.nextSafetyCheckAt) or 0) then
                state.nextSafetyCheckAt = time + 180
                state.cachedSafetyReason = Safety.Check(spec)
            end
            if state.cachedSafetyReason then
                return state.cachedSafetyReason
            end
            if time - (tonumber(state.lastHeartbeatAt) or 0) >= 1000 then
                refresh(state, spec)
                state.lastHeartbeatAt = time
            end
            return nil
        end,
        finish = function(_, spec, state, reason)
            if not state then return end
            if isNetworkClient() then
                send(Scene.CMD_END, state, reason)
                return
            end
            local _, zombie, record = Safety.ResolveActors(spec)
            if Scene and Scene.End then
                Scene.End(
                    record,
                    zombie,
                    state.token,
                    "conversation_" .. tostring(reason or "closed")
                )
            end
        end,
    }
end

function Lifecycle.RequestCeasefire(context)
    local state = context and context.conversationLifecycleState or nil
    if not state or not state.allowHostileParley then
        return false, "ceasefire_unavailable"
    end
    if isNetworkClient() then
        return send(Scene and Scene.CMD_CEASEFIRE, state)
    end
    return false, "server_only"
end

return Lifecycle
