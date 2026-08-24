-- Social-event input validation and normalization.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEvents = PNC.SocialEvents or {}
local SocialEvents = PNC.SocialEvents
local Internal = SocialEvents.Internal
local Definitions = PNC.SocialEventDefinitions
local EntityRef = PNC.EntityRef
local result = Internal.Result
local finiteNumber = Internal.FiniteNumber
local validString = Internal.ValidString
local isSafe = Internal.IsSafe
local copySafe = Internal.CopySafe

function SocialEvents.Validate(eventSpec)
    local definition
    local occurredAt
    if type(eventSpec) ~= "table" or not isSafe(eventSpec) then
        return result(false, "unsafe_event")
    end
    if not validString(eventSpec.id) then
        return result(false, "invalid_event_id")
    end
    if string.sub(eventSpec.id, 1, 7) ~= "social:" then
        return result(false, "invalid_event_id")
    end
    if not validString(eventSpec.type) then
        return result(false, "invalid_event_type")
    end
    definition = Definitions[eventSpec.type]
    if not definition then
        return result(false, "unknown_event_type")
    end
    if not EntityRef.IsValid(eventSpec.actorKey) then
        return result(false, "invalid_actor_key")
    end
    if not EntityRef.IsValid(eventSpec.targetKey) then
        return result(false, "invalid_target_key")
    end
    if eventSpec.actorKey == eventSpec.targetKey
        and definition.allowSelf ~= true
    then
        return result(false, "identical_actor_target")
    end
    occurredAt = finiteNumber(eventSpec.occurredAt)
    if not occurredAt or occurredAt < 0 then
        return result(false, "invalid_timestamp")
    end
    if not validString(eventSpec.sourceSystem)
        or not definition.allowedSourceSystems[eventSpec.sourceSystem]
    then
        return result(false, "invalid_source_system")
    end
    if eventSpec.context ~= nil and type(eventSpec.context) ~= "table" then
        return result(false, "invalid_context")
    end
    if eventSpec.x ~= nil and finiteNumber(eventSpec.x) == nil then
        return result(false, "invalid_position")
    end
    if eventSpec.y ~= nil and finiteNumber(eventSpec.y) == nil then
        return result(false, "invalid_position")
    end
    if eventSpec.z ~= nil and finiteNumber(eventSpec.z) == nil then
        return result(false, "invalid_position")
    end
    return result(true, nil, {
        event = {
            id = eventSpec.id,
            type = eventSpec.type,
            actorKey = eventSpec.actorKey,
            targetKey = eventSpec.targetKey,
            occurredAt = occurredAt,
            sourceSystem = eventSpec.sourceSystem,
            x = finiteNumber(eventSpec.x),
            y = finiteNumber(eventSpec.y),
            z = finiteNumber(eventSpec.z),
            context = eventSpec.context and copySafe(eventSpec.context)
                or {},
        },
        definition = copySafe(definition),
    })
end

return SocialEvents
