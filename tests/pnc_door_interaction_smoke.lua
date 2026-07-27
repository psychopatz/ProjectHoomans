local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/Pathing/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

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
local door = {
    __class = "IsoDoor",
    IsOpen = function() return opened end,
    getSquare = function() return fromSquare end,
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

fromSquare = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getDoorTo = function() return nil end,
    getObjects = function() return newList({ door }) end,
    InvalidateSpecialObjectPaths = function() end,
    RecalcProperties = function() end,
}
toSquare = {
    getX = function() return 1 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
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

dofile(ROOT .. "PNC_TraversalQuery.lua")
assertEqual(PNC.TraversalQuery.GetPassageBetween(fromSquare, toSquare), door, "reverse-owned door lookup")

dofile(ROOT .. "PNC_PathService/PNC_PathService_Interactions.lua")

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
assertEqual(interacted, true, "blocked passage opens")
assertEqual(interaction, "door_open", "blocked passage interaction")
assertEqual(opened, true, "blocked door state")
assertEqual(synced, 1, "blocked door synchronized")

opened = false
lane = {}
interacted, interaction = PNC.PathService.Internal.tryDoorOrWindowInteraction(
    zombie, { id = "proactive_door_test" }, lane, 2.5, 0.5, 0
)
assertEqual(interacted, true, "goal-directed passage probe opens nearby door")
assertEqual(interaction, "door_open", "proactive door interaction")
assertEqual(opened, true, "proactive door state")

opened = false
zombie.isCollidedWithDoor = function() return true end
lane = {}
interacted, interaction = PNC.PathService.Internal.tryDoorOrWindowInteraction(
    zombie, { id = "collision_door_test" }, lane, 2.5, 0.5, 0
)
assertEqual(interacted, true, "collision opens current-square door")
assertEqual(interaction, "door_open", "collision interaction")
assertEqual(opened, true, "collision door state")

opened = false
door.getLockedByKey = function() return 7 end
assertEqual(PNC.PathService.Internal.openDoorForNPC(zombie, door), false, "key-locked door stays closed")
assertEqual(opened, false, "key-locked door state")

door.getLockedByKey = nil
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
lane = {}
interacted, interaction = PNC.PathService.Internal.tryDoorOrWindowInteraction(
    zombie, { id = "proactive_window_test" }, lane, 2.5, 0.5, 0
)
assertEqual(interacted, true, "goal-directed passage probe opens nearby window")
assertEqual(interaction, "window_open", "proactive window interaction")
assertEqual(windowOpened, true, "proactive window state")

print("pnc_door_interaction_smoke: ok")
