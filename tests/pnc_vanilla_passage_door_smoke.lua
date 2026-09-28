local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/Pathing/")

-- The engine reports the door the managed body is pressed against through the
-- feeler tile. The safety guard used to cancel vanilla movement and then rely
-- on directional passage probing to open the same door; when the probe missed
-- the geometry the body re-requested the blocked path forever (NPCs stalling at
-- closed doors). These cases pin the guard-level behaviour: a closed door the
-- body can open is opened and movement continues, a door it cannot open still
-- cancels movement, and an open door is not treated as a blockage.
local opened = false
local synced = 0
local doorLocked = false
local doorBarricaded = false

local doorSquare = {
    getX = function() return 10 end,
    getY = function() return 20 end,
    getZ = function() return 0 end,
    InvalidateSpecialObjectPaths = function() end,
    RecalcProperties = function() end,
}

local door = {
    __class = "IsoDoor",
    IsOpen = function() return opened end,
    isOpen = function() return opened end,
    isObstructed = function() return false end,
    isLocked = function() return doorLocked end,
    isLockedByKey = function() return doorLocked end,
    isBarricaded = function() return doorBarricaded end,
    -- Engine predicate (IsoDoor.couldBeOpen): the Lua layer must defer to it
    -- instead of re-deriving lock/barricade rules.
    couldBeOpen = function() return not (doorLocked or doorBarricaded) end,
    -- Engine character toggle (IsoDoor.ToggleDoor).
    ToggleDoor = function()
        if doorLocked or doorBarricaded then return end
        opened = not opened
    end,
    getSquare = function() return doorSquare end,
    DirtySlice = function() end,
    ToggleDoorSilent = function() opened = not opened end,
    syncIsoObject = function() synced = synced + 1 end,
    getProperties = function()
        return {
            has = function() return false end,
            get = function() return nil end,
        }
    end,
}

instanceof = function(object, className)
    return object ~= nil and object.__class == className
end

local warnings = {}
PNC = {
    Core = {
        Now = function() return 5000 end,
        LogWarn = function(message) warnings[#warnings + 1] = message end,
    },
    PathService = {
        Internal = {
            Core = {
                Now = function() return 5000 end,
                Distance = function(x1, y1, x2, y2)
                    local dx = x2 - x1
                    local dy = y2 - y1
                    return math.sqrt(dx * dx + dy * dy)
                end,
            },
            SPECIAL_ACTION_COOLDOWN_MS = 500,
            roundHalf = function(value)
                if value > 0.25 then return 1 end
                if value < -0.25 then return -1 end
                return 0
            end,
            describeSquare = function(square)
                return tostring(square:getX()) .. "," .. tostring(square:getY())
            end,
            describePoint = function(x, y, z)
                return tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)
            end,
            logMoveDebug = function() end,
            logMoveWarning = function() end,
        },
    },
}

T.load(ROOT .. "PNC_PathService/PNC_PathService_Interactions.lua")
T.load(ROOT .. "PNC_LiveBodyControl/PNC_LiveBodyControl_State.lua")

local LiveBodyControl = PNC.LiveBodyControl
local body = {
    getActionStateName = function() return "WalkToward" end,
    getX = function() return 10.5 end,
    getY = function() return 19.5 end,
    getZ = function() return 0 end,
    setPath2 = function() end,
    getForwardDirection = function()
        return { getX = function() return 0 end, getY = function() return 1 end }
    end,
    playSound = function() end,
}
LiveBodyControl.GetVanillaPassageAhead = function() return door, "door" end

local blocked, kind = LiveBodyControl.BlockVanillaPassage(body, nil, 5000)
T.equal(opened, true, "closed door ahead is opened by the guard")
T.equal(blocked, false, "guard keeps vanilla movement once the door is open")
T.equal(kind, "door", "guard reports the blocked passage kind")
T.equal(synced > 0, true, "opened door is synchronized to other players")

opened = true
local warningCount = #warnings
blocked = LiveBodyControl.BlockVanillaPassage(body, nil, 6000)
T.equal(blocked, false, "open door is not treated as a blockage")
T.equal(#warnings, warningCount, "open door does not raise a guard warning")

opened = false
doorLocked = true
blocked, kind = LiveBodyControl.BlockVanillaPassage(body, nil, 20000)
T.equal(opened, false, "locked door is not opened for an NPC from outside")
T.equal(blocked, true, "locked door still cancels vanilla movement")
T.equal(kind, "door", "locked door keeps the door kind")
local guardWarning
for index = 1, #warnings do
    if string.find(warnings[index], "vanilla_passage_guard", 1, true) then
        guardWarning = warnings[index]
    end
end
T.equal(guardWarning ~= nil, true, "locked door reports the guard decision")
T.equal(string.find(guardWarning, "kind=door", 1, true) ~= nil, true,
    "guard warning names the door kind")

-- The engine allows a locked door to be opened by the character on its inside
-- side, which permanently clears the lock: an NPC inside a house must not need
-- the player to open the door first.
doorLocked = false
opened = false
PNC.PathService.Internal.Core.Now = function() return 30000 end
blocked = LiveBodyControl.BlockVanillaPassage(body, nil, 30000)
T.equal(opened, true, "NPC inside opens an unlocked door without the player")
T.equal(blocked, false, "door opened from inside keeps vanilla movement")

-- A barricaded door must stay shut as well.
doorBarricaded = true
opened = false
blocked = LiveBodyControl.BlockVanillaPassage(body, nil, 40000)
T.equal(opened, false, "barricaded door is not opened for an NPC")
T.equal(blocked, true, "barricaded door still cancels vanilla movement")

doorBarricaded = false
T.finish("pnc_vanilla_passage_door_smoke")
