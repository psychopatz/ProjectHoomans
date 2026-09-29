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

-- 6. Missing surface must be safe.
T.falsy(LiveBodyControl.ClearHeavyHeldItems(nil), "nil body was not safe")
T.falsy(LiveBodyControl.ClearHeavyHeldItems({}), "empty body was not safe")
T.falsy(LiveBodyControl.ClearHeavyHeldItems(makeZombie(nil)),
    "empty hands reported a change")

return T.finish("pnc_live_body_heavy_held_items_smoke")
