-- Read-only player colony presentation; canonical Need state remains on NPC records.
if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end
PNC = PNC or {}
PNC.ColonyManagement = PNC.ColonyManagement or {}
local Management, Definitions = PNC.ColonyManagement, PNC.NeedsDefinitions
Management.SettlementResults = Management.SettlementResults or {}
Management.SettlementResultOrder = Management.SettlementResultOrder or {}
Management.MAX_SETTLEMENT_RESULTS = 256

local function rememberSettlementResult(requestId, value)
    if not requestId then return end
    requestId = tostring(requestId)
    Management.SettlementResults[requestId] = PNC.Core.DeepCopy(value)
    Management.SettlementResultOrder[#Management.SettlementResultOrder + 1] = requestId
    if #Management.SettlementResultOrder > Management.MAX_SETTLEMENT_RESULTS then
        local expired = table.remove(Management.SettlementResultOrder, 1)
        Management.SettlementResults[expired] = nil
    end
end

local function owned(record, player)
    return PNC.CompanionCommands and PNC.CompanionCommands.IsOwnedByPlayer
        and PNC.CompanionCommands.IsOwnedByPlayer(record, player)
end
local canUseDebug
local function effectiveAllowedJobs(record)
    local configured = type(record.allowedJobs) == "table"
        and record.allowedJobs or {}
    local output = {}
    local jobs = PNC.WorkDefinitions and PNC.WorkDefinitions.COLONY_JOBS
        or { "Constructor", "Researcher", "WorkshopWorker" }
    for _, job in ipairs(jobs) do
        output[job] = configured[job] ~= false
    end
    return output
end

local function summary(record)
    local needs = PNC.IndividualNeeds.Ensure(record)
    local nutrition = PNC.IndividualNeeds.GetNutrition
        and PNC.IndividualNeeds.GetNutrition(record) or nil
    local priorityType, priority = PNC.IndividualNeeds.GetHighestPriority(record)
    local journal = PNC.Journals and PNC.Journals.GetNPC
        and PNC.Journals.GetNPC(record.id,
            PNC.Journals.NPC_CAPACITY or 32, true)
        or {}
    return { id=record.id, name=tostring(record.name or record.id),
        role=record.affiliation and record.affiliation.communityRole or record.affiliation and record.affiliation.role or "companion",
        activity=PNC.IndividualNeeds.GetActivity(record), job=record.activeJob,
        health=record.health and record.health.state or "unknown", needs=needs,
        nutrition=nutrition,
        conditionStats=PNC.ConditionStats
            and PNC.ConditionStats.Ensure(record,
                PNC.NeedsUtils.WorldAgeHours()) or {},
        morale=record.social and record.social.morale or 0,
        provision=PNC.ProvisionEvaluator
            and PNC.ProvisionEvaluator.GetDebugState
            and PNC.ProvisionEvaluator.GetDebugState(record) or {},
        supply=PNC.NPCSupplyService
            and PNC.NPCSupplyService.GetDebugState
            and PNC.NPCSupplyService.GetDebugState(record) or {},
        journal=journal,
        allowedJobs=effectiveAllowedJobs(record),
        home=PNC.HomeDutyService and PNC.HomeDutyService.BuildState
            and PNC.HomeDutyService.BuildState(record) or nil,
        facilityDebugWork=record.runtime and record.runtime.facilityDebugWork
            and PNC.Core.DeepCopy(record.runtime.facilityDebugWork) or nil,
        priorityType=priorityType, priority=priority,
        location={x=record.x,y=record.y,z=record.z} }
end


local function colonistHomeAction(player, args, recover)
    local record = PNC.Registry and PNC.Registry.Get(args.npcID) or nil
    if not record or record.alive == false or not owned(record, player) then
        return false, "npc_not_owned"
    end
    if not PNC.HomeDutyService then return false, "HOME_SERVICE_UNAVAILABLE" end
    if recover == true then
        return PNC.HomeDutyService.Recover(record, args.baseId)
    end
    if PNC.WorkService and PNC.WorkService.Commands
        and PNC.WorkService.Commands.ReleaseWorker
        and record.runtime and record.runtime.workOrderId
    then
        PNC.WorkService.Commands.ReleaseWorker(record.id, "return_home_requested")
    end
    return PNC.HomeDutyService.SendHome(
        record, args.baseId, "player_requested")
end

local function colonistFollowAction(player, args)
    local record = PNC.Registry and PNC.Registry.Get(args.npcID) or nil
    if not record or record.alive == false or not owned(record, player) then
        return false, "npc_not_owned"
    end
    if not PNC.HomeDutyService or not PNC.HomeDutyService.SendToPlayer then
        return false, "HOME_SERVICE_UNAVAILABLE"
    end
    return PNC.HomeDutyService.SendToPlayer(record, player,
        "player_requested")
end

local function setJobPermission(player, args)
    local record = PNC.Registry and PNC.Registry.Get(args.npcID) or nil
    if not record or record.alive == false or not owned(record, player) then
        return false, "npc_not_owned"
    end
    local job = tostring(args.job or "")
    local known = false
    for _, candidate in ipairs(PNC.WorkDefinitions.COLONY_JOBS or {}) do
        if candidate == job then known = true; break end
    end
    if not known then return false, "UNKNOWN_JOB" end
    record.allowedJobs = record.allowedJobs or {}
    record.allowedJobs[job] = args.enabled == true
    if args.enabled ~= true and record.runtime and record.runtime.workOrderId then
        local order = PNC.WorkRepository.Get(record.runtime.workOrderId)
        if order and PNC.WorkDefinitions.JOB_BY_OPERATION[order.operation] == job then
            PNC.WorkService.Commands.Cancel(order.id, "job_permission_disabled")
        end
    end
    if PNC.Registry.MarkDirty then PNC.Registry.MarkDirty(record, "allowed_jobs") end
    return true, args.enabled == true and "JOB_ENABLED" or "JOB_DISABLED", {
        npcID = record.id, job = job, enabled = args.enabled == true,
    }
end

local function debugFacilityWorkAction(player, args)
    if not canUseDebug(player) then return false, "not_authorized" end
    local record = PNC.Registry and PNC.Registry.Get(args.npcID) or nil
    if not record or record.alive == false or not owned(record, player) then
        return false, "npc_not_owned"
    end
    record.runtime = record.runtime or {}
    if tostring(args.operation or "start") == "stop" then
        local stopped, stopReason = PNC.FacilityJobs.Stop(
            record, "debug_stop")
        return stopped, stopReason, { npcID = record.id }
    end
    local facility = PNC.SettlementRepository.GetFacility(args.facilityId)
    local base = facility and PNC.BaseService.Get(facility.baseId) or nil
    if not base then return false, "FACILITY_NOT_FOUND" end
    if not PNC.BaseValidationService.CanUse(player, base) then
        return false, "NO_PERMISSION"
    end
    return PNC.FacilityJobs.StartForFacility(record, facility.id, {
        debugHold = true,
    })
end

canUseDebug = function(player)
    if not isServer or not isServer() then
        if isDebugEnabled then return isDebugEnabled() == true end
        return getCore and getCore() and getCore():getDebug() == true or false
    end
    local access = player and player.getAccessLevel
        and tostring(player:getAccessLevel() or "") or ""
    return string.lower(access) == "admin"
end

local function debugNeedAction(player, args)
    if not canUseDebug(player) then return false, "not_authorized" end
    local record = PNC.Registry and PNC.Registry.Get(args.npcID) or nil
    if not record or record.alive == false or not owned(record, player) then
        return false, "npc_not_owned"
    end
    if PNC.Recruitment and PNC.Recruitment.ReconcileOwned then
        local reconciled, reconcileReason =
            PNC.Recruitment.ReconcileOwned(player, record)
        if not reconciled and reconcileReason ~= "unchanged" then
            return false, reconcileReason or "membership_repair_failed"
        end
    end
    local operation = tostring(args.operation or "")
    if operation == "modify" then
        local needType = tostring(args.needType or "")
        if not Definitions.Get(needType) then return false, "unknown_need" end
        local amount = math.max(-1, math.min(1, tonumber(args.amount) or 0))
        local value = PNC.IndividualNeeds.Modify(
            record, needType, amount, "colony_debug"
        )
        return value ~= nil, value ~= nil and "updated" or "update_failed", {
            npcID = record.id, needType = needType, value = value,
        }
    end
    if operation == "reset" then
        return PNC.IndividualNeeds.Reset(record) == true, "reset"
    end
    if operation == "force_provision" then
        for _, kind in ipairs({ "FOOD", "HYDRATION", "MEDICAL" }) do
            PNC.NPCSupplyService.ClearRetry(record, kind)
        end
        local _, results = PNC.ProvisionScheduler.ReconcileRecord(record)
        local diagnostics = PNC.ProvisionEvaluator.Inspect(record) or {
            npcID = record.id,
        }
        diagnostics.forceResults = results
        local failed = false
        local attempted = false
        for _, result in ipairs(results or {}) do
            attempted = result.attempted == true or attempted
            if result.ok ~= true then failed = true end
        end
        local reason = failed and "provision_grab_failed"
            or attempted and "provision_grabbed" or "provision_already_satisfied"
        return not failed, reason, diagnostics
    end
    if operation == "inspect_provision" then
        local diagnostics, reason = PNC.ProvisionEvaluator.Inspect(record)
        return diagnostics ~= nil, reason or "provision_inspected", diagnostics
    end
    return false, "unknown_debug_operation"
end
function Management.BuildSnapshot(player, options)
    local people, attention, counts = {}, {}, { hunger={}, thirst={}, fatigue={} }
    local supplyShortages = { food = {}, hydration = {}, medical = {} }
    local playerFaction, colony
    if PNC.Recruitment and PNC.Recruitment.ReconcileOwned then
        for _, record in pairs(PNC.Registry.Data or {}) do
            if record.alive ~= false and owned(record, player) then
                PNC.Recruitment.ReconcileOwned(player, record)
            end
        end
    end
    if PNC.Factions and PNC.Factions.GetPlayerFaction then playerFaction = PNC.Factions.GetPlayerFaction(player) end
    if playerFaction and PNC.Communities and PNC.Communities.GetForFaction then
        for _, value in ipairs(PNC.Communities.GetForFaction(playerFaction.id) or {}) do if value.status == "active" then colony=value; break end end
    end
    for _, record in pairs(PNC.Registry.Data or {}) do
        if record.alive ~= false and owned(record, player) then
            local value = summary(record); people[#people+1]=value
            for _, needType in ipairs(Definitions.TYPES) do
                local level=Definitions.GetLevel(needType, value.needs[needType]); counts[needType][level]=(counts[needType][level] or 0)+1
                if level == "CRITICAL" or level == "SEVERE" or level == "MODERATE" then attention[#attention+1]={ severity=level, npcID=value.id, name=value.name, needType=needType, value=value.needs[needType] } end
            end
            local supply = record.runtime and record.runtime.supply
                and record.runtime.supply.byKind or {}
            for kind, bucket in pairs({
                FOOD = supplyShortages.food,
                HYDRATION = supplyShortages.hydration,
                MEDICAL = supplyShortages.medical,
            }) do
                local lane = supply[kind]
                if lane and lane.phase == "FAILED" then
                    bucket[#bucket + 1] = {
                        npcID = record.id,
                        name = tostring(record.name or record.id),
                        reason = lane.lastFailureReason,
                        nextRetry = lane.nextRetry,
                    }
                end
            end
        end
    end
    table.sort(people,function(a,b) return a.name<b.name end)
    table.sort(attention,function(a,b) return a.value>b.value end)
    local storage = PNC.ColonyStorageService
        and PNC.ColonyStorageService.BuildSnapshot
        and PNC.ColonyStorageService.BuildSnapshot(player, options) or nil
    local storageState = storage and PNC.ColonyStorageRepository
        and PNC.ColonyStorageRepository.Get(storage.storageId) or nil
    local research = PNC.ColonyResearchService
        and PNC.ColonyResearchService.BuildSnapshot(storageState)
        or { entries = {} }
    local workshop = colony and PNC.CraftingService
        and PNC.CraftingService.Queries.BuildSnapshot(colony.id)
        or { knownRecipes = {}, orders = {} }
    local tasks = colony and PNC.WorkService
        and PNC.WorkService.Queries
        and PNC.WorkService.Queries.BuildTaskSnapshot
        and PNC.WorkService.Queries.BuildTaskSnapshot(colony.id) or {}
    local provisionSettings = PNC.ProvisionPolicyService
        and PNC.ProvisionPolicyService.BuildSnapshot
        and PNC.ProvisionPolicyService.BuildSnapshot(player) or nil
    local provisionStorage = PNC.ProvisionEvaluator
        and PNC.ProvisionEvaluator.MeasureStorage
        and PNC.ProvisionEvaluator.MeasureStorage(storageState) or {}
    local base = colony and PNC.BaseService
        and PNC.BaseService.GetForColony(colony.id) or nil
    local settlement = base and PNC.BaseService.BuildSnapshot(base) or nil
    local utilities = base and PNC.WaterUtilityService
        and PNC.WaterUtilityService.BuildSnapshot(base.id)
        or { waterLiters = 0, capacityLiters = 0, tanks = 0,
            catchers = 0, litersPerTenMinutes = 0, facilities = {} }
    if settlement then
        settlement.facilities = {}
        settlement.stockpileNodes = {}
        for facilityId, _ in pairs(base.facilityIds or {}) do
            local facility = PNC.FacilityService.BuildSnapshot(facilityId)
            if facility then settlement.facilities[#settlement.facilities + 1] = facility end
        end
        for nodeId, _ in pairs(base.stockpileNodeIds or {}) do
            local node = PNC.SettlementRepository.GetStockpileNode(nodeId)
            if node then settlement.stockpileNodes[#settlement.stockpileNodes + 1] = PNC.Core.DeepCopy(node) end
        end
        table.sort(settlement.facilities, function(a, b)
            local first = tostring(a.definitionId or "") .. ":"
                .. tostring(a.id or "")
            local second = tostring(b.definitionId or "") .. ":"
                .. tostring(b.id or "")
            return first < second
        end)
        table.sort(settlement.stockpileNodes, function(a, b)
            return tostring(a.id or "") < tostring(b.id or "")
        end)
        local taskByFacility = {}
        for _, task in ipairs(tasks) do
            if task.facilityId then
                taskByFacility[tostring(task.facilityId)] = task
            end
        end
        for _, facility in ipairs(settlement.facilities) do
            facility.activeTask = taskByFacility[tostring(facility.id)]
        end
    end
    local factionSnapshot = playerFaction and {
        id = playerFaction.id,
        name = playerFaction.name,
        archetypeID = playerFaction.archetypeID,
        emblem = PNC.Core.DeepCopy(playerFaction.emblem),
        revision = playerFaction.revision,
        renamePending = playerFaction.tags
            and playerFaction.tags.factionNamePending == true or false,
    } or nil
    return { colony=colony, faction=factionSnapshot,
        people=people, attention=attention, levels=counts,
        storage=storage, research=research, workshop=workshop, tasks=tasks,
        supplyShortages=supplyShortages,
        provisionStorage=provisionStorage,
        provisionSettings=provisionSettings,
        settlement=settlement, utilities=utilities,
        generatedAt=PNC.NeedsUtils.WorldAgeHours() }
end

function Management.SetFactionEmblemForPlayer(player, args)
    args = type(args) == "table" and args or {}
    if not PNC.Factions or not PNC.Factions.SetPlayerFactionEmblem then
        return Management.BuildSnapshot(player), {
            ok = false, reason = "faction_emblem_unavailable",
        }
    end
    local ok, reason, faction = PNC.Factions.SetPlayerFactionEmblem(
        player, args.emblem)
    if ok == true and PNC.Factions.Save then PNC.Factions.Save() end
    return Management.BuildSnapshot(player), {
        ok = ok == true, reason = reason,
        action = "faction_emblem",
        factionID = faction and faction.id or nil,
    }
end

function Management.RenameFactionForPlayer(player, args)
    args = type(args) == "table" and args or {}
    if not PNC.Factions or not PNC.Factions.SetPlayerFactionName then
        return Management.BuildSnapshot(player), {
            ok = false, reason = "faction_rename_unavailable",
        }
    end
    local ok, reason, faction = PNC.Factions.SetPlayerFactionName(
        player, args.name
    )
    if ok == true and PNC.Factions.Save then PNC.Factions.Save() end
    return Management.BuildSnapshot(player), {
        ok = ok == true,
        reason = reason,
        factionID = faction and faction.id or nil,
    }
end

function Management.RenameForPlayer(player, args)
    args = type(args) == "table" and args or {}
    local faction = PNC.Factions and PNC.Factions.GetPlayerFaction
        and PNC.Factions.GetPlayerFaction(player) or nil
    local communityID = tostring(args.communityID or "")
    local allowed = false
    if faction and PNC.Communities and PNC.Communities.GetForFaction then
        for _, community in ipairs(PNC.Communities.GetForFaction(faction.id) or {}) do
            if community.id == communityID and community.status == "active" then
                allowed = true
                break
            end
        end
    end
    if not allowed then
        return Management.BuildSnapshot(player), {
            ok = false, reason = "community_not_owned",
        }
    end
    local ok, reason = PNC.Communities.SetName(
        communityID,
        args.name
    )
    if ok == true and PNC.Communities.Save then
        PNC.Communities.Save()
        if GlobalModData and GlobalModData.save then
            GlobalModData.save()
        end
    end
    return Management.BuildSnapshot(player), {
        ok = ok == true,
        reason = reason,
        communityID = communityID,
    }
end

function Management.HandleAction(player, args)
    args = type(args) == "table" and args or {}
    local action = tostring(args.action or "")
    if action == "rename" then return Management.RenameForPlayer(player, args) end
    if action == "faction_rename" then
        return Management.RenameFactionForPlayer(player, args)
    end
    if action == "faction_emblem" then
        return Management.SetFactionEmblemForPlayer(player, args)
    end
    local ok, reason, details, storage, record
    local settlementActions = {
        base_create = PNC.BaseService and PNC.BaseService.Create,
        base_expand = PNC.BaseService and PNC.BaseService.Expand,
        base_shrink = PNC.BaseService and PNC.BaseService.Shrink,
        barricade_build = PNC.BaseService and PNC.BaseService.BuildBarricade,
        hq_upgrade = PNC.BaseService and PNC.BaseService.UpgradeHQ,
        facility_create = PNC.FacilityService and PNC.FacilityService.Create,
        facility_upgrade = PNC.FacilityService and PNC.FacilityService.Upgrade,
        facility_component_set = PNC.FacilityService and PNC.FacilityService.SetComponent,
        facility_anchor_role_replace = PNC.FacilityService
            and PNC.FacilityService.ReplaceAnchorRole,
        facility_component_remove = PNC.FacilityService and PNC.FacilityService.RemoveComponent,
        facility_destroy = PNC.FacilityService and PNC.FacilityService.Destroy,
        stockpile_node_create = PNC.StockpileAccessService and PNC.StockpileAccessService.Create,
        stockpile_node_remove = PNC.StockpileAccessService and PNC.StockpileAccessService.Remove,
    }
    local settlementHandler = settlementActions[action]
    local cached = args.requestId and Management.SettlementResults[tostring(args.requestId)] or nil
    if settlementHandler and cached then
        details, ok, reason = PNC.Core.DeepCopy(cached), cached.ok, cached.reason
    elseif settlementHandler then
        details = settlementHandler(player, args)
        ok, reason = details and details.ok == true, details and details.reason
        if ok and PNC.SettlementRepository
            and PNC.SettlementRepository.Save
        then
            PNC.SettlementRepository.Save()
        end
        if args.requestId then
            rememberSettlementResult(args.requestId, details)
        end
    elseif action == "storage_player_deposit" then
        ok, reason, details, storage =
            PNC.ColonyStorageService.RequestPlayerDeposit(player, args)
    elseif action == "storage_player_withdraw" then
        ok, reason, details, storage =
            PNC.ColonyStorageService.RequestPlayerWithdrawal(player, args)
    elseif action == "storage_npc_deposit" then
        ok, reason, details, storage, record =
            PNC.ColonyStorageService.RequestNPCDeposit(player, args)
        if record and PNC.Network and PNC.Network.SendInventoryDelta then
            PNC.Network.SendInventoryDelta(
                player, record, tonumber(args.inventoryRevision) or 0
            )
        end
    elseif action == "storage_debug" then
        ok, reason, storage, details =
            PNC.ColonyStorageService.DebugAction(player, args)
    elseif action == "storage_upgrade" then
        ok, reason, storage, details =
            PNC.ColonyStorageService.Upgrade(player, args)
    elseif action == "job_permission_set" then
        ok, reason, details = setJobPermission(player, args)
    elseif action == "colonist_return_home" then
        ok, reason, details = colonistHomeAction(player, args, false)
    elseif action == "colonist_follow_player" then
        ok, reason, details = colonistFollowAction(player, args)
    elseif action == "colonist_recover" then
        ok, reason, details = colonistHomeAction(player, args, true)
    elseif action == "research_queue_technology" then
        details, reason = PNC.ResearchService.Commands.QueueTechnology(
            player, tostring(args.technologyId or ""))
        ok = details ~= nil
    elseif action == "research_study_blueprint" then
        details, reason = PNC.ResearchService.Commands.StudyBlueprint(
            player, args.recordIndex)
        ok = details ~= nil
    elseif action == "research_reverse_engineer" then
        details, reason = PNC.ResearchService.Commands.ReverseEngineer(
            player, args.recordIndex)
        ok = details ~= nil
    elseif action == "blueprint_debug_create" then
        if canUseDebug(player) then
            ok, reason = PNC.ResearchService.Commands.CreateBlueprint(
                player, tostring(args.recipeKey or ""))
        else
            ok, reason = false, "not_authorized"
        end
    elseif action == "production_debug_spear_kit" then
        if canUseDebug(player) then
            ok, details = PNC.ResearchService.Commands.CreateSpearTestKit(player)
            reason = ok and "SPEAR_TEST_KIT_CREATED" or details
        else
            ok, reason = false, "not_authorized"
        end
    elseif action == "craft_queue" then
        details, reason = PNC.CraftingService.Commands.QueueCraft(
            player, args.recipeId, args.quantity)
        ok = details ~= nil
    elseif action == "disassemble_queue" then
        details, reason = PNC.CraftingService.Commands.QueueDisassembly(
            player, args.recordIndex)
        ok = details ~= nil
    elseif action == "work_cancel" then
        ok, details = PNC.WorkService.Commands.CancelForPlayer(player,
            args.workOrderId,
            "player_cancelled")
        reason = ok and "CANCELLED" or details
    elseif action == "work_pause" then
        ok, details = PNC.WorkService.Commands.PauseForPlayer(player,
            args.workOrderId,
            args.paused ~= false)
        reason = ok and "PAUSED" or details
    elseif action == "work_priority" then
        ok, details = PNC.WorkService.Commands.SetPriorityForPlayer(player,
            args.workOrderId, args.priority)
        reason = ok and "PRIORITY_CHANGED" or details
    elseif action == "provision_set" then
        ok, reason, details = PNC.ProvisionPolicyService.Apply(
            player, args.submission
        )
    elseif action == "debug_need" then
        ok, reason, details = debugNeedAction(player, args)
    elseif action == "debug_facility_work" then
        ok, reason, details = debugFacilityWorkAction(player, args)
    else
        ok, reason = false, "unknown_colony_action"
    end
    local snapshot = Management.BuildSnapshot(player)
    return snapshot, {
        ok = ok == true,
        reason = reason,
        details = details,
        storageId = storage and storage.id or nil,
        requestId = args.requestId,
        action = action,
    }
end
return Management
