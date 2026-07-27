--[[
    PNC Live Body Control
    Owns suppression of vanilla zombie-only body states on embodied NPCs.
    This stays separate from path ownership so animation, presence, and pathing
    can reuse the same body-state rules without duplicating them.
]]

PNC = PNC or {}
PNC.LiveBodyControl = PNC.LiveBodyControl or {}

local LiveBodyControl = PNC.LiveBodyControl
local Core = PNC.Core

local SUPPRESSION_AUDIO_COOLDOWN_MS = 250
local NEXT_AUDIO_SUPPRESSION_AT = setmetatable({}, { __mode = "k" })
local SAFETY_REPAIR_LOGGED = setmetatable({}, { __mode = "k" })
local ZOMBIE_VOICE_SOUNDS = {
    "FemaleZombieVoiceA",
    "FemaleZombieVoiceB",
    "FemaleZombieVoiceC",
    "MaleZombieVoiceA",
    "MaleZombieVoiceB",
    "MaleZombieVoiceC",
}
local SUPPRESSED_STATES = {
    ["getup"] = true,
    ["getup-fromonback"] = true,
    ["getup-fromonfront"] = true,
    ["getup-fromsitting"] = true,
    ["climbfence"] = true,
    ["climbwindow"] = true,
    ["lunge"] = true,
    ["onground"] = true,
    ["onground-ragdoll"] = true,
    ["pathfind"] = true,
    ["sitonground"] = true,
    ["staggerback"] = true,
    ["staggerback-knockeddown"] = true,
    ["turnalerted"] = true,
}

local IDLE_RESET_STATES = {
    ["getup"] = true,
    ["getup-fromonback"] = true,
    ["getup-fromonfront"] = true,
    ["getup-fromsitting"] = true,
    ["climbfence"] = true,
    ["climbwindow"] = true,
    ["lunge"] = true,
    ["pathfind"] = true,
    ["turnalerted"] = true,
}

function LiveBodyControl.SetAuthoritativePosition(zombie, x, y, z)
    if not zombie then
        return false
    end
    zombie:setX(x)
    zombie:setY(y)
    zombie:setZ(z)
    -- PNC has already validated and authored this movement. Keep the engine's
    -- previous-position fields aligned so its collision pass does not
    -- reinterpret a Lua-controlled step as a fence/window/vehicle collision.
    if zombie.setLastX then zombie:setLastX(x) end
    if zombie.setLastY then zombie:setLastY(y) end
    if zombie.setLastZ then zombie:setLastZ(z) end
    return true
end

local function isDamageReactionState(actionState)
    actionState = string.lower(tostring(actionState or ""))
    return string.find(actionState, "staggerback", 1, true) == 1
        or string.find(actionState, "hitreaction", 1, true) == 1
end

function LiveBodyControl.IsSuppressedActionState(actionState)
    if not actionState or actionState == "" then
        return false
    end
    actionState = string.lower(tostring(actionState))
    return SUPPRESSED_STATES[actionState] == true or isDamageReactionState(actionState)
end

function LiveBodyControl.GetActionStateName(zombie)
    if not zombie or not zombie.getActionStateName then
        return ""
    end
    return string.lower(tostring(zombie:getActionStateName() or ""))
end

function LiveBodyControl.ReleaseDamageReaction(zombie, actionState)
    local modData
    local isDamageReaction
    if not zombie then
        return false
    end
    actionState = string.lower(tostring(actionState or LiveBodyControl.GetActionStateName(zombie) or ""))
    isDamageReaction = isDamageReactionState(actionState)

    -- IsoZombie:Hit raises this Java-side latch before ActionContext enters
    -- staggerback. Clear it even if the transition has not become visible yet.
    if zombie.setStaggerBack then
        zombie:setStaggerBack(false)
    end
    if zombie.setHitReaction then
        zombie:setHitReaction("")
    end
    if zombie.setBumpDone then
        zombie:setBumpDone(true)
    end
    if zombie.setBumpStaggered then
        zombie:setBumpStaggered(false)
    end
    if zombie.setBumpFall then
        zombie:setBumpFall(false)
    end
    if zombie.setBumpType then
        zombie:setBumpType("")
    end
    if zombie.setVariable then
        zombie:setVariable("BumpDone", true)
        zombie:setVariable("BumpAnimFinished", true)
        zombie:setVariable("BumpFall", false)
        zombie:setVariable("BumpFallType", "")
    end

    if isDamageReaction then
        -- The staggerback ActionContext exits only when this timer reaches zero.
        -- Calling changeState(ZombieIdleState) is not an ActionContext reset: its
        -- enter() installs a new 400-1000 tick delay and can keep staggerback
        -- alive indefinitely while maintenance repeats.
        if string.find(actionState, "staggerback", 1, true) == 1
            and zombie.setStateEventDelayTimer
        then
            zombie:setStateEventDelayTimer(0)
        end
        -- Hit-reaction states use this event, rather than the stagger timer, as
        -- their normal transition back to idle.
        if string.find(actionState, "hitreaction", 1, true) == 1
            and zombie.reportEvent
        then
            zombie:reportEvent("ActiveAnimFinishing")
        end
    end

    if zombie.setTarget then
        zombie:setTarget(nil)
    end
    if zombie.clearAggroList then
        zombie:clearAggroList()
    end
    if zombie.setAttackedBy then
        zombie:setAttackedBy(nil)
    end
    modData = zombie.getModData and zombie:getModData() or nil
    if modData then
        modData.PNC_BumpReleasePending = nil
        modData.PNC_BumpReleaseAt = nil
    end
    return isDamageReaction
end

function LiveBodyControl.SyncLocomotionState(zombie, moving)
    local actionState
    if not zombie then
        return false
    end
    moving = moving == true
    actionState = LiveBodyControl.GetActionStateName(zombie)
    if moving then
        return actionState == "walktoward" or actionState == "idle" or actionState == ""
    end
    if actionState == "walktoward"
        and zombie.changeState
        and ZombieIdleState
        and ZombieIdleState.instance
    then
        zombie:changeState(ZombieIdleState.instance())
        return true
    end
    return actionState == "idle" or actionState == ""
end

function LiveBodyControl.ApplyHumanizedBodyFlags(zombie)
    local descriptor
    if not zombie then
        return
    end
    if zombie.setVariable then
        zombie:setVariable("ZombieHitReaction", "Chainsaw")
        zombie:setVariable("NoLungeTarget", true)
        zombie:setVariable("NoLungeAttack", true)
        zombie:setVariable("bBecomeCrawler", false)
        zombie:setVariable("bCrawling", false)
        zombie:setVariable("FallOnFront", false)
        zombie:setVariable("BumpFall", false)
        zombie:setVariable("BumpFallType", "")
        zombie:setVariable("PNCLive", true)
    end
    if zombie.setKnockedDown then
        zombie:setKnockedDown(false)
    end
    if zombie.setBumpFall then
        zombie:setBumpFall(false)
    end
    if zombie.setSitAgainstWall then
        zombie:setSitAgainstWall(false)
    end
    if zombie.setOnFloor then
        zombie:setOnFloor(false)
    end
    if zombie.setFallOnFront then
        zombie:setFallOnFront(false)
    end
    if zombie.setCrawler then
        zombie:setCrawler(false)
    end
    if zombie.setFakeDead then
        zombie:setFakeDead(false)
    end
    if zombie.setCanWalk then
        zombie:setCanWalk(true)
    end
    if zombie.setTarget then
        zombie:setTarget(nil)
    end
    if zombie.clearAggroList then
        zombie:clearAggroList()
    end
    if zombie.setAttackedBy then
        zombie:setAttackedBy(nil)
    end
    if zombie.setAnimatingBackwards then
        zombie:setAnimatingBackwards(false)
    end
    -- Replicated zombie packets can restore this flag after the initial body
    -- setup. Reassert it from every maintenance lane so vanilla AI/audio does
    -- not briefly treat a human NPC as an ordinary zombie.
    if zombie.setUseless then
        zombie:setUseless(true)
    end
    -- This is a second, engine-level fail-safe for the short load/rebind window
    -- where a persisted IsoZombie may update before its record is reconciled.
    -- Released infected reanimations explicitly restore teeth to vanilla.
    if zombie.setNoTeeth then
        zombie:setNoTeeth(true)
    end
    -- Repair bodies saved while an older client safeguard leaked this flag.
    -- The LOS correction may set it only around one synchronous updateLOS()
    -- call; normal body maintenance must always leave the NPC out of vanilla's
    -- prone/reanimation-only posture.
    if zombie.setReanimatedForGrappleOnly then
        zombie:setReanimatedForGrappleOnly(false)
    end
    if zombie.getDescriptor then
        descriptor = zombie:getDescriptor()
        if descriptor and descriptor.setVoicePrefix then
            descriptor:setVoicePrefix("NotAZombie")
        end
    end
end

function LiveBodyControl.StopEmitter(zombie)
    local emitter
    if not zombie or not zombie.getEmitter then
        return false
    end
    emitter = zombie:getEmitter()
    if not emitter or not emitter.stopAll then
        return false
    end
    emitter:stopAll()
    return true
end

function LiveBodyControl.SuppressZombieSounds(zombie)
    local descriptor
    local emitter
    local i
    if not zombie then return false end
    if zombie.getDescriptor then
        descriptor = zombie:getDescriptor()
        if descriptor and descriptor.setVoicePrefix then
            descriptor:setVoicePrefix("NotAZombie")
        end
    end
    emitter = zombie.getEmitter and zombie:getEmitter() or nil
    if not emitter or not emitter.stopSoundByName then return descriptor ~= nil end
    -- Bandits uses these six Build 42 channels in addition to NotAZombie.
    -- Stop only zombie voices here: stopAll() would also cut gun, melee, door,
    -- and treatment sounds emitted intentionally by the NPC.
    for i = 1, #ZOMBIE_VOICE_SOUNDS do
        emitter:stopSoundByName(ZOMBIE_VOICE_SOUNDS[i])
    end
    return true
end

function LiveBodyControl.MaintainHumanizedBody(zombie, now)
    local nextAudioAt
    if not zombie then return false end
    LiveBodyControl.ApplyHumanizedBodyFlags(zombie)
    now = tonumber(now) or (Core and Core.Now and Core.Now() or 0)
    nextAudioAt = tonumber(NEXT_AUDIO_SUPPRESSION_AT[zombie]) or 0
    if now >= nextAudioAt then
        LiveBodyControl.SuppressZombieSounds(zombie)
        NEXT_AUDIO_SUPPRESSION_AT[zombie] = now + SUPPRESSION_AUDIO_COOLDOWN_MS
    end
    return true
end

function LiveBodyControl.EnforceManagedSafety(zombie, source)
    local hadTarget
    local wasUseless
    local hadTeeth
    local wasGrappleOnly
    local modData
    local npcId
    if not zombie or not Core or not Core.IsManagedNPCBody
        or not Core.IsManagedNPCBody(zombie)
    then
        return false
    end
    hadTarget = zombie.getTarget and zombie:getTarget() ~= nil or false
    wasUseless = zombie.isUseless and zombie:isUseless() or false
    hadTeeth = zombie.isNoTeeth and not zombie:isNoTeeth() or false
    wasGrappleOnly = zombie.isReanimatedForGrappleOnly
        and zombie:isReanimatedForGrappleOnly() or false
    LiveBodyControl.MaintainHumanizedBody(
        zombie,
        Core.Now and Core.Now() or 0
    )
    if (hadTarget or not wasUseless or hadTeeth or wasGrappleOnly)
        and not SAFETY_REPAIR_LOGGED[zombie]
        and Core.LogWarn
    then
        SAFETY_REPAIR_LOGGED[zombie] = true
        modData = zombie.getModData and zombie:getModData() or nil
        npcId = modData and modData.PNC_UUID or "unknown"
        Core.LogWarn("human_safety_repaired npc=" .. tostring(npcId)
            .. " source=" .. tostring(source or "unknown")
            .. " target=" .. tostring(hadTarget)
            .. " useless=" .. tostring(wasUseless)
            .. " hadTeeth=" .. tostring(hadTeeth)
            .. " grappleOnly=" .. tostring(wasGrappleOnly))
    end
    return true
end

function LiveBodyControl.ScanLoadedManagedBodies(source)
    local cell = getCell and getCell() or nil
    local zombies = cell and cell.getZombieList and cell:getZombieList() or nil
    local repaired = 0
    local i
    if not zombies then return 0 end
    for i = 0, zombies:size() - 1 do
        if LiveBodyControl.EnforceManagedSafety(
            zombies:get(i),
            source or "loaded_scan"
        ) then
            repaired = repaired + 1
        end
    end
    if repaired > 0 and Core and Core.LogDebug then
        Core.LogDebug("human_safety_scan source=" .. tostring(source)
            .. " managed=" .. tostring(repaired))
    end
    return repaired
end

function LiveBodyControl.OnZombieUpdate(zombie)
    LiveBodyControl.EnforceManagedSafety(zombie, "zombie_update")
end

function LiveBodyControl.OnWorldReady()
    LiveBodyControl.ScanLoadedManagedBodies("world_ready")
end

function LiveBodyControl.TrySilenceEmitter(zombie, lane, now)
    if not lane then
        return false
    end
    now = tonumber(now) or (Core and Core.Now and Core.Now() or 0)
    if (now - (tonumber(lane.lastSuppressAudioAt) or 0)) < SUPPRESSION_AUDIO_COOLDOWN_MS then
        return false
    end
    if not LiveBodyControl.SuppressZombieSounds(zombie) then
        return false
    end
    lane.lastSuppressAudioAt = now
    return true
end

function LiveBodyControl.SuppressZombieState(zombie, lane, now)
    local actionState = LiveBodyControl.GetActionStateName(zombie)
    local needsIdleReset
    if not zombie then
        return false, actionState
    end
    LiveBodyControl.ApplyHumanizedBodyFlags(zombie)
    LiveBodyControl.TrySilenceEmitter(zombie, lane, now)
    if not LiveBodyControl.IsSuppressedActionState(actionState) then
        return false, actionState
    end
    needsIdleReset = IDLE_RESET_STATES[actionState or ""] == true
    if isDamageReactionState(actionState) then
        LiveBodyControl.ReleaseDamageReaction(zombie, actionState)
    end
    -- Reset the alert-turn payload only while recovering that actual engine
    -- state.  Applying it from the generic body-flags path meant it ran more
    -- than once per movement tick and could race the facing owner.
    if actionState == "turnalerted" and zombie.setTurnAlertedValues then
        zombie:setTurnAlertedValues(0, 0)
    end
    if zombie.setVariable and actionState == "climbfence" then
        zombie:setVariable("ClimbFenceStarted", false)
        zombie:setVariable("ClimbFenceFinished", true)
        zombie:setVariable("ClimbFenceOutcome", "")
    elseif zombie.setVariable and actionState == "climbwindow" then
        zombie:setVariable("ClimbWindowStarted", false)
        zombie:setVariable("ClimbWindowOutcome", "")
    end
    if zombie.setUseless then
        zombie:setUseless(true)
    end
    if needsIdleReset and zombie.changeState and ZombieIdleState and ZombieIdleState.instance then
        zombie:changeState(ZombieIdleState.instance())
    end
    LiveBodyControl.TrySilenceEmitter(zombie, lane, now)
    return true, actionState
end

if Events and Events.OnZombieUpdate then
    if Events.OnZombieUpdate.Remove then
        Events.OnZombieUpdate.Remove(LiveBodyControl.OnZombieUpdate)
    end
    Events.OnZombieUpdate.Add(LiveBodyControl.OnZombieUpdate)
end
if Events and Events.OnGameStart then
    if Events.OnGameStart.Remove then
        Events.OnGameStart.Remove(LiveBodyControl.OnWorldReady)
    end
    Events.OnGameStart.Add(LiveBodyControl.OnWorldReady)
end
if Events and Events.OnServerStarted then
    if Events.OnServerStarted.Remove then
        Events.OnServerStarted.Remove(LiveBodyControl.OnWorldReady)
    end
    Events.OnServerStarted.Add(LiveBodyControl.OnWorldReady)
end
