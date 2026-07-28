local FILE = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"
    .. "Pathing/PNC_TraversalProfiles.lua"

PNC = {}
dofile(FILE)

local window = PNC.TraversalProfiles.Get("window_climb")
assert(window.anim == "PNC_ClimbWindow")
assert(window.travelDurationMs == 700)

assert(PNC.TraversalProfiles.Register("window_climb", "fast", {
    anim = "PNC_ClimbWindowFast",
    travelDurationMs = 420,
    finishHoldMs = 180,
}))
local fast = PNC.TraversalProfiles.Get("window_climb", "fast")
assert(fast.anim == "PNC_ClimbWindowFast")
assert(fast.travelDurationMs == 420)
assert(PNC.TraversalProfiles.RegisterSelector(
    "window_climb",
    function(context)
        return context.fast and "fast" or "default"
    end
))
local selected, variant = PNC.TraversalProfiles.Resolve(
    "window_climb",
    { fast = true }
)
assert(variant == "fast" and selected.anim == "PNC_ClimbWindowFast")

print("pnc_traversal_profiles_smoke: ok")
