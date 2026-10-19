-- Optional Core-owned map, portrait, nearby-talk, and notification bridge.
-- Hoomans retains UI and body ownership; this adapter only projects canonical
-- Core presentation state into the existing PNC surfaces.

PNC = PNC or {}
PNC.Persistence = PNC.Persistence or {}

local Persistence = PNC.Persistence
local Adapter = Persistence.CorePresentation or {}
Persistence.CorePresentation = Adapter

local function actors(core)
    return core and core.Actors
end

function Adapter.BuildPortrait(actor, core)
    local service = actors(core)
    if not service or not service.Presentation
        or type(service.Presentation.BuildPortrait) ~= "function"
    then return nil, "core_presentation_unavailable" end
    return service.Presentation.BuildPortrait(actor)
end

function Adapter.BuildMapEntry(actor, core, spec)
    local service = actors(core)
    if not service or not service.Map
        or type(service.Map.NewRegistry) ~= "function"
    then return nil, "core_map_unavailable" end
    local registry = service.Map.NewRegistry()
    return registry:ProjectActor(actor, spec)
end

function Adapter.BuildNearbyConversation(entry, core, viewerKey, distance)
    local service = actors(core)
    if not service or not service.Interaction
        or type(service.Interaction.BuildNearbyConversation) ~= "function"
    then return nil, "core_interaction_unavailable" end
    return service.Interaction.BuildNearbyConversation(entry, viewerKey,
        distance)
end

function Adapter.PublishNotification(queue, core, spec)
    if type(queue) ~= "table"
        or type(queue.Publish) ~= "function"
    then return nil, "notification_queue_required" end
    local service = actors(core)
    if not service or not service.Notifications then
        return nil, "core_notifications_unavailable"
    end
    return queue:Publish(spec)
end

return Adapter
