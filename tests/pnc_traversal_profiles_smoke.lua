local T = require "tests/support/test"

local FILE = T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Pathing/PNC_TraversalProfiles.lua"

PNC = {}
T.load(FILE)

local window = PNC.TraversalProfiles.Get("window_climb")
T.truthy(window.anim == "PNC_ClimbWindow")
T.truthy(window.travelDurationMs == 700)

T.truthy(PNC.TraversalProfiles.Register("window_climb", "fast", {
    anim = "PNC_ClimbWindowFast",
    travelDurationMs = 420,
    finishHoldMs = 180,
}))
local fast = PNC.TraversalProfiles.Get("window_climb", "fast")
T.truthy(fast.anim == "PNC_ClimbWindowFast")
T.truthy(fast.travelDurationMs == 420)
T.truthy(PNC.TraversalProfiles.RegisterSelector(
    "window_climb",
    function(context)
        return context.fast and "fast" or "default"
    end
))
local selected, variant = PNC.TraversalProfiles.Resolve(
    "window_climb",
    { fast = true }
)
T.truthy(variant == "fast" and selected.anim == "PNC_ClimbWindowFast")
T.finish("pnc_traversal_profiles_smoke")

T.finish("pnc_traversal_profiles_smoke")
