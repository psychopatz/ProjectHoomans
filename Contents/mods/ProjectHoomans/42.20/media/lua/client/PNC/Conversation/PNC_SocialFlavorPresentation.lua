-- Project Hoomans adapter for the reusable PsychopatzCore social-flavor hub.
--
-- This module owns Hoomans relationship vocabulary and the two Hoomans
-- presentation sinks (conversation history and diary).  Arbitration remains
-- in Core so other mods can enqueue their own ambient events without knowing
-- anything about this UI.

require "PsychopatzCore/Conversation/PsychopatzSocialFlavorClient"
require "PsychopatzCore/Conversation/PsychopatzSocialFlavor"
require "PsychopatzCore/Conversation/PsychopatzNameParts"
require "PsychopatzCore/Events/PC_EventBus"
require "PNC/Conversation/PNC_ConversationDiary"
require "PNC/Conversation/PNC_SocialFlavorDefinitions"

PNC = PNC or {}
PNC.SocialFlavorPresentation = PNC.SocialFlavorPresentation or {}

local Presentation = PNC.SocialFlavorPresentation
local Client = PsychopatzCore.SocialFlavorClient
local EventBus = PsychopatzCore.Events
local Diary = PNC.Conversation.Diary
local NameParts = PsychopatzCore.Conversation.NameParts
local OWNER_TOKEN = Presentation

local function clean(value, fallback)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value ~= "" and value or fallback
end

local function log(event, details)
    if print then
        print("[PNC][SocialFlavor] " .. tostring(event) .. " "
            .. tostring(details or ""))
    end
end

local function currentPlayer()
    return getSpecificPlayer and getSpecificPlayer(0) or nil
end

local function playerIdentity()
    local state = PNC.Network and PNC.Network.ClientState or {}
    return NameParts.ForPlayer(currentPlayer(), state.playerContext)
end

local function playerUUID()
    local state = PNC.Network and PNC.Network.ClientState or {}
    local context = state.playerContext or {}
    return clean(context.characterUUID or context.playerUUID, nil)
end

local function npcName(npcID)
    local state = PNC.Network and PNC.Network.ClientState or {}
    local snapshot = state.snapshots and state.snapshots[tostring(npcID)] or nil
    local identity = PNC.NPCIdentityPresentation
    if identity and identity.GetName then
        return identity.GetName(snapshot or { id = npcID })
    end
    return clean(snapshot and (snapshot.name or snapshot.displayName), npcID)
end

local function npcIdentity(npcID, fallbackName)
    local state = PNC.Network and PNC.Network.ClientState or {}
    local snapshot = state.snapshots
        and state.snapshots[tostring(npcID)] or nil
    local identityPresentation = PNC.NPCIdentityPresentation
    local displayedName = npcName(npcID)
    if fallbackName and (
        not snapshot or displayedName == tostring(npcID or "")
    ) then
        return NameParts.Split(fallbackName, fallbackName, "")
    end
    if identityPresentation and identityPresentation.IsNameKnown
        and not identityPresentation.IsNameKnown(
            snapshot or { id = npcID }
        )
    then
        -- Do not leak transport-level forename/surname data before the
        -- player's identity knowledge says the name is known.
        return NameParts.Split(displayedName)
    end
    local identity = snapshot and snapshot.identity or {}
    local survivor = identity and identity.survivor or {}
    return NameParts.Split(
        displayedName,
        snapshot and (snapshot.forename or snapshot.firstName)
            or survivor and (survivor.forename or survivor.firstName),
        snapshot and (snapshot.surname or snapshot.lastName)
            or survivor and (survivor.surname or survivor.lastName)
    )
end

local function activeConversationFor(npcID)
    local conversation = PsychopatzCore and PsychopatzCore.Conversation
    local view = conversation and conversation.instance or nil
    local id = view and view.spec and view.spec.npcID or nil
    return view and tostring(id or "") == tostring(npcID or ""), view
end

function Presentation.Receive(ambientFlavor, summary, networkArgs)
    if type(ambientFlavor) ~= "table" then return false, "invalid_flavor" end
    local npcID = clean(
        ambientFlavor.npcID
            or networkArgs and networkArgs.npcID
            or summary and summary.npcID,
        nil
    )
    local eventID = clean(
        ambientFlavor.eventID
            or networkArgs and networkArgs.eventID,
        nil
    )
    if not npcID or not eventID then return false, "identity_required" end
    local role = clean(
        ambientFlavor.socialRole or ambientFlavor.npcType,
        "neutral"
    )
    local before = networkArgs and (
        networkArgs.relationshipBefore or networkArgs.before
    ) or nil
    local relationshipState = clean(
        ambientFlavor.relationshipState
            or before and (before.state or before.category)
            or summary and (summary.state or summary.category),
        "unknown"
    )
    local relationshipTier = clean(
        ambientFlavor.relationshipTier,
        "reserved"
    )
    local active, view = activeConversationFor(npcID)
    local context = type(ambientFlavor.context) == "table"
        and ambientFlavor.context or {}
    local speaker = npcIdentity(npcID)
    local player = playerIdentity()
    local victimID = clean(
        ambientFlavor.victimNPCID or context.victimNPCID,
        nil
    )
    local victim = victimID
        and npcIdentity(victimID, "your teammate") or nil
    context.npcType = context.npcType or role
    context.socialRole = context.socialRole or role
    context.relationshipState = context.relationshipState or relationshipState
    context.relationshipTier = context.relationshipTier or relationshipTier
    -- Full names remain available for identity-bearing UI, while ordinary
    -- dialogue aliases address people by their first name.
    context.name = speaker.addressName
    context.firstName = speaker.firstName
    context.surname = speaker.surname
    context.lastName = speaker.lastName
    context.speakerFullName = speaker.fullName
    context.speakerFirstName = speaker.firstName
    context.speakerSurname = speaker.surname
    context.speakerLastName = speaker.lastName
    context.player = player.addressName
    context.playerName = player.addressName
    context.playerFullName = player.fullName
    context.playerFirstName = player.firstName
    context.playerSurname = player.surname
    context.playerLastName = player.lastName
    if victim then
        context.victimNPCID = victimID
        context.victim = victim.addressName
        context.victimName = victim.addressName
        context.victimFullName = victim.fullName
        context.victimFirstName = victim.firstName
        context.victimSurname = victim.surname
        context.victimLastName = victim.lastName
    end
    context.count = 1
    local accepted, reason = Client.Enqueue({
        eventID = eventID,
        flavorID = ambientFlavor.flavorID
            or "social.witnessed_player_kill",
        family = ambientFlavor.family or "combat_commentary",
        priority = tonumber(ambientFlavor.priority) or 35,
        llmPriority = tonumber(ambientFlavor.llmPriority) or 90,
        weight = tonumber(ambientFlavor.weight) or 1,
        speakerID = npcID,
        -- Nameplates and history retain the NPC's full display identity.
        speakerName = speaker.fullName,
        playerUUID = playerUUID(),
        npcType = role,
        socialRole = role,
        relationshipState = relationshipState,
        relationshipTier = relationshipTier,
        context = context,
        seed = eventID,
        mergeKey = ambientFlavor.mergeKey
            or npcID .. ":" .. tostring(ambientFlavor.family or "ambient"),
        llmEligible = ambientFlavor.llmEligible ~= false,
        memoryEligible = ambientFlavor.memoryEligible == true,
        llmGraceMs = tonumber(ambientFlavor.llmGraceMs) or 2500,
        cooldowns = ambientFlavor.cooldowns,
        presentationState = {
            nameplate = not active,
            conversationUI = active,
            interrupt = false,
        },
        source = {
            kind = "social_flavor",
            eventType = ambientFlavor.eventType or "social_flavor",
            relationshipState = relationshipState,
            socialRole = role,
        },
    })
    log("received", "event=" .. eventID .. " npc=" .. npcID
        .. " role=" .. role .. " accepted=" .. tostring(accepted == true)
        .. " reason=" .. tostring(reason or ""))
    return accepted, reason
end

local function onDelivered(payload)
    if type(payload) ~= "table" then return end
    local item = payload.item or {}
    local message = payload.message
    local npcID = tostring(item.speakerID or "")
    if npcID == "" or type(message) ~= "table" then return end
    Diary.Append(npcID, {
        kind = "social_flavor",
        source = "social_flavor",
        eventType = item.context and item.context.eventType
            or item.family,
        eventID = item.eventID,
        npcFlavorID = item.flavorID,
        npcText = payload.text or message.text,
        npcType = item.context and (item.context.socialRole
            or item.context.npcType),
        relationshipState = item.context and item.context.relationshipState,
        relationshipTier = item.context and item.context.relationshipTier,
        priority = item.priority,
        mergedCount = item.mergedCount,
        llm = payload.llm == true,
    })
    log("delivered", "event=" .. tostring(item.eventID or "")
        .. " npc=" .. npcID .. " llm=" .. tostring(payload.llm == true)
        .. " text=" .. string.gsub(tostring(payload.text or message.text or ""),
            "[\r\n]+", " "))
    if message.presentationState
        and message.presentationState.conversationUI == true
    then
        local conversation = PsychopatzCore and PsychopatzCore.Conversation
        local view = conversation and conversation.instance or nil
        if view and view.spec
            and tostring(view.spec.npcID or "") == npcID
            and view.historyPart and view.historyPart.addMessage
        then
            view.historyPart:addMessage(message)
        end
    end
end

function Presentation.SetDebug(enabled)
    return Client.SetDebug(enabled)
end

if PNC.HoomansLLM
    and PNC.HoomansLLM.SubmitAmbientFlavor
then
    Client.SetLLMProvider(
        function(item, complete)
            return PNC.HoomansLLM.SubmitAmbientFlavor(item, complete)
        end,
        function(eventID)
            if PNC.HoomansLLM.CancelAmbientFlavor then
                return PNC.HoomansLLM.CancelAmbientFlavor(eventID)
            end
            return false
        end
    )
end
EventBus.clearOwner(OWNER_TOKEN)
EventBus.subscribe(Client.EVENT_DELIVERED, onDelivered, OWNER_TOKEN)

return Presentation
