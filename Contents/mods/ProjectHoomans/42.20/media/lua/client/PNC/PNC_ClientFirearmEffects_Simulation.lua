local Effects = PNC and PNC.ClientFirearmEffects
if not Effects then return end

local Internal = Effects.Internal or {}
local Deps = Internal.SimulationDeps or {}
local nowMs = Deps.nowMs
local readMethod = Deps.readMethod
local DEBUG_SIMULATION_INTERVAL_MS = Deps.DEBUG_SIMULATION_INTERVAL_MS

function Effects.SimulateShot(body, npcID, playerIndex)
    local x
    local y
    local z
    local id = tostring(npcID or "debug_npc")
    local payload
    if not body then return false, "body_missing" end
    x = tonumber(readMethod(body, "getX"))
    y = tonumber(readMethod(body, "getY"))
    z = tonumber(readMethod(body, "getZ")) or 0
    if not x or not y then return false, "body_position_missing" end
    Effects.DebugShotSequence = Effects.DebugShotSequence + 1
    payload = {
        body = body,
        npcId = id,
        shotId = "debug_firearm:" .. id .. ":"
            .. tostring(Effects.DebugShotSequence) .. ":" .. tostring(nowMs()),
        playerIndex = tonumber(playerIndex) or 0,
        sx = x,
        sy = y,
        sz = z,
        -- Deliberately use a non-matching type so a held weapon cannot route
        -- this dry-fire probe through the native effect path. The purpose of
        -- this action is to visualize the cached fallback anchor itself, so it
        -- opts into the nameplate anchor instead of the world bore line.
        weaponFullType = "PNC.DebugSimulatedWeapon",
        anchorProbe = true,
        projectileCount = 1,
        projectileSpread = 0,
        ammoType = "PNC.DebugAmmo",
    }
    return Effects.Play(payload), payload
end

function Effects.IsSimulationActive(body, npcID)
    local simulation = Effects.DebugSimulation
    if not simulation then return false end
    return simulation.body == body
        and tostring(simulation.npcID or "") == tostring(npcID or "")
end

function Effects.StopSimulation()
    Effects.DebugSimulation = nil
end

function Effects.ToggleSimulation(body, npcID, playerIndex)
    local now
    local simulation
    local ok
    if Effects.IsSimulationActive(body, npcID) then
        Effects.StopSimulation()
        return false
    end
    if not body then return false, "body_missing" end
    Effects.StopSimulation()
    ok = Effects.SimulateShot(body, npcID, playerIndex)
    if not ok then return false, "initial_simulation_failed" end
    now = nowMs()
    simulation = {
        body = body,
        npcID = npcID,
        playerIndex = tonumber(playerIndex) or 0,
        nextShotAt = now + DEBUG_SIMULATION_INTERVAL_MS,
    }
    Effects.DebugSimulation = simulation
    return true
end

function Effects.OnTick()
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    local simulation = Effects.DebugSimulation
    if simulation and now >= (tonumber(simulation.nextShotAt) or 0) then
        if not simulation.body then
            Effects.StopSimulation()
        elseif Effects.SimulateShot(
            simulation.body,
            simulation.npcID,
            simulation.playerIndex
        ) then
            simulation.nextShotAt = now + DEBUG_SIMULATION_INTERVAL_MS
        else
            Effects.StopSimulation()
        end
    end
    for shotId, seenAt in pairs(Effects.SeenShots) do
        if now - (tonumber(seenAt) or 0) > 10000 then
            Effects.SeenShots[shotId] = nil
        end
    end
end
