-- Shared actor/source projections used by interactive context assembly.
require "PsychopatzCore/Conversation/PsychopatzConversationMessage"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_ActorIdentity"

PNC = PNC or {}
PNC.PBrainZ = PNC.PBrainZ or {}
PNC.PBrainZ.Internal = PNC.PBrainZ.Internal or {}

local Integration = PNC.PBrainZ
local Internal = Integration.Internal
local Runtime = Internal.Runtime
local Identity = Internal.ActorIdentity
local Message = PsychopatzCore.Conversation.Message
local Actors = Internal.ContextActors or {}
Internal.ContextActors = Actors

function Actors.SourceFor(entry)
    local state = PNC.Network and PNC.Network.ClientState or {}
    local id = tostring(entry and entry.id or "")
    local primary = entry and (entry.snapshot or entry.record) or nil
    local replica = state.snapshots and state.snapshots[id] or nil
    if type(primary) ~= "table" then return replica or {} end
    if type(replica) ~= "table" or replica.needs == nil then return primary end
    local merged = {}
    for key, value in pairs(primary) do merged[key] = value end
    for key, value in pairs(replica) do merged[key] = value end
    return merged
end

function Actors.CopyMap(source, keys)
    local output = {}
    if type(source) ~= "table" then return output end
    for _, key in ipairs(keys) do
        if source[key] ~= nil then output[key] = source[key] end
    end
    return output
end

local AUDIO_PRESENTATION_KEYS = {
    "effect_profile", "effectProfile",
    "audio_effect_profile", "audioEffectProfile",
    "environment", "audio_environment", "audioEnvironment",
    "intensity", "effect_intensity", "effectIntensity",
}

function Actors.AudioPresentation(source)
    if type(source) ~= "table" then return nil end
    local requested = source.audio_presentation
        or source.audioPresentation
        or source.audio_context
        or source.audioContext
        or source.speech
        or source.speechPolicy
        or source
    if type(requested) ~= "table" then return nil end
    local output = Actors.CopyMap(requested, AUDIO_PRESENTATION_KEYS)
    for index = 1, #AUDIO_PRESENTATION_KEYS do
        if output[AUDIO_PRESENTATION_KEYS[index]] ~= nil then return output end
    end
    return nil
end

function Actors.WorldUUID()
    if Message and Message.GetSaveID then
        return Message.GetSaveID()
    end
    local saveName = getCurrentSaveName and getCurrentSaveName()
        or getWorld and getWorld()
        or "default"
    return "pz-save:" .. Runtime.Trim(saveName, 256)
end

function Actors.PlayerUUID(view)
    local context = view and view.spec and view.spec.context or {}
    local clientState = PNC.Network and PNC.Network.ClientState or {}
    local playerContext = clientState.playerContext or {}
    local value = playerContext.characterUUID
        or context.characterUUID
        or view and view.spec and view.spec.characterUUID
    value = Runtime.Trim(value)
    return value ~= "" and value or "unbound-player"
end

function Actors.ResolveConversation(view, entry, source, definition, presentation)
    local identity = source.identity or {}
    local npcID = Runtime.Trim(definition.npcID or entry.id)
    npcID = npcID ~= "" and npcID or "unknown-npc"
    local clientState = PNC.Network and PNC.Network.ClientState or {}
    local playerID = Actors.PlayerUUID(view)
    local playerAddress = Identity.ResolvePlayer({
        npcID = npcID,
        npcIdentitySeed = PNC.FlavorAddress.ResolveNPCSeed(source, npcID),
        player = presentation.player,
        playerContext = clientState.playerContext,
        playerUUID = playerID,
        isFemale = presentation.playerIsFemale,
        playerNameKnown = presentation.playerNameKnown,
        playerFullName = presentation.playerFullName
            or presentation.playerName,
        playerFirstName = presentation.playerFirstName,
        playerSurname = presentation.playerSurname
            or presentation.playerLastName,
        state = clientState,
    })
    local npcParts = Identity.Split(
        Runtime.Trim(presentation.npcFullName or presentation.npcName),
        presentation.npcFirstName,
        presentation.npcSurname or presentation.npcLastName
    )
    local playerParts = Identity.Split(
        playerAddress.fullName,
        playerAddress.firstName,
        playerAddress.surname
    )
    npcParts.fullName = Runtime.Trim(npcParts.fullName)
    npcParts.fullName = npcParts.fullName ~= "" and npcParts.fullName or npcID
    playerParts.addressName = Runtime.Trim(playerParts.addressName)
    playerParts.addressName = playerParts.addressName ~= ""
        and playerParts.addressName or "the player"
    return {
        sourceIdentity = identity,
        npcID = npcID,
        clientState = clientState,
        playerID = playerID,
        playerAddress = playerAddress,
        npcParts = npcParts,
        playerParts = playerParts,
        npcName = npcParts.fullName,
        playerName = playerParts.addressName,
    }
end

return Actors
