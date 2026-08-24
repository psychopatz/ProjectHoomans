if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Traversal = PNC.AbstractTraversal
local H = Traversal.Internal
local Store = PNC.AbstractWorldStore
local Groups = PNC.AbstractGroups
local Locations = PNC.AbstractLocations
local Encounters = PNC.AbstractEncounters
local Actions = PNC.AbstractActions
local ResourceNeeds = PNC.AbstractResourceNeeds
local Config = PNC.DirectorConfig

function H.RunBatch(at, budget, cursorName, predicate)
    local groups = Groups.List()
    if #groups == 0 then return 0 end
    budget = math.max(1, math.floor(tonumber(budget)
        or Config.DIRECTOR_JOB_BUDGET))
    local processed = 0
    local visited = 0
    while processed < budget and visited < #groups do
        Traversal[cursorName] = (Traversal[cursorName] % #groups) + 1
        local group = groups[Traversal[cursorName]]
        if predicate(group) then
            Traversal.Advance(group, at)
            processed = processed + 1
        end
        visited = visited + 1
    end
    return processed
end

function Traversal.AdvanceTravelBatch(at, budget)
    return H.RunBatch(at, budget, "TravelCursor",
        function(group) return group.state == "TRAVELING"
            or group.state == "ACTIVE" end)
end

function Traversal.DecideBatch(at, budget)
    return H.RunBatch(at, budget, "DecisionCursor",
        function(group) return group.state ~= "TRAVELING"
            and group.state ~= "ACTIVE" and group.state ~= "PERFORMING_ACTION"
            and group.state ~= "ENGAGED" end)
end

function Traversal.AdvanceBatch(at, budget)
    return Traversal.AdvanceTravelBatch(at, budget)
        + Traversal.DecideBatch(at, budget)
end

function Traversal.ForceArrival(groupID, at)
    local group = Groups.Get(groupID)
    if not group or group.state ~= "TRAVELING" then
        return false, "not_traveling"
    end
    return Traversal.Arrive(group, tonumber(at) or Store.WorldAgeHours())
end
