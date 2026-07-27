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
