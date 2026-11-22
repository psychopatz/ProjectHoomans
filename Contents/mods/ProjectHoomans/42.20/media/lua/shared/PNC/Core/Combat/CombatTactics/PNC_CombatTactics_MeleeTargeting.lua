-- Ground-target checks and melee formation approach points.

PNC = PNC or {}
PNC.CombatTactics = PNC.CombatTactics or {}

local Tactics = PNC.CombatTactics
Tactics.Internal = Tactics.Internal or {}

local Internal = Tactics.Internal
local Const = PNC.Const
local Perception = PNC.Perception
local Spatial = PNC.SpatialIndex
local TraversalQuery = PNC.TraversalQuery

local MELEE_SLOT_ANGLE_OFFSETS = {
    0,
    math.pi / 4,
    -math.pi / 4,
    math.pi / 2,
    -math.pi / 2,
    3 * math.pi / 4,
    -3 * math.pi / 4,
    math.pi,
}
local HARD_STEP_BLOCK_REASONS = {
    wall = true,
    window = true,
    door = true,
    fence = true,
    blocked_edge = true,
    unloaded = true,
    vehicle = true,
}
local ALLY_SLOT_CROWD_DIST_SQ = 0.65 * 0.65

local function targetObject(target)
    if not target then return nil end
    if target.kind == "zombie" then
        return Perception and Perception.FindZombieByID
            and Perception.FindZombieByID(target.zombieId) or nil
    end
    if target.kind == "player" then return target.player end
    return nil
end

function Tactics.IsGroundTarget(target)
    local object = targetObject(target)
    local Unarmed = PNC.CombatUnarmed
    return object ~= nil
        and Unarmed
        and Unarmed.IsGroundTarget
        and Unarmed.IsGroundTarget(object) == true
end

function Tactics.ShouldUseGroundFinisher(record, target)
    local report
    if not Tactics.IsGroundTarget(target) then
        return false, "target_not_grounded"
    end
    report = Internal.AssessThreat(record, target)
    if report.pressureCount
        > (tonumber(Const.COMBAT_GROUND_FINISHER_MAX_PRESSURE) or 1)
    then
        return false, "ground_finisher_unsafe"
    end
    return true, "ground_finisher_safe"
end

function Tactics.ResolveMeleeApproach(record, dist)
    local state = Internal.EnsureRetreatState(record)
    local shouldApproach
    local preferredMode
    dist = tonumber(dist) or math.huge
    if not state then return false, Const.MELEE_RANGE, "walk" end
    if state.approachActive then
        if dist <= (Const.MELEE_RANGE - Const.COMBAT_KITE_MELEE_STOP_BUFFER) then
            state.approachActive = false
        end
    elseif dist > (Const.MELEE_RANGE + Const.COMBAT_KITE_MELEE_ENTER_BUFFER) then
        state.approachActive = true
    end
    shouldApproach = state.approachActive == true
    preferredMode = dist
        > (Const.MELEE_RANGE + Const.COMBAT_KITE_MELEE_HOLD_BUFFER)
        and "run" or "walk"
    return shouldApproach,
        tonumber(Const.MELEE_APPROACH_STOP_DISTANCE)
            or math.max(0.75, (tonumber(Const.MELEE_RANGE) or 1.3) - 0.35),
        preferredMode
end

local function isValidMeleeSlot(cx, cy, slotZ, tx, ty)
    local canOccupy = TraversalQuery and TraversalQuery.CanOccupy or nil
    local canStep = TraversalQuery and TraversalQuery.CanStep or nil
    local stepped
    local stepReason
    if canOccupy and not canOccupy(cx, cy, slotZ) then
        return false
    end
    if canStep then
        stepped, stepReason = canStep(cx, cy, slotZ, tx, ty, slotZ)
        if not stepped and HARD_STEP_BLOCK_REASONS[stepReason] then
            return false
        end
    end
    return true
end

local function countNearbySlotAllies(record, target, candidates, cx, cy)
    local crowded = 0
    local other
    local ox
    local oy
    local dx
    local dy
    local j
    for j = 1, #candidates do
        other = candidates[j]
        if Internal.IsProtectedNPC(record, other, target)
            and math.abs((tonumber(other.z) or record.z) - record.z) < 1
        then
            ox = tonumber(other.x)
            oy = tonumber(other.y)
            if ox and oy then
                dx = ox - cx
                dy = oy - cy
                if ((dx * dx) + (dy * dy)) < ALLY_SLOT_CROWD_DIST_SQ then
                    crowded = crowded + 1
                end
            end
        end
    end
    return crowded
end

function Tactics.GetMeleeApproachPoint(record, target)
    local candidates
    local other
    local allyCount = 0
    local baseAngle
    local radius
    local slotZ
    local bestX
    local bestY
    local bestCrowded
    local i
    if not record or not target or not Spatial or not Spatial.QueryNPCs then
        return target and target.x, target and target.y, false
    end
    candidates = Spatial.QueryNPCs(
        target.x, target.y,
        tonumber(Const.COMBAT_FORMATION_QUERY_RADIUS) or 2.4
    )
    for i = 1, #candidates do
        other = candidates[i]
        if Internal.IsProtectedNPC(record, other, target)
            and math.abs((tonumber(other.z) or record.z) - record.z) < 1
        then
            allyCount = allyCount + 1
        end
    end
    if allyCount <= 0 then return target.x, target.y, false end
    baseAngle = Internal.StableDirection(record.id)
    radius = tonumber(Const.COMBAT_FORMATION_SLOT_RADIUS) or 1.05
    slotZ = target.z or record.z
    for i = 1, #MELEE_SLOT_ANGLE_OFFSETS do
        local angle = baseAngle + MELEE_SLOT_ANGLE_OFFSETS[i]
        local cx = target.x + math.cos(angle) * radius
        local cy = target.y + math.sin(angle) * radius
        if isValidMeleeSlot(cx, cy, slotZ, target.x, target.y) then
            local crowded = countNearbySlotAllies(
                record, target, candidates, cx, cy
            )
            if crowded == 0 then
                return cx, cy, true
            end
            if bestCrowded == nil or crowded < bestCrowded then
                bestX, bestY, bestCrowded = cx, cy, crowded
            end
        end
    end
    if bestX ~= nil then
        return bestX, bestY, true
    end
    return target.x, target.y, false
end

return Tactics
