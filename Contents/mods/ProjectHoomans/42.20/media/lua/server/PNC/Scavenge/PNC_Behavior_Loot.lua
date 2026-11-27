-- Unified, actor-agnostic opportunistic looting behavior.
-- Works identically for player followers (respecting ScavengePolicy + leash)
-- and AI-owned NPCs (mobile scavengers, roamers, raiders/looters).

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

require "PNC/Scavenge/PNC_WorldLoot_Transfer"

PNC = PNC or {}
PNC.BehaviorLoot = PNC.BehaviorLoot or {}

local BehaviorLoot = PNC.BehaviorLoot
local WorldLoot = PNC.WorldLoot

local PICKUP_RANGE_SQ = 2.56 -- 1.6 tiles
local DEFAULT_TARGET_TIMEOUT_MS = 8000

local function clearTarget(record)
    local rt = record and record.runtime or nil
    if rt and rt.lootTarget then
        WorldLoot.ReleaseClaim(rt.lootTarget.targetKey, record.id)
        rt.lootTarget = nil
    end
end

local function isBlockedByHigherPriority(record)
    local rt = type(record.runtime) == "table" and record.runtime or nil
    if not rt then return false end
    if rt.inCombat == true or rt.suicideState ~= nil or rt.incapacitated == true then
        return true
    end
    return false
end

local function exceedsLeaderLeash(record, opts)
    local leader = opts and opts.leader or nil
    local maxLeash = tonumber(opts and opts.maxLeashDist) or 10
    if not leader then return false end
    local lx, ly = tonumber(leader.x), tonumber(leader.y)
    if not lx or not ly then return false end
    local dx = (tonumber(record.x) or 0) - lx
    local dy = (tonumber(record.y) or 0) - ly
    return (dx * dx + dy * dy) > (maxLeash * maxLeash)
end

-- Executes one bounded opportunistic loot step for `record`.
-- Returns (active, status, payload).
function BehaviorLoot.Tick(record, nowMs, opts)
    if type(record) ~= "table" or record.alive == false then
        return false, "dead"
    end
    opts = type(opts) == "table" and opts or {}
    nowMs = tonumber(nowMs) or (PNC.Core and PNC.Core.Now and PNC.Core.Now()) or 0

    if isBlockedByHigherPriority(record) or exceedsLeaderLeash(record, opts) then
        clearTarget(record)
        return false, "yielded"
    end

    local policy = opts.policy or WorldLoot.ResolvePolicy(record, opts.ownerPlayer)
    if not policy or policy.enabled ~= true then
        clearTarget(record)
        return false, "disabled"
    end

    record.runtime = type(record.runtime) == "table" and record.runtime or {}
    local target = record.runtime.lootTarget

    if not target then
        local scanned, reason = WorldLoot.ScanNearbyTarget(record, nowMs, {
            policy = policy,
            ownerPlayer = opts.ownerPlayer,
            radius = opts.radius,
            cell = opts.cell,
            cooldownMs = opts.cooldownMs,
            bypassCooldown = opts.bypassCooldown,
            bypassBudget = opts.bypassBudget,
        })
        if not scanned then
            if reason == "inventory_full" then
                local beats = PNC.Semantics and PNC.Semantics.DialogueBeats or nil
                if beats and type(beats.EmitWorldLootPackFull) == "function" then
                    pcall(beats.EmitWorldLootPackFull, record, opts.ownerPlayer or opts.leader, nowMs)
                end
            end
            return false, reason or "no_target"
        end
        scanned.startedAt = nowMs
        record.runtime.lootTarget = scanned
        target = scanned
    end

    -- Timeout guard so an unreachable shelf never traps an NPC
    local timeout = tonumber(opts.targetTimeoutMs) or DEFAULT_TARGET_TIMEOUT_MS
    if (nowMs - (tonumber(target.startedAt) or nowMs)) > timeout then
        clearTarget(record)
        return false, "timeout"
    end

    -- Distance check to target tile
    local dx = (tonumber(target.x) or 0) - (tonumber(record.x) or 0)
    local dy = (tonumber(target.y) or 0) - (tonumber(record.y) or 0)
    if (dx * dx + dy * dy) <= PICKUP_RANGE_SQ then
        local ok, result = WorldLoot.CollectTarget(record, target, nowMs, policy)
        record.runtime.lootTarget = nil
        if ok then
            return true, "collected", result
        end
        return false, result
    end

    -- Dispatch movement toward loot target
    if type(opts.moveFn) == "function" then
        opts.moveFn(record, target.x, target.y, target.z)
    elseif PNC.BehaviorCommon and type(PNC.BehaviorCommon.MoveRecord) == "function" then
        local zombie = PNC.Registry and type(PNC.Registry.GetLiveZombie) == "function"
            and PNC.Registry.GetLiveZombie(record.id) or nil
        pcall(
            PNC.BehaviorCommon.MoveRecord,
            record,
            zombie,
            target.x,
            target.y,
            target.z or 0,
            "walk",
            1.2,
            "opportunistic_loot"
        )
    end
    return true, "moving", target
end

function BehaviorLoot.Cancel(record)
    clearTarget(record)
end

return BehaviorLoot
