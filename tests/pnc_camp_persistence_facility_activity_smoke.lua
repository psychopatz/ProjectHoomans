local T = require "tests/support/test"

T.addPackagePaths()

PNC = {
    Const = {
        ORDER_FOLLOW = "follow",
        ORDER_CAMP = "camp",
        ORDER_PATROL = "patrol",
        ROAM_DEFAULT_RADIUS = 8,
        ROAM_TARGET_RADIUS = 4,
        ROAM_REACHED_DISTANCE = 1.5,
        ROAM_PAUSE_MIN_MS = 1000,
        ROAM_PAUSE_MAX_MS = 3000,
    },
    Core = {
        DeepCopy = function(v)
            if type(v) ~= "table" then return v end
            local out = {}
            for k, val in pairs(v) do
                if type(val) == "table" then
                    local sub = {}
                    for sk, sv in pairs(val) do sub[sk] = sv end
                    out[k] = sub
                else
                    out[k] = val
                end
            end
            return out
        end,
    },
}

local Repo = T.load("ProjectHoomans", "shared", "PNC/Core/Commands/PNC_CompanionRecordRepository.lua")

-- 1. Standing camper serializes its camp order directly.
local standingCamper = {
    id = "npc_1",
    recruited = true,
    anchorX = 100, anchorY = 200, anchorZ = 0,
    orderSpec = {
        kind = "camp",
        campId = "camp:1",
        x = 100, y = 200, z = 0,
        ownerUsername = "Pat",
    },
    runtime = {},
}
local serializedStanding = Repo.SerializeOrder(standingCamper)
T.truthy(serializedStanding, "Standing camper order must serialize")
T.equal(serializedStanding.kind, "camp", "Standing camper must remain camp")
T.equal(serializedStanding.campId, "camp:1", "Standing camper campId preserved")

-- 2. Camper currently sitting/sleeping in a temporary facility_activity must
--    unwrap runtime.facilityActivity.previousOrder and serialize camp (NOT nil).
local seatedCamper = {
    id = "npc_2",
    recruited = true,
    anchorX = 102, anchorY = 200, anchorZ = 0,
    orderSpec = {
        kind = "facility_activity",
        facilityId = "seat:1",
    },
    runtime = {
        facilityActivity = {
            seating = true,
            previousOrder = {
                kind = "camp",
                campId = "camp:1",
                x = 102, y = 200, z = 0,
                ownerUsername = "Pat",
            },
        },
    },
}
local serializedSeated = Repo.SerializeOrder(seatedCamper)
T.truthy(serializedSeated, "Seated camper must not serialize nil orderSpec")
T.equal(serializedSeated.kind, "camp", "Seated camper must preserve durable camp order")
T.equal(serializedSeated.campId, "camp:1", "Seated camper campId preserved")

-- 3. Facility activity with no durable previousOrder still returns nil safely.
local transientOnly = {
    id = "npc_3",
    anchorX = 104, anchorY = 200, anchorZ = 0,
    orderSpec = { kind = "facility_activity" },
    runtime = { facilityActivity = { seating = true } },
}
T.falsy(Repo.SerializeOrder(transientOnly), "Transient facility_activity without previousOrder returns nil")

-- 4. RestoreDirective restores the camp order cleanly on reload.
local reloaded = { id = "npc_2", recruited = true, anchorX = 102, anchorY = 200, anchorZ = 0 }
Repo.RestoreDirective(reloaded, { orderSpec = serializedSeated })
T.truthy(reloaded.orderSpec, "Reloaded camper should have orderSpec")
T.equal(reloaded.orderSpec.kind, "camp", "Reloaded camper must stay on camp, not revert to follow")
T.equal(reloaded.orderSpec.campId, "camp:1", "Reloaded camper keeps campId")
