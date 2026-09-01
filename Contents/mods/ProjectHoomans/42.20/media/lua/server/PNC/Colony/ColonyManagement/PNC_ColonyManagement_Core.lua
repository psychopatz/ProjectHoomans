if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ColonyManagement = PNC.ColonyManagement or {}
PNC.ColonyManagement.Internal = PNC.ColonyManagement.Internal or {}

local Management = PNC.ColonyManagement
local Internal = Management.Internal
local Definitions = PNC.NeedsDefinitions
local canUseDebug = Internal.canUseDebug

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

local function specialOrderState(record)
    local output = {}
    local npcId = record and record.id or nil
    local fishing = PNC.FishingService
    local fishingJob = fishing and fishing.GetJob
        and fishing.GetJob(npcId) or nil
    output.Fishing = fishingJob and fishingJob.active == true or false
    local lumber = PNC.LumberService
    local lumberJob = lumber and lumber.GetJob
        and lumber.GetJob(npcId) or nil
    output.Lumber = lumberJob and lumberJob.active == true or false
    local lease = PNC.TaskLeaseService and PNC.TaskLeaseService.ForNPC
        and PNC.TaskLeaseService.ForNPC(npcId) or nil
    output.CorpseHaul = lease and lease.sourceDomain == "corpse_haul" or false
    return output
end

local function summary(record, player)
    local needs = PNC.IndividualNeeds.Ensure(record)
    local nutrition = PNC.IndividualNeeds.GetNutrition
        and PNC.IndividualNeeds.GetNutrition(record) or nil
    local priorityType, priority = PNC.IndividualNeeds.GetHighestPriority(record)
    local needsView = PNC.NeedsEvaluator
        and PNC.NeedsEvaluator.Queries.BuildNeedsView(record) or {}
    local moraleView = PNC.NeedsEvaluator
        and PNC.NeedsEvaluator.Queries.BuildView(record)
        or { score = record.social and record.social.morale or 0,
            modifiers = {} }
    local journal = PNC.Journals and PNC.Journals.GetNPC
        and PNC.Journals.GetNPC(record.id,
            PNC.Journals.NPC_CAPACITY or 32, true)
        or {}
    local order = record.orderSpec or {}
    local playerOnlineID = player and player.getOnlineID
        and tonumber(player:getOnlineID()) or nil
    local playerUsername = player and player.getUsername
        and tostring(player:getUsername() or "") or ""
    local targetOnlineID = tonumber(order.ownerOnlineID
        or record.ownerOnlineID)
    local targetUsername = tostring(order.ownerUsername
        or record.ownerUsername or "")
    local followingCurrentPlayer = tostring(order.kind or "")
        == tostring(PNC.Const and PNC.Const.ORDER_FOLLOW or "follow")
        and (playerOnlineID ~= nil and targetOnlineID ~= nil
            and playerOnlineID == targetOnlineID
            or playerUsername ~= "" and playerUsername == targetUsername)
    return { id=record.id, name=tostring(record.name or record.id),
        role=record.affiliation and record.affiliation.communityRole or record.affiliation and record.affiliation.role or "companion",
        activity=PNC.IndividualNeeds.GetActivity(record), job=record.activeJob,
        health=record.health and record.health.state or "unknown", needs=needs,
        nutrition=nutrition,
        conditionStats=PNC.ConditionStats
            and PNC.ConditionStats.Ensure(record,
                PNC.NeedsUtils.WorldAgeHours()) or {},
        needsView=needsView, morale=moraleView.score,
        moraleModifiers=moraleView.modifiers,
        presenceState=record.presenceState,
        actionInformation=PNC.ActivityStatus
            and PNC.ActivityStatus.Build
            and PNC.ActivityStatus.Build(record) or nil,
        manualActivityDisabled=record.runtime
            and record.runtime.manualActivityDisabled or nil,
        provision=PNC.ProvisionEvaluator
            and PNC.ProvisionEvaluator.GetDebugState
            and PNC.ProvisionEvaluator.GetDebugState(record) or {},
        supply=PNC.NPCSupplyService
            and PNC.NPCSupplyService.GetDebugState
            and PNC.NPCSupplyService.GetDebugState(record) or {},
        journal=journal,
        allowedJobs=effectiveAllowedJobs(record),
        specialOrders=specialOrderState(record),
        home=PNC.HomeDutyService and PNC.HomeDutyService.BuildState
            and PNC.HomeDutyService.BuildState(record) or nil,
        storageCourier=record.runtime and record.runtime.storageCourier
            and PNC.Core.DeepCopy(record.runtime.storageCourier) or nil,
        facilityDebugWork=record.runtime and record.runtime.facilityDebugWork
            and PNC.Core.DeepCopy(record.runtime.facilityDebugWork) or nil,
        order=PNC.Core.DeepCopy(order),
        followingCurrentPlayer=followingCurrentPlayer == true,
        priorityType=priorityType, priority=priority,
        location={x=record.x,y=record.y,z=record.z} }
end



Internal.rememberSettlementResult = rememberSettlementResult
Internal.owned = owned
Internal.effectiveAllowedJobs = effectiveAllowedJobs
Internal.summary = summary

return Management
