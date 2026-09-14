local T = require "tests/support/test"

local SERVER = T.path("ProjectHoomans", "server", "PNC/")

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, item in pairs(value) do output[key] = copy(item) end
    return output
end

local at = 10
local registry = {}
local communities = {}
local factions = {}
local clearCalls = 0

function isServer() return true end
function isClient() return false end
function getGameTime()
    return { getWorldAgeHours = function() return at end }
end

PNC = {
    Core = {
        DeepCopy = copy,
        IsAuthority = function() return true end,
    },
    FactionConstants = {
        ID_MAX_LENGTH = 192,
        MOBILE_TRAVEL_SETTLEMENT = "settlement",
        MOBILE_TRAVEL_PURPOSE_ADMISSION = "settlement_admission",
        MOBILE_TRAVEL_PURPOSE_HOSTILE_CONTACT = "hostile_contact",
    },
    DirectorConfig = {
        MOBILE_SETTLEMENT_VISIT_HOURS = 12,
        MOBILE_SETTLEMENT_AI_JOIN_CHANCE = 1,
    },
    Sandbox = {},
    Registry = {
        Get = function(id) return registry[tostring(id)] end,
    },
    AbstractWorldStore = { Registry = { encounters = {} } },
}
PNC.FactionConstants.VALID_MOBILE_TRAVEL_PURPOSES = {
    settlement_admission = true,
    hostile_contact = true,
}
local sandboxChance = 100
PNC.Sandbox.MobileSettlementAIJoinChance = function()
    return sandboxChance
end

local playerFaction = {
    id = "faction_player",
    status = "active",
    playerMemberKeys = { player_one = true },
}
local settlement = {
    id = "community_player",
    factionID = "faction_player",
    status = "active",
    capacity = { population = 8 },
    currentPopulation = 1,
    memberIDs = {},
}
communities[settlement.id] = settlement
local aiSettlement = {
    id = "community_ai",
    factionID = "faction_ai_owner",
    status = "active",
    capacity = { population = 8 },
    currentPopulation = 1,
    memberIDs = {},
}
communities[aiSettlement.id] = aiSettlement

factions.faction_mobile = {
    id = "faction_mobile",
    status = "active",
    archetypeID = "refugee",
    mobile = {
        active = true,
        visit = nil,
    },
    memberIDs = { npc_one = true, npc_two = true },
}
factions.faction_looter = {
    id = "faction_looter",
    status = "active",
    archetypeID = "looter",
    mobile = { active = true },
    memberIDs = { npc_looter = true },
}
factions.faction_ai_mobile = {
    id = "faction_ai_mobile",
    status = "active",
    archetypeID = "settler",
    mobile = { active = true },
    memberIDs = { npc_ai = true },
}
factions.faction_ai_owner = {
    id = "faction_ai_owner",
    status = "active",
    archetypeID = "settler",
    memberIDs = {},
}
factions.faction_player = playerFaction

registry.npc_one = {
    id = "npc_one", alive = true,
    affiliation = { factionID = "faction_mobile", role = "civilian",
        rank = "member", membershipStatus = "member" },
    hostility = { attackPlayers = false },
}
registry.npc_two = {
    id = "npc_two", alive = true,
    affiliation = { factionID = "faction_mobile", role = "civilian",
        rank = "member", membershipStatus = "member" },
    hostility = { attackPlayers = false },
}
registry.npc_looter = {
    id = "npc_looter", alive = true,
    affiliation = { factionID = "faction_looter", role = "raider",
        rank = "member", membershipStatus = "member" },
    hostility = { attackPlayers = true },
}
registry.npc_ai = {
    id = "npc_ai", alive = true,
    affiliation = { factionID = "faction_ai_mobile", role = "civilian",
        rank = "member", membershipStatus = "member" },
    hostility = { attackPlayers = false },
}

PNC.Factions = {
    Registry = { byID = factions },
    Get = function(id) return factions[id] end,
    GetMobileGroup = function(id)
        return factions[id] and copy(factions[id].mobile) or nil
    end,
    GetFactionID = function(record)
        return record and record.affiliation and record.affiliation.factionID
    end,
    GetRelation = function(sourceID, targetID)
        local source = factions[sourceID]
        return source and source.relations
            and source.relations[targetID] or nil
    end,
    GetPlayerFaction = function() return playerFaction end,
    UpdateMobileGroup = function(id, patch)
        local mobile = factions[id].mobile
        for key, value in pairs(patch or {}) do mobile[key] = copy(value) end
        return true, "updated", copy(mobile)
    end,
    SetMobileGroup = function(id, spec)
        factions[id].mobile = copy(spec)
        return true, "updated", copy(spec)
    end,
    ClearMobileGroup = function(id)
        factions[id].mobile = nil
        clearCalls = clearCalls + 1
        return true, "cleared"
    end,
    TransferNPC = function(npcID, destinationID)
        local record = registry[npcID]
        local sourceID = record.affiliation.factionID
        factions[sourceID].memberIDs[npcID] = nil
        factions[destinationID].memberIDs = factions[destinationID].memberIDs or {}
        factions[destinationID].memberIDs[npcID] = true
        record.affiliation.factionID = destinationID
        return true, "transferred"
    end,
}
playerFaction.memberIDs = {}
PNC.Communities = {
    Get = function(id) return communities[id] end,
    AddNPC = function(id, npcID)
        local record = registry[npcID]
        local destination = communities[id]
        if destination.currentPopulation
            >= destination.capacity.population
        then
            return false, "population_capacity_reached"
        end
        record.affiliation.communityID = id
        destination.memberIDs[npcID] = true
        destination.currentPopulation = destination.currentPopulation + 1
        return true, "added"
    end,
}

T.load(SERVER .. "Director/PNC_MobileSettlementVisitService.lua")
local Service = PNC.MobileSettlementVisitService
local target = {
    kind = "player_colony",
    factionID = "faction_player",
    communityID = "community_player",
    locationID = "aloc_player",
}

local eligible, reason = Service.IsAdmissionEligible(
    factions.faction_mobile,
    target,
    at
)
T.truthy(eligible, reason)
factions.faction_mobile.relations = {
    faction_player = { state = "hostile" },
}
T.falsy(Service.IsAdmissionEligible(
    factions.faction_mobile,
    target,
    at
), "forward hostile relation blocks admission")
factions.faction_mobile.relations = nil
factions.faction_player.relations = {
    faction_mobile = { state = "hostile" },
}
T.falsy(Service.IsAdmissionEligible(
    factions.faction_mobile,
    target,
    at
), "reverse hostile relation blocks admission")
factions.faction_player.relations = nil
T.falsy(Service.IsAdmissionEligible(factions.faction_looter, target, at),
    "looters never qualify for admission")

local aiTarget = {
    kind = "ai_settlement",
    factionID = "faction_ai_owner",
    communityID = "community_ai",
    locationID = "aloc_ai",
}
local aiEligible, aiEligibleReason = Service.IsAdmissionEligible(
    factions.faction_ai_mobile,
    aiTarget,
    at
)
T.truthy(aiEligible, aiEligibleReason)
local aiStarted, aiReason, aiJoined = Service.OnSettlementArrival(
    factions.faction_ai_mobile,
    aiTarget,
    {
        kind = "settlement",
        purpose = "settlement_admission",
        revision = 1,
    },
    at,
    nil,
    {}
)
T.truthy(aiStarted, aiReason)
T.equal(aiJoined, 1, "AI admission roll admits the eligible member")
T.equal(registry.npc_ai.affiliation.factionID, "faction_ai_owner",
    "AI settlement admission transfers into the destination faction")
T.equal(registry.npc_ai.affiliation.communityID, "community_ai",
    "AI settlement admission adds the NPC to the community")
T.falsy(factions.faction_ai_mobile.mobile,
    "an emptied AI mobile group is cleared after admission")

sandboxChance = 0
local sandboxBlocked, sandboxBlockedReason = Service.OnSettlementArrival(
    factions.faction_mobile,
    aiTarget,
    {
        kind = "settlement",
        purpose = "settlement_admission",
        revision = 2,
    },
    at,
    nil,
    {}
)
T.falsy(sandboxBlocked, sandboxBlockedReason)
T.equal(registry.npc_one.affiliation.factionID, "faction_mobile",
    "sandbox join chance can disable AI admission")
sandboxChance = 100

PNC.AbstractWorldStore.Registry.encounters[1] = {
    id = "report_1",
    outcome = "QUEUED",
}

local noVisit, noVisitReason = Service.OnSettlementArrival(
    factions.faction_mobile,
    target,
    {
        kind = "settlement",
        purpose = "settlement_admission",
        destination = target,
        revision = 1,
    },
    at,
    { memberIds = { "npc_one", "npc_two" } },
    { { id = "report_1", outcome = "QUEUED" } }
)
T.falsy(noVisit, "encounter arrival does not create an admission visit")
T.equal(noVisitReason, "encounter_pending", "encounters keep priority")
T.truthy(factions.faction_mobile.mobile.pendingSettlementArrival,
    "encounter-backed arrival is persisted for a later retry")
T.truthy(factions.faction_mobile.mobile.pendingSettlementArrival.reportIDs.report_1,
    "pending arrival remembers the encounter report")
PNC.AbstractGroups = {
    FindByFactionID = function(id)
        if id == "faction_mobile" then
            return {
                location = { id = "aloc_player" },
                memberIds = { "npc_one", "npc_two" },
            }
        end
        return nil
    end,
}
T.equal(Service.PumpPendingArrivals(at, 4), 0,
    "queued encounters hold the admission retry")
PNC.AbstractWorldStore.Registry.encounters[1].outcome = "IGNORE"
T.equal(Service.PumpPendingArrivals(at, 4), 1,
    "resolved non-hostile encounters release the admission retry")
T.truthy(factions.faction_mobile.mobile.visit,
    "resolved arrival creates the bounded player visit")

T.equal(factions.faction_mobile.mobile.visit.expiresAt, 22,
    "visit has a bounded expiry")

local presentation = Service.GetNPCVisit("npc_one", {}, at)
T.truthy(presentation, "pending member exposes player-safe visit data")
T.equal(presentation.kind, "settlement_admission", "visit kind")

PNC.AbstractGroups = {
    FindByFactionID = function(id)
        if id == "faction_mobile" then
            return { location = { id = "aloc_elsewhere" } }
        end
        return nil
    end,
}
local moved, movedReason = Service.AdmitPlayer(
    {}, "npc_one", presentation.visitID, at
)
T.falsy(moved, "a visit cannot be used after the group changes location")
T.equal(movedReason, "settlement_visit_location_changed",
    "location mismatch is reported")
PNC.AbstractGroups.FindByFactionID = function(id)
    if id == "faction_mobile" then
        return { location = { id = "aloc_player" } }
    end
    return nil
end

settlement.currentPopulation = settlement.capacity.population
local fullAdmission, fullAdmissionReason = Service.AdmitPlayer(
    {}, "npc_one", presentation.visitID, at
)
T.falsy(fullAdmission, fullAdmissionReason)
T.equal(fullAdmissionReason, "population_capacity_reached",
    "player colony capacity blocks admission")
T.equal(registry.npc_one.affiliation.factionID, "faction_mobile",
    "capacity rejection rolls back the faction transfer")
settlement.currentPopulation = 1

local admitted, admissionReason = Service.AdmitPlayer(
    {}, "npc_one", presentation.visitID, at
)
T.truthy(admitted, admissionReason)
T.equal(registry.npc_one.affiliation.factionID, "faction_player",
    "admission transfers the NPC into the settlement faction")
T.equal(registry.npc_one.affiliation.communityID, "community_player",
    "admission adds the NPC to the settlement community")
T.falsy(Service.GetNPCVisit("npc_one", {}, at),
    "admitted member no longer offers the same visit")
T.truthy(Service.GetNPCVisit("npc_two", {}, at),
    "remaining member keeps the one-by-one opportunity")

at = 23
T.truthy(Service.ExpireVisits(at, 4) >= 1,
    "expired visits are cleared by the bounded pump")
T.falsy(factions.faction_mobile.mobile.visit,
    "expired visit is removed from persistent mobile state")

T.equal(clearCalls, 1,
    "only the emptied AI group is cleared while player members remain pending")
return T.finish("mobile_settlement_admission_smoke")
