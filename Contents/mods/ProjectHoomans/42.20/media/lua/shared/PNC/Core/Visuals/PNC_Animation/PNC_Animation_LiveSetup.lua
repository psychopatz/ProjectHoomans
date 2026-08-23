PNC = PNC or {}
PNC.Animation = PNC.Animation or {}
PNC.Animation.Internal = PNC.Animation.Internal or {}

local Animation = PNC.Animation
local Internal = Animation.Internal
local Core = PNC.Core
local LiveBodyControl = PNC.LiveBodyControl
local LocomotionProfiles = PNC.LocomotionProfiles
local AnimationTrace = PNC.AnimationTrace

function Animation.ApplyLiveSetup(zombie, record)
    local descriptor
    local releasedDamageReaction = false
    if not zombie or not record then
        return
    end
    if Animation.IsBumpActionActive(zombie) then
        Internal.applyBumpLeaseBodyMode(zombie)
        return false
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
    Internal.applyWalkType(zombie, "", 1.0)
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
    if LiveBodyControl and LiveBodyControl.ReleaseDamageReaction then
        releasedDamageReaction = LiveBodyControl.ReleaseDamageReaction(zombie)
    end
    if not releasedDamageReaction
        and zombie.changeState
        and ZombieIdleState
        and ZombieIdleState.instance
    then
        zombie:changeState(ZombieIdleState.instance())
    end
    if LiveBodyControl and LiveBodyControl.StopEmitter then
        LiveBodyControl.StopEmitter(zombie)
    end
    Internal.setManagedUseless(zombie, true)
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
    -- Animation is the final presentation arbiter. Even if a behavior,
    -- snapshot, or path controller reaches this generic locomotion writer out
    -- of order, it cannot replace an active special-action clip.
    if Animation.IsBumpActionActive(zombie) then
        Internal.applyBumpLeaseBodyMode(zombie)
        return false
    end
    profile = Internal.resolveProfile(record, profileOverride, animState)
    Internal.setPNCStateVars(zombie, record, animState)
    if movingOverride ~= nil then
        moving = movingOverride == true
    else
        moving = animState == "Run" or animState == "Walk" or animState == "SneakWalk" or animState == "Crawl"
    end
    animSpeed = tonumber(profile and profile.animSpeed) or 1.0
    Internal.setLocomotionVars(zombie, profile, moving, animSpeed)
    Internal.applyWalkType(zombie, profile and profile.engineWalkType or "", animSpeed)
    if zombie.setRunning then
        zombie:setRunning(profile and profile.isRunning == true)
    end
    if LiveBodyControl and LiveBodyControl.SyncLocomotionState then
        LiveBodyControl.SyncLocomotionState(zombie, moving)
    end
    return true
end
