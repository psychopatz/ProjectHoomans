-- Tactical Flee Behavior + Far-Migration Handoff (especially for looters and
-- defeated/spared human NPCs).
PNC = PNC or {}
PNC.BehaviorFlee = PNC.BehaviorFlee or {}

local Flee = PNC.BehaviorFlee

local DEFAULT_SAFE_DISTANCE = 55
local DEFAULT_STEP_DISTANCE = 24
local DEFAULT_MIGRATE_MIN_DIST = 350
local DEFAULT_MIGRATE_MAX_DIST = 1400

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return tonumber(PNC.Core.Now()) or 0
    end
    return 0
end

function Flee.ComputeFleeGoal(record, threatX, threatY, stepDist)
    local rx = tonumber(record and record.x) or 0
    local ry = tonumber(record and record.y) or 0
    local tx = tonumber(threatX) or rx
    local ty = tonumber(threatY) or ry
    local dx, dy = rx - tx, ry - ty
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.01 then
        -- Deterministic fallback bearing from NPC ID so fleeing NPCs fan out.
        local seed = 0
        local idStr = tostring(record and record.id or "flee")
        for i = 1, #idStr do
            seed = (seed * 31 + string.byte(idStr, i)) % 360
        end
        local rad = math.rad(seed)
        dx, dy, len = math.cos(rad), math.sin(rad), 1
    end
    local dist = tonumber(stepDist) or DEFAULT_STEP_DISTANCE
    return math.floor(rx + (dx / len) * dist), math.floor(ry + (dy / len) * dist)
end

function Flee.StartFlee(record, opts, at)
    if type(record) ~= "table" or record.alive == false then return false, "invalid_record" end
    opts = type(opts) == "table" and opts or {}
    local now = nowMs(at)
    local tx = tonumber(opts.threatX) or tonumber(record.x) or 0
    local ty = tonumber(opts.threatY) or tonumber(record.y) or 0
    local reason = tostring(opts.reason or "morale_break")

    record.activeBehavior = "flee"
    record.isHostile = false
    if type(record.runtime) == "table" then
        record.runtime.target = nil
        record.runtime.combatTarget = nil
        record.runtime.attackAction = nil
        record.runtime.inCombatUntil = 0
    end

    local gx, gy = Flee.ComputeFleeGoal(record, tx, ty, opts.stepDist)
    record.fleeState = {
        active = true,
        reason = reason,
        threatX = tx,
        threatY = ty,
        goalX = gx,
        goalY = gy,
        safeDist = tonumber(opts.safeDist) or DEFAULT_SAFE_DISTANCE,
        startedAt = now,
        migrated = false,
    }

    local Beats = PNC.Semantics and PNC.Semantics.DialogueBeats or nil
    if Beats and type(Beats.Emit) == "function" then
        local role = reason == "spared" and "flee_spared"
            or (reason == "last_standing" and "flee_last_standing" or "flee_morale_break")
        Beats.Emit("combat.flee", {
            anchor = record,
            speaker = record,
            role = role,
            poolID = "semantic.combat.flee",
        }, now)
    end
    return true, record.fleeState
end

function Flee.Step(record, at)
    if type(record) ~= "table" or type(record.fleeState) ~= "table" or record.fleeState.active ~= true then
        return false, "not_fleeing"
    end
    local st = record.fleeState
    local rx = tonumber(record.x) or 0
    local ry = tonumber(record.y) or 0
    local dx = rx - (tonumber(st.threatX) or rx)
    local dy = ry - (tonumber(st.threatY) or ry)
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist >= (tonumber(st.safeDist) or DEFAULT_SAFE_DISTANCE) then
        st.active = false
        st.migrated = true
        -- Handoff to strengthened AbstractTraversal far-migration!
        local Traversal = PNC.AbstractTraversal
        local group = record.abstractGroupId and PNC.AbstractGroups
            and PNC.AbstractGroups.Get and PNC.AbstractGroups.Get(record.abstractGroupId) or nil
        if group and Traversal and type(Traversal.BeginFarMigration) == "function" then
            local ok, reason = Traversal.BeginFarMigration(group, {
                threatX = st.threatX,
                threatY = st.threatY,
                minDistance = DEFAULT_MIGRATE_MIN_DIST,
                maxDistance = DEFAULT_MIGRATE_MAX_DIST,
            }, at)
            return ok, ok and "far_migration_started" or reason
        end
        return true, "flee_safe_clear"
    end

    local gx, gy = Flee.ComputeFleeGoal(record, st.threatX, st.threatY, DEFAULT_STEP_DISTANCE)
    st.goalX, st.goalY = gx, gy
    local common = PNC.BehaviorCommon
    if common and type(common.MoveRecordTo) == "function" then
        common.MoveRecordTo(record, gx, gy, tonumber(record.z) or 0, { run = true, reason = "flee" })
    end
    return true, "fleeing"
end

return Flee
