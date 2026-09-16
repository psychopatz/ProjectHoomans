-- Runtime-only foreign actor reference normalization.
--
-- actorId is the provider-owned stable identity. worldObject is deliberately
-- runtime-only and must never be serialized into a network payload.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
PNC.Compatibility.ActorRef = PNC.Compatibility.ActorRef or {}

local ActorRef = PNC.Compatibility.ActorRef

function ActorRef.New(provider, actorID, kind, worldObject, options)
    local ref
    local x
    local y
    local z
    if provider == nil or actorID == nil then return nil end
    ref = {
        provider = tostring(provider),
        actorId = tostring(actorID),
        id = tostring(actorID),
        kind = kind or "foreign_npc",
        worldObject = worldObject,
    }
    options = type(options) == "table" and options or {}
    ref.generation = options.generation
    ref.visible = options.visible
    if worldObject then
        x = worldObject.getX and worldObject:getX() or nil
        y = worldObject.getY and worldObject:getY() or nil
        z = worldObject.getZ and worldObject:getZ() or nil
    end
    ref.x = options.x ~= nil and options.x or x
    ref.y = options.y ~= nil and options.y or y
    ref.z = options.z ~= nil and options.z or z
    return ref
end

function ActorRef.IsValid(reference)
    return type(reference) == "table"
        and reference.provider ~= nil
        and reference.actorId ~= nil
        and tostring(reference.provider) ~= ""
        and tostring(reference.actorId) ~= ""
end

function ActorRef.Key(reference)
    if not ActorRef.IsValid(reference) then return nil end
    return tostring(reference.provider) .. ":"
        .. tostring(reference.actorId) .. ":"
        .. tostring(reference.generation or "")
end

function ActorRef.IsSame(left, right)
    return ActorRef.Key(left) ~= nil
        and ActorRef.Key(left) == ActorRef.Key(right)
end

return ActorRef
