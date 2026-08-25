-- Managed-body scanning, zombie updates, and global event registration.

PNC = PNC or {}
PNC.LiveBodyControl = PNC.LiveBodyControl or {}

local LiveBodyControl = PNC.LiveBodyControl
local Core = PNC.Core
local Diagnostics = PNC.PerformanceScalingDiagnostics
local plantProtectionState = setmetatable({}, { __mode = "k" })

local function hasFarmingPlant(square)
    return square and square.hasFarmingPlant
        and square:hasFarmingPlant() == true
end

local function relocateToSquare(zombie, square)
    local x
    local y
    local z
    if not zombie or not square then
        return false
    end
    x = square.getX and square:getX() or nil
    y = square.getY and square:getY() or nil
    z = square.getZ and square:getZ() or zombie:getZ()
    if x == nil or y == nil then
        return false
    end
    if zombie.setX then zombie:setX(x + 0.5) end
    if zombie.setY then zombie:setY(y + 0.5) end
    if zombie.setZ then zombie:setZ(z) end
    if zombie.setCurrent then zombie:setCurrent(square) end
    return true
end

local function findNearbyPlantFreeSquare(zombie, square)
    local cell
    local x
    local y
    local z
    local radius
    local dx
    local dy
    local candidate
    if not zombie or not square or not zombie.getCell
        or not square.getX or not square.getY
    then
        return nil
    end
    cell = zombie:getCell()
    if not cell or not cell.getGridSquare then
        return nil
    end
    x = square:getX()
    y = square:getY()
    z = square.getZ and square:getZ() or math.floor(zombie:getZ())
    for radius = 1, 4 do
        for dx = -radius, radius do
            for dy = -radius, radius do
                if math.abs(dx) == radius or math.abs(dy) == radius then
                    candidate = cell:getGridSquare(x + dx, y + dy, z)
                    if candidate and not hasFarmingPlant(candidate)
                        and (not candidate.isFree or candidate:isFree(false))
                    then
                        return candidate
                    end
                end
            end
        end
    end
    return nil
end

function LiveBodyControl.ProtectManagedPlant(zombie)
    local square
    local state
    local safeSquare
    if not zombie or not Core or not Core.IsManagedNPCBody
        or not Core.IsManagedNPCBody(zombie)
    then
        return false
    end
    square = zombie.getSquare and zombie:getSquare() or nil
    if not square then
        return false
    end
    state = plantProtectionState[zombie]
    if not hasFarmingPlant(square) then
        plantProtectionState[zombie] = {
            square = square,
            x = zombie:getX(),
            y = zombie:getY(),
            z = zombie:getZ(),
        }
        return false
    end
    safeSquare = state and state.square or nil
    if not safeSquare or hasFarmingPlant(safeSquare) then
        safeSquare = findNearbyPlantFreeSquare(zombie, square)
    end
    if safeSquare and relocateToSquare(zombie, safeSquare) then
        plantProtectionState[zombie] = {
            square = safeSquare,
            x = zombie:getX(),
            y = zombie:getY(),
            z = zombie:getZ(),
        }
        return true
    end
    return false
end

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
    if Core and (not Core.IsAuthority or Core.IsAuthority()) then
        if Core.ProtectVisualClothingFromFall then
            Core.ProtectVisualClothingFromFall(zombie)
        end
        LiveBodyControl.ProtectManagedPlant(zombie)
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

function LiveBodyControl.OnTick()
    if Core and Core.RestoreVisualClothingFallProtection then
        Core.RestoreVisualClothingFallProtection()
    end
end

function LiveBodyControl.OnWeaponHitCharacter(attacker, target)
    if not Core or not Core.IsAuthority
        or not Core.IsAuthority()
        or not Core.IsManagedNPCBody
        or not Core.IsManagedNPCBody(target)
    then
        return
    end
    if Core.ProtectVisualClothingFromFall then
        Core.ProtectVisualClothingFromFall(target)
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
if Events and Events.OnTick then
    if Events.OnTick.Remove then
        Events.OnTick.Remove(LiveBodyControl.OnTick)
    end
    Events.OnTick.Add(LiveBodyControl.OnTick)
end
if Events and Events.OnWeaponHitCharacter then
    if Events.OnWeaponHitCharacter.Remove then
        Events.OnWeaponHitCharacter.Remove(
            LiveBodyControl.OnWeaponHitCharacter
        )
    end
    Events.OnWeaponHitCharacter.Add(
        LiveBodyControl.OnWeaponHitCharacter
    )
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
