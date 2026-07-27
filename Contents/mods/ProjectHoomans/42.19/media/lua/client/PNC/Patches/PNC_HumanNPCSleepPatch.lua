require "ISUI/ISWorldObjectContextMenu"
require "PNC/PNC_ClientHumanNPCSafeguards"

PNC = PNC or {}
PNC.HumanNPCSleepPatch = PNC.HumanNPCSleepPatch or {}

local Patch = PNC.HumanNPCSleepPatch

local function readThreatCounters(playerObj)
    local stats = playerObj and playerObj.getStats and playerObj:getStats() or nil
    if not stats then return 0, 0, 0, nil end
    return stats.getNumVisibleZombies and stats:getNumVisibleZombies() or 0,
        stats.getNumChasingZombies and stats:getNumChasingZombies() or 0,
        stats.getNumVeryCloseZombies and stats:getNumVeryCloseZombies() or 0,
        CharacterStat and CharacterStat.PANIC and stats.get
            and stats:get(CharacterStat.PANIC) or nil
end

if not Patch.OriginalOnSleepWalkToComplete then
    Patch.OriginalOnSleepWalkToComplete =
        ISWorldObjectContextMenu.onSleepWalkToComplete

    function ISWorldObjectContextMenu.onSleepWalkToComplete(player, bed)
        local playerObj = getSpecificPlayer and getSpecificPlayer(player) or nil
        local safeguards = PNC.ClientHumanNPCSafeguards
        local beforeVisible
        local beforeChasing
        local beforeClose
        local afterVisible
        local afterChasing
        local afterClose
        local panic
        local refreshed = false
        if playerObj and safeguards
            and safeguards.RefreshVanillaThreatCounters
        then
            -- This exact LOS refresh excludes managed human bodies only. Any
            -- ordinary zombie remains in the vanilla counters and the original
            -- sleep function below still rejects the unsafe sleep attempt.
            beforeVisible, beforeChasing, beforeClose =
                readThreatCounters(playerObj)
            refreshed = safeguards.RefreshVanillaThreatCounters(playerObj)
            afterVisible, afterChasing, afterClose, panic =
                readThreatCounters(playerObj)
            if PNC.Core and PNC.Core.LogDebug then
                PNC.Core.LogDebug("sleep_gate refreshed=" .. tostring(refreshed)
                    .. " before=" .. tostring(beforeVisible)
                    .. "/" .. tostring(beforeChasing)
                    .. "/" .. tostring(beforeClose)
                    .. " after=" .. tostring(afterVisible)
                    .. "/" .. tostring(afterChasing)
                    .. "/" .. tostring(afterClose)
                    .. " panic=" .. tostring(panic))
            end
        end
        return Patch.OriginalOnSleepWalkToComplete(player, bed)
    end
end

return Patch
