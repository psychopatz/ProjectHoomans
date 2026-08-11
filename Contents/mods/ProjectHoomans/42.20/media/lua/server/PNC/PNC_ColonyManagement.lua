-- Read-only player colony presentation; canonical Need state remains on NPC records.
if isClient and isClient() and (not isServer or not isServer()) then return end
PNC = PNC or {}
PNC.ColonyManagement = PNC.ColonyManagement or {}
local Management, Definitions = PNC.ColonyManagement, PNC.NeedsDefinitions

local function owned(record, player)
    return PNC.CompanionCommands and PNC.CompanionCommands.IsOwnedByPlayer
        and PNC.CompanionCommands.IsOwnedByPlayer(record, player)
end
local function summary(record)
    local needs = PNC.IndividualNeeds.Ensure(record)
    local priorityType, priority = PNC.IndividualNeeds.GetHighestPriority(record)
    local journal = PNC.Journals and PNC.Journals.GetNPC
        and PNC.Journals.GetNPC(record.id,
            PNC.Journals.NPC_CAPACITY or 32, true)
        or {}
    return { id=record.id, name=tostring(record.name or record.id),
        role=record.affiliation and record.affiliation.communityRole or record.affiliation and record.affiliation.role or "companion",
        activity=PNC.IndividualNeeds.GetActivity(record), job=record.activeJob,
        health=record.health and record.health.state or "unknown", needs=needs,
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
        priorityType=priorityType, priority=priority,
        location={x=record.x,y=record.y,z=record.z} }
end

local function canUseDebug(player)
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
    local people, attention, counts = {}, {}, { hunger={}, hydration={}, fatigue={} }
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
                if level == "EMERGENCY" or level == "CRITICAL" or level == "LOW" then attention[#attention+1]={ severity=level, npcID=value.id, name=value.name, needType=needType, value=value.needs[needType] } end
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
    local provisionSettings = PNC.ProvisionPolicyService
        and PNC.ProvisionPolicyService.BuildSnapshot
        and PNC.ProvisionPolicyService.BuildSnapshot(player) or nil
    local provisionStorage = PNC.ProvisionEvaluator
        and PNC.ProvisionEvaluator.MeasureStorage
        and PNC.ProvisionEvaluator.MeasureStorage(storageState) or {}
    return { colony=colony, people=people, attention=attention, levels=counts,
        storage=storage, research=research, supplyShortages=supplyShortages,
        provisionStorage=provisionStorage,
        provisionSettings=provisionSettings,
        generatedAt=PNC.NeedsUtils.WorldAgeHours() }
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
    local ok, reason, details, storage, record
    if action == "storage_player_deposit" then
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
    elseif action == "research_debug_upgrade" then
        ok, reason, storage = PNC.ColonyResearchService.DebugUpgrade(
            player, tostring(args.researchId or ""), args
        )
    elseif action == "provision_set" then
        ok, reason, details = PNC.ProvisionPolicyService.Apply(
            player, args.submission
        )
    elseif action == "debug_need" then
        ok, reason, details = debugNeedAction(player, args)
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
