PNC = PNC or {}
PNC.NameplateDebug = PNC.NameplateDebug or {}

local Debug = PNC.NameplateDebug
local Const = PNC.Const

local SYNTH_FRAMES = {
    Walk = 24,
    Run = 20,
    SneakWalk = 24,
    Crawl = 20,
    Idle = 16,
}

local SYNTH_CYCLE_MS = {
    Walk = 900,
    Run = 720,
    SneakWalk = 1100,
    Crawl = 1300,
    Idle = 1500,
}

local ANIMATION_FRAME_RATE = 30
local DEBUG_TRACK_LAYER_COUNT = 4
local DEBUG_TRACKS_PER_LAYER = 4

local function syntheticAnimFrame(zombie, animName, moving, animSpeed)
    if not zombie then return nil, nil, nil end
    animName = tostring(animName or "Idle")
    local frameCount = SYNTH_FRAMES[animName]
    local cycleMs = SYNTH_CYCLE_MS[animName]
    if not frameCount or not cycleMs then return nil, nil, nil end

    local modData = zombie.getModData and zombie:getModData() or nil
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    local key = table.concat({
        animName,
        tostring(moving == true),
        string.format("%.3f", tonumber(animSpeed) or 0),
    }, "|")
    local elapsed = 0
    if modData then
        if modData.PNC_DebugAnimCycleKey ~= key then
            modData.PNC_DebugAnimCycleKey = key
            modData.PNC_DebugAnimCycleStartAt = now
        end
        now = tonumber(now) or 0
        elapsed = math.max(0, now - (tonumber(modData.PNC_DebugAnimCycleStartAt) or now))
    end
    local phase = frameCount <= 1 and 0
        or ((elapsed * math.max(0.05, tonumber(animSpeed) or 0)) % cycleMs) / cycleMs
    local frame = math.max(0, math.min(frameCount - 1, math.floor((phase * frameCount) + 0.0001)))
    return frame, frameCount, phase
end

local function settingEnabled(settings, key)
    return not settings or settings[key] ~= false
end

local function infectionState(snapshot)
    local infection = snapshot and snapshot.bodyHealth
        and snapshot.bodyHealth.infection or nil
    local infected = infection
        and (infection.active == true
            or infection.fatal == true
            or infection.pendingFatal == true)
        or false
    return infected, infection
end

function Debug.BuildText(snapshot, hasBoundBody, settings)
    local debugState = snapshot and snapshot.debugState or nil
    local combatDebug = snapshot and snapshot.combatDebugState or nil
    local firearmState = snapshot and snapshot.firearmState or nil
    local parts = {}
    if not debugState then
        return settingEnabled(settings, "debugShowAI") and "AI: Unknown" or ""
    end
    local presence = string.upper(tostring(snapshot.presenceState or "unknown"))
    if snapshot.presenceState == Const.PRESENCE_LIVE then
        presence = presence .. "/" .. (hasBoundBody and "BOUND" or "MISSING")
    end
    if settingEnabled(settings, "debugShowPresence") then
        parts[#parts + 1] = "Presence: " .. presence
    end
    if settingEnabled(settings, "debugShowAI") then
        parts[#parts + 1] =
            "AI: " .. tostring(debugState.aiState or snapshot.aiState or "Unknown")
    end
    if settingEnabled(settings, "debugShowJob") then
        parts[#parts + 1] = "Job: " .. tostring(debugState.activeJob or "-")
    end
    if settingEnabled(settings, "debugShowOrder") then
        parts[#parts + 1] = "Order: " .. tostring(debugState.orderKind or "-")
    end
    if settingEnabled(settings, "debugShowTarget") then
        parts[#parts + 1] =
            "Target: " .. tostring(debugState.targetKind or "none")
    end
    if settingEnabled(settings, "debugShowCombat") then
        parts[#parts + 1] = "Mode: " .. tostring(
            debugState.combatModeResolved or debugState.weaponMode or "-"
        )
        parts[#parts + 1] =
            "Weapon: " .. tostring(debugState.weaponStatus or "-")
        if combatDebug then
            parts[#parts + 1] = "Intent: "
                .. tostring(combatDebug.attackType or "auto")
                .. "/" .. tostring(combatDebug.mode or "-")
            parts[#parts + 1] = "Tactic: " .. tostring(
                combatDebug.decision
                    or combatDebug.retreatReason
                    or combatDebug.blockReason
                    or "observing"
            )
            parts[#parts + 1] = "ViewZ: "
                .. tostring(
                    tonumber(combatDebug.visibleZombieCount) or 0
                )
                .. "/" .. tostring(
                    tonumber(combatDebug.nearbyZombieCount) or 0
                )
        end
    end
    if settingEnabled(settings, "debugShowMagazine") and firearmState then
        parts[#parts + 1] = "Mag: "
            .. tostring(firearmState.count or 0)
            .. "/"
            .. tostring(firearmState.capacity or 0)
            .. (firearmState.reloadActive == true and " (reloading)" or "")
        parts[#parts + 1] = "Reserve: " .. (
            firearmState.unlimitedReserve == true
                and "infinite"
                or tostring(firearmState.reserveCount or 0)
        )
    end
    if settingEnabled(settings, "debugShowStamina") then
        parts[#parts + 1] = "Stamina: " .. tostring(
            debugState.staminaState or snapshot.staminaState or "-"
        )
    end
    if settingEnabled(settings, "debugShowBlock") then
        parts[#parts + 1] =
            "Block: " .. tostring(debugState.combatBlockReason or "-")
    end
    return table.concat(parts, " | ")
end

function Debug.InfectionText(snapshot, settings)
    local infected
    local infection
    if not settingEnabled(settings, "debugShowInfection") then
        return ""
    end
    infected, infection = infectionState(snapshot)
    if not infected then
        return ""
    end
    return table.concat({
        "INFECTED: YES",
        "Stage: " .. tostring(infection.stage or "incubating"),
        "Fever: " .. tostring(
            math.floor((tonumber(infection.fever) or 0) + 0.5)
        ) .. "%",
        string.format(
            "Temp: %.1f C",
            tonumber(infection.temperatureC) or 37
        ),
    }, " | ")
end

-- IsoGameCharacter exposes these debug accessors directly to Lua. They are
-- safe for empty layer/track slots and avoid indexing AnimationTrack or
-- AdvancedAnimator Java userdata, whose methods are not Lua-exposed.
function Debug.CaptureAnimationRuntime(zombie)
    local runtime = {
        actionState = "-",
        animationState = "-",
        clip = "",
        layer = nil,
        trackIndex = nil,
        time = nil,
        weight = nil,
        frame = nil,
        frameRate = ANIMATION_FRAME_RATE,
        trackCount = 0,
        updating = nil,
    }
    local best
    local layer
    local trackIndex
    if not zombie then return runtime end
    runtime.actionState = tostring(
        zombie.getCurrentActionContextStateName
            and zombie:getCurrentActionContextStateName()
            or zombie.getActionStateName
                and zombie:getActionStateName()
            or "-"
    )
    runtime.animationState = tostring(
        zombie.getAnimationStateName
            and zombie:getAnimationStateName()
            or "-"
    )
    if zombie.isAnimationUpdatingThisFrame then
        runtime.updating =
            zombie:isAnimationUpdatingThisFrame() == true
    end
    if not zombie.dbgGetAnimTrackName then return runtime end
    for layer = 0, DEBUG_TRACK_LAYER_COUNT - 1 do
        for trackIndex = 0, DEBUG_TRACKS_PER_LAYER - 1 do
            local name = tostring(
                zombie:dbgGetAnimTrackName(
                    layer,
                    trackIndex
                ) or ""
            )
            if name ~= "" then
                local time = zombie.dbgGetAnimTrackTime
                    and tonumber(
                        zombie:dbgGetAnimTrackTime(
                            layer,
                            trackIndex
                        )
                    )
                    or 0
                local weight = zombie.dbgGetAnimTrackWeight
                    and tonumber(
                        zombie:dbgGetAnimTrackWeight(
                            layer,
                            trackIndex
                        )
                    )
                    or 0
                local candidate = {
                    clip = name,
                    layer = layer,
                    trackIndex = trackIndex,
                    time = time,
                    weight = weight,
                }
                runtime.trackCount = runtime.trackCount + 1
                if not best
                    or weight > best.weight
                then
                    best = candidate
                end
            end
        end
    end
    if best then
        runtime.clip = best.clip
        runtime.layer = best.layer
        runtime.trackIndex = best.trackIndex
        runtime.time = best.time
        runtime.weight = best.weight
        runtime.frame = math.max(
            0,
            math.floor(
                math.max(0, tonumber(best.time) or 0)
                    * ANIMATION_FRAME_RATE
                    + 0.0001
            )
        )
    end
    return runtime
end

function Debug.AnimationTrackText(zombie)
    local runtime = Debug.CaptureAnimationRuntime(zombie)
    if runtime.clip == "" then
        return "TRACK clip=- state="
            .. tostring(runtime.actionState)
            .. "/" .. tostring(runtime.animationState)
            .. " frame@30=- weight=-"
    end
    return "TRACK clip=" .. tostring(runtime.clip)
        .. " slot=" .. tostring(runtime.layer)
        .. ":" .. tostring(runtime.trackIndex)
        .. " state=" .. tostring(runtime.actionState)
        .. "/" .. tostring(runtime.animationState)
        .. " time=" .. string.format(
            "%.3fs",
            tonumber(runtime.time) or 0
        )
        .. " frame@30=" .. tostring(runtime.frame)
        .. " weight=" .. string.format(
            "%.3f",
            tonumber(runtime.weight) or 0
        )
        .. " tracks=" .. tostring(runtime.trackCount)
        .. (
            runtime.updating ~= nil
                and " updating=" .. tostring(runtime.updating)
                or ""
        )
end

-- Dedicated scene diagnostics keep authority state and the actual local
-- animator on the same overlay. This makes a missing selector, a stuck
-- ActionContext, or an MP primitive-revision problem visible immediately.
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
        "name=" .. tostring(snapshot.name),
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
