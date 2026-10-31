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
local handlers = {}
local travelRequests = {}
local events = {}
local followOwned = false
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
        LogWarn = function() end,
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
        EXCURSION_MAX_INTENT_LENGTH = 96,
        MOBILE_SETTLEMENT_VISIT_INTENT_GENERAL = "general",
        MOBILE_SETTLEMENT_VISIT_INTENT_COMMERCIAL = "commercial",
        MOBILE_SETTLEMENT_VISIT_INTENT_MAX_LENGTH = 96,
    },
    FactionTypes = {},
}
PNC.FactionTypes.Internal = {}
T.load(SHARED .. "PNC_FactionTypes.lua")

local homeCommunity = {
    id = "community_m10d_generic_home",
    factionID = "faction_m10d_generic",
    status = "active",
    siteID = "site_m10d_generic_home",
    home = { x = 10, y = 10, z = 0, radius = 12 },
}
local destinationCommunity = {
    id = "community_m10d_generic_destination",
    factionID = "faction_m10d_generic_destination",
    status = "active",
    siteID = "site_m10d_generic_destination",
    home = { x = 100, y = 100, z = 0, radius = 12 },
}
local hostileCommunity = {
    id = "community_m10d_generic_hostile",
    factionID = "faction_m10d_generic_hostile",
    status = "active",
    siteID = "site_m10d_generic_hostile",
    home = { x = 200, y = 200, z = 0, radius = 12 },
}
local faction = {
    id = homeCommunity.factionID,
    status = "active",
    revision = 1,
    memberIDs = { npc_m10d_generic = true },
}
local npc = {
    id = "npc_m10d_generic",
    alive = true,
    x = 10,
    y = 10,
    affiliation = {
        factionID = faction.id,
        communityID = homeCommunity.id,
        membershipStatus = "member",
    },
    runtime = {},
}
factions[faction.id] = faction
communities[homeCommunity.id] = homeCommunity
communities[destinationCommunity.id] = destinationCommunity
communities[hostileCommunity.id] = hostileCommunity
registry[npc.id] = npc

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
PNC.MobileSettlementVisitService = {
    IsSettlementVisitEligible = function(_, target)
        return target and target.communityID == destinationCommunity.id,
            target and target.communityID == destinationCommunity.id
                and "eligible" or "destination_rejected"
    end,
}
PNC.Travel = {
    Arrivals = {
        StrictActionTypes = {},
        RegisterHandler = function(actionType, handler)
            handlers[actionType] = handler
            return true
        end,
    },
    Service = {
        IsFollowOwned = function() return followOwned end,
    },
}
PNC.API = {
    Travel = {
        Start = function(npcID, request)
            travelRequests[#travelRequests + 1] = {
                npcID = npcID,
                request = copy(request),
            }
            npc.travel = {
                state = "planned",
                request = copy(request),
            }
            return {
                journeyId = "journey_m10d_generic_" .. tostring(#travelRequests),
                destination = copy(request.destination),
                arrivalAction = copy(request.arrivalAction),
                arrivedWorldHour = at,
            }, "travel_started"
        end,
    },
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
T.truthy(handlers.community_excursion_settlement,
    "generic settlement arrival handler is registered")
T.truthy(handlers.community_excursion_home,
    "generic exact-home arrival handler is registered")

local target = {
    kind = "settlement",
    communityID = destinationCommunity.id,
    locationID = "location_m10d_generic_destination",
    x = destinationCommunity.home.x,
    y = destinationCommunity.home.y,
    z = 0,
}
local started, startReason = Service.BeginParticipantExcursion({
    homeFactionID = faction.id,
    homeCommunityID = homeCommunity.id,
    participants = { npc.id },
    purpose = "commercial",
    visitIntent = "commercial",
    publicReason = "trading run",
    destination = target,
    itinerary = { target },
    expectedReturnAt = at + 12,
}, at)
T.truthy(started, startReason)
T.equal(Service.Get(faction.id).state, Constants.EXCURSION_STATE_OUTBOUND,
    "participant excursion reaches outbound")
T.falsy(faction.mobile, "generic participant excursion does not make faction mobile")
T.equal(npc.affiliation.factionID, faction.id,
    "participant keeps original faction membership")
T.equal(npc.affiliation.communityID, homeCommunity.id,
    "participant keeps original home community membership")
T.equal(#travelRequests, 1, "Hoomans starts one abstract participant journey")
T.equal(travelRequests[1].request.arrivalAction.intent, "commercial",
    "generic travel carries the extensible visit intent")
local homeFactionStatus = Service.GetSocialStatus(faction.id, {
    factionID = faction.id,
})
T.equal(homeFactionStatus.state, Constants.EXCURSION_STATE_OUTBOUND,
    "social status exposes authoritative outbound state")
T.equal(homeFactionStatus.status, "away",
    "social status exposes the semantic away fact")
T.equal(homeFactionStatus.phase, Constants.EXCURSION_STATE_OUTBOUND,
    "social status keeps the authoritative phase")
T.equal(homeFactionStatus.locationState, "away",
    "social status exposes the away location state")
T.equal(homeFactionStatus.publicReason, "trading run",
    "social status exposes the bounded public reason")
T.truthy(homeFactionStatus.destinationKnown,
    "home faction can know the rough destination")
T.equal(homeFactionStatus.destination.communityID,
    destinationCommunity.id, "authorized social view exposes rough destination")
local semanticContext = Service.GetSemanticContext(faction.id, {
    factionID = faction.id,
})
T.equal(semanticContext.status, "away",
    "semantic context can answer the local trader-location question")
T.equal(semanticContext.destinationCommunityID,
    destinationCommunity.id,
    "semantic context consumes the authoritative rough destination")
local absences = Service.GetCommunityAbsences(homeCommunity.id, {
    factionID = faction.id,
}, 4)
T.equal(#absences, 1,
    "community absence projection includes the temporary traveler")
T.equal(absences[1].factionID, faction.id,
    "community absence projection retains generic faction identity")
local outsiderStatus = Service.GetSocialStatus(faction.id, {
    factionID = "faction_m10d_outsider",
})
T.falsy(outsiderStatus.destinationKnown,
    "outsider social view does not learn the route")
T.falsy(outsiderStatus.destination,
    "outsider social view hides the destination")
T.falsy(outsiderStatus.expectedReturnAt,
    "outsider social view hides the expected return")

npc.travel = nil
local arrived, arrivalReason = handlers.community_excursion_settlement(
    npc,
    {
        destination = copy(travelRequests[1].request.destination),
        arrivedWorldHour = at + 12,
    },
    copy(travelRequests[1].request.arrivalAction)
)
T.truthy(arrived, arrivalReason)
T.equal(Service.Get(faction.id).state, Constants.EXCURSION_STATE_VISITING,
    "generic arrival enters temporary visit without admission")
T.equal(Service.GetNPCSocialStatus(npc.id, { factionID = faction.id }).state,
    Constants.EXCURSION_STATE_VISITING,
    "NPC social status projects the visiting phase")
T.equal(npc.affiliation.factionID, faction.id,
    "commercial visit never transfers faction membership")
T.equal(npc.affiliation.communityID, homeCommunity.id,
    "commercial visit never transfers community membership")

-- Persist/reload the visiting record, then let the bounded reconciler start
-- the exact-home leg. This is the same durable state the world director uses.
faction.excursion = copy(faction.excursion)
at = 30
local processed = Service.ReconcileAll(at, 1)
T.equal(processed, 1, "reconciliation processes a persisted visit")
T.equal(Service.Get(faction.id).state,
    Constants.EXCURSION_STATE_RETURNING_HOME,
    "visit expiry starts the exact-home return")
T.equal(#travelRequests, 2, "reconciliation starts one return journey")
T.equal(travelRequests[2].request.arrivalAction.destinationCommunityID,
    homeCommunity.id, "return journey targets the exact home community")
T.equal(Service.GetSocialStatus(faction.id, { factionID = faction.id }).state,
    Constants.EXCURSION_STATE_RETURNING_HOME,
    "social status exposes the returning phase")
faction.excursion = copy(faction.excursion)
T.equal(Service.ReconcileAll(at, 1), 1,
    "save/reload reconciliation sees the returning phase")
T.equal(Service.Get(faction.id).state,
    Constants.EXCURSION_STATE_RETURNING_HOME,
    "return reload does not select an alternate settlement")

npc.travel = nil
local returned, returnReason = handlers.community_excursion_home(
    npc,
    {
        destination = copy(travelRequests[2].request.destination),
        arrivedWorldHour = at + 1,
    },
    copy(travelRequests[2].request.arrivalAction)
)
T.truthy(returned, returnReason)
T.equal(Service.Get(faction.id).state, Constants.EXCURSION_STATE_AT_HOME,
    "exact-home arrival restores at-home state")
T.equal(Service.ResolveHome(faction.id).id, homeCommunity.id,
    "home resolver remains exact after return")

local evaluatorCalls = 0
T.truthy(Service.RegisterRequestEvaluator("commercial", function(
    request, submittedAt, context
)
    evaluatorCalls = evaluatorCalls + 1
    T.equal(request.visitIntent, "commercial",
        "request seam preserves the generic visit intent")
    T.equal(submittedAt, at + 2,
        "request seam preserves the authoritative submission time")
    T.equal(context.relationshipState, "friendly",
        "request evaluator receives bounded relationship context")
    return { status = "deferred", reason = "awaiting_ai_review" }
end), "request evaluator registers")
local requestResult, requestReason = Service.SubmitRequest({
    homeFactionID = faction.id,
    requesterFactionID = "faction_m10d_requester",
    purpose = "commercial",
    visitIntent = "commercial",
    destination = target,
}, at + 2, { relationshipState = "friendly" })
T.truthy(requestResult, requestReason)
T.equal(requestReason, "deferred",
    "request seam returns an AI-evaluable deferred decision")
T.equal(requestResult.status, "deferred",
    "request seam preserves evaluator status")
T.equal(evaluatorCalls, 1, "request evaluator runs once")
T.equal(#travelRequests, 2,
    "request submission never commands a direct journey")
T.equal(Service.Get(faction.id).state, Constants.EXCURSION_STATE_AT_HOME,
    "request submission leaves the excursion lifecycle unchanged")

-- Invalid/hostile destination handling becomes a bounded failure and can
-- retry through preparation without deleting the member or teleporting it.
local hostileTarget = {
    kind = "settlement",
    communityID = hostileCommunity.id,
    locationID = "location_m10d_generic_hostile",
    x = hostileCommunity.home.x,
    y = hostileCommunity.home.y,
    z = 0,
}
local failedStart, failedStartReason = Service.BeginParticipantExcursion({
    homeFactionID = faction.id,
    homeCommunityID = homeCommunity.id,
    participants = { npc.id },
    purpose = "commercial",
    visitIntent = "commercial",
    destination = hostileTarget,
    itinerary = { hostileTarget },
    expectedReturnAt = at + 12,
}, at + 3)
T.truthy(failedStart, failedStartReason)
T.equal(Service.Get(faction.id).state, Constants.EXCURSION_STATE_OUTBOUND,
    "invalid destination test reaches the normal outbound phase")
local failedTravel = copy(travelRequests[#travelRequests].request)
npc.travel = nil
local failedArrival, failedArrivalReason = handlers.community_excursion_settlement(
    npc,
    {
        destination = copy(failedTravel.destination),
        arrivedWorldHour = at + 4,
    },
    copy(failedTravel.arrivalAction)
)
T.truthy(failedArrival, failedArrivalReason)
T.equal(Service.Get(faction.id).state, Constants.EXCURSION_STATE_FAILED,
    "invalid destination becomes an explicit failure")
T.equal(Service.Get(faction.id).failure.code, "destination_rejected",
    "failure preserves the Hoomans safety reason")
local retryOK, retryReason = Service.Retry(faction.id, at + 5, {
    participants = { npc.id },
    itinerary = { target },
})
T.truthy(retryOK, retryReason)
T.equal(Service.Get(faction.id).state, Constants.EXCURSION_STATE_PREPARING,
    "failed excursion retries through generic preparation")
T.truthy(Service.SetPhase(faction.id, Constants.EXCURSION_STATE_AT_HOME,
    nil, at + 6), "failure fixture returns to home without teleporting")

-- The generic safety gate rejects both player-following and protected work.
followOwned = true
local followOK, followReason = Service.CanParticipantDepart(
    faction.id, npc.id)
T.falsy(followOK, "Follow Player prevents generic departure")
T.equal(followReason, "FOLLOWING_PLAYER", "follow guard is diagnostic")
followOwned = false
npc.orderSpec = { kind = "work" }
local workOK, workReason = Service.CanParticipantDepart(faction.id, npc.id)
T.falsy(workOK, "protected work prevents generic departure")
T.equal(workReason, "PROTECTED_TASK", "protected task is diagnostic")
npc.orderSpec = nil

T.truthy(#events >= 4, "generic phase changes emit lifecycle notifications")

return T.finish("pnc_community_excursion_participant_smoke")
