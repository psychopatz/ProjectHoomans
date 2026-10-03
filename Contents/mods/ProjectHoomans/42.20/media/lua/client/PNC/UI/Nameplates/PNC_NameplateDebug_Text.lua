local Debug = PNC.NameplateDebug
local syntheticAnimFrame = Debug._SyntheticAnimFrame

function Debug.AnimationSceneText(zombie, snapshot)
    local visual = snapshot and snapshot.visualState or {}
    local active = visual.sceneActive == true
    local runtime = Debug.CaptureAnimationRuntime(zombie)
    local actualBump = zombie
        and zombie.getBumpType
        and tostring(zombie:getBumpType() or "")
        or ""
    local phase = active and (
        tostring(visual.sceneBump or "") ~= ""
            and "playing" or "gap"
    ) or "inactive"
    local sceneLine = "SCENE " .. tostring(
        active and visual.sceneId or "inactive"
    )
        .. " policy=" .. tostring(
            visual.sceneRepeatMode or "once"
        )
        .. " phase=" .. phase
        .. " step=" .. tostring(
            visual.sceneStepPosition or 0
        )
        .. "/" .. tostring(visual.sceneStepCount or 0)
        .. ":" .. tostring(visual.sceneStepId or "-")
        .. " pass=" .. tostring(
            visual.sceneSequenceIteration or 0
        )
        .. " rev=" .. tostring(visual.sceneRevision or 0)
        .. ":" .. tostring(
            visual.scenePlaybackRevision or 0
        )
    local trackLine = "SCENE ANIM req="
        .. tostring(visual.sceneBump or "-")
        .. " actual="
        .. tostring(actualBump ~= "" and actualBump or "-")
        .. " state=" .. tostring(runtime.actionState)
        .. "/" .. tostring(runtime.animationState)
        .. " clip="
        .. tostring(runtime.clip ~= "" and runtime.clip or "-")
        .. " t=" .. (
            runtime.time ~= nil
                and string.format(
                    "%.3fs",
                    tonumber(runtime.time) or 0
                )
                or "-"
        )
        .. " frame@30=" .. tostring(runtime.frame or "-")
        .. " weight=" .. (
            runtime.weight ~= nil
                and string.format(
                    "%.3f",
                    tonumber(runtime.weight) or 0
                )
                or "-"
        )
        .. " updating=" .. tostring(runtime.updating)
    return sceneLine, trackLine
end

function Debug.AnimationText(zombie, snapshot)
    if not zombie then return "Anim: n/a" end
    local animName = tostring(snapshot and snapshot.visualState and snapshot.visualState.anim
        or zombie.getVariableString and zombie:getVariableString("PNCAnim") or "-")
    local moveAnim = tostring(zombie.getVariableString and zombie:getVariableString("PNCMoveAnim") or "-")
    local moving = zombie.isMoving and zombie:isMoving()
        or zombie.getVariableBoolean and zombie:getVariableBoolean("bMoving") or false
    local actionState = tostring(zombie.getActionStateName and zombie:getActionStateName()
        or zombie.getCurrentStateName and zombie:getCurrentStateName() or "-")
    local walkType = tostring(zombie.getVariableString and zombie:getVariableString("WalkType") or "")
    local engineWalkType = tostring(zombie.getVariableString and zombie:getVariableString("PNCEngineWalkType") or "")
    local animSpeed = tonumber(zombie.getVariableFloat and zombie:getVariableFloat("PNCAnimSpeed", 0.0) or 0.0) or 0.0
    local parts = {
        "Anim: " .. animName,
        "MoveAnim: " .. moveAnim,
        "Moving: " .. tostring(moving),
        "Action: " .. actionState,
        "WalkVar: " .. walkType,
        "EngineWalk: " .. engineWalkType,
        string.format("AnimSpd: %.2f", animSpeed),
    }
    local runtime = Debug.CaptureAnimationRuntime(zombie)
    if runtime.clip ~= "" then
        parts[#parts + 1] = "Clip: " .. tostring(runtime.clip)
        parts[#parts + 1] = "Track: "
            .. tostring(runtime.layer)
            .. ":" .. tostring(runtime.trackIndex)
        parts[#parts + 1] = string.format(
            "Time: %.3fs",
            tonumber(runtime.time) or 0
        )
        parts[#parts + 1] = "Frame@30: "
            .. tostring(runtime.frame)
        parts[#parts + 1] = string.format(
            "Weight: %.3f",
            tonumber(runtime.weight) or 0
        )
    else
        local frame, frameCount, phase = syntheticAnimFrame(
            zombie,
            moveAnim ~= "" and moveAnim or animName,
            moving == true,
            animSpeed
        )
        if frame ~= nil and frameCount ~= nil then
            parts[#parts + 1] = "Frame~: "
                .. tostring(frame)
                .. "/" .. tostring(frameCount)
        elseif phase ~= nil then
            parts[#parts + 1] = string.format(
                "Cycle: %.2f",
                tonumber(phase) or 0
            )
        else
            parts[#parts + 1] = "Frame~: n/a"
        end
    end
    return table.concat(parts, " | ")
end

function Debug.DescribeSnapshot(snapshot)
    if not snapshot then return "No snapshot" end
    local infection = snapshot.bodyHealth and snapshot.bodyHealth.infection or nil
    local firearm = snapshot.firearmState or nil
    return table.concat({
        "id=" .. tostring(snapshot.id),
        "name=" .. tostring(snapshot.displayName),
        "archetype=" .. tostring(snapshot.archetypeLabel or "-"),
        "ai=" .. tostring(snapshot.aiState),
        "job=" .. tostring(snapshot.debugState and snapshot.debugState.activeJob or "-"),
        "order=" .. tostring(snapshot.debugState and snapshot.debugState.orderKind or "-"),
        "target=" .. tostring(snapshot.debugState and snapshot.debugState.targetKind or "none"),
        "mode=" .. tostring(snapshot.debugState and snapshot.debugState.combatModeResolved or snapshot.weaponMode or "-"),
        "weapon=" .. tostring(snapshot.debugState and snapshot.debugState.weaponStatus or "-"),
        "magazine=" .. tostring(firearm and firearm.count or "-")
            .. "/" .. tostring(firearm and firearm.capacity or "-"),
        "reserve=" .. tostring(firearm and (
            firearm.unlimitedReserve == true and "infinite" or firearm.reserveCount
        ) or "-"),
        "block=" .. tostring(snapshot.debugState and snapshot.debugState.combatBlockReason or "-"),
        "hp=" .. tostring(snapshot.hpCurrent) .. "/" .. tostring(snapshot.hpMax),
        "stamina=" .. tostring(snapshot.staminaCurrent) .. "/" .. tostring(snapshot.staminaMax),
        "healthState=" .. tostring(snapshot.healthState),
        "infected=" .. tostring(infection
            and (infection.active == true or infection.fatal == true) or false),
        "infectionStage=" .. tostring(infection and infection.stage or "-"),
        "fever=" .. tostring(infection and math.floor((tonumber(infection.fever) or 0) + 0.5) or 0),
        "presence=" .. tostring(snapshot.presenceState),
    }, " | ")
end

return Debug
