PNC = PNC or {}
PNC.API = PNC.API or {}
PNC.API.Internal = PNC.API.Internal or {}

local API = PNC.API
local Internal = API.Internal
local Core = PNC.Core
local Types = PNC.Types
local Registry = PNC.Registry
local OrderSystem = PNC.OrderSystem
local Presence = PNC.Presence
local Equipment = PNC.Equipment
local Health = PNC.Health
local Inventory = PNC.Inventory
local Network = PNC.Network

function API.AnimationScenes.Register(sceneId, definition)
    local registered
    local normalized
    registered, normalized =
        PNC.AnimationScenes.Register(sceneId, definition)
    return registered,
        normalized and Core.DeepCopy(normalized) or nil
end

function API.AnimationScenes.Unregister(sceneId)
    return PNC.AnimationScenes.Unregister(sceneId)
end

function API.AnimationScenes.Get(sceneId)
    local definition = PNC.AnimationScenes.Get(sceneId)
    return definition and Core.DeepCopy(definition) or nil
end

function API.AnimationScenes.Play(npcId, sceneId, options)
    local record = Registry.Get(npcId)
    local zombie = record
        and Registry.GetLiveZombie(record.id) or nil
    if not Core.IsAuthority() then
        return false, "authority_required"
    end
    return PNC.AnimationScenes.Request(
        record,
        zombie,
        sceneId,
        options
    )
end

function API.AnimationScenes.Stop(npcId, reason)
    local record = Registry.Get(npcId)
    local zombie = record
        and Registry.GetLiveZombie(record.id) or nil
    if not Core.IsAuthority() then
        return false, "authority_required"
    end
    return PNC.AnimationScenes.Stop(
        record,
        zombie,
        reason
    )
end

