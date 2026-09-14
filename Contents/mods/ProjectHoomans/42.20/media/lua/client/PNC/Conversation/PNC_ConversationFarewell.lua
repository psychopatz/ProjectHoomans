-- Client-only farewell exchange for ordinary conversation closes.
--
-- This is presentation-only. The server relationship summary is read locally;
-- no farewell event, random roll, or text is sent back to the server.

pcall(require, "PsychopatzCore/Conversation/PsychopatzSocialFlavorClient")
require "PsychopatzCore/Conversation/PsychopatzSocialFlavor"
require "PNC/Conversation/PNC_SocialFlavorDefinitions"
require "PNC/Audio/PNC_PlayerSpeech"
require "PNC/Conversation/PNC_ConversationFarewellContext"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Farewell = PNC.Conversation.Farewell or {}
PNC.Conversation.Farewell = Farewell

local pending = {}
local recent = {}
local Context = PNC.Conversation.FarewellContext

Farewell.CHANCE_PERCENT = Farewell.CHANCE_PERCENT or 55
Farewell.NPC_DELAY_MS = Farewell.NPC_DELAY_MS or 1900
Farewell.COOLDOWN_MS = Farewell.COOLDOWN_MS or 12000
Farewell.PENDING_TTL_MS = Farewell.PENDING_TTL_MS or 7000

local function clean(value, fallback)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value ~= "" and value or fallback
end

local function socialClient()
    local client = PsychopatzCore and PsychopatzCore.SocialFlavorClient
    if client then return client end
    local ok, loaded = pcall(
        require,
        "PsychopatzCore/Conversation/PsychopatzSocialFlavorClient"
    )
    return ok and loaded or PsychopatzCore
        and PsychopatzCore.SocialFlavorClient or nil
end

local function socialFlavor()
    return PsychopatzCore and PsychopatzCore.SocialFlavor or nil
end

local function now()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now()
        or getTimeInMillis and getTimeInMillis() or 0
end

Farewell.ResolveSocialRole = Context.ResolveSocialRole

local function activeFor(npcID)
    local conversation = PsychopatzCore and PsychopatzCore.Conversation
    local view = conversation and conversation.instance or nil
    return view and view.spec
        and tostring(view.spec.npcID or "") == tostring(npcID or "")
end

local function removePending(npcID)
    local index
    for index = #pending, 1, -1 do
        if pending[index].npcID == npcID then
            table.remove(pending, index)
        end
    end
end

function Farewell.RollChance(percent)
    local roll = ZombRand and ZombRand(100) or math.random(0, 99)
    return roll < (tonumber(percent) or Farewell.CHANCE_PERCENT)
end

local function eligibleReason(reason)
    reason = tostring(reason or "closed")
    return reason ~= "danger"
        and reason ~= "npc_unavailable"
        and reason ~= "nameplate_fallback"
        and reason ~= "lifecycle_error"
        and reason ~= "replaced"
        and reason ~= "headless_closed"
        and reason ~= "conversation_opened"
        and reason ~= "conversation_handoff"
        and reason ~= "retargeted"
        and reason ~= "message_submitted"
        and reason ~= "conversation_interrupted"
        and reason ~= "bridge_disabled"
end

local function deliver(item, current)
    local client = socialClient()
    if not client or type(client.Enqueue) ~= "function" then
        return false, "social_client_unavailable"
    end
    local accepted, enqueueReason = client.Enqueue({
        eventID = item.eventID,
        flavorID = "social.conversation_farewell",
        family = "conversation_farewell",
        priority = 100,
        weight = 1,
        speakerID = item.npcID,
        speakerName = item.context.npcFullName,
        speakerKind = "npc",
        playerUUID = item.playerID,
        context = item.context,
        seed = item.seed,
        llmEligible = false,
        memoryEligible = false,
        ttlMs = 4500,
        holdMs = 4500,
        cooldowns = { ambientMs = 0, familyMs = 0, speakerMs = 0 },
        mergeKey = "conversation-farewell:" .. item.npcID,
        presentationState = {
            nameplate = true,
            conversationUI = false,
            interrupt = false,
            tts = true,
        },
        source = {
            kind = "conversation_farewell",
            eventType = "conversation_farewell",
            socialRole = item.role,
            contextEligible = false,
        },
    })
    if accepted == true then
        recent[item.npcID] = current + Farewell.COOLDOWN_MS
    end
    return accepted, enqueueReason
end

function Farewell.Schedule(spec, state, reason)
    local context = spec and spec.context or {}
    local npcID = clean(spec and spec.npcID or state and state.npcID, nil)
    local current = now()
    local role
    local farewellContext
    local player
    local playerID
    local seed
    local playerText
    if not state or state.farewellEvaluated then
        return false, "already_evaluated"
    end
    state.farewellEvaluated = true
    if not npcID or not eligibleReason(reason) then
        return false, "ineligible_close"
    end
    if recent[npcID] and current < recent[npcID] then
        return false, "cooldown"
    end
    if not Farewell.RollChance(Farewell.CHANCE_PERCENT) then
        return false, "chance"
    end
    role = Context.ResolveSocialRole(spec)
    farewellContext, player, playerID = Context.Build(spec, role, npcID)
    seed = "conversation-farewell:" .. npcID .. ":"
        .. tostring(state.token or current)
    local flavor = socialFlavor()
    playerText = flavor and flavor.Resolve
        and flavor.Resolve(
            "social.conversation_farewell",
            "player",
            seed,
            farewellContext
        ) or nil
    if playerText and player then
        PNC.PlayerSpeech.Speak(player, playerText, {
            commandID = "conversation_farewell",
            eventID = seed .. ":player",
            target = nil,
            targets = {},
            suppressSocialReaction = true,
        })
    end
    removePending(npcID)
    pending[#pending + 1] = {
        npcID = npcID,
        playerID = playerID,
        role = role,
        context = farewellContext,
        seed = seed,
        dueAt = current + Farewell.NPC_DELAY_MS,
        expiresAt = current + Farewell.PENDING_TTL_MS,
        eventID = seed .. ":npc",
    }
    return true, "scheduled"
end

function Farewell.Pump(current)
    current = tonumber(current) or now()
    local index
    local item
    for index = #pending, 1, -1 do
        item = pending[index]
        if current >= item.dueAt then
            table.remove(pending, index)
            if current <= item.expiresAt and not activeFor(item.npcID) then
                deliver(item, current)
            end
        end
    end
end

function Farewell.Reset()
    pending = {}
    recent = {}
    return true
end

if Events and Events.OnTick and Events.OnTick.Add
    and not Farewell.TickRegistered
then
    Events.OnTick.Add(function() Farewell.Pump() end)
    Farewell.TickRegistered = true
end

return Farewell
