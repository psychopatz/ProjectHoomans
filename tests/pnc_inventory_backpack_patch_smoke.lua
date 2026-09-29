--[[
    Vanilla inventory backpack refresh guard.

    ISInventoryPage:refreshBackpacks() iterates vehicle parts without checking
    the part it fetched, so a vehicle with a hole in its part list (destroyed
    part, or a vehicle caught mid-reload) throws out of the Kahlua invoker and
    dumps a stack trace every frame. The guard must swallow that, report it once
    and throttle retries without breaking the healthy path.
]]

local T = require "tests/support/test"
T.addPackagePaths()

local FILE = T.path("ProjectHoomans", "client",
    "PNC/Patches/PNC_InventoryBackpackPatch.lua")

local warnings = 0
local calls = 0
local shouldFail = true

-- Pre-define the vanilla surface so the patch's guarded require is skipped.
ISInventoryPage = {
    refreshBackpacks = function(self)
        calls = calls + 1
        if shouldFail then
            error("java.lang.NullPointerException: callFrame is null")
        end
        self.refreshed = (self.refreshed or 0) + 1
    end,
}
getTimestampMs = function() return 5000 end

PNC = {
    Core = {
        LogWarn = function() warnings = warnings + 1 end,
    },
}

T.load(FILE)

T.truthy(PNC._InventoryBackpackPatchApplied, "patch did not mark itself applied")
T.equal(type(ISInventoryPage.refreshBackpacks), "function",
    "patched refresh is not a function")

local page = { backpacks = {} }

-- 1. A failing vanilla refresh must not propagate.
local ok = pcall(ISInventoryPage.refreshBackpacks, page)
T.truthy(ok, "vanilla failure propagated out of the guard")
T.equal(calls, 1, "vanilla refresh was not attempted")
T.equal(warnings, 1, "failure was not reported exactly once")

-- 2. Repeated failures are throttled instead of throwing every frame.
ISInventoryPage.refreshBackpacks(page)
ISInventoryPage.refreshBackpacks(page)
T.equal(calls, 1, "throttle did not suppress repeated attempts")

-- 3. Once the vehicle is healthy again the real refresh runs and the guard
-- stops reporting.
shouldFail = false
getTimestampMs = function() return 5000 + 2000 end
ISInventoryPage.refreshBackpacks(page)
T.equal(calls, 2, "healthy refresh was not attempted after the cooldown")
T.equal(page.refreshed, 1, "healthy refresh did not run the vanilla body")
T.equal(warnings, 1, "healthy refresh produced a warning")

return T.finish("pnc_inventory_backpack_patch_smoke")
