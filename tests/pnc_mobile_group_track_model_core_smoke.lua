local T = require "tests/support/test"

PNC = {}
local Model = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/UI/Mobile/PNC_MobileGroupTrackModel.lua"
)
local Journey = require
    "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldGroupJourney"

local journey = assert(Journey.New(
    "agroup_track_core",
    {
        origin = { x = 0, y = 0, z = 0 },
        destination = { x = 100, y = 100, z = 0 },
        route = {
            { x = 0, y = 0, z = 0 },
            { x = 0, y = 100, z = 0 },
            { x = 100, y = 100, z = 0 },
        },
        speed = 20,
        startAt = 10,
    },
    10
))

local group = {
    id = "agroup_track_core",
    state = "TRAVELING",
    mobile = { presence = "abstract" },
    journey = journey,
    location = { x = 0, y = 0, z = 0 },
    targetLocation = { x = 100, y = 100, z = 0 },
}

T.truthy(Model.ShouldTrack(group),
    "Core journey should be eligible for tracking")
local track = Model.Begin(group, 10)
T.truthy(track and track.coreJourney,
    "track should retain normalized Core journey")

local firstLeg = assert(Model.Position(track, 12.5))
T.near(firstLeg.x, 0, 0.0001,
    "Core route projection must follow first route segment")
T.near(firstLeg.y, 50, 0.0001,
    "Core route first-leg y")
T.near(firstLeg.progress, 0.25, 0.0001,
    "Core route first-leg progress")

local corner = assert(Model.Position(track, 15))
T.near(corner.x, 0, 0.0001, "route corner x")
T.near(corner.y, 100, 0.0001, "route corner y")
T.near(corner.progress, 0.5, 0.0001,
    "route corner progress")

local secondLeg = assert(Model.Position(track, 17.5))
T.near(secondLeg.x, 50, 0.0001,
    "Core route projection must follow second route segment")
T.near(secondLeg.y, 100, 0.0001,
    "Core route second-leg y")
T.near(secondLeg.progress, 0.75, 0.0001,
    "Core route second-leg progress")

local arrived = assert(Model.Position(track, 20))
T.near(arrived.x, 100, 0.0001, "Core route arrival x")
T.near(arrived.y, 100, 0.0001, "Core route arrival y")
T.near(arrived.progress, 1, 0.0001,
    "Core route arrival progress")

T.falsy(Model.ShouldTrack({
    id = group.id,
    state = "TRAVELING",
    mobile = { presence = "live" },
    journey = journey,
}), "live group must still defer to physical authority")

T.finish("pnc_mobile_group_track_model_core_smoke")
