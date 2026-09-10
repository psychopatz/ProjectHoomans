local T = require "tests/support/test"

PNC = {}
T.load(
    "ProjectHoomans",
    "client",
    "PNC/UI/Mobile/PNC_MobileGroupDebugModel.lua"
)

local Model = PNC.MobileGroupDebugModel

local road = {
    active = true,
    ambient = {
        objective = "road",
        target = { kind = "nav", x = 10, y = 20, z = 0 },
    },
}
T.equal(Model.State(road), "road_roaming",
    "road lobby has a distinct lifecycle state")
T.equal(Model.StateText(road), "ROAD ROAMING",
    "road lifecycle label")
T.contains(Model.TargetText(road), "nav / anonymous @ 10, 20, 0",
    "road objective target")

local street = { active = true, ambient = { objective = "shelter" } }
T.equal(Model.State(street), "street_roaming",
    "non-road ambient group stays street roaming")

local travel = {
    active = true,
    activity = "traveling_to_settlement",
    groupState = "TRAVELING",
    presence = "abstract",
    travel = {
        kind = "settlement",
        startedAt = 10,
        destination = {
            kind = "player_colony",
            baseID = "base_1",
            locationID = "aloc_base_1",
            x = 110,
            y = 120,
            z = 0,
        },
    },
}
T.equal(Model.State(travel), "en_route",
    "traveling group uses the abstract traversal state")
T.equal(Model.Presence(travel), "abstract",
    "mobile presence is visible")
T.contains(Model.TargetText(travel), "base_1",
    "settlement target is visible")
T.near(Model.Progress(travel, { stateEndsAt = 30 }, 20),
    0.5, 0.0001, "travel progress")

travel.groupState = "ARRIVED"
T.equal(Model.State(travel), "arrival_pending",
    "mobile activity exposes a stale arrival handoff")

local override = {
    active = true,
    debugState = "arrival_pending",
}
T.equal(Model.State(override), "arrival_pending",
    "server lifecycle override is respected")

T.finish("pnc_mobile_debug_model_smoke")
