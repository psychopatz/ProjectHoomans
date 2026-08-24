if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Debug = PNC.NeedsDebug
local H = Debug.Internal
local Definitions = PNC.NeedsDefinitions
local Utils = PNC.NeedsUtils

function Debug.BuildSnapshot(selectedGroupID, selectedNPCID, action)
    local groups, individuals = {}, {}
    local lowest = { hunger = nil, thirst = nil, fatigue = nil }
    local members = 0
    for _, faction in ipairs(PNC.Factions.List()) do
        if PNC.GroupNeeds.IsGroup(faction) then
            local summary = H.GroupSummary(faction)
            groups[#groups + 1] = summary
            members = members + summary.members
            for _, needType in ipairs(Definitions.TYPES) do
                if not lowest[needType]
                    or summary.needs[needType]
                        > lowest[needType].needs[needType]
                then lowest[needType] = summary end
            end
        end
    end
    for _, record in pairs(PNC.Registry.Data or {}) do
        if record.alive ~= false and PNC.IndividualNeeds.IsEligible(record) then
            local summary = H.IndividualSummary(record)
            if summary then individuals[#individuals + 1] = summary end
        end
    end
    table.sort(groups, function(a, b) return a.id < b.id end)
    table.sort(individuals, function(a, b) return a.name < b.name end)
    local selectedGroup, selectedNPC
    for _, value in ipairs(groups) do if value.id == selectedGroupID then selectedGroup = value end end
    for _, value in ipairs(individuals) do if value.id == selectedNPCID then selectedNPC = value end end
    selectedGroup = selectedGroup or groups[1]
    selectedNPC = selectedNPC or individuals[1]
    return {
        groups = groups, individuals = individuals, selectedGroup = selectedGroup, selectedNPC = selectedNPC,
        summary = { groupCount = #groups, individualCount = #individuals, totalGroupMembers = members, lowest = lowest },
        profiler = { enabled = Debug.ProfilingEnabled == true,
            data = Debug.ProfilingEnabled and H.Copy(PNC.NeedsScheduler and PNC.NeedsScheduler.Profile or {}) or nil,
            supply = PNC.SupplyMetrics and PNC.SupplyMetrics.Snapshot
                and PNC.SupplyMetrics.Snapshot() or {} },
        supplyLoggingEnabled = Debug.SupplyLoggingEnabled == true,
        action = action,
        generatedAt = Utils.WorldAgeHours(),
    }
end
