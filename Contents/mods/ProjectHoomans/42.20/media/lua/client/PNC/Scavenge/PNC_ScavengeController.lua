PNC = PNC or {}
PNC.ScavengeController = PNC.ScavengeController or {}

local Controller = PNC.ScavengeController

Controller.Team = Controller.Team or {}
Controller.Listeners = Controller.Listeners or {}
Controller.Initialized = Controller.Initialized == true

local function copyIDs(values)
    local output, seen = {}, {}
    for _, value in ipairs(type(values) == "table" and values or {}) do
        local id = tostring(value or "")
        if id ~= "" and not seen[id] then
            seen[id] = true
            output[#output + 1] = id
        end
    end
    table.sort(output)
    return output
end

local function emitTeamChanged()
    local ids = Controller.TeamIDs()
    for _, listener in ipairs(Controller.Listeners) do
        pcall(listener, ids)
    end
end

function Controller.OnTeamChanged(listener)
    if type(listener) ~= "function" then return false end
    Controller.Listeners[#Controller.Listeners + 1] = listener
    return true
end

function Controller.TeamIDs()
    local output = {}
    for npcId, assigned in pairs(Controller.Team) do
        if assigned == true then output[#output + 1] = tostring(npcId) end
    end
    table.sort(output)
    return output
end

function Controller.IsAssigned(npcId)
    return Controller.Team[tostring(npcId or "")] == true
end

function Controller.SetAssigned(npcId, assigned)
    npcId = tostring(npcId or "")
    if npcId == "" then return false, "npc_required" end
    local nextValue = assigned == true
    if Controller.IsAssigned(npcId) == nextValue then return true, "unchanged" end
    Controller.Initialized = true
    Controller.Team[npcId] = nextValue or nil
    emitTeamChanged()
    return true, nextValue and "assigned" or "removed"
end

function Controller.ToggleAssigned(npcId)
    local assigned = not Controller.IsAssigned(npcId)
    local ok, reason = Controller.SetAssigned(npcId, assigned)
    return ok, reason, assigned
end

function Controller.SetTeam(npcIds)
    local nextTeam = {}
    for _, npcId in ipairs(copyIDs(npcIds)) do nextTeam[npcId] = true end
    local changed = false
    for npcId, assigned in pairs(Controller.Team) do
        if assigned == true and nextTeam[npcId] ~= true then changed = true; break end
    end
    if not changed then
        for npcId, assigned in pairs(nextTeam) do
            if assigned == true and Controller.Team[npcId] ~= true then
                changed = true
                break
            end
        end
    end
    Controller.Team = nextTeam
    Controller.Initialized = true
    if changed then emitTeamChanged() end
    return Controller.TeamIDs()
end

function Controller.SeedTeam(npcIds)
    if Controller.Initialized then return Controller.TeamIDs() end
    return Controller.SetTeam(npcIds)
end

function Controller.IsSearchActive(snapshot)
    return type(snapshot) == "table"
        and snapshot.runActive == true
        and snapshot.state ~= "CANCELLED"
        and snapshot.state ~= "PAUSED"
        and snapshot.state ~= "COMPLETED"
        and snapshot.state ~= "FAILED"
end

function Controller.StartSearch(options)
    options = type(options) == "table" and options or {}
    local npcIds = Controller.TeamIDs()
    if #npcIds < 1 then npcIds = copyIDs(options.npcIds) end
    if #npcIds < 1 and options.npcId then
        npcIds[1] = tostring(options.npcId)
    end
    if #npcIds < 1 then return false, "scavenger_team_empty" end
    return PNC.Client.SendScavengeRequest("start_search", {
        npcId = npcIds[1],
        npcIds = npcIds,
        radius = tonumber(options.radius)
            or tonumber(PNC.Const.SCAVENGE_DEFAULT_RADIUS),
        sourcePolicy = options.sourcePolicy,
    })
end

function Controller.StopSearch(snapshot, npcId)
    snapshot = type(snapshot) == "table" and snapshot or nil
    return PNC.Client.SendScavengeRequest("cancel_search", {
        sessionId = snapshot and snapshot.sessionId or nil,
        npcId = npcId or snapshot and snapshot.npcId or nil,
        reason = "player_stopped_search",
    })
end

function Controller.Disband(snapshot, npcId)
    snapshot = type(snapshot) == "table" and snapshot or nil
    return PNC.Client.SendScavengeRequest("disband", {
        sessionId = snapshot and snapshot.sessionId or nil,
        npcId = npcId or snapshot and snapshot.npcId or nil,
    })
end

function Controller.Open(npcId, context)
    npcId = npcId and tostring(npcId) or nil
    local npcIds = Controller.TeamIDs()
    if #npcIds < 1 and npcId then npcIds[1] = npcId end
    if not PNC.ScavengeUI then
        require "PNC/UI/Scavenge/PNC_ScavengeWindow"
    end
    if not PNC.ScavengeUI or not PNC.ScavengeUI.OpenSetup then return false end
    context = type(context) == "table" and context or {}
    context.npcIds = npcIds
    return PNC.ScavengeUI.OpenSetup(npcId or npcIds[1], context)
end

function Controller.ReceiveSnapshot(snapshot)
    if type(snapshot) ~= "table" or snapshot.requestFailed == true
        or snapshot.policyOnly == true
    then return false end
    if snapshot.disbanded == true then
        Controller.SetTeam({})
    elseif type(snapshot.npcIds) == "table" then
        Controller.SetTeam(snapshot.npcIds)
    end
    return true
end

function Controller.Reset()
    Controller.Team = {}
    Controller.Initialized = false
    emitTeamChanged()
end

return Controller
