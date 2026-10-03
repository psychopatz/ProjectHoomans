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
require "PNC/Core/Identity/PNC_FlavorAddress"
require "PNC/Core/Social/PNC_FlavorTextResolver"
require "PNC/Conversation/PNC_ConversationDiary"
require "PNC/Conversation/PNC_SocialFlavorDefinitions"
require "PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated"
require "PNC/Conversation/PNC_SocialFlavorDefinitions_LeaderDeath"

PNC = PNC or {}
PNC.SocialFlavorPresentation = PNC.SocialFlavorPresentation or {}

local Presentation = PNC.SocialFlavorPresentation
local Client = PsychopatzCore.SocialFlavorClient
local EventBus = PsychopatzCore.Events
local Diary = PNC.Conversation.Diary
local NameParts = PsychopatzCore.Conversation.NameParts
local FlavorAddress = PNC.FlavorAddress
local Targets = PNC.CompanionTargetResolver
local OWNER_TOKEN = Presentation
local MAX_PLAYER_SPEECH_RECIPIENTS = 8
local MEDICAL_SUPPLY_REQUEST_TTL = 30 * 60 * 1000
Presentation.MedicalSupplyRequests = Presentation.MedicalSupplyRequests or {}

local function clean(value, fallback)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value ~= "" and value or fallback
end

local function firstBoolean(primary, secondary)
    if type(primary) == "boolean" then return primary end
    if type(secondary) == "boolean" then return secondary end
    return nil
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

local function currentTime()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now()
        or getTimeInMillis and getTimeInMillis()
        or 0
end

local function updateMedicalSupplyRequest(npcID, context)
    local status = string.lower(tostring(
        context and context.medicalSupplyRequestStatus or ""))
    local npcKey = tostring(npcID or "")
    local requestID = clean(context and context.medicalSupplyRequestID, nil)
    local taskID = clean(context and context.medicalSupplyTaskID, nil)
    local requests = Presentation.MedicalSupplyRequests
    if npcKey == "" or type(requests) ~= "table" then return end
    if status == "needed" and requestID and taskID then
        requests[npcKey] = {
            requestID = requestID,
            taskID = taskID,
            itemQuery = "bandage",
            expiresAt = currentTime() + MEDICAL_SUPPLY_REQUEST_TTL,
        }
        return
    end
    if status == "fulfilled" or status == "resolved" or status == "closed" then
        local active = requests[npcKey]
        if active and (not requestID
            or tostring(active.requestID) == requestID)
        then
            requests[npcKey] = nil
        end
    end
end

function Presentation.GetActiveMedicalSupplyRequest(npcID)
    local requests = Presentation.MedicalSupplyRequests
    local key = tostring(npcID or "")
    local active = type(requests) == "table" and requests[key] or nil
    if not active then return nil end
    if (tonumber(active.expiresAt) or 0) <= currentTime() then
        requests[key] = nil
        return nil
    end
    return {
        requestID = tostring(active.requestID or ""),
        taskID = tostring(active.taskID or ""),
        itemQuery = tostring(active.itemQuery or "bandage"),
    }
end

local function playerUUID()
    local state = PNC.Network and PNC.Network.ClientState or {}
    local context = state.playerContext or {}
    return clean(context.characterUUID or context.playerUUID, nil)
end

local function playerAddress(npcID, player, options)
    local state = PNC.Network and PNC.Network.ClientState or {}
    local playerContext = state.playerContext or {}
    options = type(options) == "table" and options or {}
    local snapshot = state.snapshots
        and state.snapshots[tostring(npcID)] or nil
    return FlavorAddress.ResolveForNPC({
        npcID = npcID,
        npcIdentitySeed = FlavorAddress.ResolveNPCSeed(snapshot, npcID),
        player = player,
        playerContext = playerContext,
        playerUUID = playerUUID(),
        isFemale = options.playerIsFemale,
        playerNameKnown = options.playerNameKnown,
        authoritative = options.authoritative,
        state = state,
    })
end

local function npcName(npcID)
    local state = PNC.Network and PNC.Network.ClientState or {}
    local snapshot = state.snapshots and state.snapshots[tostring(npcID)] or nil
    local identity = PNC.NPCIdentityPresentation
    if identity and identity.GetName then
        return identity.GetName(snapshot or { id = npcID })
    end
    return clean(snapshot and snapshot.displayName, npcID)
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


PNC.SocialFlavorPresentationInternal =
    PNC.SocialFlavorPresentationInternal or {}
local H = PNC.SocialFlavorPresentationInternal
H.Clean = clean
H.FirstBoolean = firstBoolean
H.Log = log
H.CurrentPlayer = currentPlayer
H.CurrentTime = currentTime
H.UpdateMedicalSupplyRequest = updateMedicalSupplyRequest
H.PlayerUUID = playerUUID
H.PlayerAddress = playerAddress
H.NPCIdentity = npcIdentity
H.ActiveConversationFor = activeConversationFor

return Presentation
