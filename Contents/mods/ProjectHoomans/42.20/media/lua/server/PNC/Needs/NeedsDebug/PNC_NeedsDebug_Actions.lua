if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Debug = PNC.NeedsDebug
local H = Debug.Internal

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
                and H.Copy(supply.byKind[kind].candidateScores) or {}
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
