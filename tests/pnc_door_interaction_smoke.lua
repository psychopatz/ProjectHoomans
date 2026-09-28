local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/Pathing/")

local opened = false
local synced = 0

local function newList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local fromSquare
local toSquare
local doorLocked = false
local doorBlockedByEngine = false
local doorToggleRefuses = false
local doorToggleCalls = 0
local silentToggleCalls = 0
local zombieOutside = false
local doorRoom = { __class = "IsoRoom" }
local door = {
    __class = "IsoDoor",
    IsOpen = function() return opened end,
    isOpen = function() return opened end,
    isLocked = function() return doorLocked end,
    isLockedByKey = function() return doorLocked end,
    isBarricaded = function() return doorBlockedByEngine end,
    getKeyId = function() return -1 end,
    setLocked = function(_, value) doorLocked = value end,
    setLockedByKey = function(_, value) doorLocked = value end,
    getOppositeSquare = function() return toSquare end,
    -- Engine predicate (IsoDoor.couldBeOpen): barricades and obstruction.
    couldBeOpen = function() return not doorBlockedByEngine end,
    -- The character-aware engine toggle is unusable for zombie bodies (it
    -- dereferences a null IsoPlayer), so the adapter must never call it.
    ToggleDoor = function()
        doorToggleCalls = doorToggleCalls + 1
        error("IsoDoor.ToggleDoor must not be used for an NPC body")
    end,
    getSquare = function() return fromSquare end,
    DirtySlice = function() end,
    -- Engine silent toggle: character independent, refuses a barricaded door.
    ToggleDoorSilent = function()
        silentToggleCalls = silentToggleCalls + 1
        if doorToggleRefuses then return end
        opened = not opened
    end,
    syncIsoObject = function() synced = synced + 1 end,
    getProperties = function()
        return {
            has = function() return false end,
            get = function() return nil end,
        }
    end,
}

fromSquare = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getRoom = function() return doorRoom end,
    getDoorTo = function() return nil end,
    getObjects = function() return newList({ door }) end,
    InvalidateSpecialObjectPaths = function() end,
    RecalcProperties = function() end,
}
toSquare = {
    getX = function() return 1 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getRoom = function() return nil end,
    getDoorTo = function(_, other)
        if other == fromSquare then return door end
        return nil
    end,
    getObjects = function() return newList({}) end,
    InvalidateSpecialObjectPaths = function() end,
    RecalcProperties = function() end,
}

local cell = {
    getGridSquare = function(_, x)
        if x == 0 then return fromSquare end
        if x == 1 then return toSquare end
        return nil
    end,
}

instanceof = function(object, className)
    return object and object.__class == className
end
getCell = function() return cell end

PNC = {
    Core = {
        Now = function() return 1000 end,
        Distance = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return math.sqrt(dx * dx + dy * dy)
        end,
    },
    PathService = {
        Internal = {
            Core = {
                Now = function() return 1000 end,
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
                return tostring(square:getX()) .. "," .. tostring(square:getY()) .. "," .. tostring(square:getZ())
            end,
            describePoint = function(x, y, z)
                return tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)
            end,
            logMoveDebug = function() end,
            logMoveWarning = function() end,
        },
    },
}

T.load(ROOT .. "PNC_TraversalQuery.lua")
T.equal(PNC.TraversalQuery.GetPassageBetween(fromSquare, toSquare), door, "reverse-owned door lookup")

T.load(ROOT .. "PNC_PathService/PNC_PathService_Interactions.lua")

local zombie = {
    getX = function() return 0.75 end,
    getY = function() return 0.5 end,
    getZ = function() return 0 end,
    getForwardDirection = function()
        return { getX = function() return 1 end, getY = function() return 0 end }
    end,
    isFacingObject = function() return true end,
    isCollidedWithDoor = function() return false end,
    playSound = function() end,
    -- Inside-side data used for the lock rule (IsoDoor.canBeOpenFromInside).
    isOutside = function() return zombieOutside end,
    getCurrentSquare = function() return fromSquare end,
    getInventory = function()
        return { haveThisKeyId = function() return nil end }
    end,
}
local lane = {
    blockedStepFromX = 0.75,
    blockedStepFromY = 0.5,
    blockedStepFromZ = 0,
    blockedStepToX = 1.05,
    blockedStepToY = 0.5,
    blockedStepToZ = 0,
}

local interacted, interaction = PNC.PathService.Internal.tryDoorOrWindowInteraction(
    zombie, { id = "door_test" }, lane, 2.5, 0.5, 0
)
T.equal(interacted, true, "blocked passage opens")
T.equal(interaction, "door_open", "blocked passage interaction")
T.equal(opened, true, "blocked door state")
T.equal(synced, 1, "blocked door synchronized")

opened = false
lane = {}
interacted, interaction = PNC.PathService.Internal.tryDoorOrWindowInteraction(
    zombie, { id = "proactive_door_test" }, lane, 2.5, 0.5, 0
)
T.equal(interacted, true, "goal-directed passage probe opens nearby door")
T.equal(interaction, "door_open", "proactive door interaction")
T.equal(opened, true, "proactive door state")

opened = false
zombie.isCollidedWithDoor = function() return true end
lane = {}
interacted, interaction = PNC.PathService.Internal.tryDoorOrWindowInteraction(
    zombie, { id = "collision_door_test" }, lane, 2.5, 0.5, 0
)
T.equal(interacted, true, "collision opens current-square door")
T.equal(interaction, "door_open", "collision interaction")
T.equal(opened, true, "collision door state")

-- The live-body safety guard cancels vanilla movement with no lane object.
-- The interaction resolver must recover the exact door from the same feeler,
-- otherwise a corner-aligned door can be missed by directional probing.
PNC.LiveBodyControl = {
    GetVanillaPassageAhead = function() return door, "door" end,
}
opened = false
zombie.isCollidedWithDoor = function() return false end
lane = {}
interacted, interaction = PNC.PathService.Internal.tryDoorOrWindowInteraction(
    zombie, { id = "feeler_door_test" }, lane, 2.5, 0.5, 0
)
T.equal(interacted, true, "feeler passage opens without blocked-lane metadata")
T.equal(interaction, "door_open", "feeler passage interaction")
T.equal(opened, true, "feeler-resolved door state")
PNC.LiveBodyControl = nil

-- The engine decides whether a character may open a door (IsoDoor.couldBeOpen /
-- IsoDoor.ToggleDoor): barricades, the open-from-inside lock rule, obstruction
-- and keys, plus the lock rule for a key holder or a character on the inside.
opened = false
doorBlockedByEngine = true
silentToggleCalls = 0
T.equal(PNC.PathService.Internal.openDoorForNPC(zombie, door), false,
    "engine-refused door stays closed")
T.equal(opened, false, "engine-refused door state")
T.equal(silentToggleCalls, 0, "engine-refused door is not toggled")
doorBlockedByEngine = false

-- A locked door is refused for a body outside without a key, and the refusal
-- backs off instead of hammering the door every tick.
PNC.PathService.Internal.Core.Now = function() return 10000 end
opened = false
doorLocked = true
zombieOutside = true
silentToggleCalls = 0
T.equal(PNC.PathService.Internal.openDoorForNPC(zombie, door), false,
    "locked door is refused for a body outside")
T.equal(PNC.PathService.Internal.openDoorForNPC(zombie, door), false,
    "locked door keeps failing inside the backoff window")
T.equal(silentToggleCalls, 0, "refused door is not toggled")

-- The same locked door opens for the NPC standing inside, exactly like the
-- player's first open used to, and that open clears the lock for good.
PNC.PathService.Internal.Core.Now = function() return 20000 end
opened = false
zombieOutside = false
T.equal(PNC.PathService.Internal.openDoorForNPC(zombie, door), true,
    "NPC inside opens the locked door without the player")
T.equal(opened, true, "locked door state after the NPC opened it")
T.equal(doorLocked, false, "NPC open clears the lock like a player open")
zombie.isCollidedWithDoor = function() return false end
local windowOpened = false
local window = {
    __class = "IsoWindow",
    getSquare = function() return fromSquare end,
    IsOpen = function() return windowOpened end,
    isSmashed = function() return false end,
    isPermaLocked = function() return false end,
    ToggleWindow = function() windowOpened = true end,
    syncIsoObject = function() synced = synced + 1 end,
    canClimbThrough = function() return windowOpened end,
    getOppositeSquare = function() return toSquare end,
}
fromSquare.getObjects = function() return newList({ window }) end
toSquare.getDoorTo = function() return nil end
toSquare.getWindowTo = function(_, other)
    if other == fromSquare then return window end
    return nil
end
PNC.PathService.Internal.isSquareWalkable = function() return true end
PNC.PathService.Internal.beginTraversalAction = function(
    _,
    _,
    activeLane,
    spec
)
    activeLane.testTraversalSpec = spec
    return true
end
lane = {}
interacted, interaction = PNC.PathService.Internal.tryDoorOrWindowInteraction(
    zombie, { id = "proactive_window_test" }, lane, 2.5, 0.5, 0
)
T.equal(interacted, true, "goal-directed passage probe opens nearby window")
T.equal(interaction, "window_climb", "opened window transfers directly to traversal")
T.equal(windowOpened, true, "proactive window state")
T.equal(lane.testTraversalSpec.kind, "window_climb",
    "opened window did not acquire scripted traversal")

-- IsoWindow:getOppositeSquare() is fixed to the object's storage side, not
-- relative to the actor. Approaching the same window from its opposite side
-- must therefore land on object:getSquare(), never back on the actor's tile.
windowOpened = true
zombie.getX = function() return 1.25 end
zombie.getForwardDirection = function()
    return { getX = function() return -1 end, getY = function() return 0 end }
end
lane = {}
interacted, interaction = PNC.PathService.Internal.tryDoorOrWindowInteraction(
    zombie, { id = "reverse_window_test" }, lane, -1.5, 0.5, 0
)
T.equal(interacted, true, "reverse-side window traversal starts")
T.equal(interaction, "window_climb", "reverse-side window action")
T.equal(lane.testTraversalSpec.toX, 0.5,
    "reverse-side window selected the actor's own square")
zombie.getX = function() return 0.75 end
zombie.getForwardDirection = function()
    return { getX = function() return 1 end, getY = function() return 0 end }
end

local windowSmashed = false
windowOpened = false
window.isPermaLocked = function() return true end
window.isSmashed = function() return windowSmashed end
window.smashWindow = function() windowSmashed = true end
lane = {}
interacted, interaction = PNC.PathService.Internal.tryDoorOrWindowInteraction(
    zombie, { id = "window_break_test" }, lane, 2.5, 0.5, 0
)
T.equal(interacted, true, "locked window begins breach")
T.equal(interaction, "window_smash", "locked window breach mode")
T.equal(lane.testTraversalSpec.anim, "PNC_WindowSmash",
    "window breach animation")
T.equal(lane.testTraversalSpec.obstacle, window,
    "window breach retains obstacle")
T.equal(
    PNC.PathService.Internal.smashWindowForNPC(zombie, window),
    true,
    "window breach applies breakage"
)
T.equal(windowSmashed, true, "window glass was broken")

-- A merely adjacent window must not steal a failed native route by rotating
-- the NPC toward itself. Bandits only acts on the collision-facing object.
windowOpened = true
window.isPermaLocked = function() return false end
window.isSmashed = function() return false end
fromSquare.getWindowTo = function() return nil end
toSquare.getWindowTo = function() return nil end
zombie.isFacingObject = function() return false end
zombie.faceThisObject = function()
    error("unrelated window should not take facing ownership")
end
lane = {}
interacted = PNC.PathService.Internal.tryDoorOrWindowInteraction(
    zombie, { id = "side_window_reject_test" }, lane, 0.75, 2.5, 0
)
T.equal(interacted, false, "non-facing adjacent window was selected")
-- The Lua layer defers to the engine predicate (IsoDoor.couldBeOpen) instead of
-- re-deriving obstruction rules, so a door the predicate allows still opens even
-- when its square reports isObstructed().
opened = false
door.isObstructed = function() return true end
doorBlockedByEngine = false
PNC.PathService.Internal.Core.Now = function() return 40000 end
T.equal(PNC.PathService.Internal.openDoorForNPC(zombie, door), true,
    "door whose square reports isObstructed still opens when the engine allows it")
T.equal(opened, true, "obstructed-square door state")
door.isObstructed = nil

-- Indexing a member the engine does not expose may raise instead of returning
-- nil. The passage compatibility probe must treat that as "method unavailable"
-- rather than breaking door opening.
opened = false
local raisingDoor = setmetatable({}, {
    __index = function(_, key)
        if key == "__class" then return "IsoDoor" end
        if key == "IsOpen" or key == "isOpen" then
            return function() return opened end
        end
        if key == "isLocked" then return function() return false end end
        if key == "getSquare" then return function() return fromSquare end end
        if key == "DirtySlice" or key == "syncIsoObject" then
            return function() end
        end
        if key == "ToggleDoorSilent" then
            return function() opened = not opened end
        end
        if key == "getProperties" then
            return function()
                return {
                    has = function() return false end,
                    get = function() return nil end,
                }
            end
        end
        error("attempt to index unknown member " .. tostring(key))
    end,
})
T.equal(PNC.PathService.Internal.openDoorForNPC(zombie, raisingDoor), true,
    "unexposed member lookup does not break door opening")
T.equal(opened, true, "raising-member door state")

-- Every door goes through the character-independent silent toggle: the
-- character-aware IsoDoor.ToggleDoor raises for a zombie body (null IsoPlayer),
-- so the adapter must never call it, multi-tile door or not.
opened = false
doorToggleCalls = 0
PNC.PathService.Internal.Core.Now = function() return 50000 end
IsoDoor = {
    getDoubleDoorIndex = function() return 0 end,
    getGarageDoorIndex = function() return -1 end,
}
T.equal(PNC.PathService.Internal.openDoorForNPC(zombie, door), true,
    "double door opens for an NPC")
T.equal(opened, true, "double door state")
T.equal(doorToggleCalls, 0, "character toggle is never used for an NPC body")
IsoDoor = nil

-- A raising engine toggle must be contained: the pass continues, the failure is
-- reported once, and the door backs off instead of dumping a stack trace every
-- tick.
opened = false
doorToggleRefuses = false
local raisingToggleDoor = {
    __class = "IsoDoor",
    IsOpen = function() return opened end,
    isOpen = function() return opened end,
    isLocked = function() return false end,
    couldBeOpen = function() return true end,
    getSquare = function() return fromSquare end,
    ToggleDoor = function()
        doorToggleCalls = doorToggleCalls + 1
        error("character toggle must not be used")
    end,
    ToggleDoorSilent = function()
        error("engine door toggle failure")
    end,
}
doorToggleCalls = 0
PNC.PathService.Internal.Core.Now = function() return 60000 end
T.equal(PNC.PathService.Internal.openDoorForNPC(zombie, raisingToggleDoor), false,
    "raising engine toggle reports failure")
T.equal(opened, false, "raising engine toggle leaves the door closed")
T.equal(doorToggleCalls, 0, "raising case still avoids the character toggle")

T.finish("pnc_door_interaction_smoke")
