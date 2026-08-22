--[[
    PNC Traversal Profiles

    Data-only animation/timing registry for fake-locomotion traversal actions.
    Adding an animation does not require editing the movement or routing state
    machines: register a profile before the path service begins pumping.
]]

PNC = PNC or {}
PNC.TraversalProfiles = PNC.TraversalProfiles or {}

local Profiles = PNC.TraversalProfiles

Profiles.Registry = Profiles.Registry or {}
Profiles.Selectors = Profiles.Selectors or {}
-- Clear the retired reflective probe when this file is hot-reloaded. The
-- registry table is intentionally reused across reloads.
Profiles.GetActiveAnimationTiming = nil

local function key(kind, variant)
    return tostring(kind or "") .. ":" .. tostring(variant or "default")
end

function Profiles.Register(kind, variant, profile)
    if type(variant) == "table" and profile == nil then
        profile = variant
        variant = "default"
    end
    if tostring(kind or "") == "" or type(profile) ~= "table" then
        return false
    end
    Profiles.Registry[key(kind, variant)] = profile
    return true
end

function Profiles.Get(kind, variant)
    return Profiles.Registry[key(kind, variant)]
        or Profiles.Registry[key(kind, "default")]
end

function Profiles.RegisterSelector(kind, selector)
    if tostring(kind or "") == "" or type(selector) ~= "function" then
        return false
    end
    Profiles.Selectors[tostring(kind)] = selector
    return true
end

function Profiles.Resolve(kind, context, fallbackVariant)
    local selector = Profiles.Selectors[tostring(kind or "")]
    local variant = fallbackVariant or "default"
    local selected
    if selector then
        selected = selector(context or {})
        if selected ~= nil then
            variant = tostring(selected)
        end
    end
    return Profiles.Get(kind, variant), variant
end

Profiles.Register("window_climb", {
    anim = "PNC_ClimbWindow",
    travelDurationMs = 700,
    finishHoldMs = 320,
})
Profiles.Register("fence_climb", "low", {
    anim = "PNC_ClimbFence",
    startAnim = "PNC_LegacyClimbFenceStart",
    endAnim = "PNC_LegacyClimbFenceEnd",
    -- Profile timing is deliberately authoritative. AnimationPlayer is
    -- engine userdata that is not safely reflectable from Kahlua.
    upDurationMs = 700,
    crossingDurationMs = 560,
    travelDurationMs = 600,
    finishHoldMs = 320,
})
Profiles.Register("fence_climb", "tall", {
    anim = "PNC_ClimbFenceTall",
    travelDurationMs = 900,
    finishHoldMs = 420,
})

return Profiles
