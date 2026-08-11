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
local BODY_MAINTENANCE_INTERVAL_MS = 500
local NEXT_AUDIO_SUPPRESSION_AT = setmetatable({}, { __mode = "k" })
local NEXT_BODY_MAINTENANCE_AT = setmetatable({}, { __mode = "k" })
local LAST_KEEP_ENGINE_ACTIVE = setmetatable({}, { __mode = "k" })
local SAFETY_REPAIR_LOGGED = setmetatable({}, { __mode = "k" })
local NATIVE_MOVEMENT_LEASE_KEY = "PNC_NativeMovementLease"
local NATIVE_MOVEMENT_LEASE_UNTIL_KEY =
    "PNC_NativeMovementLeaseUntil"
local ZOMBIE_VOICE_SOUNDS = {
    "FemaleZombieVoiceA",
    "FemaleZombieVoiceB",
    "FemaleZombieVoiceC",
    "MaleZombieVoiceA",
    "MaleZombieVoiceB",
    "MaleZombieVoiceC",
}
local SUPPRESSED_STATES = {
    ["attack"] = true,
    ["attack-network"] = true,
    ["bumped"] = true,
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
    ["attack"] = true,
    ["attack-network"] = true,
    ["bumped"] = true,
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

local function clearVanillaIntent(zombie)
    if not zombie then return false end
    if zombie.setTarget then
        zombie:setTarget(nil)
    end
    if zombie.setTargetSeenTime then
        zombie:setTargetSeenTime(0)
    end
    if zombie.setEatBodyTarget then
        zombie:setEatBodyTarget(nil, false)
    end
    if zombie.clearAggroList then
        zombie:clearAggroList()
    end
    if zombie.setAttackedBy then
        zombie:setAttackedBy(nil)
    end
    return true
end

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
    if PNC.AnimationTrace and PNC.AnimationTrace.Sample then
        PNC.AnimationTrace.Sample(
            zombie,
            "damage_release_before"
        )
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

    clearVanillaIntent(zombie)
    modData = zombie.getModData and zombie:getModData() or nil
    if modData then
        modData.PNC_BumpReleasePending = nil
        modData.PNC_BumpReleaseAt = nil
        modData.PNC_BumpActionLease = nil
        modData.PNC_BumpActionLeaseUntil = nil
        modData.PNC_BumpActionLeaseStartedAt = nil
        modData.PNC_BumpRequestedType = nil
        modData.PNC_BumpKeepUseless = nil
    end
    if PNC.AnimationTrace and PNC.AnimationTrace.Sample then
        PNC.AnimationTrace.Sample(
            zombie,
            "damage_release_after"
        )
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

function LiveBodyControl.IsMultiplayer()
    local world = getWorld and getWorld() or nil
    local gameMode = world and world.getGameMode
        and tostring(world:getGameMode() or "") or ""
    if gameMode == "Multiplayer" then
        return true
    end
    return (isClient and isClient() == true)
        or (isServer and isServer() == true)
        or false
end

function LiveBodyControl.SetManagedBodyUseless(
    zombie,
    requestedUseless,
    keepEngineMovementActive
)
    local desiredUseless
    if not zombie or not zombie.setUseless then
        return false
    end
    -- Native PathFindState and the bumped ActionContext both need a useful
    -- IsoZombie. Multiplayer is not itself a lease: callers explicitly keep
    -- the engine active only while it owns pathing or a scripted bump clip.
    desiredUseless = keepEngineMovementActive ~= true
        and requestedUseless == true
        or false
    -- setUseless() is not a harmless flag assignment on IsoZombie. Repeating
    -- it while BumpedState is entering can rebuild the action context and
    -- discard the selected PNC clip. The safety pass runs every zombie update,
    -- so make this body-mode write strictly edge-triggered.
    if zombie.isUseless
        and zombie:isUseless() == desiredUseless
    then
        return desiredUseless
    end
    zombie:setUseless(desiredUseless)
    return desiredUseless
end

function LiveBodyControl.BeginNativeMovementLease(
    zombie,
    leaseKey,
    now,
    durationMs
)
    local modData
    if not zombie or not zombie.getModData then
        return false
    end
    now = tonumber(now) or (Core and Core.Now and Core.Now() or 0)
    durationMs = math.max(
        250,
        tonumber(durationMs)
            or tonumber(PNC.Const and PNC.Const.CLIENT_NATIVE_MOVEMENT_LEASE_MS)
            or 750
    )
    modData = zombie:getModData()
    if not modData then
        return false
    end
    modData[NATIVE_MOVEMENT_LEASE_KEY] =
        tostring(leaseKey or "native_path")
    modData[NATIVE_MOVEMENT_LEASE_UNTIL_KEY] =
        now + durationMs
    LiveBodyControl.SetManagedBodyUseless(
        zombie,
        false,
        true
    )
    return true
end

function LiveBodyControl.EndNativeMovementLease(
    zombie,
    leaseKey
)
    local modData
    if not zombie or not zombie.getModData then
        return false
    end
    modData = zombie:getModData()
    if not modData then
        return false
    end
    if leaseKey ~= nil
        and modData[NATIVE_MOVEMENT_LEASE_KEY] ~= nil
        and tostring(modData[NATIVE_MOVEMENT_LEASE_KEY])
            ~= tostring(leaseKey)
    then
        return false
    end
    modData[NATIVE_MOVEMENT_LEASE_KEY] = nil
    modData[NATIVE_MOVEMENT_LEASE_UNTIL_KEY] = nil
    return true
end

function LiveBodyControl.HasNativeMovementLease(zombie, now)
    local modData
    local leaseKey
    local leaseUntil
    if not zombie or not zombie.getModData then
        return false
    end
    modData = zombie:getModData()
    leaseKey = modData and modData[NATIVE_MOVEMENT_LEASE_KEY]
        or nil
    if leaseKey == nil then
        return false
    end
    now = tonumber(now) or (Core and Core.Now and Core.Now() or 0)
    leaseUntil = tonumber(
        modData[NATIVE_MOVEMENT_LEASE_UNTIL_KEY]
    ) or 0
    if now <= leaseUntil then
        return true
    end
    modData[NATIVE_MOVEMENT_LEASE_KEY] = nil
    modData[NATIVE_MOVEMENT_LEASE_UNTIL_KEY] = nil
    return false
end

function LiveBodyControl.SuppressVanillaIntent(
    zombie,
    keepEngineMovementActive
)
    if not clearVanillaIntent(zombie) then
        return false
    end
    LiveBodyControl.SetManagedBodyUseless(
        zombie,
        true,
        keepEngineMovementActive
    )
    return true
end

local function hasBumpActionLease(zombie, now)
    local modData = zombie
        and zombie.getModData
        and zombie:getModData()
        or nil
    now = tonumber(now) or (Core and Core.Now and Core.Now() or 0)
    return modData
        and modData.PNC_BumpActionLease == true
        and now <= (
            tonumber(modData.PNC_BumpActionLeaseUntil)
                or now
        )
        or false
end

local function applyActionLeaseSafeguards(zombie, modData)
    local descriptor
    clearVanillaIntent(zombie)
    if zombie.setVariable then
        zombie:setVariable("NoLungeTarget", true)
        zombie:setVariable("NoLungeAttack", true)
        zombie:setVariable("PNCLive", true)
    end
    if zombie.setNoTeeth then
        zombie:setNoTeeth(true)
    end
    if zombie.setReanimatedForGrappleOnly then
        zombie:setReanimatedForGrappleOnly(false)
    end
    if zombie.getDescriptor then
        descriptor = zombie:getDescriptor()
        if descriptor and descriptor.setVoicePrefix then
            descriptor:setVoicePrefix("NotAZombie")
        end
    end
    LiveBodyControl.SetManagedBodyUseless(
        zombie,
        modData and modData.PNC_BumpKeepUseless == true,
        not modData or modData.PNC_BumpKeepUseless ~= true
    )
end

function LiveBodyControl.ApplyHumanizedBodyFlags(
    zombie,
    keepEngineMovementActive
)
    local descriptor
    local modData
    if not zombie then
        return
    end
    modData = zombie.getModData and zombie:getModData() or nil
    if hasBumpActionLease(zombie) then
        -- This function has several callers outside the regular maintenance
        -- pass (notably fake locomotion). Make the protection central: prone,
        -- fall, crawler, and bump setters can eject BumpedState on the exact
        -- frame a PNC melee clip enters it.
        applyActionLeaseSafeguards(zombie, modData)
        return
    end
    if PNC.AnimationTrace and PNC.AnimationTrace.Sample then
        PNC.AnimationTrace.Sample(
            zombie,
            "humanize_before"
        )
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
    clearVanillaIntent(zombie)
    if zombie.setAnimatingBackwards then
        zombie:setAnimatingBackwards(false)
    end
    -- Replicated zombie packets can restore this flag after the initial body
    -- setup. The MP authority may temporarily clear it for an active native
    -- movement lease; all target, teeth, lunge, and voice safeguards above
    -- remain enforced during that lease.
    LiveBodyControl.SetManagedBodyUseless(
        zombie,
        true,
        keepEngineMovementActive
    )
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
    if PNC.AnimationTrace and PNC.AnimationTrace.Sample then
        PNC.AnimationTrace.Sample(
            zombie,
            "humanize_after"
        )
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

function LiveBodyControl.MaintainHumanizedBody(
    zombie,
    now,
    keepEngineMovementActive,
    force
)
    local modData
    local nextAudioAt
    local nextMaintenanceAt
    local actionLeaseActive
    if not zombie then return false end
    now = tonumber(now) or (Core and Core.Now and Core.Now() or 0)
    modData = zombie.getModData and zombie:getModData() or nil
    actionLeaseActive = hasBumpActionLease(zombie, now)
    if LAST_KEEP_ENGINE_ACTIVE[zombie]
        ~= (keepEngineMovementActive == true)
    then
        force = true
    end
    nextMaintenanceAt = tonumber(
        NEXT_BODY_MAINTENANCE_AT[zombie]
    ) or 0
    if force == true or now >= nextMaintenanceAt then
        if actionLeaseActive then
            -- During a PNC special action, do not repeatedly write prone,
            -- crawler, fall, or usefulness setters. Those setters can eject
            -- BumpedState on the frame its XML node is selected.
            applyActionLeaseSafeguards(zombie, modData)
        else
            LiveBodyControl.ApplyHumanizedBodyFlags(
                zombie,
                keepEngineMovementActive
            )
        end
        NEXT_BODY_MAINTENANCE_AT[zombie] =
            now + BODY_MAINTENANCE_INTERVAL_MS
        LAST_KEEP_ENGINE_ACTIVE[zombie] =
            keepEngineMovementActive == true
    end
    nextAudioAt = tonumber(NEXT_AUDIO_SUPPRESSION_AT[zombie]) or 0
    if now >= nextAudioAt then
        LiveBodyControl.SuppressZombieSounds(zombie)
        NEXT_AUDIO_SUPPRESSION_AT[zombie] = now + SUPPRESSION_AUDIO_COOLDOWN_MS
    end
    return true
end

function LiveBodyControl.ShouldKeepEngineMovementActive(record, zombie)
    local runtime = record and record.runtime or nil
    local navigation = runtime and runtime.localNavigation or nil
    local attackAction = runtime and runtime.attackAction or nil
    local treatment = runtime and runtime.selfTreatment or nil
    local modData = zombie
        and zombie.getModData
        and zombie:getModData()
        or nil
    local now = Core and Core.Now and Core.Now() or 0
    -- The nearest multiplayer client owns PathFindState for replicated
    -- IsoZombie bodies. That body-local lease is authoritative for the Java
    -- action graph even though the client does not own NPC decisions.
    if LiveBodyControl.HasNativeMovementLease(zombie, now) then
        return true
    end
    -- MP replicas own their local animation ActionContext even though they do
    -- not own combat decisions. Honor that body-local lease before applying
    -- the authority-only restriction used by navigation records.
    if modData and modData.PNC_BumpActionLease == true then
        if now <= (
            tonumber(modData.PNC_BumpActionLeaseUntil)
                or now
        ) then
            return modData.PNC_BumpKeepUseless ~= true
        end
        modData.PNC_BumpActionLease = nil
        modData.PNC_BumpActionLeaseUntil = nil
        modData.PNC_BumpActionLeaseStartedAt = nil
        modData.PNC_BumpRequestedType = nil
        modData.PNC_BumpKeepUseless = nil
    end
    if Core and Core.IsAuthority and not Core.IsAuthority() then
        return false
    end
    if attackAction
        and now < (tonumber(attackAction.finishAt) or 0)
    then
        return true
    end
    if treatment and treatment.phase == "bandaging" then
        return true
    end
    if not navigation
        or navigation.provider ~= "engine_path"
        or navigation.nativeActive ~= true
    then
        return false
    end
    -- SP Behavior2 is manually pumped and must retain Bandits' useless-body
    -- isolation. Only delegated/PathFindState movement leases the vanilla
    -- IsoZombie update loop.
    return navigation.controllerMode ~= "behavior2_move"
end

function LiveBodyControl.EnforceManagedSafety(zombie, source)
    local actionState
    local hadTarget
    local wasUseless
    local hadTeeth
    local wasGrappleOnly
    local modData
    local npcId
    local record
    local keepEngineMovementActive
    local now
    local actionLeaseActive
    local needsImmediateRepair
    if not zombie or not Core or not Core.IsManagedNPCBody
        or not Core.IsManagedNPCBody(zombie)
    then
        return false
    end
    if PNC.Registry and PNC.Registry.FindRecordByZombie then
        record = PNC.Registry.FindRecordByZombie(zombie)
    end
    -- Native movement and bumped action leases temporarily keep the body
    -- useful so Java can advance their action states.
    now = Core.Now and Core.Now() or 0
    keepEngineMovementActive =
        LiveBodyControl.ShouldKeepEngineMovementActive(record, zombie)
    actionLeaseActive = hasBumpActionLease(zombie, now)
    hadTarget = zombie.getTarget and zombie:getTarget() ~= nil or false
    wasUseless = zombie.isUseless and zombie:isUseless() or false
    hadTeeth = zombie.isNoTeeth and not zombie:isNoTeeth() or false
    wasGrappleOnly = zombie.isReanimatedForGrappleOnly
        and zombie:isReanimatedForGrappleOnly() or false
    actionState = LiveBodyControl.GetActionStateName(zombie)
    needsImmediateRepair = hadTarget
        or (not wasUseless and not keepEngineMovementActive)
        or hadTeeth
        or wasGrappleOnly
        or (
            not keepEngineMovementActive
            and not actionLeaseActive
            and LiveBodyControl.IsSuppressedActionState(actionState)
        )
    LiveBodyControl.MaintainHumanizedBody(
        zombie,
        now,
        keepEngineMovementActive,
        needsImmediateRepair
    )
    -- PNC weapon actions live in BumpedState. A managed body reaching the
    -- vanilla zombie attack/lunge graph outside an engine lease has escaped
    -- presentation ownership; that graph has no PNC walk nodes and produces
    -- Bob_Idle sliding while fake locomotion continues.
    if not keepEngineMovementActive
        and not actionLeaseActive
        and LiveBodyControl.IsSuppressedActionState(actionState)
    then
        LiveBodyControl.SuppressZombieState(
            zombie,
            nil,
            now,
            true
        )
    end
    if (
            hadTarget
            or (not wasUseless and not keepEngineMovementActive)
            or hadTeeth
            or wasGrappleOnly
        )
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
    -- OnZombieUpdate runs for every loaded vanilla zombie. Avoid registry and
    -- planner work entirely unless this is one of our managed NPC bodies.
    if not LiveBodyControl.EnforceManagedSafety(
        zombie,
        "zombie_update"
    ) then
        return
    end
    if Core
        and Core.IsAuthority
        and Core.IsAuthority()
        and not LiveBodyControl.IsMultiplayer()
        and PNC.Registry
        and PNC.Registry.FindRecordByZombie
        and PNC.EnginePathPlanner
        and PNC.EnginePathPlanner.PumpFrame
    then
        local record = PNC.Registry.FindRecordByZombie(zombie)
        if record then
            PNC.EnginePathPlanner.PumpFrame(record, zombie)
        end
    end
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

function LiveBodyControl.SuppressZombieState(
    zombie,
    lane,
    now,
    bodyFlagsApplied
)
    local actionState = LiveBodyControl.GetActionStateName(zombie)
    local needsIdleReset
    if not zombie then
        return false, actionState
    end
    if not LiveBodyControl.IsSuppressedActionState(actionState) then
        return false, actionState
    end
    if bodyFlagsApplied ~= true then
        LiveBodyControl.ApplyHumanizedBodyFlags(zombie)
    end
    LiveBodyControl.TrySilenceEmitter(zombie, lane, now)
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
    LiveBodyControl.SetManagedBodyUseless(zombie, true)
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
