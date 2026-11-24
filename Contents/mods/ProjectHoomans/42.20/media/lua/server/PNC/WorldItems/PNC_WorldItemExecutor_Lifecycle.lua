-- Tasking lifecycle callbacks (candidates, validate, assign, start, continue, recovery).
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorldItemExecutor = PNC.WorldItemExecutor or {}
PNC.WorldItemExecutor.Internal = PNC.WorldItemExecutor.Internal or {}

local Executor = PNC.WorldItemExecutor
local Internal = Executor.Internal
local Service = PNC.WorldItemService
local Common = PNC.BehaviorCommon

local function nowMs()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

local function isCombatBlocking(record, now)
    local rt = record and record.runtime or nil
    if not rt then return false end
    if rt.target ~= nil or rt.attackAction ~= nil then return true end
    if now < (tonumber(rt.inCombatUntil) or 0) then return true end
    if rt.recentThreat and now <= (tonumber(rt.recentThreat.expiresAt) or 0) then return true end
    return false
end

function Executor.GetCandidates(npcId)
    local intent = Service.GetActiveIntent(npcId)
    local record = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(npcId) or nil
    if not intent or not record or record.alive == false then return {} end
    return {
        {
            taskId = "world_item:" .. tostring(intent.id) .. ":" .. tostring(npcId),
            npcId = tostring(npcId),
            kind = intent.action == "rip_bandage" and "RIP_CLOTHING" or "WORLD_LOOT",
            sourceDomain = "world_item",
            sourceRef = intent.id,
            precedence = intent.precedence or "NORMAL_NEED",
            urgency = tonumber(intent.urgency) or 0.72,
            capability = "WORLD_ITEM",
            interruptPolicy = "NORMAL",
            revision = intent.revision or 1,
            createdAt = intent.createdAt or nowMs(),
        },
    }
end

function Executor.Validate(taskIntent)
    local npcId = taskIntent and taskIntent.npcId
    local active = Service.GetActiveIntent(npcId)
    if not active or tostring(active.id) ~= tostring(taskIntent and taskIntent.sourceRef or "") then
        return false
    end
    return Internal.IsCandidateStillValid(active) == true
end

function Executor.Assign(taskIntent)
    local npcId = taskIntent and taskIntent.npcId
    local active = Service.GetActiveIntent(npcId)
    if not active then return nil, "world_item_intent_missing" end
    return { executionMode = "LIVE", resourceKey = active.id, resourceKind = active.action }
end

function Executor.Start(lease)
    local intent = Service.GetActiveIntent(lease and lease.npcId)
    local record = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(lease.npcId) or nil
    if not intent or not record then return false, "world_item_unavailable" end
    intent.phase = "TRAVEL"
    intent.leaseId = lease.leaseId
    intent.updatedAt = nowMs()
    record.runtime = record.runtime or {}
    record.runtime.worldItem = {
        action = intent.action,
        purpose = intent.purpose,
        phase = "TRAVEL",
        itemFullType = intent.candidate and intent.candidate.itemCtx
            and intent.candidate.itemCtx.fullType or nil,
    }
    if PNC.Tasking and PNC.Tasking.Commands and PNC.Tasking.Commands.SetPhase then
        PNC.Tasking.Commands.SetPhase(lease.npcId, "TRAVEL")
    end
    return true
end

function Executor.CanContinue(lease)
    local intent = Service.GetActiveIntent(lease and lease.npcId)
    local record = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(lease.npcId) or nil
    if not intent or not record or record.alive == false then return false end
    if isCombatBlocking(record, nowMs()) then return false end
    if intent.purpose == "companion_scavenge" and intent.maxLeashDist then
        local owner = Common and Common.GetOwner and Common.GetOwner(record) or nil
        if owner and owner.getX then
            if owner.getVehicle and owner:getVehicle() ~= nil then return false end
            local dx = (tonumber(record.x) or 0) - owner:getX()
            local dy = (tonumber(record.y) or 0) - owner:getY()
            if dx * dx + dy * dy > (intent.maxLeashDist + 2) * (intent.maxLeashDist + 2) then
                return false
            end
        end
    end
    return Internal.IsCandidateStillValid(intent) == true
end

function Executor.GetRecoveryState(lease)
    local intent = Service.GetActiveIntent(lease and lease.npcId)
    if not intent then return { terminal = true } end
    local record = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(lease.npcId) or nil
    local snapshot = {
        phase = intent.phase == "INTERACTING" and "WORKING" or "TRAVEL",
        lastProgressAt = intent.actionStartedAt or intent.updatedAt or lease.lastProgressAt,
        watchable = true,
    }
    if snapshot.phase == "TRAVEL" and PNC.Tasking and PNC.Tasking.Commands
        and PNC.Tasking.Commands.ApplyMovementRecovery
    then
        snapshot = PNC.Tasking.Commands.ApplyMovementRecovery(snapshot, lease, record)
    else
        snapshot.timeoutMs = 10000
        snapshot.recoveryReason = "world_item_interact_timeout"
    end
    return snapshot
end

return Executor
