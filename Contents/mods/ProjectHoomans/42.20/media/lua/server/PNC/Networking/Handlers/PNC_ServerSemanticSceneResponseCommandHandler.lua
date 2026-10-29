-- Server-authoritative resume of a Scene that is explicitly waiting for a
-- participating player's semantic choice. Gameplay actions are not accepted.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}

local Router = PNC.ServerCommandRouter
local Const = PNC.Const
local Runtime = require "PNC/Semantics/PNC_SemanticInteractionSceneRuntime"
local Transport = require "PNC/Semantics/PNC_SemanticInteractionSceneTransport"

local function clean(value, maximum)
    value = tostring(value or "")
    if value == "" or string.find(value, "%c") then return nil end
    return string.sub(value, 1, maximum or 128)
end

local function playerKey(player)
    local characters = PNC.PlayerCharacters
    if not characters or type(characters.GetEntityKey) ~= "function" then
        return nil
    end
    return characters.GetEntityKey(player, {
        callback = "semantic_scene_response",
    })
end

local function boundedList(values, maximum)
    local output = {}
    local seen = {}
    for _, value in ipairs(type(values) == "table" and values or {}) do
        local item = clean(value, 128)
        if item and not seen[item] then
            output[#output + 1] = item
            seen[item] = true
            if #output >= (maximum or 8) then break end
        end
    end
    return output
end

local function semanticPayload(value)
    value = type(value) == "table" and value or {}
    if value.action ~= nil then
        return nil, "scene_player_action_unsupported"
    end
    local intent = clean(value.intent, 64)
    local speechAct = clean(value.speechAct or value.intent, 64)
    if not intent or not speechAct then
        return nil, "scene_player_semantic_act_required"
    end
    return {
        intent = intent,
        speechAct = speechAct,
        subject = clean(value.subject, 96),
        topic = clean(value.topic, 96),
        modifiers = type(value.modifiers) == "table"
            and value.modifiers or {},
        factRefs = boundedList(value.factRefs, 8),
        eventRefs = boundedList(value.eventRefs, 8),
    }
end

local function handle(player, args)
    args = type(args) == "table" and args or {}
    local sceneID = clean(args.sceneID, 128)
    local key = playerKey(player)
    if not sceneID or not key then
        return false, "scene_response_identity_required"
    end
    local semantic, semanticReason = semanticPayload(args.semantic)
    if not semantic then return false, semanticReason end

    local result, reason = Runtime.ResumePlayer(
        sceneID,
        key,
        tonumber(args.expectedSceneSequence),
        semantic
    )
    if not result then return false, reason end

    local scene = Runtime.Get(sceneID)
    if scene then
        Transport.Deliver(scene, result, {
            {
                player = player,
                actorID = key,
                role = "recipient",
            },
        })
        if result.continuation
            and result.continuation.mode == "terminate"
        then
            Runtime.Close(sceneID, "continuation_terminate")
        end
    end
    return true, "scene_response_accepted"
end

Router.Register(Const.CMD_SEMANTIC_SCENE_RESPONSE, handle)

return PNC
