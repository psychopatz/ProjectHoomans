if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Provider = PNC.Semantics.ActionPlanPathProvider
local WorldTargets = Provider.WorldTargets

local function number(value)
    return tonumber(value)
end

local function parameters(step)
    return step and type(step.parameters) == "table"
        and step.parameters or {}
end

local function targetSpec(step)
    local args = parameters(step)
    local target = type(args.target) == "table" and args.target
        or type(args.destination) == "table" and args.destination
        or args
    return target, args
end

function Provider.AssignmentFor(step, record, body, runtime, metadata)
    local target, args = targetSpec(step)
    metadata = type(metadata) == "table" and metadata or {}
    if WorldTargets and type(WorldTargets.Resolve) == "function" then
        local resolved, reason = WorldTargets.Resolve(target, {
            record = record,
            body = body,
            abstract = body == nil,
            runtime = runtime,
            npcID = record and record.id,
            planID = metadata.planID,
            requestID = metadata.requestID,
        })
        if resolved then
            resolved.mode = tostring(args.mode or resolved.mode or "walk")
            resolved.stopDistance = number(args.stopDistance
                or resolved.stopDistance) or 0.7
            return resolved
        end
        if number(target and (target.x or target.targetX)) == nil
            or number(target and (target.y or target.targetY)) == nil
        then
            return nil, reason or "world_target_unresolved"
        end
    end
    local x = number(target and (target.x or target.targetX))
    local y = number(target and (target.y or target.targetY))
    local z = number(target and (target.z or target.targetZ)) or 0
    if x == nil or y == nil then return nil, "target_coordinates_required" end
    return {
        kind = tostring(target.kind or "world_point"),
        targetID = target.id and tostring(target.id) or nil,
        x = x,
        y = y,
        z = z,
        mode = tostring(args.mode or target.mode or "walk"),
        stopDistance = number(args.stopDistance or target.stopDistance) or 0.7,
        dynamic = target.dynamic == true,
    }
end

return Provider
