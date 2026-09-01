local Renderer = PNC.NameplateRenderer
local Internal = Renderer.Internal
local NameplateDebug = PNC.NameplateDebug
local rounded = Internal.Rounded

function Renderer.BuildPathDebugLines(debugState, currentFinalDistance)
    local lines = {}
    local policy
    local provider
    local route
    local movement
    local diagnostic
    local pathIndex
    local pathLength
    local steeringIndex
    local goalDistance
    local finalDistance
    local turnDot
    local turnDegrees
    if type(debugState) ~= "table" then return lines end
    policy = tostring(debugState.navigationPolicy or "unknown")
    provider = tostring(debugState.navigationProvider or "unknown")
    route = tostring(
        debugState.navigationPlanReason
            or debugState.navigationSteeringKind
            or "direct"
    )
    pathIndex = tonumber(debugState.navigationPathIndex)
    steeringIndex = tonumber(
        debugState.navigationSteeringIndex
    )
    pathLength = tonumber(debugState.navigationPathLength) or 0
    if pathIndex and pathLength > 0 then
        route = route .. " wp=" .. tostring(pathIndex)
            .. "/" .. tostring(pathLength)
        if steeringIndex and steeringIndex ~= pathIndex then
            route = route .. " aim=" .. tostring(steeringIndex)
        end
    elseif debugState.navigationSteeringKind then
        route = route .. " " .. tostring(
            debugState.navigationSteeringKind
        )
    end
    if debugState.navigationTraversalKind then
        route = route .. " edge="
            .. tostring(debugState.navigationTraversalKind)
    end
    lines[#lines + 1] = "NAV " .. policy .. "/" .. provider
        .. " | " .. route

    goalDistance = rounded(debugState.moveGoalDistance, 2)
    finalDistance = rounded(
        currentFinalDistance or debugState.moveFinalDistance,
        2
    )
    movement = tostring(debugState.movePhase or "idle")
        .. "/" .. tostring(debugState.moveMode or "-")
        .. " step=" .. tostring(debugState.moveLastStep or "-")
    if goalDistance then movement = movement .. " goal=" .. goalDistance end
    if finalDistance then movement = movement .. " final=" .. finalDistance end
    movement = movement .. " np="
        .. tostring(tonumber(debugState.moveNonProgressSteps) or 0)
    if (tonumber(debugState.moveRetargetCount) or 0) > 0 then
        movement = movement .. " rt="
            .. tostring(tonumber(debugState.moveRetargetCount) or 0)
    end
    turnDot = tonumber(debugState.moveSteeringTurnDot)
    if turnDot then
        turnDot = math.max(-1, math.min(1, turnDot))
        turnDegrees = math.floor(
            math.deg(math.acos(turnDot)) + 0.5
        )
        movement = movement .. " turn="
            .. tostring(turnDegrees)
    end
    lines[#lines + 1] = movement

    if debugState.moveBlockReason
        or debugState.moveBlockedStepReason
        or (tonumber(debugState.navigationPlanFailures) or 0) > 0
        or debugState.navigationInvalidationReason
    then
        diagnostic = "DIAG block="
            .. tostring(
                debugState.moveBlockReason
                    or debugState.moveBlockedStepReason
                    or "-"
            )
            .. " failures="
            .. tostring(
                tonumber(debugState.navigationPlanFailures) or 0
            )
        if debugState.navigationInvalidationReason then
            diagnostic = diagnostic .. " replan="
                .. tostring(debugState.navigationInvalidationReason)
        end
        lines[#lines + 1] = diagnostic
    end
    return lines
end

function Renderer.BuildCombatDebugLines(debugState, currentTargetDistance)
    local lines = {}
    local mode
    local decision
    local pressure
    local horde
    local target
    local targetLine
    local aim
    local lane
    local ammo
    local action
    local movement
    if type(debugState) ~= "table" then return lines end
    mode = tostring(debugState.mode or "unknown")
    decision = tostring(
        debugState.decision
            or debugState.blockReason
            or "observing"
    )
    lines[#lines + 1] = "COMBAT " .. mode
        .. " | " .. decision
        .. (
            debugState.assessmentAgeMs ~= nil
                and " age=" .. tostring(
                    math.floor(
                        tonumber(debugState.assessmentAgeMs) or 0
                    )
                ) .. "ms"
                or ""
        )

    pressure = tostring(
        tonumber(debugState.visiblePressureCount) or 0
    ) .. "/" .. tostring(
        tonumber(debugState.pressureCount) or 0
    )
    horde = tostring(
        tonumber(debugState.visibleHordeCount) or 0
    ) .. "/" .. tostring(
        tonumber(debugState.hordeCount) or 0
    )
    lines[#lines + 1] = "THREAT near="
        .. tostring(tonumber(debugState.surroundedCount) or 0)
        .. " pressure=" .. pressure
        .. " tol=" .. tostring(
            tonumber(debugState.pressureTolerance) or "-"
        )
        .. " horde=" .. horde
        .. " crowd=" .. tostring(
            tonumber(debugState.targetCrowdCount) or 0
        )
        .. " sta=" .. tostring(
            debugState.staminaRatio ~= nil
                and math.floor(
                    (tonumber(debugState.staminaRatio) or 0)
                        * 100 + 0.5
                ) .. "%"
                or "-"
        )
        .. "/" .. tostring(
            debugState.staminaCurrent ~= nil
                and math.floor(
                    tonumber(debugState.staminaCurrent) or 0
                )
                or "-"
        )

    if debugState.visibleZombieCount ~= nil
        or debugState.nearbyZombieCount ~= nil
    then
        lines[#lines + 1] = "VIEW zombies="
            .. tostring(
                tonumber(debugState.visibleZombieCount) or 0
            )
            .. "/" .. tostring(
                tonumber(debugState.nearbyZombieCount) or 0
            )
            .. " intent=" .. tostring(
                debugState.attackType or "auto"
            )
            .. " tactical=" .. tostring(
                debugState.tacticalState or "-"
            )
            .. " retreat=" .. tostring(
                debugState.retreatPhase or "-"
            )
            .. ":" .. tostring(
                debugState.retreatReason or "-"
            )
            .. " biteLane=" .. tostring(
                debugState.biteLaneClear == true
                    and "clear"
                    or debugState.biteLaneReason or "-"
            )
    end
    if type(debugState.viewZombies) == "table" then
        local index
        local viewed
        for index = 1, #debugState.viewZombies do
            viewed = debugState.viewZombies[index]
            lines[#lines + 1] = "Z" .. tostring(index)
                .. " id=" .. tostring(viewed.id or "-")
                .. " d=" .. tostring(
                    rounded(
                        viewed.distSq
                            and math.sqrt(
                                tonumber(viewed.distSq) or 0
                            ),
                        2
                    ) or "-"
                )
                .. " mode=" .. tostring(viewed.intent or "visible")
                .. " state=" .. tostring(
                    viewed.actionState or "-"
                )
                .. " los=" .. tostring(
                    viewed.visibilityKind or "-"
                )
                .. (
                    tostring(viewed.bumpType or "") ~= ""
                        and " bump=" .. tostring(viewed.bumpType)
                        or ""
                )
                .. (
                    viewed.targetKind ~= nil
                        and " target="
                            .. tostring(viewed.targetKind)
                            .. "["
                            .. tostring(
                                viewed.targetName
                                    or viewed.targetId
                                    or "?"
                            )
                            .. "]"
                            .. (
                                viewed.targetSource ~= nil
                                    and " via="
                                        .. tostring(viewed.targetSource)
                                    or ""
                            )
                        or " target=none"
                )
        end
    end

    target = debugState.target
    if type(target) == "table" then
        targetLine = "TARGET " .. tostring(target.kind or "unknown")
            .. (
                target.id ~= nil
                    and "[" .. tostring(target.id) .. "]"
                    or ""
            )
            .. " d=" .. tostring(
                rounded(
                    currentTargetDistance
                        or (
                            target.distSq
                            and math.sqrt(
                                tonumber(target.distSq) or 0
                            )
                        ),
                    2
                ) or "-"
            )
            .. " los=" .. tostring(
                target.visible == false
                    and (target.visibilityKind or "lost")
                    or (target.visibilityKind or "clear")
            )
        if target.threatening == true then
            targetLine = targetLine .. " ACTIVE"
        end
        lines[#lines + 1] = targetLine
    else
        lines[#lines + 1] = "TARGET none"
    end

    if mode == "ranged" or mode == "mixed" then
        aim = tonumber(debugState.aimConfidence)
        if debugState.fireLaneSafe == false then
            lane = "BLOCKED"
            if debugState.fireLaneBlocker then
                lane = lane .. ":"
                    .. tostring(
                        debugState.fireLaneBlocker.kind or "friendly"
                    )
            end
        elseif debugState.fireLaneSafe == true then
            lane = "CLEAR"
        else
            lane = "UNCHECKED"
        end
        ammo = debugState.magazineCount ~= nil
            and (
                tostring(debugState.magazineCount)
                .. "/" .. tostring(
                    debugState.magazineCapacity or "?"
                )
            ) or "-"
        lines[#lines + 1] = "RANGED aim="
            .. tostring(
                aim and math.floor(aim * 100 + 0.5) or "-"
            )
            .. "% ready="
            .. tostring(
                debugState.aimReadyInMs ~= nil
                    and tostring(
                        math.floor(
                            tonumber(debugState.aimReadyInMs) or 0
                        )
                    ) .. "ms"
                    or "-"
            )
            .. " lane=" .. lane
            .. " ammo=" .. ammo
            .. " reserve=" .. tostring(
                debugState.ammoReserveUnlimited == true
                    and "inf"
                    or debugState.ammoReserveCount or "-"
            )
            .. (
                debugState.reloadActive == true
                    and " RELOAD"
                    or ""
            )
    end

    action = debugState.action
    if type(action) == "table" then
        lines[#lines + 1] = "ACTION "
            .. tostring(action.attackType or "-")
            .. "/" .. tostring(action.attackKind or "-")
            .. " anim=" .. tostring(action.anim or "-")
            .. " retry=" .. tostring(
                tonumber(action.animationRetries) or 0
            )
            .. " via=" .. tostring(
                action.animationTriggerMode or "-"
            )
            .. " state=" .. tostring(
                action.animationActionState or "-"
            )
            .. " hit=" .. tostring(
                math.floor(
                    tonumber(action.hitRemainingMs) or 0
                )
            )
            .. "ms finish=" .. tostring(
                math.floor(
                    tonumber(action.finishRemainingMs) or 0
                )
            ) .. "ms"
    end

    movement = debugState.tacticalMove
    if type(movement) == "table" then
        lines[#lines + 1] = "MOVE "
            .. tostring(movement.phase or "-")
            .. "/" .. tostring(movement.mode or "-")
            .. " reason=" .. tostring(movement.reason or "-")
            .. " lock=" .. tostring(
                math.floor(
                    tonumber(movement.lockRemainingMs) or 0
                )
            ) .. "ms"
    end
    lines[#lines + 1] = "DEFENSE r="
        .. tostring(rounded(debugState.defenseRadius, 1) or "-")
        .. " nearby=" .. tostring(
            tonumber(debugState.defenseNearbyCount) or 0
        )
        .. " fit=" .. tostring(
            debugState.defenseFitness ~= nil
                and math.floor(tonumber(debugState.defenseFitness) or 0)
                or "-"
        )
        .. " dodge=" .. tostring(
            debugState.defenseAvoidChance ~= nil
                and math.floor(
                    (tonumber(debugState.defenseAvoidChance) or 0)
                        * 100 + 0.5
                ) .. "%"
                or "-"
        )
        .. " gear=" .. tostring(
            debugState.defenseProtection ~= nil
                and math.floor(
                    (tonumber(debugState.defenseProtection) or 0)
                        + 0.5
                ) .. "%"
                or "-"
        )
        .. " type=" .. tostring(debugState.defenseDamageType or "-")
        .. " last=" .. tostring(debugState.defenseOutcome or "-")
        .. (debugState.defensePushed == true and "+push" or "")
    return lines
end

function Renderer.BuildBodyAnimationDebugLine(zombie, action)
    local modData
    local actionState
    local bumpType
    local requested
    local useless
    local moving
    local sneaking
    local finished
    if not zombie then return nil end
    modData = zombie.getModData and zombie:getModData() or nil
    actionState = zombie.getActionStateName
        and tostring(zombie:getActionStateName() or "")
        or "-"
    bumpType = zombie.getBumpType
        and tostring(zombie:getBumpType() or "")
        or "-"
    requested = modData
        and modData.PNC_ClientAttackRequestedAnim
        or action and action.anim
        or "-"
    useless = zombie.isUseless
        and zombie:isUseless() == true or false
    moving = zombie.isMoving
        and zombie:isMoving() == true or false
    sneaking = zombie.isSneaking
        and zombie:isSneaking() == true or false
    finished = zombie.getVariableBoolean
        and zombie:getVariableBoolean("BumpAnimFinished")
        == true or false
    return "ANIM req=" .. tostring(requested)
        .. " bump=" .. tostring(bumpType ~= "" and bumpType or "-")
        .. " state=" .. tostring(actionState ~= "" and actionState or "-")
        .. " useless=" .. tostring(useless)
        .. " moving=" .. tostring(moving)
        .. " sneak=" .. tostring(sneaking)
        .. " done=" .. tostring(finished)
        .. " lease=" .. tostring(
            modData and modData.PNC_BumpActionLease == true
                or false
        )
end

function Renderer.BuildAnimationTraceDebugLine(zombie)
    if not PNC.AnimationTrace
        or not PNC.AnimationTrace.GetOverlayLine
    then
        return nil
    end
    return PNC.AnimationTrace.GetOverlayLine(zombie)
end

function Renderer.BuildAnimationTrackDebugLine(zombie)
    if not NameplateDebug
        or not NameplateDebug.AnimationTrackText
    then
        return nil
    end
    return NameplateDebug.AnimationTrackText(zombie)
end

return Renderer
