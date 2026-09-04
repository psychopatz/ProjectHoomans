-- Core-backed delivery adapter for command and interactive-emote speech.
--
-- This module owns only queue admission and delivery.  Outcome policy lives
-- in PNC_CompanionCommandInteraction.lua.

PNC = PNC or {}
PNC.CompanionCommandPresentation = PNC.CompanionCommandPresentation or {}

require "PNC/Knowledge/PNC_NPCIdentityPresentation"
pcall(require, "PsychopatzCore/Conversation/PsychopatzSocialFlavorClient")
pcall(require, "PsychopatzCore/Events/PC_EventBus")

local Presentation = PNC.CompanionCommandPresentation
local Flavor = PNC.CompanionCommandFlavor
local Identity = PNC.NPCIdentityPresentation
local Registry = PNC.Registry
local SocialFlavorClient = PsychopatzCore
    and PsychopatzCore.SocialFlavorClient or nil
local EventBus = PsychopatzCore and PsychopatzCore.Events or nil

Presentation.INTERACTION_PRIORITY = Presentation.INTERACTION_PRIORITY or 100
Presentation.INTERACTION_WEIGHT = Presentation.INTERACTION_WEIGHT or 100

local function speak(actor, text)
    if not actor or not text or text == "" then return false end
    if actor.Say then
        actor:Say(text)
        return true
    end
    if actor.setHaloNote then
        actor:setHaloNote(text, 255, 255, 255, 300)
        return true
    end
    return false
end

local function targetName(target)
    return Identity.GetName(target or { recruited = true })
end

local function currentTime()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

local function playerID(player)
    if not player then return nil end
    if player.getUsername then
        local username = tostring(player:getUsername() or "")
        if username ~= "" then return username end
    end
    if player.getOnlineID then
        local onlineID = tostring(player:getOnlineID() or "")
        if onlineID ~= "" then return onlineID end
    end
    return nil
end

local function interactionEventID(flavorID, speaker, speakerID, context,
    options)
    local base = options.eventID
        or type(context) == "table" and (context.eventID
            or context.requestID)
        or nil
    if not base or tostring(base) == "" then
        base = tostring(flavorID or "flavor") .. ":"
            .. tostring(currentTime())
    end
    return tostring(base) .. ":" .. tostring(speaker or "npc") .. ":"
        .. tostring(speakerID or "unknown")
end

local function deliverPlayerSpeech(text)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player then return false end
    -- Core already published the canonical queued message.  Say() is the
    -- local visual sink; routing it through PlayerSpeech again would publish
    -- a duplicate voice/message event.
    return speak(player, text)
end

local function onFlavorDelivered(payload)
    local item = payload and payload.item or nil
    local text = payload and payload.text or nil
    if not text or text == "" then return end
    if item and item.speakerKind == "player" then
        deliverPlayerSpeech(text)
    elseif item and Registry and Registry.GetLiveZombie then
        speak(Registry.GetLiveZombie(item.speakerID), text)
    end
end

-- Queue one line through Core.  Interaction priority is deliberately the top
-- priority class; weight remains the tie-breaker among equally urgent lines.
function Presentation.EnqueueFlavor(flavorID, speaker, actor, context, options)
    local player = type(context) == "table" and context.playerActor
        or speaker == "player" and actor
        or getSpecificPlayer and getSpecificPlayer(0) or nil
    local speakerID = speaker == "player" and playerID(player)
        or type(context) == "table" and (context.npcID
            or context.target and (context.target.id or context.target.npcID))
        or actor and actor.getModData and actor:getModData().PNC_UUID
        or nil
    local flavorContext
    local seed
    local text
    local eventID
    local accepted
    local reason
    local queueContext
    local source
    local presentationState
    options = type(options) == "table" and options or {}
    speaker = tostring(speaker or "npc")
    if speakerID == nil or tostring(speakerID) == "" then
        return false, "speaker_identity_unavailable"
    end
    flavorContext = Presentation.BuildFlavorContext(player, context)
    seed = options.seed
        or type(context) == "table" and (context.seed
            or context.requestID or context.eventID)
        or tostring(currentTime())
    text = Flavor and Flavor.Resolve
        and Flavor.Resolve(flavorID, speaker, seed, flavorContext)
        or nil
    if not text or text == "" then return false, "flavor_unavailable" end
    eventID = interactionEventID(flavorID, speaker, speakerID, context,
        options)
    SocialFlavorClient = SocialFlavorClient
        or PsychopatzCore and PsychopatzCore.SocialFlavorClient or nil
    if not SocialFlavorClient
        or type(SocialFlavorClient.Enqueue) ~= "function"
    then
        if speaker == "player" then
            return speak(player, text), "presented", text, eventID
        end
        return speak(actor, text), "presented", text, eventID
    end
    queueContext = {
        name = flavorContext.name,
        names = flavorContext.names,
        count = flavorContext.count,
        player = flavorContext.player,
    }
    source = {
        kind = "emote_interaction",
        channel = "player_npc_interaction",
        commandID = type(context) == "table" and context.commandID or nil,
        origin = type(context) == "table" and context.origin or nil,
        contextEligible = false,
    }
    presentationState = {
        conversationUI = false,
        nameplate = speaker == "npc" and not actor,
        tts = speaker == "player",
    }
    accepted, reason = SocialFlavorClient.Enqueue({
        eventID = eventID,
        flavorID = flavorID,
        seed = seed,
        text = text,
        family = options.family or "emote_interaction",
        priority = tonumber(options.priority)
            or Presentation.INTERACTION_PRIORITY,
        weight = tonumber(options.weight)
            or Presentation.INTERACTION_WEIGHT,
        speakerID = tostring(speakerID),
        speakerKind = speaker,
        speakerName = speaker == "player"
            and tostring(player and player.getUsername
                and player:getUsername() or speakerID)
            or targetName(type(context) == "table" and context.target or {}),
        playerUUID = playerID(player),
        context = queueContext,
        presentationState = presentationState,
        source = source,
        ttlMs = 15000,
        holdMs = 1200,
    })
    return accepted == true, reason, text, eventID
end

if EventBus and SocialFlavorClient and SocialFlavorClient.EVENT_DELIVERED
    and EventBus.subscribe
then
    EventBus.clearOwner(Presentation)
    EventBus.subscribe(
        SocialFlavorClient.EVENT_DELIVERED,
        onFlavorDelivered,
        Presentation
    )
end

return Presentation
