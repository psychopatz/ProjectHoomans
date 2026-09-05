-- Build 42.20 conversation lifecycle implementation.
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

local function isNameplateConversation(spec)
    return spec and spec.context
        and spec.context.nameplateConversation == true
end

local function isHostileConversation(spec)
    local context = spec and spec.context or {}
    local entry = context.entry or {}
    local snapshot = entry.snapshot or {}
    local entryRecord = entry.record or {}
    local hostility = snapshot.hostility or entryRecord.hostility or {}
    if hostility.attackPlayers == true then return true end
    local _, _, record = Safety.ResolveActors(spec)
    return record and record.hostility
        and record.hostility.attackPlayers == true or false
end

local function requestNameplateFallback(view, spec, reason)
    if isNameplateConversation(spec) or not isHostileConversation(spec) then
        return false
    end
    local integration = PNC.HoomansLLM
    if not integration or not integration.RequestInlineFallback then
        return false
    end
    local context = spec and spec.context or {}
    local entry = context.entry or {
        id = spec and spec.npcID,
        zombie = spec and spec.character,
    }
    return integration.RequestInlineFallback(entry, reason, view) == true
end

local function send(command, state, reason, extra)
    if not sendClientCommand or not Scene then return false end
    local payload = {
        id = state.npcID,
        token = state.token,
        reason = reason,
        maximumDistance = Safety.GetMaximumDistance(),
        dangerRadius = Safety.GetDangerRadius(),
        -- Distance is an opening gate only. Once the lease exists, movement
        -- and the compact UI must not end the conversation.
        enforceDistance = state.enforceDistance == true
            and state.started ~= true,
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
                enforceDistance = state.enforceDistance == true
                    and state.started ~= true,
                allowHostileParley = state.allowHostileParley == true,
            }
        )
        or false
end

function Lifecycle.Create()
    return {
        begin = function(view, spec)
            if requestNameplateFallback(
                view,
                spec,
                "hostile_nameplate_fallback"
            ) then
                return false, "nameplate_fallback"
            end
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
                enforceDistance = not isNameplateConversation(spec),
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
        end,
        update = function(view, spec, state)
            if not state then return "npc_unavailable" end
            if requestNameplateFallback(
                view,
                spec,
                "hostile_nameplate_fallback"
            ) then
                return "nameplate_fallback"
            end
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
            if PNC.Core and PNC.Core.LogInfo then
                PNC.Core.LogInfo(table.concat({
                    "Conversation closed",
                    "npc=" .. tostring(state and state.npcID
                        or spec and spec.npcID or "unknown"),
                    "token=" .. tostring(state and state.token or "none"),
                    "reason=" .. tostring(reason or "closed"),
                }, " "))
            end
            if not state then return end
            if isNetworkClient() then
                send(Scene.CMD_END, state, reason, {
                    llmRequestID = state and state.llmRequestID or nil,
                })
                return
            end
            local _, zombie, record = Safety.ResolveActors(spec)
            if Scene and Scene.End then
                Scene.End(
                    record,
                    zombie,
                    state.token,
                    "conversation_" .. tostring(reason or "closed"),
                    {
                        llmRequestID = state and state.llmRequestID or nil,
                        player = spec and spec.context and spec.context.player,
                    }
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
