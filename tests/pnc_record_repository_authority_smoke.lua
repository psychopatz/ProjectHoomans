local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "shared" } })
local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = copy(item) end
    return result
end
local dirtyReason
PNC = {
    Core = { DeepCopy = copy },
    Const = { PRESENCE_LIVE = "live", ORDER_FOLLOW = "follow", ORDER_TRAVEL = "travel" },
    Registry = { MarkDirty = function(_, reason) dirtyReason = reason end },
}

local Skills = require "PNC/Core/Skills/PNC_SkillsRepository"
local progression = Skills.NormalizeProgression({
    skillLevelDeltas = { A = -20, B = 20, C = 0 }, skillXP = { A = -1, B = 12 },
})
T.equal(progression.skillLevelDeltas.A, -10, "skill delta lower bound")
T.equal(progression.skillLevelDeltas.B, 10, "skill delta upper bound")
T.falsy(progression.skillLevelDeltas.C, "zero deltas stay omitted")
T.falsy(progression.skillXP.A, "negative XP stays omitted")
local levels = Skills.NormalizeBaseLevels({ A = -1, B = 12, C = 3.7 })
T.equal(levels.A, 0, "authored skill lower bound")
T.equal(levels.B, 10, "authored skill upper bound")
T.equal(levels.C, 3, "authored skill integer normalization")
local record = { recruited = true, progression = {} }
local encoded = Skills.SerializeRecord(record)
T.equal(encoded.recruited, true, "recruitment learning gate remains durable")
Skills.RestoreRecord(record, progression)
T.equal(record.recruited, true, "restoring progression cannot demote recruitment")

local Body = require "PNC/Core/Presence/PNC_BodyRepository"
record = {
    id = "proof", presenceState = "live", liveBodyInstanceID = "instance",
    liveBodyPopulationID = "population", liveBodyOnlineID = 21,
    x = 10, y = 20, z = 0, runtime = { bodyLease = "lease" },
}
local hint = Body.BuildHint(record)
T.equal(hint.wasLive, true, "live carrier proof survives serialization")
T.equal(hint.lease, "lease", "carrier incarnation is preserved")
T.equal(hint.onlineID, 21, "vanilla transport identity is preserved")
local restored = { presenceState = "abstract", x = 10, y = 20, z = 0, runtime = {} }
Body.RestoreHint(restored, { bodyHint = hint })
T.equal(restored.runtime.startupRehydrateExpected, true, "saved-live admission survives")
T.equal(restored.runtime.lastLiveBodyLease, "lease", "restart proof keeps the lease")
T.falsy(restored.runtime.bodyLease, "saved proof cannot assign an active physical incarnation")
T.equal(restored.presenceState, "abstract", "schema restore cannot materialize a shell")
Body.RestoreHint(restored, { bodyHint = {
    instanceID = "instance", lease = "lease", wasLive = false,
} })
T.equal(restored.runtime.startupRehydrateExpected, false, "explicit non-live hint is not upgraded")
Body.RestoreHint(restored, { bodyHint = { instanceID = "instance", lease = "lease" } })
T.equal(restored.runtime.startupRehydrateExpected, true, "legacy lease fallback stays compatible")
T.falsy(Body.BuildHint({ presenceState = "abstract", runtime = {} }),
    "abstract record without carrier proof stays empty")

local Companions = require "PNC/Core/Commands/PNC_CompanionRecordRepository"
local directive = Companions.NormalizeOrder({
    kind = "follow", ownerOnlineID = 99, ownerCharacterUUID = "character",
}, { anchorX = 0, anchorY = 0, anchorZ = 0 })
T.falsy(directive.ownerOnlineID, "session owner ID is not persisted")
T.equal(directive.ownerCharacterUUID, "character", "durable owner UUID is preserved")
PNC.Travel = {
    Model = { Normalize = copy, IsActive = function(route) return route.state == "en_route" end },
    Service = { WorldHour = function() return 11 end },
}
local Travel = require "PNC/Core/Travel/PNC_TravelRepository"
record = { orderSpec = { kind = "follow" }, x = 10, y = 20 }
local active = Travel.RestoreRecord(record, { travel = {
    state = "en_route", journeyId = "stale",
} }, Companions.IsFollowing(record))
T.falsy(active, "Follow cannot revive a stale travel directive")
T.falsy(record.travel, "stale route is retired by Travel")
T.equal(dirtyReason, "follow_travel_reconciled", "travel repair remains durable")
T.equal(record.x, 10, "schema restoration does not move the follower")
record.orderSpec = { kind = "wait" }
local journeyID
active, journeyID = Travel.RestoreRecord(record, { travel = {
    state = "en_route", journeyId = "current",
} }, false)
T.equal(active, true, "active route requests its directive transition")
Companions.SetTravelOrder(record, journeyID)
T.equal(record.orderSpec.journeyId, "current", "Companions owns the travel directive write")

local Combat = require "PNC/Core/Combat/PNC_CombatRecordRepository"
T.equal(Combat.NormalizeHostility(nil, "hostile").attackPlayers, true,
    "partial composition keeps hostility fallback")
T.equal(Combat.NormalizeAttackType(nil, "melee"), "melee", "partial attack fallback")
PNC.Types = { NormalizeHostility = function() return { marker = "typed" } end }
T.equal(Combat.NormalizeHostility(nil, "neutral").marker, "typed",
    "full composition delegates to the existing typed combat policy")
T.falsy(PNC.Persistence, "cold repositories cannot load envelope orchestration")
T.falsy(PNC.BodyLifecycle, "carrier schema cannot load physical lifecycle authority")

T.finish("pnc_record_repository_authority_smoke")
