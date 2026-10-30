-- Build 42.20 conversation lifecycle implementation.
require "PNC/Conversation/PNC_ConversationSafety"
require "PNC/Conversation/PNC_ConversationFarewell"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Lifecycle = PNC.Conversation.Lifecycle or {}
PNC.Conversation.Lifecycle = Lifecycle
local Safety = PNC.Conversation.Safety
local Farewell = PNC.Conversation.Farewell
local Scene = PNC.ConversationScene
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

Lifecycle.Internal = Lifecycle.Internal or {}
local H = Lifecycle.Internal
H.IsNetworkClient = isNetworkClient
H.Send = send
H.Safety = Safety
H.Farewell = Farewell
H.Scene = Scene

require "PNC/Conversation/PNC_ConversationLifecycle_Support"
require "PNC/Conversation/PNC_ConversationLifecycle_Create_Begin"
require "PNC/Conversation/PNC_ConversationLifecycle_Create_Update"
require "PNC/Conversation/PNC_ConversationLifecycle_Close"

function Lifecycle.Create()
    return {
        begin = H.CreateBegin,
        update = H.CreateUpdate,
        finish = Lifecycle.Finish,
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
