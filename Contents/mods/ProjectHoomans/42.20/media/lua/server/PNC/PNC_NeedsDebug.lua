-- Server-only Needs diagnostics. Histories are intentionally runtime-only.
if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NeedsDebug = PNC.NeedsDebug or { groupHistory = {}, individualHistory = {} }

local Debug = PNC.NeedsDebug
local Definitions = PNC.NeedsDefinitions
local Utils = PNC.NeedsUtils

Debug.groupHistory = Debug.groupHistory or {}
Debug.individualHistory = Debug.individualHistory or {}
Debug.ProfilingEnabled = Debug.ProfilingEnabled == true
Debug.SupplyLoggingEnabled = Debug.SupplyLoggingEnabled == true

local function copy(value)
    return PNC.Core and PNC.Core.DeepCopy and PNC.Core.DeepCopy(value) or value
end

local function groupSummary(faction)
    local state = PNC.GroupNeeds.Ensure(faction)
    local mobile = faction.mobile or {}
    local site = mobile.site or {}
    local home = site.home or {}
    local members = 0
    for _, value in pairs(faction.memberIDs or {}) do if value == true then members = members + 1 end end
    local rates = PNC.GroupNeeds.GetRates(faction) or {}
    return {
        id = faction.id, name = faction.name, type = faction.archetypeID,
        faction = faction.name, members = members, activity = PNC.GroupNeeds.GetActivity(faction),
        location = { x = home.x, y = home.y, z = home.z },
        destination = mobile.nextMoveAt, needs = state, rates = rates,
        history = copy(Debug.groupHistory[faction.id] or {}),
        elapsed = math.max(0, Utils.WorldAgeHours() - (tonumber(state and state.lastUpdateWorldAge) or 0)),
    }
end

local function individualSummary(record)
    local state = PNC.IndividualNeeds.Ensure(record)
    local persistence = PNC.Inventory and PNC.Inventory.Serialize
        and PNC.Inventory.Serialize(record) or nil
    local mode = PNC.Inventory and PNC.Inventory.GetPersistenceMode
        and PNC.Inventory.GetPersistenceMode(record) or "UNKNOWN"
    local delta = mode == "BASELINE_DELTA" and persistence and persistence[5] or nil
    return state and {
        id = record.id, name = tostring(record.name or record.id), owner = record.ownerUsername or "Player",
        activity = record.activeBehavior or record.activeJob or record.orderSpec and record.orderSpec.kind or "idle",
        needs = state, history = copy(Debug.individualHistory[record.id] or {}),
        conditionStats = PNC.ConditionStats
            and PNC.ConditionStats.Ensure(record, Utils.WorldAgeHours()) or {},
        conditionRates = PNC.ConditionStats
            and PNC.ConditionStats.GetRates(record,
                PNC.IndividualNeeds.GetActivity(record)) or {},
        dynamicTraits = copy(record.dynamicTraits or {}),
        elapsed = math.max(0, Utils.WorldAgeHours() - (tonumber(state.lastUpdateWorldAge) or 0)),
        supply = PNC.NPCSupplyService and PNC.NPCSupplyService.GetDebugState
            and PNC.NPCSupplyService.GetDebugState(record) or { byKind = {} },
        provision = PNC.ProvisionEvaluator
            and PNC.ProvisionEvaluator.GetDebugState
            and PNC.ProvisionEvaluator.GetDebugState(record)
            or { evaluations = {}, dirtyRules = {} },
        inventoryMode = mode,
        deltaRecordCount = delta and (#(delta[2] or {}) + #(delta[3] or {})) or 0,
        fullPromotionReason = record.inventoryPromotionReason,
    } or nil
end

function Debug.BuildSnapshot(selectedGroupID, selectedNPCID, action)
    local groups, individuals = {}, {}
    local lowest = { hunger = nil, hydration = nil, fatigue = nil }
    local members = 0
    for _, faction in ipairs(PNC.Factions.List()) do
        if PNC.GroupNeeds.IsGroup(faction) then
            local summary = groupSummary(faction)
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
            local summary = individualSummary(record)
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
            data = Debug.ProfilingEnabled and copy(PNC.NeedsScheduler and PNC.NeedsScheduler.Profile or {}) or nil,
            supply = PNC.SupplyMetrics and PNC.SupplyMetrics.Snapshot
                and PNC.SupplyMetrics.Snapshot() or {} },
        supplyLoggingEnabled = Debug.SupplyLoggingEnabled == true,
        action = action,
        generatedAt = Utils.WorldAgeHours(),
    }
end

function Debug.PerformAction(args)
    args = type(args) == "table" and args or {}
    local target = tostring(args.target or "")
    local operation = tostring(args.operation or "")
    if operation == "profiling" then
        Debug.ProfilingEnabled = args.enabled == true
        return Debug.BuildSnapshot(args.groupID, args.npcID, {
            ok = true, reason = Debug.ProfilingEnabled and "profiling_enabled" or "profiling_disabled", operation = operation,
        })
    end
    if operation == "supply_logging" then
        Debug.SupplyLoggingEnabled = args.enabled == true
        return Debug.BuildSnapshot(args.groupID, args.npcID, {
            ok = true,
            reason = Debug.SupplyLoggingEnabled
                and "supply_logging_enabled" or "supply_logging_disabled",
            operation = operation,
        })
    end
    local owner = target == "group" and PNC.Factions.Get(args.ownerID)
        or target == "individual" and PNC.Registry.Get(args.ownerID) or nil
    local ok, reason, value = false, "owner_not_found", nil
    if owner and target == "group" then
        if operation == "set" then value = PNC.GroupNeeds.Set(owner, args.needType, args.value, "debug")
        elseif operation == "modify" then value = PNC.GroupNeeds.Modify(owner, args.needType, args.amount, "debug")
        elseif operation == "reset" then ok, reason = PNC.GroupNeeds.Reset(owner), "reset"
        elseif operation == "simulate" then ok, reason = PNC.NeedsScheduler.SimulateGroup(owner, args.hours), "simulated"
        elseif operation == "scavenge" then value = PNC.GroupNeeds.DebugAbstractScavenge(owner); ok, reason = value ~= nil, "debug_abstract_scavenge"
        elseif operation == "activity" then ok, reason = PNC.GroupNeeds.SetDebugActivity(owner, args.activity), "activity_set" end
        if value ~= nil then ok, reason = true, "updated" end
    elseif owner and target == "individual" then
        if operation == "set" then value = PNC.IndividualNeeds.Set(owner, args.needType, args.value, "debug")
        elseif operation == "modify" then value = PNC.IndividualNeeds.Modify(owner, args.needType, args.amount, "debug")
        elseif operation == "reset" then ok, reason = PNC.IndividualNeeds.Reset(owner), "reset"
        elseif operation == "simulate" then ok, reason = PNC.NeedsScheduler.SimulateIndividual(owner, args.hours), "simulated" end
        if operation == "force_supply_evaluation" then
            ok, reason = PNC.NeedSupplyBridge.Evaluate(owner)
        elseif operation == "force_food_supply" then
            ok, reason = PNC.NeedSupplyBridge.Evaluate(owner, "FOOD")
        elseif operation == "force_hydration_supply" then
            ok, reason = PNC.NeedSupplyBridge.Evaluate(owner, "HYDRATION")
        elseif operation == "force_medical_supply" then
            ok, reason = PNC.NeedSupplyBridge.Evaluate(owner, "MEDICAL")
        elseif operation == "clear_supply_retry" then
            for _, kind in ipairs({ "FOOD", "HYDRATION", "MEDICAL" }) do
                PNC.NPCSupplyService.ClearRetry(owner, kind)
            end
            ok, reason = true, "supply_retry_cleared"
        elseif operation == "dump_candidate_scores" then
            local supply = PNC.NPCSupplyService.GetDebugState(owner)
            local kind = supply.currentKind
            value = kind and supply.byKind and supply.byKind[kind]
                and copy(supply.byKind[kind].candidateScores) or {}
            ok, reason = true, "candidate_scores_dumped"
        elseif operation == "force_provision_evaluation" then
            PNC.ProvisionScheduler.ReconcileRecord(owner)
            ok, reason = true, "provision_evaluated"
        elseif operation == "mark_provision_dirty" then
            PNC.ProvisionScheduler.MarkAllDirty(owner)
            ok, reason = true, "provision_marked_dirty"
        elseif operation == "clear_provision_retry" then
            for _, kind in ipairs({ "FOOD", "HYDRATION", "MEDICAL" }) do
                PNC.NPCSupplyService.ClearRetry(owner, kind)
            end
            ok, reason = true, "provision_retry_cleared"
        elseif operation == "dump_effective_provision" then
            value, reason = PNC.ProvisionResolver.GetEffectivePolicy(owner)
            ok = value ~= nil
        end
        if value ~= nil then ok, reason = true, "updated" end
    end
    return Debug.BuildSnapshot(args.groupID or (target == "group" and args.ownerID), args.npcID or (target == "individual" and args.ownerID), {
        ok = ok == true, reason = reason, operation = operation, value = value,
    })
end

function Debug.CleanupGroup(factionID)
    Debug.groupHistory[tostring(factionID)] = nil
end

function Debug.CleanupIndividual(npcID)
    Debug.individualHistory[tostring(npcID)] = nil
end

return Debug
