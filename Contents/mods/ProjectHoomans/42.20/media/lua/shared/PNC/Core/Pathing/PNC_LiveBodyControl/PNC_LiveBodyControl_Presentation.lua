-- Humanized body flags and special-action safeguards.

local LiveBodyControl = PNC.LiveBodyControl
local Internal = LiveBodyControl.Internal
local Core = PNC.Core

function Internal.hasBumpActionLease(zombie, now)
    local modData = zombie
        and zombie.getModData
        and zombie:getModData()
        or nil
    now = tonumber(now) or (Core and Core.Now and Core.Now() or 0)
    return modData
        and modData.PNC_BumpActionLease == true
        and now <= (tonumber(modData.PNC_BumpActionLeaseUntil) or now)
        or false
end

function Internal.applyActionLeaseSafeguards(zombie, modData)
    local descriptor
    Internal.clearVanillaIntent(zombie)
    if zombie.setVariable then
        zombie:setVariable("NoLungeTarget", true)
        zombie:setVariable("NoLungeAttack", true)
        zombie:setVariable("PNCLive", true)
    end
    if zombie.setNoTeeth then zombie:setNoTeeth(true) end
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
    if not zombie then return end
    modData = zombie.getModData and zombie:getModData() or nil
    if Internal.hasBumpActionLease(zombie) then
        Internal.applyActionLeaseSafeguards(zombie, modData)
        return
    end
    if PNC.AnimationTrace and PNC.AnimationTrace.Sample then
        PNC.AnimationTrace.Sample(zombie, "humanize_before")
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
    if zombie.setKnockedDown
        and zombie.isKnockedDown
        and zombie:isKnockedDown()
    then
        zombie:setKnockedDown(false)
    end
    if zombie.setBumpFall then zombie:setBumpFall(false) end
    if zombie.setSitAgainstWall then zombie:setSitAgainstWall(false) end
    if zombie.setOnFloor and zombie.isOnFloor and zombie:isOnFloor() then
        zombie:setOnFloor(false)
    end
    if zombie.setFallOnFront then zombie:setFallOnFront(false) end
    if zombie.setCrawler then zombie:setCrawler(false) end
    if zombie.setFakeDead then zombie:setFakeDead(false) end
    if zombie.setCanWalk then zombie:setCanWalk(true) end
    Internal.clearVanillaIntent(zombie)
    if zombie.setAnimatingBackwards then zombie:setAnimatingBackwards(false) end
    LiveBodyControl.SetManagedBodyUseless(
        zombie,
        true,
        keepEngineMovementActive
    )
    if zombie.setNoTeeth then zombie:setNoTeeth(true) end
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
        PNC.AnimationTrace.Sample(zombie, "humanize_after")
    end
end
