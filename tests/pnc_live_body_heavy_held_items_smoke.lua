--[[
    Heavy hand items on a managed shell.

    Vanilla's window climb calls dropHeavyItems(), whose multiplayer branch
    sends PlayerDropHeldItems for the climbing character. That packet casts to
    IsoPlayer, so a managed IsoZombie that climbs an open window throws a
    ClassCastException, spams the log and desyncs the shell's hand slot. The
    guard must therefore stow heavy hand items before vanilla reaches
    IsoZombie.tryThump(), while leaving weapons in hand and never losing an item
    that cannot be stored.
]]

local T = require "tests/support/test"
T.addPackagePaths()

local SHARED = T.path("ProjectHoomans", "shared", "")
local FILE = SHARED
    .. "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_State.lua"

PNC = {
    Core = {
        Now = function() return 1000 end,
        LogInfo = function() end,
        LogWarn = function() end,
        LogDebug = function() end,
        IsAuthority = function() return true end,
    },
    Const = {},
}
ItemTag = { HEAVY_ITEM = "HEAVY_ITEM" }

T.load(FILE)

local LiveBodyControl = PNC.LiveBodyControl

local function makeItem(spec)
    spec = spec or {}
    return {
        IsInventoryContainer = function()
            return spec.container == true
        end,
        hasTag = function(_, tag)
            return spec.heavyTag == true and tag == ItemTag.HEAVY_ITEM
        end,
        getType = function()
            return spec.itemType or "Base.Axe"
        end,
    }
end

local function makeZombie(primary, secondary)
    local zombie = { primary = primary, secondary = secondary }
    zombie.getPrimaryHandItem = function(self) return self.primary end
    zombie.getSecondaryHandItem = function(self) return self.secondary end
    zombie.setPrimaryHandItem = function(self, value) self.primary = value end
    zombie.setSecondaryHandItem = function(self, value) self.secondary = value end
    return zombie
end

-- 1. A carried container is the common heavy case (bags restored on
-- rematerialization): it must move to the inventory and leave the hand empty.
local container = makeItem({ container = true })
local zombie = makeZombie(container)
T.truthy(LiveBodyControl.ClearHeavyHeldItems(zombie),
    "heavy container was not cleared")
T.falsy(zombie.primary, "heavy container stayed in the hand")

-- 2. Tagged heavy items are sheltered the same way.
local tagged = makeItem({ heavyTag = true })
zombie = makeZombie(nil, tagged)
T.truthy(LiveBodyControl.ClearHeavyHeldItems(zombie),
    "tagged heavy item was not cleared")
T.falsy(zombie.secondary, "tagged heavy item stayed in the hand")

-- 3. Unwieldy engine types are sheltered by type name.
zombie = makeZombie(makeItem({ itemType = "Generator" }))
T.truthy(LiveBodyControl.ClearHeavyHeldItems(zombie),
    "generator was not cleared")

-- 4. A weapon is not heavy: NPC visuals and animations must not change.
local weapon = makeItem({ itemType = "Base.Axe" })
zombie = makeZombie(weapon, nil)
T.falsy(LiveBodyControl.ClearHeavyHeldItems(zombie),
    "ordinary weapon was treated as heavy")
T.equal(zombie.primary, weapon, "weapon was removed from the hand")

-- 5. Only the client-side hand slot changes: the item is never moved, so it
-- cannot be lost or duplicated by this guard.
zombie = makeZombie(container, container)
T.truthy(LiveBodyControl.ClearHeavyHeldItems(zombie),
    "both hands were not cleared")
T.falsy(zombie.primary, "primary heavy item stayed in hand")
T.falsy(zombie.secondary, "secondary heavy item stayed in hand")

-- 6. Native movement detection mirrors the movement test vanilla uses before
-- it can reach tryThump(), so a climbable passage is blocked for a walking
-- shell even when its action state is idle.
local function movingZombie(nextX, nextY, x, y)
    return {
        getNextX = function() return nextX end,
        getNextY = function() return nextY end,
        getX = function() return x end,
        getY = function() return y end,
    }
end
T.truthy(LiveBodyControl.IsNativeMoving(movingZombie(1.2, 2, 1, 2)),
    "horizontal movement not detected")
T.truthy(LiveBodyControl.IsNativeMoving(movingZombie(1, 2.3, 1, 2)),
    "vertical movement not detected")
T.falsy(LiveBodyControl.IsNativeMoving(movingZombie(1, 2, 1, 2)),
    "idle body reported as moving")
T.falsy(LiveBodyControl.IsNativeMoving({}), "missing movement API was not safe")
T.falsy(LiveBodyControl.IsNativeMoving(nil), "nil body was not safe")

-- 7. Climb-ahead guard: it must run for shells the managed-safety gate
-- rejects (duplicates, lease mismatches) and must stay out of the server's
-- authoritative hand slots, because the failing packet is client-only.
local originalProbe = LiveBodyControl.GetVanillaPassageAhead
LiveBodyControl.GetVanillaPassageAhead = function()
    return { id = "window" }, "window"
end
local heavyZombie = makeZombie(makeItem({ container = true }))
isClient = function() return false end
T.falsy(LiveBodyControl.ClearHeavyItemsForClimbAhead(heavyZombie),
    "server-side climb clear ran")
T.truthy(heavyZombie.primary, "server-side climb clear touched the hand")
isClient = function() return true end
T.truthy(LiveBodyControl.ClearHeavyItemsForClimbAhead(heavyZombie),
    "client climb-ahead clear did not run")
T.falsy(heavyZombie.primary, "client climb-ahead clear left the item")

-- 8. Only climb-capable passages count: a door ahead is not a climb hazard.
LiveBodyControl.GetVanillaPassageAhead = function()
    return { id = "door" }, "door"
end
local doorZombie = makeZombie(makeItem({ container = true }))
T.falsy(LiveBodyControl.ClearHeavyItemsForClimbAhead(doorZombie),
    "door ahead triggered a climb clear")
T.truthy(doorZombie.primary, "door ahead cleared the hand")

-- 9. Window frames and thumpables are climb paths too.
LiveBodyControl.GetVanillaPassageAhead = function()
    return { id = "frame" }, "window_frame"
end
local frameZombie = makeZombie(makeItem({ heavyTag = true }))
T.truthy(LiveBodyControl.ClearHeavyItemsForClimbAhead(frameZombie),
    "window frame climb clear did not run")
LiveBodyControl.GetVanillaPassageAhead = originalProbe

-- 10. Hoppable low doors and fences are vaulted through the player-only
-- ClimbOverFenceState, which dereferences BodyDamage an IsoZombie does not
-- have. They must be recognised as a hazard and the vanilla lane stopped.
local function door(hoppable, tall)
    return {
        isHoppable = function() return hoppable == true end,
        isTallHoppable = function() return tall == true end,
    }
end
T.truthy(LiveBodyControl.IsHoppableLowDoor(door(true, false)),
    "hoppable low door not detected")
T.falsy(LiveBodyControl.IsHoppableLowDoor(door(true, true)),
    "tall hoppable door treated as vaultable")
T.falsy(LiveBodyControl.IsHoppableLowDoor(door(false, false)),
    "non-hoppable door treated as vaultable")
T.falsy(LiveBodyControl.IsHoppableLowDoor(nil), "nil door was not safe")
T.falsy(LiveBodyControl.IsHoppableLowDoor({}), "door without API was not safe")

-- 11. A moving shell facing a hoppable low door has its native lane stopped,
-- which is what keeps vanilla out of that state. The crossing then belongs to
-- the PNC action runtime.
local behaviorsCanceled = 0
local pathsCleared = 0
local vaultZombie = {
    getNextX = function() return 2 end,
    getNextY = function() return 1 end,
    getX = function() return 1 end,
    getY = function() return 1 end,
    getModData = function() return {} end,
    getPathFindBehavior2 = function()
        return {
            cancel = function() behaviorsCanceled = behaviorsCanceled + 1 end,
            reset = function() end,
        }
    end,
    setPath2 = function() pathsCleared = pathsCleared + 1 end,
}
LiveBodyControl.GetVanillaPassageAhead = function()
    return door(true, false), "door"
end
isClient = function() return false end
T.truthy(LiveBodyControl.BlockVanillaPassage(vaultZombie, nil, 1000),
    "hoppable low door did not stop the vanilla lane on the authority side")
T.equal(pathsCleared, 1, "native path was not cleared at the vault hazard")
T.equal(behaviorsCanceled, 1,
    "native pathfind behavior was not cancelled at the vault hazard")

-- 12. An idle body is not touched: only a moving one can reach tryThump().
vaultZombie.getNextX = function() return 1 end
T.falsy(LiveBodyControl.BlockVanillaPassage(vaultZombie, nil, 2000),
    "idle body was stopped at a vault hazard")
LiveBodyControl.GetVanillaPassageAhead = originalProbe

-- 13. Missing surface must be safe.
T.falsy(LiveBodyControl.ClearHeavyHeldItems(nil), "nil body was not safe")
T.falsy(LiveBodyControl.ClearHeavyHeldItems({}), "empty body was not safe")
T.falsy(LiveBodyControl.ClearHeavyHeldItems(makeZombie(nil)),
    "empty hands reported a change")

return T.finish("pnc_live_body_heavy_held_items_smoke")
