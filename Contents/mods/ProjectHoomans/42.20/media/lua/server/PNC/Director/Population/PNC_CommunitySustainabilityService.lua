-- Round-robin, O(1)-per-tick settlement supply sustainability & emergent collapse.
-- Scavengers returning home deposit carriedSupplies into their home settlement's
-- abstracted resources; settlements consume food/water per resident per day.
-- When supplies run dry for 48+ hours, the settlement collapses, unregisters its
-- Tier-1 CorridorGraph hub, publishes a Core WorldEvent, and airs a radio alert.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CommunitySustainabilityService = PNC.CommunitySustainabilityService or {}

local Service = PNC.CommunitySustainabilityService

Service.FOOD_PER_RESIDENT_PER_DAY = 0.80
Service.WATER_PER_RESIDENT_PER_DAY = 0.60
Service.MIN_TICK_DELTA_HOURS = 6.0
Service.STARVATION_COLLAPSE_HOURS = 48.0
Service.DEFAULT_BATCH_BUDGET = 2
Service.DEFAULT_INITIAL_FOOD = 40.0
Service.DEFAULT_INITIAL_WATER = 40.0
Service.DEFAULT_INITIAL_SUPPLIES = 25.0
Service._cursor = Service._cursor or 0
Service._registeredPlayerBases = Service._registeredPlayerBases or {}
Service._baseSyncCounter = Service._baseSyncCounter or 0

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return tonumber(fallback) or 0
    end
    return value
end

local function ensureResources(community)
    if type(community) ~= "table" then return nil end
    community.resources = type(community.resources) == "table" and community.resources or {}
    if community.resources.food == nil then
        community.resources.food = Service.DEFAULT_INITIAL_FOOD
    end
    if community.resources.water == nil then
        community.resources.water = Service.DEFAULT_INITIAL_WATER
    end
    if community.resources.supplies == nil then
        community.resources.supplies = Service.DEFAULT_INITIAL_SUPPLIES
    end
    return community.resources
end

local function residentCount(community)
    if type(community) ~= "table" then return 0 end
    if type(community.memberIds) == "table" and #community.memberIds > 0 then
        return #community.memberIds
    end
    if type(community.roster) == "table" and #community.roster > 0 then
        return #community.roster
    end
    return math.max(1, math.floor(finite(community.population or community.residentCount, 3)))
end

local function isPlayerOwnedCommunity(community)
    if type(community) ~= "table" then return false end
    return community.owner == "player"
        or community.isPlayerBase == true
        or community.playerOwned == true
        or community.claimantKey ~= nil
end

function Service.DepositScavengerSupplies(group, at)
    if type(group) ~= "table" or not group.homeCommunityId then
        return false, "no_home_community"
    end
    local carried = math.max(0, finite(group.carriedSupplies, 0))
    if carried <= 0 then
        return false, "no_carried_supplies"
    end
    local community = PNC.Communities and type(PNC.Communities.Get) == "function"
        and PNC.Communities.Get(group.homeCommunityId) or nil
    if not community or community.status == "COLLAPSED" then
        return false, "community_unavailable"
    end
    local res = ensureResources(community)
    res.food = finite(res.food, 0) + carried * 0.60
    res.water = finite(res.water, 0) + carried * 0.25
    res.supplies = finite(res.supplies, 0) + carried * 0.15
    community.lastSupplyDepositAt = finite(at, 0)
    if res.food > 5 and res.water > 5 then
        community.starvationHours = math.max(0, finite(community.starvationHours, 0) - 12)
    end
    group.carriedSupplies = 0
    return true, {
        communityId = community.id,
        deposited = carried,
        food = res.food,
        water = res.water,
        supplies = res.supplies,
    }
end

local function collapseCommunity(community, at)
    community.status = "COLLAPSED"
    community.collapsedAt = finite(at, 0)
    community.collapseReason = "supply_exhaustion"

    local home = type(community.home) == "table" and community.home or {}
    local cx = finite(home.x, 0)
    local cy = finite(home.y, 0)
    local cz = finite(home.z, 0)

    local sw = PsychopatzCore and PsychopatzCore.SurvivorWorld or nil
    if sw and sw.CorridorGraph and type(sw.CorridorGraph.UnregisterSettlementNode) == "function" then
        sw.CorridorGraph.UnregisterSettlementNode(community.id)
    end
    if sw and sw.Events and type(sw.Events.Publish) == "function" then
        sw.Events.Publish({
            id = "settlement_collapsed:" .. tostring(community.id),
            kind = "SETTLEMENT_COLLAPSED",
            ownerMod = "ProjectHoomans",
            x = cx,
            y = cy,
            z = cz,
            createdAt = finite(at, 0),
            ttlHours = 72,
            summary = tostring(community.name or community.id) .. " collapsed from supply exhaustion",
            metadata = {
                communityId = community.id,
                reason = "supply_exhaustion",
            },
        })
    end
    if PNC.AbstractAftermathService
        and type(PNC.AbstractAftermathService.BroadcastRadioNotice) == "function"
    then
        pcall(
            PNC.AbstractAftermathService.BroadcastRadioNotice,
            "SETTLEMENT_COLLAPSED",
            cx,
            cy,
            tostring(community.name or "A nearby settlement")
                .. " has run out of food and disbanded — refugees spotted heading out."
        )
    end
    -- Spawn a displaced Refugee group from surviving residents, migrating toward
    -- the nearest healthy settlement (including the player's base).
    local members = type(community.memberIds) == "table" and community.memberIds or nil
    if members and #members > 0 and PNC.AbstractGroups
        and type(PNC.AbstractGroups.Create) == "function"
    then
        local okCreate, refGroup = pcall(PNC.AbstractGroups.Create, {
            id = "displaced_refugees:" .. tostring(community.id),
            groupType = "REFUGEE",
            factionId = community.factionId,
            memberIds = members,
            location = { id = "collapsed:" .. tostring(community.id), x = cx, y = cy, z = cz },
            mission = "SCAVENGE",
            resources = { food = 4, water = 4, supplies = 5 },
            displacedFromSettlement = true,
            formerSettlementId = community.id,
        }, finite(at, 0))
        if okCreate and type(refGroup) == "table" then
            community.displacedGroupId = refGroup.id
        end
    end
    return true
end

function Service.TickCommunity(community, at)
    if type(community) ~= "table" then return false, "invalid_community" end
    if community.status == "COLLAPSED" or isPlayerOwnedCommunity(community) then
        return false, "skipped"
    end
    at = finite(at, 0)
    local lastAt = finite(community.lastSustainabilityTickAt, at)
    local deltaHours = math.max(0, at - lastAt)
    if community.lastSustainabilityTickAt == nil then
        ensureResources(community)
        community.lastSustainabilityTickAt = at
        return true, "initialized"
    end
    if deltaHours < Service.MIN_TICK_DELTA_HOURS then
        return false, "cadence_wait"
    end
    community.lastSustainabilityTickAt = at

    local res = ensureResources(community)
    local residents = residentCount(community)
    local deltaDays = deltaHours / 24.0
    res.food = math.max(0, finite(res.food, 0) - residents * Service.FOOD_PER_RESIDENT_PER_DAY * deltaDays)
    res.water = math.max(0, finite(res.water, 0) - residents * Service.WATER_PER_RESIDENT_PER_DAY * deltaDays)

    local foodRatio = math.max(0, math.min(1, res.food / math.max(1, Service.DEFAULT_INITIAL_FOOD)))
    local waterRatio = math.max(0, math.min(1, res.water / math.max(1, Service.DEFAULT_INITIAL_WATER)))
    local demandLevel = (foodRatio <= 0.10 or waterRatio <= 0.10) and "critical"
        or ((foodRatio < 0.30 or waterRatio < 0.30) and "shortage" or "normal")

    local sw = PsychopatzCore and PsychopatzCore.SurvivorWorld or nil
    if sw and sw.CorridorGraph and type(sw.CorridorGraph.UpdateSettlementState) == "function" then
        sw.CorridorGraph.UpdateSettlementState(community.id, {
            foodRatio = foodRatio,
            waterRatio = waterRatio,
            demandLevel = demandLevel,
            population = residents,
        })
    end
    if demandLevel ~= "normal" and community._lastShortageNoticeLevel ~= demandLevel then
        community._lastShortageNoticeLevel = demandLevel
        if sw and sw.Events and type(sw.Events.Publish) == "function" then
            local home = type(community.home) == "table" and community.home or {}
            sw.Events.Publish({
                id = "supply_shortage:" .. tostring(community.id),
                kind = "SUPPLY_SHORTAGE",
                ownerMod = "ProjectHoomans",
                x = finite(home.x, 0),
                y = finite(home.y, 0),
                z = finite(home.z, 0),
                createdAt = at,
                ttlHours = 36,
                summary = tostring(community.name or community.id) .. " needs food/water (" .. demandLevel .. ")",
                tags = { trade_demand = true, supply_shortage = true },
            }, at)
        end
    elseif demandLevel == "normal" then
        community._lastShortageNoticeLevel = nil
    end

    if res.food <= 0.01 or res.water <= 0.01 then
        community.starvationHours = finite(community.starvationHours, 0) + deltaHours
        if community.starvationHours >= Service.STARVATION_COLLAPSE_HOURS then
            collapseCommunity(community, at)
            return true, "collapsed"
        end
        return true, "starving"
    end

    if res.food >= 10 and res.water >= 10 then
        community.starvationHours = 0
    end
    return true, "sustained"
end

-- Lazily registers active player bases as Tier-1 corridor gravity hubs in Core
-- so traders, refugees, and looters naturally weave around player settlements.
function Service.SyncPlayerBaseHubs()
    local BaseService = PNC.BaseService
    local Candidates = PNC.SettlementCandidates
    if not BaseService or not Candidates
        or type(Candidates.RegisterPlayerBaseHub) ~= "function"
    then
        return 0
    end
    local bases = type(BaseService.GetAll) == "function" and BaseService.GetAll()
        or (type(BaseService.List) == "function" and BaseService.List()) or nil
    if type(bases) ~= "table" then return 0 end
    local registered = 0
    for _, base in pairs(bases) do
        if type(base) == "table" and base.id and not Service._registeredPlayerBases[base.id] then
            local snap = type(BaseService.BuildSnapshot) == "function"
                and BaseService.BuildSnapshot(base) or nil
            local bounds = snap and snap.geometry and snap.geometry.bounds or nil
            local bx = bounds and ((bounds.minX + bounds.maxX) * 0.5) or tonumber(base.x)
            local by = bounds and ((bounds.minY + bounds.maxY) * 0.5) or tonumber(base.y)
            local bz = bounds and tonumber(bounds.minZ) or tonumber(base.z) or 0
            if bx and by then
                local node = Candidates.RegisterPlayerBaseHub(
                    "player_base:" .. tostring(base.id),
                    bx,
                    by,
                    bz,
                    tostring(base.name or "Player Base")
                )
                if node then
                    Service._registeredPlayerBases[base.id] = true
                    registered = registered + 1
                end
            end
        end
    end
    return registered
end

function Service.TickBatch(at, budget)
    Service._baseSyncCounter = (Service._baseSyncCounter or 0) + 1
    if Service._baseSyncCounter == 1 or (Service._baseSyncCounter % 12) == 0 then
        Service.SyncPlayerBaseHubs()
    end
    if not PNC.Communities or type(PNC.Communities.List) ~= "function" then
        return 0
    end
    local list = PNC.Communities.List() or {}
    local total = #list
    if total == 0 then return 0 end
    budget = math.max(1, math.floor(tonumber(budget) or Service.DEFAULT_BATCH_BUDGET))
    local processed = 0
    local visited = 0
    while processed < budget and visited < total do
        Service._cursor = (Service._cursor % total) + 1
        local comm = list[Service._cursor]
        local ok = Service.TickCommunity(comm, at)
        if ok then
            processed = processed + 1
        end
        visited = visited + 1
    end
    return processed
end

return Service
