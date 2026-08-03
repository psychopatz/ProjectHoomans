-- Registry-driven lifecycle for persistent abstract actions.

if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.AbstractActions = PNC.AbstractActions or {}

local Actions = PNC.AbstractActions
local Store = PNC.AbstractWorldStore
local Groups = PNC.AbstractGroups
local Locations = PNC.AbstractLocations
local Config = PNC.DirectorConfig

Actions.Handlers = Actions.Handlers or {}
Actions.Cursor = Actions.Cursor or 0
Actions.Metrics = Actions.Metrics or { started = 0, completed = 0, interrupted = 0 }

function Actions.Register(actionType, handler)
    if type(actionType) ~= "string" or type(handler) ~= "table"
        or type(handler.Apply) ~= "function"
    then return false end
    Actions.Handlers[actionType] = handler
    return true
end

function Actions.Start(groupOrID, actionType, at, options)
    local group = type(groupOrID) == "table" and groupOrID or Groups.Get(groupOrID)
    local handler = Actions.Handlers[tostring(actionType or "")]
    at = tonumber(at) or Store.WorldAgeHours()
    options = type(options) == "table" and options or {}
    local location = group and Locations.Get(group.location.id) or nil
    if not group or not location or not handler then return nil, "invalid_action" end
    if group.simulation.lod ~= "ABSTRACT" or group.state == "TRAVELING"
        or group.activeEncounterId
    then return nil, "group_unavailable" end
    local seed = handler.Seed and handler.Seed(group, location, at) or 0
    local duration = tonumber(options.duration) or (handler.Duration
        and handler.Duration(group, location, seed)) or Config.Actions.DEFAULT_DURATION_HOURS
    group.action = { type = actionType, locationId = location.id,
        startedAt = at, endsAt = at + math.max(0, duration),
        seed = seed, status = "ACTIVE" }
    Groups.SetState(group, "PERFORMING_ACTION", at, group.action.endsAt)
    local visit = location.occupants.groups[group.id]
    if visit then visit.plannedDepartureAt = group.action.endsAt end
    Actions.Metrics.started = Actions.Metrics.started + 1
    Store.Emit("ABSTRACT_ACTION_STARTED", { groupId = group.id,
        action = group.action })
    return group.action, "started"
end

function Actions.StartForMission(groupOrID, at)
    local group = type(groupOrID) == "table" and groupOrID or Groups.Get(groupOrID)
    if not group then return nil, "group_not_found" end
    if Actions.Handlers[group.mission] then return Actions.Start(group, group.mission, at) end
    Groups.SetState(group, "ACTION_COMPLETE", at, at)
    return nil, "no_action_for_mission"
end

function Actions.Complete(groupOrID, at, force)
    local group = type(groupOrID) == "table" and groupOrID or Groups.Get(groupOrID)
    local action = group and group.action or nil
    at = tonumber(at) or Store.WorldAgeHours()
    if not group or not action then return nil, "no_action" end
    if force ~= true and at < (tonumber(action.endsAt) or 0) then
        return nil, "action_in_progress"
    end
    local location = Locations.Get(action.locationId)
    local handler = Actions.Handlers[action.type]
    if not location or not handler then
        return Actions.Interrupt(group, "invalid_action_context", at)
    end
    local result, reason = handler.Apply(group, location, action)
    if not result then return nil, reason end
    group.action = nil
    Groups.SetState(group, "ACTION_COMPLETE", at, at)
    Actions.Metrics.completed = Actions.Metrics.completed + 1
    Store.Emit("ABSTRACT_ACTION_COMPLETED", { groupId = group.id,
        actionType = action.type, locationId = location.id, result = result })
    return result, "completed"
end

function Actions.Interrupt(groupOrID, reason, at)
    local group = type(groupOrID) == "table" and groupOrID or Groups.Get(groupOrID)
    if not group or not group.action then return false, "no_action" end
    local action = group.action
    group.action = nil
    Groups.SetState(group, "IDLE", at, at)
    Actions.Metrics.interrupted = Actions.Metrics.interrupted + 1
    Store.Emit("ABSTRACT_ACTION_INTERRUPTED", { groupId = group.id,
        actionType = action.type, reason = reason })
    return true, "interrupted"
end

function Actions.AdvanceBatch(at, budget)
    local groups = Groups.List()
    if #groups == 0 then return 0 end
    budget = math.max(1, math.floor(tonumber(budget) or Config.DIRECTOR_JOB_BUDGET))
    local processed, visited = 0, 0
    while processed < budget and visited < #groups do
        Actions.Cursor = (Actions.Cursor % #groups) + 1
        local group = groups[Actions.Cursor]
        if group.state == "PERFORMING_ACTION" and group.action then
            if at >= (tonumber(group.action.endsAt) or 0) then
                Actions.Complete(group, at, false)
            end
            processed = processed + 1
        end
        visited = visited + 1
    end
    return processed
end

Actions.Register("SCAVENGE", PNC.AbstractScavengeResolver)

return Actions
