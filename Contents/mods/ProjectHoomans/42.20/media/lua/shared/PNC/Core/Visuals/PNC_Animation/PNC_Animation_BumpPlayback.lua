PNC = PNC or {}
PNC.Animation = PNC.Animation or {}
PNC.Animation.Internal = PNC.Animation.Internal or {}

local Animation = PNC.Animation
local Internal = Animation.Internal
local Core = PNC.Core
local LiveBodyControl = PNC.LiveBodyControl
local AnimationTrace = PNC.AnimationTrace

local function notifyExternalScene(record, zombie, bumpType, options)
    if (not options or options.sceneId == nil)
        and PNC.AnimationScenes
        and PNC.AnimationScenes.OnExternalBump
    then
        PNC.AnimationScenes.OnExternalBump(record, zombie, bumpType)
    end
end

local function beginTrace(zombie, record, requested, resolved, now)
    if not AnimationTrace or not AnimationTrace.Ensure then
        return
    end
    AnimationTrace.Ensure(zombie, {
        npcId = record and record.id or nil,
        requested = requested,
        resolved = resolved,
        debugEnabled = record
            and record.runtime
            and record.runtime.debug == true
            or false,
    }, now)
end

local function resolveKeepManagedUseless(options, combatBump)
    if options and options.keepManagedUseless ~= nil then
        return options.keepManagedUseless == true
    end
    if combatBump
        and LiveBodyControl
        and LiveBodyControl.IsMultiplayer
    then
        return LiveBodyControl.IsMultiplayer() ~= true
    end
    return false
end

local function installLease(
    modData,
    options,
    now,
    resolvedBumpType,
    keepManagedUseless
)
    local leaseUntil = tonumber(options and options.leaseUntil)
        or (now + Internal.BUMP_ACTION_LEASE_TIMEOUT_MS)
    leaseUntil = math.max(
        now + Internal.BUMP_ACTION_ENTRY_GRACE_MS,
        leaseUntil
    )
    if not modData then
        return leaseUntil
    end
    modData.PNC_BumpReleasePending = nil
    modData.PNC_BumpReleaseAt = nil
    modData.PNC_BumpActionLease = true
    modData.PNC_BumpActionLeaseUntil = leaseUntil
    modData.PNC_BumpActionLeaseStartedAt = now
    modData.PNC_BumpRequestedType = resolvedBumpType
    modData.PNC_BumpKeepUseless = keepManagedUseless
    return leaseUntil
end

local function resetLocomotion(zombie, combatBump)
    if combatBump then return end
    Internal.setLocomotionVars(zombie, {
        moveAnim = "",
        walkType = "",
        engineWalkType = "",
        isRunning = false,
        isCrawling = false,
    }, false, 1.0)
    Internal.applyWalkType(zombie, "", 1.0)
    if zombie.setRunning then
        zombie:setRunning(false)
    end
end

local function resetCompletionVariables(zombie, combatBump)
    if zombie.setBumpDone then
        zombie:setBumpDone(false)
    end
    if zombie.setBumpFall then
        zombie:setBumpFall(false)
    end
    if not zombie.setVariable then return end
    zombie:setVariable("CombatSpeed", "1.0")
    zombie:setVariable("ReloadSpeed", "1.0")
    zombie:setVariable("BumpDone", false)
    zombie:setVariable("BumpAnimFinished", false)
    zombie:setVariable("BumpFall", false)
    zombie:setVariable("BumpFallType", "")
    if combatBump then
        zombie:setVariable("PNCAttackVariationX", "1.0")
        zombie:setVariable("PNCAttackVariationY", "0.0")
        if zombie.clearVariable then
            zombie:clearVariable("AttackVariationX")
            zombie:clearVariable("AttackVariationY")
        end
    else
        zombie:setVariable("BumpFall", false)
        zombie:setVariable("BumpFallType", "")
    end
end

local function triggerSelector(
    zombie,
    record,
    resolvedBumpType,
    now
)
    Internal.applyBumpLeaseBodyMode(zombie)
    local stateBefore = Internal.getActionStateName(zombie)
    if AnimationTrace and AnimationTrace.Sample then
        AnimationTrace.Sample(zombie, "setter_before", now, true)
    end
    if zombie.setBumpType then
        zombie:setBumpType(resolvedBumpType)
    end
    local stateAfter = Internal.getActionStateName(zombie)
    if AnimationTrace and AnimationTrace.Sample then
        AnimationTrace.Sample(zombie, "setter_after", now, true)
    end
    local entered = stateBefore ~= stateAfter
        or stateBefore == "bumped"
        or stateAfter == "bumped"
    Internal.recordBumpTrigger(
        zombie,
        record,
        resolvedBumpType,
        entered,
        "bump_type_setter",
        stateBefore,
        stateAfter
    )
end

function Animation.PlayBump(zombie, record, bumpType, options)
    if not zombie then
        return false, "no_body"
    end
    notifyExternalScene(record, zombie, bumpType, options)
    local now = Core and Core.Now and Core.Now() or 0
    local resolvedBumpType = Animation.ResolveBumpType(bumpType)
    beginTrace(
        zombie,
        record,
        bumpType,
        resolvedBumpType,
        now
    )
    local combatBump = Internal.isCombatBumpType(
        bumpType,
        resolvedBumpType
    )
    local keepManagedUseless = resolveKeepManagedUseless(
        options,
        combatBump
    )
    local modData = zombie.getModData
        and zombie:getModData() or nil
    installLease(
        modData,
        options,
        now,
        resolvedBumpType,
        keepManagedUseless
    )
    Internal.setPNCStateVars(
        zombie,
        record,
        bumpType or "Bump"
    )
    resetLocomotion(zombie, combatBump)
    resetCompletionVariables(zombie, combatBump)
    triggerSelector(zombie, record, resolvedBumpType, now)
    return true, "bump_type_setter"
end

