PNC = PNC or {}
PNC.CharacterWindowShared = PNC.CharacterWindowShared or {}

local Shared = PNC.CharacterWindowShared

function Shared.GetCharacterData(snapshot, payload)
    local resolved = Shared.GetSnapshot(snapshot, payload)
    return resolved.characterWindow or snapshot and snapshot.characterWindow or {}
end

function Shared.GetIdentity(snapshot, payload)
    local resolved = Shared.GetSnapshot(snapshot, payload)
    return resolved.identity or {}
end

function Shared.GetEquipment(snapshot, payload)
    local resolved = Shared.GetSnapshot(snapshot, payload)
    return payload and payload.equipment or resolved.equipmentSummary or {}
end

function Shared.GetCarry(snapshot, payload)
    local resolved = Shared.GetSnapshot(snapshot, payload)
    return payload and payload.inventory and payload.inventory.summary or resolved.inventorySummary or {}
end

function Shared.GetLiveCharacter(npcId)
    local key = npcId and tostring(npcId) or nil
    local sync = PNC.ClientPresenceSync
    local character = key and sync and sync.BodyByID and sync.BodyByID[key] or nil
    local function isUsable(candidate)
        if not candidate then return false end
        if not candidate.isDead then return true end
        local ok, dead = pcall(candidate.isDead, candidate)
        return ok and dead ~= true
    end
    if isUsable(character) then return character end
    if PNC.Registry and PNC.Registry.GetLiveZombie then
        character = PNC.Registry.GetLiveZombie(key)
        if isUsable(character) then return character end
    end
    return nil
end

local ClientPortraitSpec = require "PNC/UI/PNC_ClientPortraitSpec"

function Shared.BuildPortraitSpec(npcId, snapshot, payload)
    local resolved = Shared.GetSnapshot(snapshot, payload)
    local id = npcId or resolved.id
    local built = ClientPortraitSpec.Build(id, {
        id = id,
        snapshot = resolved,
        payload = payload,
        faceOnly = false,
        includeCurrentClothing = true,
        clothingMode = "current",
    })
    if built then return built end
    return {
        id = id,
        identitySeed = resolved.identitySeed or 1,
        preferDescriptor = true,
        faceOnly = false,
        includeCurrentClothing = true,
        clothingMode = "current",
        outfit = resolved.appearance and resolved.appearance.outfit or nil,
        appearance = resolved.appearance or {},
        equipment = Shared.GetEquipment(snapshot, payload),
    }
end

return Shared
