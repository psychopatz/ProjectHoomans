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

-- Stable cross-mod map marker API. Relationship systems decide when to call
-- SetKnown; the map renderer only consumes this neutral presentation record.
API.MapPresentation = API.MapPresentation or {}

function API.MapPresentation.Get(npcId)
    local record = Registry.Get(npcId)
    if record and PNC.MapPresentation then
        return PNC.MapPresentation.BuildSummary(record.mapPresentation)
    end
    local snapshot = PNC.Network
        and PNC.Network.ClientState
        and PNC.Network.ClientState.snapshots
        and PNC.Network.ClientState.snapshots[tostring(npcId)] or nil
    return snapshot and Core.DeepCopy(snapshot.mapPresentation) or nil
end

function API.MapPresentation.Set(npcId, spec)
    local record = Registry.Get(npcId)
    local presentation
    local reason
    if not Core.IsAuthority() or not record or not PNC.MapPresentation then
        return nil, "not_authority_or_missing"
    end
    presentation, reason = PNC.MapPresentation.Apply(record, spec or {})
    if not presentation then return nil, reason end
    if Registry.MarkDirty then
        Registry.MarkDirty(record, "map_presentation")
    end
    Network.BroadcastRecord(record, "map_presentation")
    return PNC.MapPresentation.BuildSummary(presentation)
end

function API.MapPresentation.SetVisibility(npcId, visibility)
    return API.MapPresentation.Set(npcId, {
        visibility = visibility,
    })
end

function API.MapPresentation.SetKnown(npcId, playerKey, known)
    local record = Registry.Get(npcId)
    local presentation
    local reason
    if not Core.IsAuthority() or not record or not PNC.MapPresentation then
        return nil, "not_authority_or_missing"
    end
    presentation, reason = PNC.MapPresentation.SetKnown(
        record,
        playerKey,
        known
    )
    if not presentation then return nil, reason end
    if Registry.MarkDirty then
        Registry.MarkDirty(record, "map_presentation")
    end
    Network.BroadcastRecord(record, "map_presentation")
    return PNC.MapPresentation.BuildSummary(presentation)
end

function API.MapPresentation.RegisterIcon(iconID, definition)
    return PNC.MapMarkerIcons
        and PNC.MapMarkerIcons.Register
        and PNC.MapMarkerIcons.Register(iconID, definition)
        or false
end

function API.MapPresentation.UnregisterIcon(iconID)
    return PNC.MapMarkerIcons
        and PNC.MapMarkerIcons.Unregister
        and PNC.MapMarkerIcons.Unregister(iconID)
        or false
end

