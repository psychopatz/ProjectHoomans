local T = require "tests/support/test"

local SHARED = T.path("ProjectHoomans", "shared", "PNC/Core/Factions/")
local SERVER = T.path("ProjectHoomans", "server", "PNC/Communities/")

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, item in pairs(value) do output[key] = copy(item) end
    return output
end

local at = 10
local events = {}
local warnings = {}
local factions = {}
local communities = {}
local registry = {}

function isServer() return true end
function isClient() return false end
function getGameTime()
    return { getWorldAgeHours = function() return at end }
end

PNC = {
    Core = {
        DeepCopy = copy,
        IsAuthority = function() return true end,
        LogWarn = function(message) warnings[#warnings + 1] = message end,
    },
    FactionConstants = {
        ID_MAX_LENGTH = 192,
        TAG_VALUE_MAX_LENGTH = 192,
        EXCURSION_SCHEMA_VERSION = 1,
        EXCURSION_STATE_AT_HOME = "AT_HOME",
        EXCURSION_STATE_PREPARING = "PREPARING",
        EXCURSION_STATE_OUTBOUND = "OUTBOUND",
        EXCURSION_STATE_VISITING = "VISITING",
        EXCURSION_STATE_RETURNING_HOME = "RETURNING_HOME",
        EXCURSION_STATE_FAILED = "FAILED",
        EXCURSION_STATES = {
            AT_HOME = true,
            PREPARING = true,
            OUTBOUND = true,
            VISITING = true,
            RETURNING_HOME = true,
            FAILED = true,
        },
        EXCURSION_MAX_PARTICIPANTS = 24,
        EXCURSION_MAX_ITINERARY = 16,
        EXCURSION_MAX_PURPOSE_LENGTH = 96,
        EXCURSION_MAX_REASON_LENGTH = 128,
    },
    FactionTypes = {},
}

PNC.FactionTypes.Internal = {}
T.load(SHARED .. "PNC_FactionTypes.lua")

local faction = {
    id = "faction_home",
    status = "active",
    revision = 7,
    memberIDs = { npc_trader = true, npc_guard = true },
}
local home = {
    id = "community_home",
    factionID = "faction_home",
    status = "active",
}
factions.faction_home = faction
communities.community_home = home
registry.npc_trader = {
    id = "npc_trader",
    affiliation = { factionID = "faction_home" },
}
registry.npc_guard = {
    id = "npc_guard",
    affiliation = { factionID = "faction_home" },
}

PNC.Factions = {
    Registry = { byID = factions },
    EnsureLoaded = function() end,
    IsMember = function(factionID, npcID)
        return factions[factionID]
            and factions[factionID].memberIDs[npcID] == true
    end,
    Repository = {
        GetRecord = function(factionID) return factions[factionID] end,
        MarkChanged = function(record)
            record.revision = (tonumber(record.revision) or 0) + 1
        end,
    },
}
PNC.Communities = {
    Get = function(communityID) return communities[communityID] end,
}
PNC.Registry = {
    Get = function(npcID) return registry[npcID] end,
}
PNC.AbstractWorldStore = {
    WorldAgeHours = function() return at end,
    Emit = function(name, payload)
        events[#events + 1] = { name = name, payload = copy(payload) }
    end,
}

T.load(SERVER .. "PNC_CommunityExcursionService.lua")
local Service = PNC.CommunityExcursionService
local Constants = PNC.FactionConstants

local observed = {}
local listenerFailure = function()
    error("listener must not interrupt excursion state")
end
local listenerRejects = function()
    return false, "listener_rejected_for_diagnostics"
end
local listener = function(payload)
    observed[#observed + 1] = payload.state
end
T.truthy(Service.RegisterListener(listenerFailure),
    "failure listener registers within bounded observer budget")
T.truthy(Service.RegisterListener(listenerRejects),
    "false listener registers within bounded observer budget")
T.truthy(Service.RegisterListener(listener),
    "observer listener registers within bounded observer budget")

local target = {
    kind = "settlement",
    communityID = "community_market",
    locationID = "location_market",
    x = 100,
    y = 200,
    z = 0,
}
local spec = {
    homeFactionID = "faction_home",
    homeCommunityID = "community_home",
    purpose = "commercial",
    publicReason = "trading run",
    participants = { "npc_trader", "npc_guard", "npc_trader" },
    itinerary = { target },
}

local created, createdReason = Service.Create(spec, at)
T.truthy(created, createdReason)
T.equal(created.state, Constants.EXCURSION_STATE_AT_HOME,
    "new excursion starts at the exact home")
T.equal(created.homeCommunityID, "community_home",
    "home community is persisted as canonical identity")
T.falsy(Service.GetPublicStatus("faction_home").active,
    "at-home public status is inactive")
T.equal(#created.participants, 2,
    "participants are bounded and deduplicated")

local duplicate, duplicateReason = Service.Create(spec, at)
T.truthy(duplicate, "idempotent create returns the existing excursion")
T.equal(duplicateReason, "excursion_exists",
    "active excursion cannot be replaced by a second create")

local prepared = Service.Begin("faction_home", {
    purpose = "commercial",
    publicReason = "trading run",
    participants = { "npc_trader" },
    itinerary = { target },
}, at + 1)
T.equal(prepared.state, Constants.EXCURSION_STATE_PREPARING,
    "begin enters preparation")
local outboundOK, outboundReason, outbound = Service.StartOutbound(
    "faction_home", target, at + 2, at + 20)
T.truthy(outboundOK, outboundReason)
T.equal(outbound.state, Constants.EXCURSION_STATE_OUTBOUND,
    "outbound phase records departure")
T.equal(outbound.destination.communityID, "community_market",
    "outbound phase keeps the bounded destination")

local visitingOK, visitingReason, visiting = Service.StartVisiting(
    "faction_home", at + 3)
T.truthy(visitingOK, visitingReason)
T.equal(visiting.state, Constants.EXCURSION_STATE_VISITING,
    "arrival enters visiting without changing membership")
T.equal(Service.GetPublicStatus("faction_home").destination.communityID,
    "community_market", "public status exposes rough destination only")

local returningOK, returningReason, returning = Service.StartReturningHome(
    "faction_home", at + 4)
T.truthy(returningOK, returningReason)
T.equal(returning.state, Constants.EXCURSION_STATE_RETURNING_HOME,
    "returning phase is explicit")
T.falsy(returning.destination,
    "returning does not select an arbitrary destination")

local homeOK, homeReason, homeAgain = Service.CompleteReturn(
    "faction_home", at + 5)
T.truthy(homeOK, homeReason)
T.equal(homeAgain.state, Constants.EXCURSION_STATE_AT_HOME,
    "completion restores the exact home phase")
T.equal(homeAgain.homeCommunityID, "community_home",
    "completion retains exact home identity")

local invalid, invalidReason = Service.StartVisiting("faction_home", at + 6)
T.falsy(invalid, "phase graph rejects visiting directly from home")
T.equal(invalidReason, "invalid_excursion_transition",
    "invalid transition has a stable reason")

local startedAgain = Service.Begin("faction_home", {
    participants = { "npc_guard" },
    itinerary = { target },
}, at + 7)
T.equal(startedAgain.state, Constants.EXCURSION_STATE_PREPARING,
    "home excursion can be prepared again")
local departedAgain = Service.StartOutbound(
    "faction_home", target, at + 8)
T.truthy(departedAgain, "second excursion departs")
local failedOK, failedReason, failed = Service.Fail(
    "faction_home", "route_blocked", at + 9, at + 12)
T.truthy(failedOK, failedReason)
T.equal(failed.state, Constants.EXCURSION_STATE_FAILED,
    "failure is a persisted lifecycle phase")
T.equal(failed.failure.code, "route_blocked",
    "failure preserves a bounded diagnostic code")

local retriedOK, retryReason = Service.Retry("faction_home", at + 13, {
    participants = { "npc_trader" },
    itinerary = { target },
})
local retried = Service.Get("faction_home")
T.truthy(retriedOK, retryReason)
T.equal(retried.state, Constants.EXCURSION_STATE_PREPARING,
    "failed excursion can retry through preparation")
T.equal(retried.participants[1], "npc_trader",
    "retry reapplies bounded preparation data")

local persisted = copy(faction.excursion)
faction.excursion = persisted
local reconciled = Service.ReconcileAll(at + 14, 1)
T.equal(reconciled, 1, "reconciliation is bounded and sees persisted state")
T.equal(Service.Get("faction_home").state,
    Constants.EXCURSION_STATE_PREPARING,
    "save/reload normalization preserves the current phase")

home.status = "inactive"
local invalidHome = Service.ReconcileAll(at + 15, 1)
T.equal(invalidHome, 1, "invalid home is processed by reconciliation")
T.equal(Service.Get("faction_home").state,
    Constants.EXCURSION_STATE_FAILED,
    "invalid home becomes an explicit failure")
home.status = "active"

T.truthy(#observed >= 8, "phase changes notify generic observers")
T.truthy(#events >= #observed,
    "authoritative changes emit persistence events")
T.truthy(#warnings >= 1,
    "observer failures are diagnosed without breaking lifecycle")
local listenerDiagnostics = Service.GetListenerDiagnostics(8)
T.truthy(#listenerDiagnostics >= 1,
    "false listener returns are retained as diagnostics")
T.equal(listenerDiagnostics[#listenerDiagnostics].reason,
    "listener_rejected_for_diagnostics",
    "false listener diagnostics preserve the rejection reason")

T.finish("pnc_community_excursion_smoke")
