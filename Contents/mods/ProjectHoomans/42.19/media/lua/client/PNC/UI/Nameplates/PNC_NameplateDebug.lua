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

function Debug.BuildText(snapshot, hasBoundBody)
    local debugState = snapshot and snapshot.debugState or nil
    if not debugState then return "AI: Unknown" end
    local presence = string.upper(tostring(snapshot.presenceState or "unknown"))
    if snapshot.presenceState == Const.PRESENCE_LIVE then
        presence = presence .. "/" .. (hasBoundBody and "BOUND" or "MISSING")
    end
    return table.concat({
        "Presence: " .. presence,
        "AI: " .. tostring(debugState.aiState or snapshot.aiState or "Unknown"),
        "Job: " .. tostring(debugState.activeJob or "-"),
        "Order: " .. tostring(debugState.orderKind or "-"),
        "Target: " .. tostring(debugState.targetKind or "none"),
        "Mode: " .. tostring(debugState.combatModeResolved or debugState.weaponMode or "-"),
        "Weapon: " .. tostring(debugState.weaponStatus or "-"),
        "Stamina: " .. tostring(debugState.staminaState or snapshot.staminaState or "-"),
        "Block: " .. tostring(debugState.combatBlockReason or "-"),
    }, " | ")
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
    local frame, frameCount, phase = syntheticAnimFrame(
        zombie,
        moveAnim ~= "" and moveAnim or animName,
        moving == true,
        animSpeed
    )
    if frame ~= nil and frameCount ~= nil then
        parts[#parts + 1] = "Frame~: " .. tostring(frame) .. "/" .. tostring(frameCount)
    elseif phase ~= nil then
        parts[#parts + 1] = string.format("Cycle: %.2f", tonumber(phase) or 0)
    else
        parts[#parts + 1] = "Frame~: n/a"
    end
    return table.concat(parts, " | ")
end

function Debug.DescribeSnapshot(snapshot)
    if not snapshot then return "No snapshot" end
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
        "block=" .. tostring(snapshot.debugState and snapshot.debugState.combatBlockReason or "-"),
        "hp=" .. tostring(snapshot.hpCurrent) .. "/" .. tostring(snapshot.hpMax),
        "stamina=" .. tostring(snapshot.staminaCurrent) .. "/" .. tostring(snapshot.staminaMax),
        "healthState=" .. tostring(snapshot.healthState),
        "presence=" .. tostring(snapshot.presenceState),
    }, " | ")
end

return Debug
