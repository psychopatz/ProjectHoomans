-- Damage-reaction release and action-context cleanup.

local LiveBodyControl = PNC.LiveBodyControl
local Internal = LiveBodyControl.Internal

function LiveBodyControl.ReleaseDamageReaction(zombie, actionState)
    local modData
    local isDamageReaction
    if not zombie then return false end
    if PNC.AnimationTrace and PNC.AnimationTrace.Sample then
        PNC.AnimationTrace.Sample(zombie, "damage_release_before")
    end
    actionState = string.lower(tostring(
        actionState or LiveBodyControl.GetActionStateName(zombie) or ""
    ))
    isDamageReaction = Internal.isDamageReactionState(actionState)
    if zombie.setStaggerBack then zombie:setStaggerBack(false) end
    if zombie.setHitReaction then zombie:setHitReaction("") end
    if zombie.setBumpDone then zombie:setBumpDone(true) end
    if zombie.setBumpStaggered then zombie:setBumpStaggered(false) end
    if zombie.setBumpFall then zombie:setBumpFall(false) end
    if zombie.setBumpType then zombie:setBumpType("") end
    if zombie.setVariable then
        zombie:setVariable("BumpDone", true)
        zombie:setVariable("BumpAnimFinished", true)
        zombie:setVariable("BumpFall", false)
        zombie:setVariable("BumpFallType", "")
    end
    if isDamageReaction then
        if string.find(actionState, "staggerback", 1, true) == 1
            and zombie.setStateEventDelayTimer
        then
            zombie:setStateEventDelayTimer(0)
        end
        if string.find(actionState, "hitreaction", 1, true) == 1
            and zombie.reportEvent
        then
            zombie:reportEvent("ActiveAnimFinishing")
        end
    end
    Internal.clearVanillaIntent(zombie)
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
        PNC.AnimationTrace.Sample(zombie, "damage_release_after")
    end
    return isDamageReaction
end
