PNC = PNC or {}
PNC.Animation = PNC.Animation or {}
PNC.Animation.Internal = PNC.Animation.Internal or {}

local Animation = PNC.Animation
local Internal = Animation.Internal
local Core = PNC.Core
local LiveBodyControl = PNC.LiveBodyControl
local LocomotionProfiles = PNC.LocomotionProfiles
local AnimationTrace = PNC.AnimationTrace

function Internal.resolveProfile(record, profileOverride, animState)
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

function Internal.setLocomotionVars(zombie, profile, moving, animSpeed)
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
        -- PNC crawl is a visual locomotion profile, never the vanilla zombie
        -- crawler state. The latter changes the engine action-state tree and
        -- prevents the PNC idle/walktoward crawl nodes from being selected.
        zombie:setVariable("bBecomeCrawler", false)
        zombie:setVariable("bCrawling", false)
        zombie:setVariable("FallOnFront", false)
    end
    if zombie.setMoving then
        zombie:setMoving(movingNow)
    end
    if zombie.setSneaking then
        zombie:setSneaking(sneakingNow)
    end
end

function Internal.applyWalkType(zombie, engineWalkType, animSpeedValue)
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

-- PathFindBehavior2 owns the action state, bMoving/isMoving, and deferred
-- movement while an engine path is active.  This helper deliberately applies
-- only PNC-specific presentation variables and the same walk-type setter used
-- by Bandits.  Calling Internal.setLocomotionVars/SyncLocomotionState here would force
-- WalkTowardState on top of a non-null path2 and make doDeferredMovement reject
-- the path every frame.
