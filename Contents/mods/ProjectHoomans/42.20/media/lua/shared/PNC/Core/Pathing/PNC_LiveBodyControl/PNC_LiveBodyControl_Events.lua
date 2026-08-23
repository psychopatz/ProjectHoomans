-- Managed-body scanning, zombie updates, and global event registration.

PNC = PNC or {}
PNC.LiveBodyControl = PNC.LiveBodyControl or {}

local LiveBodyControl = PNC.LiveBodyControl
local Core = PNC.Core
local Diagnostics = PNC.PerformanceScalingDiagnostics

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
    if not LiveBodyControl.EnforceManagedSafety(
        zombie,
        "zombie_update"
    ) then
        return
    end
    if Diagnostics then
        Diagnostics.Increment("LiveAbstract.ManagedBodyUpdates")
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
            if Diagnostics
                and record.presenceState == PNC.Const.PRESENCE_ABSTRACT
            then
                Diagnostics.Increment("LiveAbstract.AbstractBodyUpdates")
            end
            PNC.EnginePathPlanner.PumpFrame(record, zombie)
        end
    end
end

function LiveBodyControl.OnWorldReady()
    LiveBodyControl.ScanLoadedManagedBodies("world_ready")
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
