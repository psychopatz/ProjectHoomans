if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionTolls = PNC.FactionTolls or {}
PNC.FactionTollServiceInternal =
    PNC.FactionTollServiceInternal or {}

local Tolls = PNC.FactionTolls
local H = PNC.FactionTollServiceInternal
local Core = PNC.Core
local Const = PNC.Const
local Factions = PNC.Factions
local Communities = PNC.Communities
local EntityRef = PNC.EntityRef

local PUMP_INTERVAL_MS = 1000
local DEMAND_LIFETIME_HOURS = 0.05
local DEPARTURE_GRACE_HOURS = 0.02
local PAID_PACIFICATION_HOURS = 24

function H.RepresentativeNPCID(factionID)
    local faction = Factions.Registry.byID[factionID]
    if not faction then return nil end
    local leader = faction.leaderNPCID
        and PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(faction.leaderNPCID) or nil
    if leader and leader.alive ~= false then
        return leader.id
    end
    local members = {}
    for npcID, _ in pairs(faction.memberIDs or {}) do
        local record = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(npcID) or nil
        if record and record.alive ~= false then
            members[#members + 1] = npcID
        end
    end
    table.sort(members)
    return members[1]
end

function H.ApplyRelationshipOutcome(
    demand,
    targetKey,
    memoryType,
    approval,
    respect,
    familiarity,
    at,
    tags
)
    local observerNPCID =
        H.RepresentativeNPCID(demand.factionID)
    if not observerNPCID
        or not PNC.Relationships
        or not PNC.Relationships.ApplyEventMutation
    then
        return false
    end
    local eventID = "toll:" .. memoryType
        .. ":" .. demand.id
    return PNC.Relationships.ApplyEventMutation(
        observerNPCID,
        targetKey,
        {
            eventID = eventID,
            worldAgeHours = at,
            familiarityDelta = familiarity,
            moraleDelta = 0,
            memory = {
                id = eventID,
                type = memoryType,
                aboutKey = targetKey,
                createdAt = at,
                lastEvaluatedAt = at,
                approvalEffect = approval,
                respectEffect = respect,
                moraleEffect = 0,
                strength = 1,
                decayPerDay = 0.0075,
                permanent = false,
                shareable = true,
                knowledgeSource = "experienced",
                tags = tags,
            },
        }
    )
end

return Tolls

