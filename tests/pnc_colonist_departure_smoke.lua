local T = require "tests/support/test"

T.addPackagePaths()

PNC = {
    Config = { Relationships = {} },
}
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Relationships/PNC_ColonistDeparturePolicy.lua"
)

local Policy = PNC.ColonistDeparturePolicy
local baseline = Policy.Evaluate(-60, -60, {
    loyalty = 0,
    bravery = 0,
})
T.truthy(baseline.eligible,
    "baseline departure requires both relationship axes to cross")
T.equal(baseline.approvalThreshold, -60,
    "baseline approval threshold is deliberately severe")
T.equal(baseline.respectThreshold, -60,
    "baseline respect threshold is deliberately severe")
T.falsy(Policy.Evaluate(-80, -20, {}).eligible,
    "one bad axis alone does not disband a colonist")

local loyal = Policy.Evaluate(-70, -55, {
    loyalty = 1,
    bravery = 0,
})
T.equal(loyal.approvalThreshold, -75,
    "loyal personality tolerates a lower approval floor")
T.falsy(loyal.eligible,
    "loyalty does not remove the respect requirement")

local brave = Policy.Evaluate(-60, -52, {
    loyalty = 0,
    bravery = 1,
})
T.equal(brave.respectThreshold, -52,
    "bravery makes disrespect slightly less tolerable")
T.truthy(brave.eligible,
    "personality-modified departure line remains visible and deterministic")
T.truthy(brave.recoverable == false,
    "relationship remains in the departure hysteresis band")

PNC.Core = {
    IsAuthority = function() return true end,
    LogInfo = function() end,
}
PNC.Const = {}
PNC.FactionConstants = {
    NAME_MAX_LENGTH = 96,
    MOBILE_PATH_RANDOM = "random",
    MOBILE_CONTROL_AMBIENT = "ambient",
    MOBILE_ACTIVITY_STREET_ROAMING = "street_roaming",
    MOBILE_AMBIENT_DAY = "day",
    MOBILE_AMBIENT_ROAD = "road",
}
PNC.EntityRef = {
    IsPlayer = function(value)
        return string.sub(tostring(value or ""), 1, 7) == "player:"
    end,
}
local record = {
    id = "npc_departure",
    alive = true,
    recruited = true,
    x = 100,
    y = 100,
    z = 0,
    affiliation = { factionID = "faction_player" },
}
local faction = {
    id = "faction_player",
    ownerPlayerKey = "player:one:character",
    mobile = nil,
}
local dirty = 0
PNC.Registry = {
    Data = { [record.id] = record },
    EnsureLoaded = function() end,
    MarkDirty = function() dirty = dirty + 1 end,
}
PNC.Factions = {
    Registry = { byID = { [faction.id] = faction } },
    Get = function(id) return id == faction.id and faction or nil end,
    IsMobileGroup = function(value)
        return value and value.mobile and value.mobile.active == true
    end,
}
PNC.Relationships = {
    Get = function()
        return { approval = -70, respect = -70 }
    end,
}
PNC.RelationshipGraph = {
    ResolveNPCPersonality = function() return {} end,
}
PNC.PlayerCharacters = {}
T.load(
    "ProjectHoomans",
    "server",
    "PNC/Colonists/PNC_ColonistDepartureService.lua"
)

local Service = PNC.ColonistDeparture
local departureCalls = 0
Service.Depart = function(_, cause, options)
    departureCalls = departureCalls + 1
    T.equal(cause, "automatic", "automatic pump uses the automatic cause")
    T.equal(options.ownerKey, faction.ownerPlayerKey,
        "automatic pump attributes the faction owner")
    return true, "stubbed"
end

T.equal(Service.Pump(48, 1), 0,
    "first severe relationship evaluation is held by the confirmation edge")
T.equal(record.colonistDeparture.belowThresholdChecks, 1,
    "first severe evaluation persists a compact pending marker")
T.equal(Service.Pump(48.5, 1), 0,
    "one-hour debounce prevents duplicate checks")
T.equal(Service.Pump(49, 1), 1,
    "second severe evaluation commits automatic departure")
T.equal(departureCalls, 1,
    "automatic departure is idempotently budgeted")
T.truthy(dirty > 0, "pending departure state is marked dirty")

record.colonistDeparture = {
    state = "pending",
    eventID = "colonist_departure:npc_departure",
    belowThresholdChecks = 1,
    firstDetectedAt = 49,
    lastEvaluatedAt = 49,
}
PNC.Relationships.Get = function()
    return { approval = -20, respect = -20 }
end
T.equal(Service.Pump(50, 1), 0,
    "recovered relationships do not depart")
T.equal(record.colonistDeparture, nil,
    "pending departure marker clears after recovery")

print("pnc_colonist_departure_smoke: ok")
