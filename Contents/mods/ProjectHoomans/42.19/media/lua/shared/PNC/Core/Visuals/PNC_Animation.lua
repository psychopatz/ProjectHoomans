--[[
    PNC Animation
    Single writer for PNC animation variables, locomotion flags, downed state,
    and custom bump-trigger playback on live NPC bodies.
]]

PNC = PNC or {}
PNC.Animation = PNC.Animation or {}

local Animation = PNC.Animation
local Core = PNC.Core
local LiveBodyControl = PNC.LiveBodyControl
local LocomotionProfiles = PNC.LocomotionProfiles

local BUMP_RELEASE_SETTLE_MS = 50

local function getActionStateName(zombie)
    if zombie and zombie.getActionStateName then
        return string.lower(tostring(zombie:getActionStateName() or ""))
    end
    return ""
end

local function setPNCStateVars(zombie, record, animState)
    if not zombie or not zombie.setVariable then
        return
    end
    zombie:setVariable("PNC", true)
    zombie:setVariable("PNCActor", true)
    zombie:setVariable("PNCState", tostring(record and (record.activeBehavior or record.activeJob) or "Idle"))
    zombie:setVariable("PNCOrder", tostring(record and record.orderSpec and record.orderSpec.kind or "none"))
    zombie:setVariable("PNCPresence", tostring(record and record.presenceState or "unknown"))
    zombie:setVariable("PNCAnim", tostring(animState or "Idle"))
    zombie:setVariable("PNCWeaponMode", tostring(record and record.weaponMode or "melee"))
end

local function resolveProfile(record, profileOverride, animState)
    local lane = record and record.runtime and record.runtime.pathing or nil
    local profile = profileOverride or lane and lane.motionProfile or nil
    if profile then
        return profile
    end
    if LocomotionProfiles and LocomotionProfiles.GetBaseProfile then
        if animState == "Run" then
            return LocomotionProfiles.GetBaseProfile("run")
        end
        if animState == "SneakWalk" then
            return LocomotionProfiles.GetBaseProfile("sneak")
        end
        if animState == "Crawl" then
            return LocomotionProfiles.GetBaseProfile("crawl")
        end
        return LocomotionProfiles.GetBaseProfile("walk")
    end
    return {
        moveAnim = animState == "Run" and "Run" or animState == "SneakWalk" and "SneakWalk" or animState == "Crawl" and "Crawl" or "Walk",
        walkType = animState == "SneakWalk" and "SneakWalk" or animState == "Crawl" and "Crawl" or animState == "Run" and "Run" or "Walk",
        engineWalkType = animState == "Crawl" and "" or animState == "Run" and "Run" or animState == "SneakWalk" and "SneakWalk" or "Walk",
        animSpeed = 1.0,
        isRunning = animState == "Run",
        isCrawling = animState == "Crawl",
        profileKey = string.lower(tostring(animState or "walk")),
    }
end

local function setLocomotionVars(zombie, profile, moving, animSpeed)
    local movingNow = moving == true
    local walkType = profile and tostring(profile.walkType or "") or ""
    local engineWalkType = profile and tostring(profile.engineWalkType or "") or ""
    local moveAnim = profile and tostring(profile.moveAnim or "Walk") or "Walk"
    local sneakingNow = walkType == "SneakWalk"
    local crawlingNow = profile and profile.isCrawling == true or false
    local resolvedAnimSpeed = movingNow and (tonumber(animSpeed) or 1.0) or 0.0
    local genericWalkType = movingNow and not crawlingNow and "1" or ""
    if not zombie then
        return
    end
    if zombie.setVariable then
        zombie:setVariable("PNC", true)
        zombie:setVariable("PNCActor", true)
        zombie:setVariable("PNCMoveAnim", moveAnim)
        zombie:setVariable("PNCWalkType", tostring(walkType or ""))
        zombie:setVariable("PNCEngineWalkType", tostring(engineWalkType or ""))
        zombie:setVariable("WalkType", genericWalkType)
        zombie:setVariable("PNCAnimSpeed", resolvedAnimSpeed)
        zombie:setVariable("PNCIsRunning", profile and profile.isRunning == true or false)
        zombie:setVariable("PNCIsCrawling", crawlingNow)
        zombie:setVariable("PNCMoving", movingNow)
        zombie:setVariable("bMoving", movingNow)
        zombie:setVariable("isMoving", movingNow)
        zombie:setVariable("IsSneaking", sneakingNow)
        zombie:setVariable("Speed", resolvedAnimSpeed)
        zombie:setVariable("MovementSpeed", resolvedAnimSpeed)
        zombie:setVariable("WalkSpeed", movingNow and math.max(0.1, resolvedAnimSpeed) or 0.0)
        zombie:setVariable("RunSpeed", movingNow and math.max(0.1, resolvedAnimSpeed) or 0.0)
        if crawlingNow ~= true or movingNow ~= true then
            zombie:setVariable("bBecomeCrawler", false)
            zombie:setVariable("bCrawling", false)
            zombie:setVariable("FallOnFront", false)
        end
    end
    if zombie.setMoving then
        zombie:setMoving(movingNow)
    end
    if zombie.setSneaking then
        zombie:setSneaking(sneakingNow)
    end
end

local function applyWalkType(zombie, engineWalkType, animSpeedValue)
    if not zombie then
        return
    end
    engineWalkType = tostring(engineWalkType or "")
    if zombie.setWalkType then
        zombie:setWalkType(engineWalkType)
    end
    if zombie.setSpeedMod then
        zombie:setSpeedMod(1)
    end
    if zombie.setAnimatingBackwards then
        zombie:setAnimatingBackwards(false)
    end
end

function Animation.ApplyLiveSetup(zombie, record)
    local descriptor
    if not zombie or not record then
        return
    end
    if zombie.setNoTeeth then
        zombie:setNoTeeth(true)
    end
    if zombie.setFemaleEtc then
        zombie:setFemaleEtc(record.isFemale == true)
    end
    if zombie.setVariable then
        zombie:setVariable("LimpSpeed", 0.80)
        zombie:setVariable("RunSpeed", 0.72)
        zombie:setVariable("WalkSpeed", 1.04)
        zombie:setVariable("PNCActor", true)
        zombie:setVariable("PNCWalkType", "")
        zombie:setVariable("PNCPrimary", "")
        zombie:setVariable("PNCSecondary", "")
        zombie:setVariable("PNCPrimaryType", "barehand")
        zombie:setVariable("PNCImmediateAnim", false)
        zombie:setVariable("PNCAnimSpeed", 1.0)
        zombie:setVariable("PNCMoveAnim", "")
        zombie:setVariable("PNCEngineWalkType", "")
        zombie:setVariable("PNCLive", true)
        zombie:setVariable("PNCMoving", false)
        zombie:setVariable("bMoving", false)
        zombie:setVariable("isMoving", false)
        zombie:setVariable("PNCIsRunning", false)
        zombie:setVariable("PNCIsCrawling", false)
        zombie:setVariable("WalkType", "")
    end
    applyWalkType(zombie, "", 1.0)
    if zombie.setTarget then
        zombie:setTarget(nil)
    end
    if zombie.clearAggroList then
        zombie:clearAggroList()
    end
    if zombie.setAttackedBy then
        zombie:setAttackedBy(nil)
    end
    if zombie.setPrimaryHandItem then
        zombie:setPrimaryHandItem(nil)
    end
    if zombie.setSecondaryHandItem then
        zombie:setSecondaryHandItem(nil)
    end
    if zombie.resetEquippedHandsModels then
        zombie:resetEquippedHandsModels()
    end
    if zombie.clearAttachedItems then
        zombie:clearAttachedItems()
    end
    if LiveBodyControl and LiveBodyControl.ApplyHumanizedBodyFlags then
        LiveBodyControl.ApplyHumanizedBodyFlags(zombie)
    end
    if zombie.changeState and ZombieIdleState and ZombieIdleState.instance then
        zombie:changeState(ZombieIdleState.instance())
    end
    if LiveBodyControl and LiveBodyControl.StopEmitter then
        LiveBodyControl.StopEmitter(zombie)
    end
    if zombie.setUseless then
        zombie:setUseless(true)
    end
    if zombie.getDescriptor then
        descriptor = zombie:getDescriptor()
        if descriptor and descriptor.setVoicePrefix then
            descriptor:setVoicePrefix("NotAZombie")
        end
    end
end

function Animation.Apply(zombie, record, animState, profileOverride, movingOverride)
    local profile
    local moving
    local animSpeed
    if not zombie or not record then
        return
    end
    profile = resolveProfile(record, profileOverride, animState)
    setPNCStateVars(zombie, record, animState)
    if movingOverride ~= nil then
        moving = movingOverride == true
    else
        moving = animState == "Run" or animState == "Walk" or animState == "SneakWalk" or animState == "Crawl"
    end
    animSpeed = tonumber(profile and profile.animSpeed) or 1.0
    setLocomotionVars(zombie, profile, moving, animSpeed)
    applyWalkType(zombie, profile and profile.engineWalkType or "", animSpeed)
    if zombie.setRunning then
        zombie:setRunning(profile and profile.isRunning == true)
    end
    if LiveBodyControl and LiveBodyControl.SyncLocomotionState then
        LiveBodyControl.SyncLocomotionState(zombie, moving)
    end
end

function Animation.ApplyDowned(zombie, record, movingOrProfile)
    local moving = movingOrProfile == true or type(movingOrProfile) == "table"
    local profile = type(movingOrProfile) == "table" and movingOrProfile or resolveProfile(record, nil, "Crawl")
    local animSpeed = moving and (tonumber(profile and profile.animSpeed) or 0.72) or 1.0
    if not zombie then
        return
    end
    zombie:setVariable("PNC", true)
    zombie:setVariable("PNCState", tostring(record and (record.activeBehavior or record.activeJob) or "Incapacitated"))
    zombie:setVariable("PNCAnim", moving and "Crawl" or "Downed")
    zombie:setVariable("PNCMoveAnim", moving and "Crawl" or "")
    zombie:setVariable("PNCWalkType", moving and "Crawl" or "")
    zombie:setVariable("WalkType", "")
    zombie:setVariable("PNCAnimSpeed", animSpeed)
    zombie:setVariable("bBecomeCrawler", true)
    zombie:setVariable("bCrawling", true)
    zombie:setVariable("FallOnFront", true)
    zombie:setVariable("bMoving", moving == true)
    zombie:setVariable("isMoving", moving == true)
    if zombie.setCrawler then
        zombie:setCrawler(true)
    end
    if zombie.setOnFloor then
        zombie:setOnFloor(true)
    end
    if zombie.setFallOnFront then
        zombie:setFallOnFront(true)
    end
    if zombie.setCanWalk then
        zombie:setCanWalk(true)
    end
    if zombie.setRunning then
        zombie:setRunning(false)
    end
    if zombie.setUseless then
        zombie:setUseless(true)
    end
    applyWalkType(zombie, "", animSpeed)
end

function Animation.ClearDowned(zombie)
    if not zombie then
        return
    end
    zombie:setVariable("bBecomeCrawler", false)
    zombie:setVariable("bCrawling", false)
    zombie:setVariable("FallOnFront", false)
    zombie:setVariable("PNCMoveAnim", "")
    zombie:setVariable("bMoving", false)
    zombie:setVariable("isMoving", false)
    if zombie.setCrawler then
        zombie:setCrawler(false)
    end
    if zombie.setOnFloor then
        zombie:setOnFloor(false)
    end
    if zombie.setFallOnFront then
        zombie:setFallOnFront(false)
    end
    setLocomotionVars(zombie, {
        moveAnim = "",
        walkType = "",
        engineWalkType = "",
        isRunning = false,
        isCrawling = false,
    }, false, 1.0)
    applyWalkType(zombie, "", 1.0)
end

function Animation.PlayBump(zombie, record, bumpType)
    local modData
    if not zombie then
        return
    end
    modData = zombie.getModData and zombie:getModData() or nil
    if modData then
        modData.PNC_BumpReleasePending = nil
        modData.PNC_BumpReleaseAt = nil
    end
    setPNCStateVars(zombie, record, bumpType or "Bump")
    setLocomotionVars(zombie, {
        moveAnim = "",
        walkType = "",
        engineWalkType = "",
        isRunning = false,
        isCrawling = false,
    }, false, 1.0)
    applyWalkType(zombie, "", 1.0)
    if zombie.setRunning then
        zombie:setRunning(false)
    end
    if zombie.setBumpDone then
        zombie:setBumpDone(false)
    end
    if zombie.setBumpFall then
        zombie:setBumpFall(false)
    end
    if zombie.setVariable then
        zombie:setVariable("BumpDone", false)
        zombie:setVariable("BumpAnimFinished", false)
        zombie:setVariable("BumpFall", false)
        zombie:setVariable("BumpFallType", "")
    end
    if zombie.setBumpType then
        zombie:setBumpType(tostring(bumpType or "Bump"))
    end
end

function Animation.FinishBump(zombie, forceIdle)
    local modData
    if not zombie then
        return
    end
    modData = zombie.getModData and zombie:getModData() or nil
    if zombie.setBumpDone then
        zombie:setBumpDone(true)
    end
    if zombie.setVariable then
        -- BumpedState must observe both completion flags during its next
        -- ActionContext update. Clearing BumpAnimFinished in this same tick
        -- leaves the body permanently in the bumped action state.
        zombie:setVariable("BumpDone", true)
        zombie:setVariable("BumpAnimFinished", true)
    end
    if modData then
        modData.PNC_BumpReleasePending = true
        modData.PNC_BumpReleaseAt = Core and Core.Now and Core.Now() or 0
    end
end

function Animation.PumpBumpRelease(zombie, now)
    local modData
    local releaseAt
    local actionState
    if not zombie then
        return false
    end
    modData = zombie.getModData and zombie:getModData() or nil
    if not modData or modData.PNC_BumpReleasePending ~= true then
        return false
    end
    now = tonumber(now) or Core and Core.Now and Core.Now() or 0
    releaseAt = tonumber(modData.PNC_BumpReleaseAt) or now
    if zombie.setBumpDone then
        zombie:setBumpDone(true)
    end
    if zombie.setVariable then
        zombie:setVariable("BumpDone", true)
        zombie:setVariable("BumpAnimFinished", true)
    end
    actionState = getActionStateName(zombie)
    if (now - releaseAt) < BUMP_RELEASE_SETTLE_MS or actionState == "bumped" then
        return true
    end
    -- BumpedState.exit owns clearing BumpAnimFinished and BumpType. This
    -- fallback only normalizes a body that has already left that state.
    if zombie.setBumpType then
        zombie:setBumpType("")
    end
    modData.PNC_BumpReleasePending = nil
    modData.PNC_BumpReleaseAt = nil
    return false
end

function Animation.SyncLocomotion(zombie, record)
    local profile
    local moving
    local moveAnim
    local walkType
    local engineWalkType
    local animSpeed
    local runtime
    local attackAction
    local path
    local now
    if not zombie then
        return
    end
    runtime = record and record.runtime or nil
    attackAction = runtime and runtime.attackAction or nil
    path = runtime and runtime.pathing or nil
    now = Core and Core.Now and Core.Now() or 0
    if Animation.PumpBumpRelease(zombie, now) then
        if zombie.setUseless then
            zombie:setUseless(true)
        end
        return
    end
    if attackAction and now < (tonumber(attackAction.finishAt) or 0) then
        if zombie.setUseless then
            zombie:setUseless(true)
        end
        return
    end
    if path and now < (tonumber(path.specialMoveUntil) or 0) and path.specialAnim then
        if zombie.setUseless then
            zombie:setUseless(true)
        end
        return
    end
    profile = path and path.motionProfile or nil
    moving = path and (
        path.phase == "requested"
        or path.phase == "active"
        or path.ownerMode == "fake_locomotion"
        or now < (tonumber(path.visualMovingUntil) or 0)
    ) or false
    moveAnim = path and path.moveAnim or zombie.getVariableString and zombie:getVariableString("PNCMoveAnim") or ""
    walkType = path and path.walkType or zombie.getVariableString and zombie:getVariableString("PNCWalkType") or ""
    engineWalkType = path and path.engineWalkType
        or zombie.getVariableString and zombie:getVariableString("PNCEngineWalkType")
        or zombie.getVariableString and zombie:getVariableString("WalkType")
        or ""
    animSpeed = path and path.animSpeed or zombie.getVariableFloat and zombie:getVariableFloat("PNCAnimSpeed", 1.0) or 1.0
    setLocomotionVars(zombie, profile or {
        moveAnim = moveAnim ~= "" and moveAnim or "Walk",
        walkType = walkType or "",
        engineWalkType = engineWalkType or "",
        isRunning = path and path.isRunning == true or false,
        isCrawling = path and path.isCrawling == true or false,
    }, moving, animSpeed)
    applyWalkType(zombie, engineWalkType, animSpeed)
    if zombie.setRunning then
        zombie:setRunning(path and path.isRunning == true)
    end
    if LiveBodyControl and LiveBodyControl.SyncLocomotionState then
        LiveBodyControl.SyncLocomotionState(zombie, moving)
    end
    if zombie.setUseless then
        zombie:setUseless(true)
    end
end
