--[[
    PNC Behavior Common
    Shared behavior helpers for combat debug state, owner resolution, and
    movement intent routing. Focused modules call through here instead of
    reimplementing the same record mutations.
]]

PNC = PNC or {}
PNC.BehaviorCommon = PNC.BehaviorCommon or {}

local Common = PNC.BehaviorCommon
local Core = PNC.Core
local Const = PNC.Const
local PathService = PNC.PathService
local Equipment = PNC.Equipment
local Combat = PNC.Combat
local NavigationRouter = PNC.NavigationRouter

local function resolveMoveIntent()
    return PNC.BehaviorMoveIntent
end

local function closeEnough(left, right, tolerance)
    left, right = tonumber(left), tonumber(right)
    return left ~= nil and right ~= nil
        and math.abs(left - right) <= (tonumber(tolerance) or 0.2)
end

local function sameMoveTarget(record, x, y, z, mode, stopDistance)
    local intent = record and record.runtime
        and record.runtime.moveIntent or nil
    if not intent or intent.kind ~= "move" then return false end
    return closeEnough(intent.finalX or intent.x, x)
        and closeEnough(intent.finalY or intent.y, y)
        and closeEnough(intent.finalZ or intent.z, z, 0.05)
        and tostring(intent.mode or "walk") == tostring(mode or "walk")
        and closeEnough(intent.stopDistance or 0.7, stopDistance or 0.7,
            0.05)
end

local function shouldInterruptScene(record, x, y, z, mode, stopDistance)
    local runtime = record and record.runtime or nil
    local scene = runtime and runtime.animationScene or nil
    local intent = runtime and runtime.moveIntent or nil
    if not scene then return false end
    if not sameMoveTarget(record, x, y, z, mode, stopDistance) then
        return true
    end
    -- A scene started after the last identical movement intent (for example a
    -- combat/action bump) still needs one interruption. Once that transition
    -- has happened, repeated movement ticks must not reset the scene again.
    return tonumber(scene.startedAt) ~= nil
        and tonumber(intent and intent.updatedAt) ~= nil
        and tonumber(scene.startedAt) > tonumber(intent.updatedAt)
end

function Common.SetCombatDebug(record, target, reason, modeResolved, weaponStatus)
    record.runtime = record.runtime or {}
    record.runtime.targetKind = target and target.kind or "none"
    record.runtime.combatModeResolved = modeResolved or tostring(record.weaponMode or "melee")
    record.runtime.weaponStatus = weaponStatus or record.runtime.weaponStatus or "unknown"
    record.runtime.combatBlockReason = reason or "idle"
end

function Common.ClearCombatTarget(record, reason, zombie)
    local equipmentInfo = Equipment.Describe(record)
    local committedAttack
    record.runtime = record.runtime or {}
    record.runtime.target = nil
    committedAttack = Combat and Combat.HasActiveAttack
        and Combat.HasActiveAttack(record, Core.Now())
        or false
    if not committedAttack then
        -- A combat hold is useful while a target is being reassessed, but an
        -- explicit disengage is authoritative. Leaving the old lease alive
        -- kept both the activity label and weapon presentation in Fighting
        -- after ordinary movement had already resumed.
        record.runtime.inCombatUntil = 0
    end
    if not zombie and PNC.Registry and PNC.Registry.GetLiveZombie then
        zombie = PNC.Registry.GetLiveZombie(record.id)
    end
    if Equipment.ApplyCombatState and zombie then
        Equipment.ApplyCombatState(zombie, record, committedAttack)
    end
    Common.SetCombatDebug(
        record,
        nil,
        reason or "no_target",
        equipmentInfo.combatModeResolved or tostring(record.weaponMode or "melee"),
        equipmentInfo.weaponStatus or record.runtime.weaponStatus
    )
end

function Common.GetOwner(record)
    return Core.ResolvePlayerByOnlineID(record.ownerOnlineID) or Core.ResolvePlayerByUsername(record.ownerUsername)
end

function Common.MoveRecord(
    record,
    zombie,
    tx,
    ty,
    tz,
    mode,
    stopDistance,
    reason,
    navigationOptions
)
    local moveReason = reason
        or (record and record.runtime and record.runtime.combatBlockReason)
        or (record and record.activeBehavior and ("move_" .. tostring(record.activeBehavior)))
        or (record and record.activeJob and ("move_" .. tostring(record.activeJob)))
        or "behavior_move"
    local finalX = tx
    local finalY = ty
    local finalZ = tz
    local policyName
    local providerName
    local policy
    local steeringTarget
    local intentNavigation = navigationOptions
    local moveIntent
    if record.presenceState == Const.PRESENCE_LIVE then
        if shouldInterruptScene(record, finalX, finalY, finalZ, mode,
            stopDistance)
            and PNC.AnimationScenes
            and PNC.AnimationScenes.Interrupt
        then
            PNC.AnimationScenes.Interrupt(
                record,
                zombie,
                "movement"
            )
        end
        if NavigationRouter and NavigationRouter.Resolve then
            policyName, providerName, policy = NavigationRouter.Resolve(
                record,
                moveReason,
                navigationOptions,
                zombie
            )
            -- The direct route is allocation-free. This is the normal combat
            -- and kiting path, where goals can change on every behavior tick.
            if providerName ~= NavigationRouter.DIRECT_PROVIDER
                and NavigationRouter.GetSteeringTarget
            then
                steeringTarget = NavigationRouter.GetSteeringTarget(
                    record,
                    zombie,
                    {
                        x = finalX,
                        y = finalY,
                        z = finalZ,
                        mode = mode,
                        stopDistance = stopDistance,
                    },
                    policyName,
                    providerName,
                    policy
                )
                if steeringTarget then
                    tx = steeringTarget.x
                    ty = steeringTarget.y
                    tz = steeringTarget.z
                    mode = steeringTarget.mode or mode
                    stopDistance = steeringTarget.stopDistance
                        or stopDistance
                end
            end
            if providerName ~= NavigationRouter.DIRECT_PROVIDER then
                intentNavigation = {
                    navigationPolicy = policyName,
                    navigationProvider = providerName,
                    finalX = finalX,
                    finalY = finalY,
                    finalZ = finalZ,
                    waypointIndex = steeringTarget
                        and steeringTarget.waypointIndex or nil,
                    steeringIndex = steeringTarget
                        and steeringTarget.steeringIndex or nil,
                    steeringKind = steeringTarget
                        and steeringTarget.steeringKind or nil,
                }
            end
        end
        moveIntent = resolveMoveIntent()
        if moveIntent and moveIntent.RequestMove then
            moveIntent.RequestMove(
                record,
                tx,
                ty,
                tz,
                mode,
                stopDistance,
                moveReason,
                intentNavigation
            )
            return true, "move_intent"
        end
        return PathService.MoveToward(
            record,
            zombie,
            tx,
            ty,
            tz,
            mode,
            stopDistance,
            moveReason,
            intentNavigation
        )
    end
    PathService.AdvanceAbstract(record, tx, ty, tz, stopDistance)
    return true, "abstract_move"
end

function Common.ResolveCombatApproachMode(dist, preferredMode)
    if preferredMode == "run" and tonumber(dist) and tonumber(dist) <= 3.5 then
        return "walk"
    end
    return preferredMode
end

function Common.HaltMovement(record, zombie, reason)
    local moveIntent = resolveMoveIntent()
    if record and record.presenceState == Const.PRESENCE_LIVE
        and moveIntent and moveIntent.Hold
    then
        moveIntent.Hold(record, reason or "hold")
        return
    end
    if zombie and PathService and PathService.Reset then
        if PathService.Commands and PathService.Commands.Reset then
            PathService.Commands.Reset(record, zombie, reason)
        else
            PathService.Reset(zombie, record, reason)
        end
    end
end
