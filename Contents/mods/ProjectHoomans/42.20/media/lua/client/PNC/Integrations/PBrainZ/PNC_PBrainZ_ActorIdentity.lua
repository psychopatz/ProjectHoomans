-- Shared actor identity normalization for ambient and interactive contexts.
require "PsychopatzCore/Conversation/PsychopatzNameParts"
require "PNC/Core/Identity/PNC_FlavorAddress"
PNC = PNC or {}
PNC.PBrainZ = PNC.PBrainZ or {}
PNC.PBrainZ.Internal = PNC.PBrainZ.Internal or {}

local Integration = PNC.PBrainZ
local NameParts = PsychopatzCore.Conversation.NameParts
local FlavorAddress = PNC.FlavorAddress
local Identity = Integration.Internal.ActorIdentity or {}
Integration.Internal.ActorIdentity = Identity

function Identity.Split(fullName, firstName, surname)
    return NameParts.Split(fullName, firstName, surname)
end

function Identity.ResolvePlayer(options)
    return FlavorAddress.ResolveForNPC(options)
end

function Identity.Resolve(item, source, npcID, playerID)
    local npc = Identity.Split(
        source.speakerFullName
            or item and item.speakerName
            or source.name or npcID or "the survivor",
        source.speakerFirstName or source.firstName,
        source.speakerSurname or source.surname
    )
    local playerAddress = Identity.ResolvePlayer({
        npcID = npcID,
        npcIdentitySeed = FlavorAddress.ResolveNPCSeed(source, npcID),
        playerUUID = playerID,
        isFemale = source.playerIsFemale,
        playerNameKnown = source.playerNameKnown,
        playerFullName = source.playerFullName,
        playerFirstName = source.playerFirstName,
        playerSurname = source.playerSurname or source.playerLastName,
        state = PNC.Network and PNC.Network.ClientState or nil,
    })
    local victim = Identity.Split(
        source.victimFullName or source.victimName
            or source.victim or "your teammate",
        source.victimFirstName,
        source.victimSurname or source.victimLastName
    )
    return {
        npc = npc,
        player = playerAddress,
        victim = victim,
        npcFullName = npc.fullName or "the survivor",
        npcFirstName = npc.firstName or npc.fullName or "the survivor",
        npcSurname = npc.surname or "",
        playerFullName = playerAddress.fullName or "the player",
        playerFirstName = playerAddress.firstName
            or playerAddress.fullName or "the player",
        playerSurname = playerAddress.surname or "",
        victimFullName = victim.fullName or "your teammate",
        victimFirstName = victim.firstName
            or victim.fullName or "your teammate",
    }
end

return Identity
