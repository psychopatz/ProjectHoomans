-- Build 42.20 conversation lifecycle implementation.
require "PNC/Conversation/PNC_ConversationSafety"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Lifecycle = PNC.Conversation.Lifecycle or {}
PNC.Conversation.Lifecycle = Lifecycle
local Safety = PNC.Conversation.Safety
local Scene = PNC.ConversationScene
local NAMEPLATE_UNAVAILABLE_GRACE_MS = 3000

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
        guardThreats = state.guardThreats ~= false,
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
                guardThreats = state.guardThreats ~= false,
                allowHostileParley = state.allowHostileParley == true,
            }
        )
        or false
end

local function presentSafetyFeedback(spec, state, reason)
    if tostring(reason or "") ~= "danger" then return false end
    if state and state.guardThreats == false then return false end
    if not Safety.GuardsThreats(spec) then return false end
    local presentation = PNC.SocialFlavorPresentation
    if not presentation then
        local ok, loaded = pcall(
            require,
            "PNC/Conversation/PNC_SocialFlavorPresentation"
        )
        presentation = ok and loaded or PNC.SocialFlavorPresentation
    end
    return presentation
        and type(presentation.EnqueueConversationSafety) == "function"
        and presentation.EnqueueConversationSafety(spec, state, reason)
        or false
end

local function logAvailability(state, spec, reason)
    if not Safety or not Safety.DescribeAvailability then return end
    local details = Safety.DescribeAvailability(spec)
    local signature = table.concat({
        tostring(reason or "available"),
        tostring(details.liveBodyPresent),
        tostring(details.liveBodyAlive),
        tostring(details.registryBodyPresent),
        tostring(details.presenceBodyPresent),
        tostring(details.presenceBodyAlive),
        tostring(details.cachedBodyPresent),
        tostring(details.snapshotPresent),
        tostring(details.snapshotAlive),
        tostring(details.snapshotPosition),
        tostring(details.snapshotConversation),
        tostring(details.networkClient),
        tostring(details.presenceState),
        tostring(details.recordAlive),
        tostring(details.bodyLease),
        tostring(details.presenceRevision),
    }, "|")
    if state and state.lastAvailabilitySignature == signature then
        return
    end
    if state then state.lastAvailabilitySignature = signature end
    if not PNC.Core or not PNC.Core.LogInfo then return end
    PNC.Core.LogInfo(table.concat({
        "Inline availability",
        "npc=" .. tostring(details.npcID),
        "reason=" .. tostring(reason or "available"),
        "liveBody=" .. tostring(details.liveBodyPresent),
        "liveAlive=" .. tostring(details.liveBodyAlive),
        "registryBody=" .. tostring(details.registryBodyPresent),
        "presenceBody=" .. tostring(details.presenceBodyPresent),
        "presenceAlive=" .. tostring(details.presenceBodyAlive),
        "cachedBody=" .. tostring(details.cachedBodyPresent),
        "snapshot=" .. tostring(details.snapshotPresent),
        "snapshotAlive=" .. tostring(details.snapshotAlive),
        "snapshotPosition=" .. tostring(details.snapshotPosition),
        "snapshotAllowed=" .. tostring(details.snapshotConversation),
        "networkClient=" .. tostring(details.networkClient),
        "presence=" .. tostring(details.presenceState),
        "recordAlive=" .. tostring(details.recordAlive),
        "bodyLease=" .. tostring(details.bodyLease),
        "presenceRevision=" .. tostring(details.presenceRevision),
    }, " "))
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
        end,
        finish = function(_, spec, state, reason)
            presentSafetyFeedback(spec, state, reason)
            if PNC.Core and PNC.Core.LogInfo then
                PNC.Core.LogInfo(table.concat({
                    "Conversation closed",
                    "npc=" .. tostring(state and state.npcID
                        or spec and spec.npcID or "unknown"),
                    "token=" .. tostring(state and state.token or "none"),
                    "guardThreats=" .. tostring(not state
                        or state.guardThreats ~= false),
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
