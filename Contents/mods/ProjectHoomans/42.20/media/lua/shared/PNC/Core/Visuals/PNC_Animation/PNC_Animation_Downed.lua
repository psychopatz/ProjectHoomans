PNC = PNC or {}
PNC.Animation = PNC.Animation or {}
PNC.Animation.Internal = PNC.Animation.Internal or {}

local Animation = PNC.Animation
local Internal = Animation.Internal
local Core = PNC.Core
local LiveBodyControl = PNC.LiveBodyControl
local LocomotionProfiles = PNC.LocomotionProfiles
local AnimationTrace = PNC.AnimationTrace

function Animation.ApplyDowned(zombie, record, movingOrProfile)
    local moving = movingOrProfile == true or type(movingOrProfile) == "table"
    local profile = type(movingOrProfile) == "table" and movingOrProfile or Internal.resolveProfile(record, nil, "Crawl")
    local animSpeed = moving and (tonumber(profile and profile.animSpeed) or 0.72) or 1.0
    if not zombie then
        return
    end
    if LiveBodyControl and LiveBodyControl.ReleaseDamageReaction then
        LiveBodyControl.ReleaseDamageReaction(zombie)
    end
    Internal.setPNCStateVars(zombie, record, moving and "Crawl" or "Downed")
    zombie:setVariable("PNCActor", true)
    zombie:setVariable("PNCMoveAnim", moving and "Crawl" or "")
    -- Fake crawling must stay in the PNC idle locomotion tree. Enabling the
    -- vanilla crawler/floor flags moves the zombie into its on-ground action
    -- state, where controlled position steps continue but PNC_Crawl cannot be
    -- selected, producing a static prone body that glides across the floor.
    zombie:setVariable("PNCWalkType", "Crawl")
    zombie:setVariable("PNCEngineWalkType", "")
    zombie:setVariable("PNCIsCrawling", true)
    zombie:setVariable("PNCMoving", moving == true)
    zombie:setVariable("WalkType", "")
    zombie:setVariable("PNCAnimSpeed", animSpeed)
    zombie:setVariable("bBecomeCrawler", false)
    zombie:setVariable("bCrawling", false)
    zombie:setVariable("FallOnFront", false)
    zombie:setVariable("bMoving", moving == true)
    zombie:setVariable("isMoving", moving == true)
    zombie:setVariable("Speed", moving and animSpeed or 0.0)
    zombie:setVariable("MovementSpeed", moving and animSpeed or 0.0)
    if zombie.setCrawler then
        zombie:setCrawler(false)
    end
    if zombie.setOnFloor then
        zombie:setOnFloor(false)
    end
    if zombie.setFallOnFront then
        zombie:setFallOnFront(false)
    end
    if zombie.setCanWalk then
        zombie:setCanWalk(true)
    end
    if zombie.setMoving then
        zombie:setMoving(moving == true)
    end
    if zombie.setSneaking then
        zombie:setSneaking(false)
    end
    if zombie.setRunning then
        zombie:setRunning(false)
    end
    Internal.setManagedUseless(zombie, true)
    Internal.applyWalkType(zombie, "", animSpeed)
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
    Internal.setLocomotionVars(zombie, {
        moveAnim = "",
        walkType = "",
        engineWalkType = "",
        isRunning = false,
        isCrawling = false,
    }, false, 1.0)
    Internal.applyWalkType(zombie, "", 1.0)
end
