local T = require "tests/support/test"

PNC = {}
T.addPackagePaths()
require "PNC/Core/Director/PNC_DirectorConfig"
local Types = require "PNC/Core/Director/PNC_AbstractWorldTypes"
local Journey = require
    "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldGroupJourney"

local journey = assert(Journey.New(
    "agroup_persist",
    {
        origin = { x = 100, y = 200, z = 0 },
        destination = { x = 500, y = 200, z = 0 },
        originAnchorID = "aloc_a",
        destinationAnchorID = "aloc_b",
        speed = 40,
        startAt = 10,
    },
    10
))
journey = assert(Journey.Advance(journey, 15))

local raw = {
    revision = 7,
    locationsByID = {
        aloc_a = {
            id = "aloc_a", type = "SETTLEMENT",
            x = 100, y = 200, z = 0,
        },
        aloc_b = {
            id = "aloc_b", type = "SETTLEMENT",
            x = 500, y = 200, z = 0,
        },
    },
    groupsByID = {
        agroup_persist = {
            id = "agroup_persist",
            factionId = "faction_persist",
            groupType = "CARAVAN",
            memberIds = { "actor_1", "actor_2" },
            leaderId = "actor_1",
            mission = "TRAVEL",
            state = "TRAVELING",
            location = {
                id = "aloc_a", type = "SETTLEMENT",
                x = 100, y = 200, z = 0,
            },
            targetLocation = {
                id = "aloc_b", type = "SETTLEMENT",
                x = 500, y = 200, z = 0,
            },
            stateStartedAt = 10,
            stateEndsAt = journey.eta,
            journey = journey,
        },
    },
}

local normalized = Types.NormalizeRegistry(raw)
local group = normalized.groupsByID.agroup_persist
T.truthy(group, "normalized group missing")
T.truthy(group.journey, "Core journey must survive normalization")
T.equal(group.journey.journeyID, journey.journeyID,
    "journey identity must survive normalization")
T.near(group.journey.distanceTravelled,
    journey.distanceTravelled, 0.0001,
    "journey progress must survive normalization")

local reloaded = Types.NormalizeRegistry(normalized)
local roundTrip = reloaded.groupsByID.agroup_persist
T.truthy(roundTrip and roundTrip.journey,
    "journey must survive repeated save/load normalization")
T.equal(roundTrip.journey.journeyID, journey.journeyID,
    "journey identity must stay stable")
T.near(roundTrip.journey.progress, journey.progress, 0.0001,
    "journey progress must stay stable")

T.finish("pnc_core_group_journey_persistence_smoke")
