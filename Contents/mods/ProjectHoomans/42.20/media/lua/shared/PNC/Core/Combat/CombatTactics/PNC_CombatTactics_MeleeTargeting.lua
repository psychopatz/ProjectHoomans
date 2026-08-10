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

function Tactics.GetMeleeApproachPoint(record, target)
    local candidates
    local other
    local allyCount = 0
    local angle
    local radius
    local x
    local y
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
    angle = Internal.StableDirection(record.id)
    radius = tonumber(Const.COMBAT_FORMATION_SLOT_RADIUS) or 1.05
    x = target.x + math.cos(angle) * radius
    y = target.y + math.sin(angle) * radius
    if TraversalQuery and TraversalQuery.CanOccupy
        and not TraversalQuery.CanOccupy(x, y, target.z or record.z)
    then
        angle = angle + math.pi
        x = target.x + math.cos(angle) * radius
        y = target.y + math.sin(angle) * radius
    end
    return x, y, true
end

return Tactics
