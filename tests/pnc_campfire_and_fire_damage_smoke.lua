local T = require "tests/support/test"

T.addPackagePaths()

local nowMs = 10000
local randRoll = 5000
ZombRand = function(limit)
    if not limit or limit <= 1 then return 0 end
    return randRoll % limit
end
IsoFlagType = { burning = "burning" }

PNC = {
    Const = {},
    Core = {
        Now = function() return nowMs end,
        IsAuthority = function() return true end,
        IsManagedNPCBody = function(z) return z and z._managed == true end,
        Clamp = function(v, lo, hi)
            if v < lo then return lo end
            if v > hi then return hi end
            return v
        end,
    },
    Sandbox = {
        CanZombieTargetRecord = function() return true end,
    },
    Registry = {
        MarkDirty = function() end,
        FindRecordByZombie = function(z) return z and z._record or nil end,
    },
    LiveBodyControl = {},
    Health = { Internal = {} },
    NPCWounds = { Internal = {} },
}

T.load("ProjectHoomans", "shared", "PNC/Core/Base/PNC_Constants/HealthThreats.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_Events.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Definitions.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_BodyState.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Mutation.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Health/PNC_Health/PNC_Health_LiveState.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Health/PNC_Health/PNC_Health_Incapacitation.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Health/PNC_Health/PNC_Health_Death.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Health/PNC_Health/PNC_Health_Damage.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Health/PNC_Health/PNC_Health_FireDamage.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Health/PNC_Health/PNC_Health_Update.lua")

local WoundCodec = T.load("ProjectHoomans", "shared", "PNC/Core/Health/Repository/PNC_HealthWoundCodec.lua")

PNC.NPCWounds.Recalculate = function(record)
    local body = PNC.NPCWounds.Ensure(record)
    local open = 0
    for _ in pairs(body.wounds) do open = open + 1 end
    body.openWoundCount = open
end
PNC.NPCWounds.HasActiveInfection = function() return false end
PNC.NPCWounds.Update = function() return false end

local function makeSquare(x, y, z, opts)
    opts = opts or {}
    return {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return z end,
        hasLitCampfire = function() return opts.campfire == true end,
        hasFarmingPlant = function() return opts.plant == true end,
        isFree = function() return opts.free ~= false end,
        getProperties = function()
            return {
                has = function(_, flag)
                    return flag == IsoFlagType.burning and opts.burning == true
                end,
            }
        end,
    }
end

local function makeGrid(squaresByKey)
    return {
        getGridSquare = function(_, x, y, z)
            return squaresByKey[string.format("%d,%d,%d", x, y, z)]
        end,
    }
end

local function makeZombie(cell, square, record)
    local z = {
        _managed = true,
        _record = record,
        _square = square,
        _x = square:getX() + 0.5,
        _y = square:getY() + 0.5,
        _z = square:getZ(),
        _onFire = false,
        _running = false,
        _fireSpread = 50,
        _fireKillRate = 0.0038,
        _stopBurningCalls = 0,
        _health = 1000,
    }
    function z:getCell() return cell end
    function z:getSquare() return self._square end
    function z:setCurrent(sq) self._square = sq end
    function z:getX() return self._x end
    function z:getY() return self._y end
    function z:getZ() return self._z end
    function z:setX(v) self._x = v end
    function z:setY(v) self._y = v end
    function z:setZ(v) self._z = v end
    function z:isOnFire() return self._onFire end
    function z:setOnFire(v) self._onFire = v == true end
    function z:StopBurning()
        self._stopBurningCalls = self._stopBurningCalls + 1
        self._onFire = false
    end
    function z:setFireSpreadProbability(v) self._fireSpread = v end
    function z:setFireKillRate(v) self._fireKillRate = v end
    function z:isRunning() return self._running end
    function z:setRunning(v) self._running = v == true end
    function z:setHealth(v) self._health = v end
    function z:isDead() return self._health <= 0 end
    return z
end

local function makeRecord(id)
    local record = {
        id = id,
        alive = true,
        x = 10,
        y = 10,
        z = 0,
        runtime = {},
    }
    PNC.Health.Ensure(record)
    PNC.NPCWounds.Ensure(record)
    return record
end

-- 1. Campfire protection: extinguishes campfire-only ignition, disables spread, nudges off campfire.
do
    local safeSq = makeSquare(10, 10, 0, {})
    local campSq = makeSquare(11, 10, 0, { campfire = true, burning = true })
    local cell = makeGrid({ ["10,10,0"] = safeSq, ["11,10,0"] = campSq })
    local record = makeRecord("npc_camp_safe")
    local zombie = makeZombie(cell, safeSq, record)

    -- Establish prior safe square (not on fire).
    PNC.LiveBodyControl.ProtectManagedCampfire(zombie)
    T.equal(zombie._fireSpread, 0, "fire spread probability was not zeroed")
    T.equal(zombie._fireKillRate, 0, "raw zombie fire kill rate was not zeroed")

    -- Step onto lit campfire and simulate vanilla IsoZombie instant ignition.
    zombie:setCurrent(campSq)
    zombie:setX(11.5)
    zombie:setOnFire(true)

    local protected = PNC.LiveBodyControl.ProtectManagedCampfire(zombie)
    T.truthy(protected, "ProtectManagedCampfire did not protect NPC on lit campfire")
    T.falsy(zombie:isOnFire(), "campfire ignition was not extinguished")
    T.equal(zombie:getSquare(), safeSq, "NPC was not relocated off lit campfire tile")

    -- Even if Health.UpdateFireDamage runs while on a campfire tile before step-off, it deals zero damage.
    zombie:setCurrent(campSq)
    zombie:setOnFire(true)
    PNC.Health.UpdateFireDamage(record, zombie, nowMs)
    T.falsy(zombie:isOnFire(), "UpdateFireDamage did not extinguish campfire-only ignition")
    T.equal(record.health.current, 100, "campfire ignition should not damage NPC")
    T.equal(record.health.body.openWoundCount, 0, "campfire ignition should not add burn wounds")
end

-- 2. Non-campfire fire damage adapter: applies burn wounds across body parts and can kill NPC.
do
    local fireSq = makeSquare(20, 20, 0, { burning = true })
    local safeSq = makeSquare(21, 20, 0, {})
    local cell = makeGrid({ ["20,20,0"] = fireSq, ["21,20,0"] = safeSq })
    local record = makeRecord("npc_wildfire")
    local zombie = makeZombie(cell, fireSq, record)

    zombie:setOnFire(true)
    nowMs = 20000
    T.truthy(PNC.Health.UpdateFireDamage(record, zombie, nowMs), "initial fire tick did not run")
    T.truthy(record.health.current < 100, "initial fire ignition did not reduce health")

    local burnCount = 0
    for _, wound in pairs(record.health.body.wounds) do
        T.equal(wound.type, "burn", "fire damage did not apply burn wound type")
        T.truthy(wound.burned, "burn wound did not set burned flag")
        burnCount = burnCount + 1
    end
    T.equal(burnCount, 1, "initial ignition should apply 1 burn wound")

    -- Advance time so fire spreads burns across additional body parts.
    nowMs = nowMs + 3000
    PNC.Health.UpdateFireDamage(record, zombie, nowMs)
    local secondBurnCount = 0
    for _, wound in pairs(record.health.body.wounds) do
        if wound.type == "burn" and wound.burned == true then
            secondBurnCount = secondBurnCount + 1
        end
    end
    T.truthy(secondBurnCount >= 2, "continued burning did not spread burn wounds across body parts")

    -- Keep burning on hazard tile until fire incapacitates and kills the NPC.
    local ticks = 0
    while record.alive ~= false and ticks < 40 do
        nowMs = nowMs + 1000
        PNC.Health.UpdateFireDamage(record, zombie, nowMs)
        ticks = ticks + 1
    end
    T.equal(record.alive, false, "continuous fire did not kill NPC")
    T.equal(record.health.state, "dead", "fire-killed NPC health state was not dead")
    T.falsy(zombie:isOnFire(), "fire-killed NPC body was not extinguished")
end

-- 3. Auto-extinguish off hazard fire tile.
do
    local safeSq = makeSquare(30, 30, 0, {})
    local cell = makeGrid({ ["30,30,0"] = safeSq })
    local record = makeRecord("npc_extinguish")
    local zombie = makeZombie(cell, safeSq, record)
    zombie:setOnFire(true)
    zombie:setRunning(true)

    nowMs = 50000
    PNC.Health.UpdateFireDamage(record, zombie, nowMs)
    T.truthy(zombie:isOnFire(), "NPC should still be on fire right after ignition")

    -- Force a low random roll so extinguish succeeds off the hazard square.
    randRoll = 0
    nowMs = nowMs + 1000
    PNC.Health.UpdateFireDamage(record, zombie, nowMs)
    T.falsy(zombie:isOnFire(), "NPC off hazard tile did not auto-extinguish")
    T.equal(record.runtime.fireState, nil, "fireState was not cleared after extinguish")
end

-- 4. Wound codec preserves burned flag.
do
    local sanitized = WoundCodec.sanitizeWound("Torso_Upper", {
        type = "burn",
        severity = 12,
        damage = 12,
        burned = true,
    })
    T.truthy(sanitized.burned, "WoundCodec.sanitizeWound dropped burned flag")
    local compacted = WoundCodec.compactWound(sanitized)
    T.truthy(compacted.burned, "WoundCodec.compactWound dropped burned flag")
end

-- 5. FireSafety behavior: flees active fire, interrupts bandaging, avoids walking into fire, and self-extinguishes.
do
    local moveCalls = {}
    local haltCalls = {}
    PNC.BehaviorCommon = {
        MoveRecord = function(rec, z, x, y, zv, mode, stopDist, reason)
            moveCalls[#moveCalls + 1] = { x = x, y = y, z = zv, mode = mode, reason = reason }
            rec.runtime.moveIntent = { x = x, y = y, z = zv, mode = mode, reason = reason }
        end,
        HaltMovement = function(rec, z, reason)
            haltCalls[#haltCalls + 1] = reason
        end,
        ClearCombatTarget = function() end,
    }
    PNC.Animation = {
        Apply = function() end,
        FinishBump = function() end,
    }
    local FireSafety = T.load("ProjectHoomans", "shared", "PNC/Core/Behaviors/PNC_Behavior_FireSafety.lua")

    local grid = {}
    for x = 40, 46 do
        for y = 40, 46 do
            local isFire = (x == 42 and y == 42)
            grid[string.format("%d,%d,0", x, y)] = makeSquare(x, y, 0, { burning = isFire })
        end
    end
    local cell = makeGrid(grid)
    local fireSq = grid["42,42,0"]
    local safeSq = grid["45,45,0"]
    local approachSq = grid["41,42,0"]

    local record = makeRecord("npc_fire_safety")
    record.runtime.selfTreatment = { phase = "bandaging", partId = "Torso_Upper" }
    local zombie = makeZombie(cell, fireSq, record)
    zombie:setOnFire(true)

    -- Standing in fire while bandaging: interrupts bandaging and sprints away.
    nowMs = 60000
    T.truthy(FireSafety.Tick(record, zombie, nowMs), "FireSafety did not take ownership while in fire")
    T.equal(record.activeBehavior, "FireSafety:flee", "NPC did not enter FireSafety:flee")
    T.equal(record.runtime.selfTreatment.phase, "idle", "bandaging was not interrupted when in fire")
    T.equal(moveCalls[#moveCalls].mode, "run", "NPC did not sprint away from fire")
    T.equal(moveCalls[#moveCalls].reason, "flee_fire", "flee move reason mismatch")

    -- Reached safe tile while still on fire: actively sprints around on safe ground to extinguish.
    zombie:setCurrent(safeSq)
    zombie:setX(45.5)
    zombie:setY(45.5)
    nowMs = 61000
    T.truthy(FireSafety.Tick(record, zombie, nowMs), "FireSafety did not enter extinguish phase on safe tile")
    T.equal(record.activeBehavior, "FireSafety:extinguish", "NPC did not enter FireSafety:extinguish")
    T.equal(moveCalls[#moveCalls].mode, "run", "burning NPC did not actively sprint while extinguishing")
    T.equal(moveCalls[#moveCalls].reason, "extinguish_run", "extinguish sprint reason mismatch")
    T.truthy(zombie:isOnFire(), "NPC should still be extinguishing before timer finishes")

    nowMs = 61000 + (PNC.Const.FIRE_SELF_EXTINGUISH_MS or 2200)
    T.falsy(FireSafety.Tick(record, zombie, nowMs), "FireSafety should release ownership once extinguished")
    T.falsy(zombie:isOnFire(), "NPC did not extinguish self after FIRE_SELF_EXTINGUISH_MS")

    -- Fence barrier test: TraversalQuery.CanStep blocks crossing x=41 <-> x=42,
    -- so fleeing from (42,42) must never pick a tile with x <= 41.
    PNC.TraversalQuery = {
        CanStep = function(fx, fy, fz, tx, ty, tz)
            if (fx == 42 and tx == 41) or (fx == 41 and tx == 42) then
                return false, "fence"
            end
            return true, "clear"
        end,
    }
    local fenceSafe = FireSafety.FindSafeTileAwayFromFire(zombie, fireSq)
    T.truthy(fenceSafe ~= nil, "fence-free BFS failed to find a reachable safe tile")
    T.truthy(fenceSafe:getX() >= 42, "fence-free BFS picked a tile across the fence")
    PNC.TraversalQuery = nil

    -- Walking straight toward a burning tile while not on fire: redirects away.
    zombie:setCurrent(approachSq)
    zombie:setX(41.5)
    zombie:setY(42.5)
    record.runtime.moveIntent = { x = 42.5, y = 42.5, z = 0, mode = "walk", reason = "follow" }
    local prevMoves = #moveCalls
    T.truthy(FireSafety.Tick(record, zombie, nowMs + 500), "FireSafety did not intercept move straight into fire")
    T.equal(record.activeBehavior, "FireSafety:flee", "NPC walking into fire did not redirect")
    T.truthy(#moveCalls > prevMoves and moveCalls[#moveCalls].reason == "flee_fire", "redirect did not issue flee_fire")
end

T.finish("pnc_campfire_and_fire_damage_smoke")
