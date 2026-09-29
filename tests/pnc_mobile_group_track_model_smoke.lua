local T = require "tests/support/test"

local FILE = T.path("ProjectHoomans", "shared",
    "PNC/UI/Mobile/PNC_MobileGroupTrackModel.lua")

PNC = {}
local Model = T.load(FILE)

-- Marks a field as absent, since a pairs() override cannot set nil.
local ABSENT = {}
local function traveling(overrides)
    local group = {
        id = "agroup_track",
        state = "TRAVELING",
        groupStateStartedAt = 100,
        groupStateEndsAt = 110,
        location = { x = 0, y = 0, z = 0 },
        targetLocation = { x = 100, y = 200, z = 0 },
        mobile = { presence = "abstract" },
    }
    for key, value in pairs(overrides or {}) do
        group[key] = value == ABSENT and nil or value
    end
    return group
end

-- Eligibility ---------------------------------------------------------------

T.falsy(Model.ShouldTrack(nil), "nil group must not track")
T.falsy(Model.ShouldTrack({ state = "TRAVELING" }),
    "group without endpoints must not track")
T.falsy(Model.ShouldTrack(traveling({ state = "IDLE" })),
    "non-traveling group must not track")
T.falsy(Model.ShouldTrack(traveling({ mobile = { presence = "live" } })),
    "live groups are authoritative elsewhere and must not be interpolated")
T.falsy(Model.ShouldTrack(traveling({ targetLocation = ABSENT })),
    "missing target must not track")
T.truthy(Model.ShouldTrack(traveling()),
    "abstract traveling group should track")

-- Degenerate / malformed spans ----------------------------------------------

T.falsy(Model.Begin(traveling({ groupStateEndsAt = 100 }), 100),
    "zero-length span must not produce a track")
T.falsy(Model.Begin(traveling({ groupStateEndsAt = 90 }), 100),
    "inverted span must not produce a track")
T.falsy(Model.Begin(traveling({ groupStateStartedAt = ABSENT }), 100),
    "missing start must not produce a track")
T.falsy(Model.Begin(traveling({
    location = { x = "nan", y = 0 },
}), 100), "non-finite origin must not produce a track")

-- Position is clamped and monotonic -----------------------------------------

-- Confirmed for the whole leg, so the marker is free to glide end to end.
local track = Model.Begin(traveling(), 110)
T.truthy(track, "track was not built")
T.near(track.fromX, 0, 1e-9, "track origin x")
T.near(track.toX, 100, 1e-9, "track target x")
T.near(track.receivedAt, 110, 1e-9, "receive stamp should be the build hour")

local atStart = Model.Position(track, 100)
T.near(atStart.x, 0, 1e-9, "marker must begin at the origin")
T.near(atStart.y, 0, 1e-9, "marker must begin at the origin")
T.near(atStart.progress, 0, 1e-9, "progress at start")

local mid = Model.Position(track, 105)
T.near(mid.x, 50, 1e-9, "mid-leg x should be eased midpoint")
T.near(mid.progress, 0.5, 1e-9, "ease must be symmetric at mid-leg")

local atEnd = Model.Position(track, 110)
T.near(atEnd.x, 100, 1e-9, "marker must finish at the target")
T.near(atEnd.y, 200, 1e-9, "marker must finish at the target")
T.near(atEnd.progress, 1, 1e-9, "progress at end")

local past = Model.Position(track, 999)
T.near(past.progress, 1, 1e-9, "past the span must stay clamped at target")
local before = Model.Position(track, -50)
T.near(before.progress, 0, 1e-9, "before the span must stay clamped at origin")

-- Monotonic walk: never step backwards and never overshoot.
local previous = -1
for hour = 100, 110 do
    local point = Model.Position(track, hour)
    T.truthy(point.progress >= previous,
        "progress must not regress at hour " .. tostring(hour))
    T.truthy(point.progress >= 0 and point.progress <= 1,
        "progress must stay in range at hour " .. tostring(hour))
    previous = point.progress
end

-- Receive clamp: a leg confirmed only up to hour 102 must not glide further
-- even though real time has moved on, or the marker would snap backwards when
-- the next snapshot arrives.
local clamped = Model.Begin(traveling(), 102)
local frozen = Model.Position(clamped, 110)
T.near(frozen.progress, Model.Ease(0.2), 1e-9,
    "position must not run ahead of the last confirmed observation")
T.near(frozen.x, 100 * Model.Ease(0.2), 1e-9,
    "clamped marker x must match the confirmed fraction")
T.near(Model.Position(clamped, 120).progress, Model.Ease(0.2), 1e-9,
    "receive clamp must hold for any later hour")
-- And the clamp must still be monotonic with respect to the confirmed hour.
T.truthy(Model.Position(clamped, 101).progress
    < Model.Position(clamped, 102).progress,
    "clamped track must still advance within the confirmed window")

-- Table reuse ---------------------------------------------------------------

local scratch = { x = -1, y = -1, progress = -1 }
local reused = Model.Position(track, 105, scratch)
T.truthy(reused == scratch, "Position must write into the supplied table")
T.near(scratch.x, 50, 1e-9, "supplied table should receive the projection")

local existing = {}
T.truthy(Model.Begin(traveling(), 100, existing) == existing,
    "Begin must reuse the supplied track table")

T.finish("pnc_mobile_group_track_model_smoke")