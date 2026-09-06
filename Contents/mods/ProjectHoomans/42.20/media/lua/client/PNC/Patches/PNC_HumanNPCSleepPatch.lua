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

local function refreshForPlayer(player)
    local playerObj = getSpecificPlayer and getSpecificPlayer(player) or nil
    local safeguards = PNC.ClientHumanNPCSafeguards
    if playerObj and safeguards and safeguards.RefreshVanillaThreatCounters then
        return safeguards.RefreshVanillaThreatCounters(playerObj), playerObj
    end
    return false, playerObj
end

-- Java creates the sleep option before Lua's onSleepWalkToComplete callback.
-- Refresh on the pre-fill event so the initial option is not marked unsafe.
if Events and Events.OnPreFillWorldObjectContextMenu
    and not Patch.PreFillRegistered
then
    Patch.PreFillRegistered = true
    Events.OnPreFillWorldObjectContextMenu.Add(function(player)
        refreshForPlayer(player)
    end)
end

if not Patch.OriginalOnSleepWalkToComplete then
    Patch.OriginalOnSleepWalkToComplete =
        ISWorldObjectContextMenu.onSleepWalkToComplete

    function ISWorldObjectContextMenu.onSleepWalkToComplete(player, bed)
        local playerObj
        local beforeVisible
        local beforeChasing
        local beforeClose
        local afterVisible
        local afterChasing
        local afterClose
        local panic
        local refreshed
        playerObj = getSpecificPlayer and getSpecificPlayer(player) or nil
        if playerObj then
            beforeVisible, beforeChasing, beforeClose =
                readThreatCounters(playerObj)
            refreshed = PNC.ClientHumanNPCSafeguards
                and PNC.ClientHumanNPCSafeguards.RefreshVanillaThreatCounters
                and PNC.ClientHumanNPCSafeguards.RefreshVanillaThreatCounters(
                    playerObj
                ) or false
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
