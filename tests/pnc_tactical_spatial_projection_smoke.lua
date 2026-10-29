local T = require "tests/support/test"
T.addPackagePaths()

local now = 1000
local heading = { x = 0, y = -1 }
local body = {
    getX = function() return 100 end,
    getY = function() return 100 end,
    getZ = function() return 0 end,
    getForwardDirection = function()
        return {
            getX = function() return heading.x end,
            getY = function() return heading.y end,
        }
    end,
}

PNC = {
    Core = { Now = function() return now end },
    Const = { PRESENCE_LIVE = "LIVE" },
    Registry = {
        GetLiveZombie = function(id)
            if tostring(id) == "npc-a" then return body end
            return nil
        end,
    },
}

PsychopatzCore = {}
local Relation = require "PsychopatzCore/Spatial/PsychopatzSpatialRelation"
local Facing = require "PNC/Core/Spatial/PNC_ActorFacing"
local Projection = require "PNC/Core/Spatial/PNC_TacticalSpatialProjection"

local record = {
    id = "npc-a",
    x = 100,
    y = 100,
    z = 0,
    presenceState = "LIVE",
    runtime = { pathing = {} },
}

local angle240 = math.rad(240)
local threat = {
    id = "zombie-group",
    kind = "zombie_group",
    x = 100 + math.sin(angle240) * 10,
    y = 100 - math.cos(angle240) * 10,
    z = 0,
    observedAt = now,
    positionSource = "combat_centroid",
}

local facing, facingReason = Facing.Resolve(record, { now = now })
T.truthy(facing, facingReason)
T.equal(facing.source, "live_body", "live body is preferred facing authority")
T.equal(facing.x, 0, "live heading x")
T.equal(facing.y, -1, "live heading y")

local projected, projectionReason = Projection.Project(record, threat, {
    now = now,
    sameAreaThreshold = 0.1,
})
T.truthy(projected, projectionReason)
T.equal(projected.clockToken, "CLOCK_08", "rear-left threat resolves to eight o'clock")
T.equal(projected.relativeSector8, "REAR_LEFT", "coarse rear-left sector")
T.equal(projected.headingSource, "live_body", "projection records heading source")
T.equal(projected.targetPositionSource, "combat_centroid",
    "projection records target geometry source")

heading = { x = 1, y = 0 }
local rotated = Projection.Project(record, threat, {
    now = now,
    sameAreaThreshold = 0.1,
})
T.truthy(rotated, "rotated projection remains available")
T.falsy(rotated.clockToken == projected.clockToken,
    "turning observer updates ephemeral clock relation")

local cachedRecord = {
    id = "npc-cached",
    x = 0,
    y = 0,
    z = 0,
    presenceState = "LIVE",
    runtime = {
        pathing = {
            lastFacingDirX = 1,
            lastFacingDirY = 0,
            lastFacingAt = 900,
        },
    },
}
local cached, cachedReason = Facing.Resolve(cachedRecord, { now = now })
T.truthy(cached, cachedReason)
T.equal(cached.source, "pathing_cache", "fresh pathing facing can be reused")
T.equal(cached.ageMs, 100, "cached facing age is explicit")

local stale, staleReason = Facing.Resolve(cachedRecord, {
    now = 2500,
    maxCachedAgeMs = 1000,
})
T.equal(stale, nil, "stale cached facing is rejected")
T.equal(staleReason, "HEADING_UNAVAILABLE", "stale facing reason")

cachedRecord.presenceState = "ABSTRACT"
local abstract = Facing.Resolve(cachedRecord, { now = 950 })
T.equal(abstract, nil, "abstract actor cannot fabricate clock facing")

local staleThreat, staleThreatReason = Projection.Project(record, {
    kind = "hostile",
    x = 120,
    y = 100,
    z = 0,
    observedAt = 1,
}, {
    now = 5000,
    maxThreatAgeMs = 1000,
})
T.equal(staleThreat, nil, "stale threat projection rejected")
T.equal(staleThreatReason, "THREAT_STALE", "stale threat reason")

heading = { x = 0, y = 0 }
local unavailable, unavailableReason = Projection.Project(record, threat, {
    now = now,
})
T.equal(unavailable, nil, "invalid live heading is not fabricated")
T.equal(unavailableReason, "HEADING_UNAVAILABLE", "invalid heading omission reason")

T.equal(Relation.GetClockLabel("CLOCK_08"), "8 o'clock",
    "published Core clock labels are available to Hoomans")

print("pnc_tactical_spatial_projection_smoke: ok")
