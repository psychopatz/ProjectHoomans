local SHARED = "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
local DIRECTOR = "Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Director/"
local POP = DIRECTOR .. "Population/"

local function equal(actual, expected, label)
    if actual ~= expected then error((label or "equal") .. ": expected="
        .. tostring(expected) .. " actual=" .. tostring(actual)) end
end
local function truthy(value, label) equal(value == true, true, label) end
local function falsy(value, label) equal(value == false, true, label) end

local worldHour = 100
local modData = {}
local players = {}
local directorLogLines = {}
function isClient() return false end
function isServer() return true end
function getCell() return nil end
WorldGenParams = { INSTANCE = {
    getSeedString = function() return "PNC-TEST-WORLD-SEED" end,
} }
function getGameTime()
    return { getWorldAgeHours = function() return worldHour end }
end
Events = { OnInitGlobalModData = { Add = function() end },
    OnSave = { Add = function() end } }
ModData = { getOrCreate = function(key)
    modData[key] = modData[key] or {}
    return modData[key]
end }
SandboxVars = { ProjectHoomans = {
    NPCPopulation = 4, SettlementDensity = 4, RoamingGroupDensity = 4,
    PopulationRegeneration = 4, SettlementRegeneration = 4,
    MultiplayerPopulationScaling = 4, PopulationGenerationDistance = 4,
} }

PNC = {
    Core = {
        IsAuthority = function() return true end,
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, item in pairs(value) do output[key] = PNC.Core.DeepCopy(item) end
            return output
        end,
        Distance = function(x1, y1, x2, y2)
            local dx, dy = x2 - x1, y2 - y1
            return math.sqrt(dx * dx + dy * dy)
        end,
        ForEachPlayer = function(callback)
            for _, player in ipairs(players) do callback(player) end
        end,
        LogInfo = function(message)
            directorLogLines[#directorLogLines + 1] = tostring(message)
        end,
        LogWarn = function(message)
            directorLogLines[#directorLogLines + 1] = tostring(message)
        end,
    },
    Const = { PRESENCE_LIVE = "live", PRESENCE_ABSTRACT = "abstract" },
    Registry = { Data = {} },
    SpatialIndex = { UpdateNPC = function() end },
    GroupNeeds = { Ensure = function()
        return { hunger = 80, hydration = 80, fatigue = 80 }
    end },
}
function PNC.Registry.Get(id) return PNC.Registry.Data[id] end
function PNC.Registry.GetLiveZombie() return nil end
function PNC.Registry.MarkDirty() return true end

local factionSerial, communitySerial, npcSerial = 0, 0, 0
local lastMobileSpec, lastCommunitySpec
local factions, communities = {}, {}
PNC.FactionArchetypes = { Get = function(id)
    return ({ settler = true, trader = true, refugee = true, looter = true })[id]
        and { id = id } or nil
end, GetDefaultRole = function() return "resident" end }
PNC.Factions = {}
function PNC.Factions.EnsureLoaded() return true end
function PNC.Factions.Create(spec)
    factionSerial = factionSerial + 1
    local id = "faction_population_" .. factionSerial
    factions[id] = { id = id, name = spec.name, archetypeID = spec.archetypeID,
        status = "active", memberIDs = {}, tags = spec.tags or {} }
    return true, "created", PNC.Core.DeepCopy(factions[id])
end
function PNC.Factions.Get(id)
    return factions[id] and PNC.Core.DeepCopy(factions[id]) or nil
end
function PNC.Factions.List()
    local output = {}
    for _, faction in pairs(factions) do output[#output + 1] = PNC.Core.DeepCopy(faction) end
    return output
end
function PNC.Factions.IsMobileGroup(value)
    local faction = type(value) == "table" and value or factions[value]
    return faction and faction.mobile and faction.mobile.active == true or false
end
function PNC.Factions.ClearMobileGroup(id)
    if factions[id] then factions[id].mobile = nil end
    return true
end
function PNC.Factions.RemoveNPC(id, npcID)
    if factions[id] then factions[id].memberIDs[npcID] = nil end
    return true
end
function PNC.Factions.Destroy(id) factions[id] = nil return true end
function PNC.Factions.GetByArchetype() return {} end

PNC.Communities = {}
function PNC.Communities.EnsureLoaded() return true end
function PNC.Communities.List()
    local output = {}
    for _, value in pairs(communities) do output[#output + 1] = PNC.Core.DeepCopy(value) end
    return output
end
function PNC.Communities.Get(id)
    return communities[id] and PNC.Core.DeepCopy(communities[id]) or nil
end
function PNC.Communities.GetForFaction(id)
    local output = {}
    for _, value in pairs(communities) do
        if value.factionID == id then output[#output + 1] = PNC.Core.DeepCopy(value) end
    end
    return output
end
function PNC.Communities.GetSite() return nil end
function PNC.Communities.ListSites()
    local output = {}
    for _, value in pairs(communities) do output[#output + 1] = value.site end
    return output
end
function PNC.Communities.BuildSiteID(site)
    return site.id or "site_meta_" .. tostring(math.floor(site.home.x))
        .. "_" .. tostring(math.floor(site.home.y))
end

dofile(SHARED .. "Factions/PNC_FactionNameGenerator.lua")
dofile(SHARED .. "Director/PNC_DirectorConfig.lua")
dofile(SHARED .. "Director/PNC_AbstractWorldTypes.lua")
dofile(SHARED .. "Scheduling/PNC_Scheduler.lua")
dofile(DIRECTOR .. "PNC_AbstractWorldStore.lua")
dofile(DIRECTOR .. "PNC_AbstractLocationManager.lua")
dofile(DIRECTOR .. "PNC_AbstractGroupManager.lua")
dofile(POP .. "PNC_PopulationSandbox.lua")
dofile(POP .. "PNC_PopulationLog.lua")
dofile(POP .. "PNC_PopulationIdentity.lua")
dofile(POP .. "PNC_PopulationSectorManager.lua")
dofile(POP .. "PNC_PopulationBudget.lua")
dofile(POP .. "PNC_GenerationQueue.lua")
dofile(POP .. "PNC_GroupGenerationPlan.lua")
dofile(POP .. "PNC_SettlementGenerationPlan.lua")
dofile(POP .. "PNC_SettlementCandidateManager.lua")
dofile(POP .. "PNC_StarterPopulation.lua")

PNC.MobileGroupDirector = {}
function PNC.MobileGroupDirector.GenerateForFaction(factionID, spec)
    lastMobileSpec = PNC.Core.DeepCopy(spec)
    local faction = factions[factionID]
    faction.mobile = { active = true, site = PNC.Core.DeepCopy(spec.siteSpec) }
    for index = 1, spec.groupSize do
        npcSerial = npcSerial + 1
        local id = "npc_population_" .. npcSerial
        PNC.Registry.Data[id] = { id = id, alive = true,
            presenceState = "abstract", x = spec.siteSpec.home.x,
            y = spec.siteSpec.home.y, z = spec.siteSpec.home.z,
            health = { current = 100, max = 100 },
            affiliation = { role = index == 1 and "leader" or "scavenger" },
            generation = PNC.Core.DeepCopy(spec.generation) }
        faction.memberIDs[id] = true
        if index == 1 then faction.leaderNPCID = id end
    end
    return true, "mobile_group_generated", { createdCount = spec.groupSize }
end

PNC.CommunityDirector = {}
function PNC.CommunityDirector.GenerateForFaction(factionID, spec)
    lastCommunitySpec = PNC.Core.DeepCopy(spec)
    communitySerial = communitySerial + 1
    local id = "community_population_" .. communitySerial
    local members = {}
    for _ = 1, spec.groupSize do
        npcSerial = npcSerial + 1
        local npcID = "npc_population_" .. npcSerial
        PNC.Registry.Data[npcID] = { id = npcID, alive = true,
            presenceState = "abstract", generation = PNC.Core.DeepCopy(spec.generation) }
        factions[factionID].memberIDs[npcID] = true
        members[npcID] = true
    end
    communities[id] = { id = id, factionID = factionID, status = "active",
        mode = "settled", home = PNC.Core.DeepCopy(spec.siteSpec.home),
        siteID = spec.siteSpec.id, site = PNC.Core.DeepCopy(spec.siteSpec),
        memberIDs = members }
    return true, "group_generated", { communityID = id,
        createdCount = spec.groupSize }
end

PNC.API = { Despawn = function(id) PNC.Registry.Data[id] = nil return true end }
dofile(POP .. "PNC_GroupGenerator.lua")
dofile(POP .. "PNC_SettlementGenerator.lua")
dofile(POP .. "PNC_CommunityGroupFormation.lua")
dofile(POP .. "PNC_PopulationReconciler.lua")
dofile(POP .. "PNC_PopulationDirector.lua")

PNC.AbstractWorldStore.Load()
players = { { getX = function() return 0 end, getY = function() return 0 end,
    getZ = function() return 0 end } }
PNC.PopulationSectors.RefreshPlayers()
local sectorID = PNC.PopulationSectors.IDForPosition(0, 0)
local sector = PNC.PopulationSectors.Get(sectorID)
equal(PNC.PopulationSectors.ListRelevant()[1].id, sectorID,
    "active sector receives reconciliation priority")
local resolved = PNC.PopulationSandbox.Resolve()
local onePlayer = { worldAge = worldHour, resolved = resolved,
    playerCount = 1, activeSectorCount = 1 }
local normal = PNC.PopulationBudget.Calculate(sector, onePlayer)
equal(normal.groups.desired, 5, "normal group target")
equal(normal.settlements.desired, 1, "normal settlement target")

ArrayList = { new = function()
    local value = { items = {} }
    function value:add(item) self.items[#self.items + 1] = item end
    function value:size() return #self.items end
    function value:get(index) return self.items[index + 1] end
    return value
end }
local starterDefinition = {
    -- A building in the outer relevant footprint exercises the bootstrap's
    -- anti-pop-in-aware sector ordering.
    getX = function() return 1580 end,
    getY = function() return 1380 end,
    getX2 = function() return 1621 end,
    getY2 = function() return 1421 end,
    containsRoom = function(_, name)
        return name == "bedroom" or name == "kitchen"
    end,
}
local metaDefinitions = { starterDefinition }
function getWorld()
    return { getMetaGrid = function()
        return { getBuildingsIntersecting = function(_, minX, minY, maxX, maxY,
            output)
            for _, definition in ipairs(metaDefinitions) do
                local x, y = definition:getX(), definition:getY()
                if x >= minX and x <= maxX and y >= minY and y <= maxY then
                    output:add(definition)
                end
            end
        end }
    end }
end
PNC.CommunitySiteResolver = {
    IsResidentialDefinition = function() return true end,
    DescribeBuildingDefinition = function(definition, z)
        local minX, minY = definition:getX(), definition:getY()
        local maxX, maxY = definition:getX2() - 1, definition:getY2() - 1
        local site = { kind = "building", home = {
            x = (minX + maxX) / 2, y = (minY + maxY) / 2,
            z = z, radius = 12 }, bounds = { minX = minX, minY = minY,
            maxX = maxX, maxY = maxY, minZ = z, maxZ = z } }
        site.id = PNC.Communities.BuildSiteID(site)
        return site
    end,
}
local populationSeed, engineSeed = PNC.PopulationSectors.WorldSeed()
truthy(populationSeed > 0, "population seed resolves")
equal(engineSeed, "PNC-TEST-WORLD-SEED", "engine world seed retained")
local starterQueued, starterReason, starterDebug = PNC.StarterPopulation.Run(
    worldHour)
truthy(starterQueued, "starter settlement queues on an empty world: "
    .. tostring(starterReason) .. "/" .. tostring(starterDebug
        and starterDebug.discovered) .. "/" .. tostring(starterDebug
        and starterDebug.diagnostics and starterDebug.diagnostics[1]
        and starterDebug.diagnostics[1].reason))
equal(starterReason, "queued", "starter queue reason")
truthy(starterDebug.discovered > 0, "bounded meta discovery finds starter site")
equal(PNC.GenerationQueue.Snapshot(worldHour)[1].source,
    "WORLD_POPULATION_BOOTSTRAP", "starter queue provenance")
equal(PNC.GenerationQueue.Count("GROUP"), 1,
    "starter package queues one seeded roaming group")
PNC.GenerationQueue.Clear()
local groupFallbackDefinition = {
    getX = function() return -820 end,
    getY = function() return 1380 end,
    getX2 = function() return -779 end,
    getY2 = function() return 1421 end,
    containsRoom = starterDefinition.containsRoom,
}
metaDefinitions[#metaDefinitions + 1] = groupFallbackDefinition
local groupFallbackSector = PNC.PopulationSectors.IDForPosition(
    groupFallbackDefinition:getX(), groupFallbackDefinition:getY())
local fallbackGroupPlan, fallbackGroupReason = PNC.GroupGenerator.BuildPlan({
    sectorId = groupFallbackSector,
    source = "WORLD_POPULATION_DIRECTOR",
}, onePlayer)
truthy(fallbackGroupPlan ~= nil,
    "roaming group uses bounded meta fallback: " .. tostring(fallbackGroupReason))
equal(PNC.PopulationSectors.IDForPosition(
    PNC.AbstractLocations.Get(fallbackGroupPlan.locationId).x,
    PNC.AbstractLocations.Get(fallbackGroupPlan.locationId).y),
    groupFallbackSector, "fallback group site belongs to sector")
equal(PNC.SettlementCandidates.LastMetaDiscovery[groupFallbackSector].purpose,
    "GROUP_FALLBACK", "group fallback discovery is diagnosed")
local sawMetaTrace = false
for _, line in ipairs(directorLogLines) do
    if string.find(line, "event=META_SITE_DISCOVERY", 1, true)
        and string.find(line, "purpose=GROUP_FALLBACK", 1, true)
    then sawMetaTrace = true break end
end
truthy(sawMetaTrace, "bounded group discovery writes a structured trace")

PNC.GenerationQueue.Clear()
PNC.PopulationDirector.StartupGraceUntil = worldHour + 1
local startupProcessed = PNC.PopulationDirector.ProcessStarterPopulation(
    worldHour)
truthy(startupProcessed >= 2,
    "immediate starter pump commits settlement and roaming group")
equal(#PNC.Communities.List(), 1,
    "new world immediately receives one canonical settlement")
truthy(#PNC.AbstractGroups.List() >= 1,
    "new world immediately receives a seeded abstract roaming group")
truthy(PNC.StarterPopulation.GetDebugSnapshot().completed,
    "starter completion is recorded by the immediate pump")

-- Return to a clean world for the remaining focused transaction tests.
factions, communities = {}, {}
PNC.Registry.Data = {}
PNC.AbstractWorldStore.Registry = PNC.AbstractWorldTypes.NewRegistry()
PNC.AbstractWorldStore.Loaded = true
PNC.AbstractWorldStore.Dirty = false
PNC.AbstractLocations.Cells, PNC.AbstractLocations.Membership = {}, {}
PNC.AbstractLocations.IndexedRevision = -1
PNC.AbstractLocations.RebuildIndex()
PNC.PopulationSectors.Runtime, PNC.PopulationSectors.GroupIDs = {}, {}
PNC.PopulationSectors.CommunityIDs, PNC.PopulationSectors.GroupSector = {}, {}
PNC.PopulationSectors.CommunitySector = {}
PNC.PopulationSectors.PlayerPositions = {}
PNC.SettlementCandidates.Pools = {}
PNC.SettlementCandidates.Reservations = {}
PNC.GenerationQueue.Clear()
PNC.PopulationDirector.Initialized = false
PNC.StarterPopulation.LastRun = nil
PNC.PopulationSectors.RefreshPlayers()
sectorID = PNC.PopulationSectors.IDForPosition(0, 0)
sector = PNC.PopulationSectors.Get(sectorID)
local resetSeed = PNC.PopulationSectors.WorldSeed()
equal(resetSeed, populationSeed, "reset retains deterministic engine seed")
truthy(PNC.StarterPopulation.Run(worldHour),
    "clean test world can queue its starter package")
PNC.GenerationQueue.Clear()

equal(PNC.GroupGenerator.ChooseArchetype(sectorID, worldHour, 4567),
    PNC.GroupGenerator.ChooseArchetype(sectorID, worldHour, 4567),
    "archetype selection is seed deterministic")
local seededGroupTypes, seededSettlementTypes = {}, {}
for seed = 1, 64 do
    seededGroupTypes[PNC.GroupGenerator.ChooseArchetype(
        sectorID, worldHour, seed)] = true
    local _, factionType = PNC.SettlementGenerator.ChooseFaction(seed)
    seededSettlementTypes[factionType] = true
end
local groupTypeCount, settlementTypeCount = 0, 0
for _ in pairs(seededGroupTypes) do groupTypeCount = groupTypeCount + 1 end
for _ in pairs(seededSettlementTypes) do
    settlementTypeCount = settlementTypeCount + 1
end
truthy(groupTypeCount > 1, "world seeds vary roaming archetypes")
truthy(settlementTypeCount > 1, "world seeds vary settlement archetypes")

for index = 1, normal.groups.lowerThreshold do
    local id = "agroup_hysteresis_" .. index
    PNC.AbstractWorldStore.Registry.groupsByID[id] =
        PNC.AbstractWorldTypes.NormalizeGroup({ id = id, groupType = "SCAVENGER",
            memberIds = {}, state = "IDLE", mission = "SCAVENGE",
            location = PNC.AbstractLocations.Ref({ id = "aloc_hysteresis",
                type = "TEMPORARY", x = 10, y = 10, z = 0 }) }, id)
    -- Normalization requires the location record only as a stable reference;
    -- the population index remains the tested source of counts here.
    PNC.PopulationSectors.RegisterGroup(PNC.AbstractWorldStore.Registry.groupsByID[id])
end
local healthyBand = PNC.PopulationBudget.Calculate(
    PNC.PopulationSectors.Get(sectorID), onePlayer)
equal(healthyBand.groups.deficit, 0, "healthy lower band suppresses generation")
local removedHysteresis = "agroup_hysteresis_" .. normal.groups.lowerThreshold
PNC.AbstractWorldStore.Registry.groupsByID[removedHysteresis] = nil
PNC.PopulationSectors.UnregisterGroup(removedHysteresis)
local belowBand = PNC.PopulationBudget.Calculate(
    PNC.PopulationSectors.Get(sectorID), onePlayer)
truthy(belowBand.groups.deficit > 0, "below healthy band generates pressure")
for index = 1, normal.groups.lowerThreshold - 1 do
    local id = "agroup_hysteresis_" .. index
    PNC.AbstractWorldStore.Registry.groupsByID[id] = nil
    PNC.PopulationSectors.UnregisterGroup(id)
end

SandboxVars.ProjectHoomans.NPCPopulation = 5
local high = PNC.PopulationBudget.Calculate(sector, {
    worldAge = worldHour, resolved = PNC.PopulationSandbox.Resolve(),
    playerCount = 1, activeSectorCount = 1 })
truthy(high.groups.desired > normal.groups.desired, "high target increases")
SandboxVars.ProjectHoomans.NPCPopulation = 1
local disabled = PNC.PopulationBudget.Calculate(sector, {
    worldAge = worldHour, resolved = PNC.PopulationSandbox.Resolve(),
    playerCount = 1, activeSectorCount = 1 })
equal(disabled.groups.desired, 0, "disabled group target")
equal(disabled.settlements.desired, 0, "disabled settlement target")
SandboxVars.ProjectHoomans.NPCPopulation = 4

local scaleOne = PNC.PopulationBudget.MultiplayerFactor(1, 1, resolved)
local scaleFourTogether = PNC.PopulationBudget.MultiplayerFactor(4, 1, resolved)
local scaleFourSpread = PNC.PopulationBudget.MultiplayerFactor(4, 4, resolved)
truthy(scaleFourTogether > scaleOne, "multiplayer grows")
truthy(scaleFourTogether < 4, "multiplayer is sublinear")
truthy(scaleFourSpread > scaleFourTogether, "spread footprint grows more")

local location = assert(PNC.AbstractLocations.RegisterSite({
    id = "site_population_valid", kind = "building",
    home = { x = 700, y = 100, z = 0, radius = 12 },
    bounds = { minX = 690, minY = 90, maxX = 710, maxY = 110,
        minZ = 0, maxZ = 0 } }, { tags = { HOUSE = true, RURAL = true },
        resourcePotential = { food = 60, water = 60 } }))
PNC.SettlementCandidates.RegisterLocation(location)

local queued = PNC.GenerationQueue.Enqueue("GROUP", { sectorId = sectorID }, worldHour)
truthy(queued, "group queued")
local duplicate, duplicateReason = PNC.GenerationQueue.Enqueue("GROUP",
    { sectorId = sectorID }, worldHour)
falsy(duplicate, "queue duplicate rejected")
equal(duplicateReason, "queue_duplicate", "queue duplicate reason")
PNC.GenerationQueue.Clear()
PNC.GenerationQueue.Enqueue("GROUP", { sectorId = sectorID,
    qualifier = "retry_bound" }, worldHour)
local retryItem = PNC.GenerationQueue.Pop("GROUP", worldHour)
truthy(PNC.GenerationQueue.Retry(retryItem, worldHour), "first retry accepted")
retryItem = PNC.GenerationQueue.Pop("GROUP", worldHour)
truthy(PNC.GenerationQueue.Retry(retryItem, worldHour), "second retry accepted")
retryItem = PNC.GenerationQueue.Pop("GROUP", worldHour)
local retryAllowed, retryReason = PNC.GenerationQueue.Retry(retryItem, worldHour)
falsy(retryAllowed, "retry attempt bound")
equal(retryReason, "attempt_limit", "retry bound reason")
PNC.GenerationQueue.Clear()
for index = 1, PNC.DirectorConfig.Population.HARD_MAX_GENERATION_QUEUE + 10 do
    PNC.GenerationQueue.Enqueue("GROUP", { sectorId = sectorID,
        qualifier = tostring(index) }, worldHour)
end
equal(PNC.GenerationQueue.Count("GROUP"),
    PNC.DirectorConfig.Population.HARD_MAX_GENERATION_QUEUE,
    "queue hard bound")
PNC.GenerationQueue.Clear()

local oldLooter = PNC.DirectorConfig.Population.GROUP_ARCHETYPE_WEIGHTS.LOOTER
local oldScavenger = PNC.DirectorConfig.Population.GROUP_ARCHETYPE_WEIGHTS.SCAVENGER
PNC.DirectorConfig.Population.GROUP_ARCHETYPE_WEIGHTS.LOOTER = 0.80
PNC.DirectorConfig.Population.GROUP_ARCHETYPE_WEIGHTS.SCAVENGER = 0.20
equal(PNC.GroupGenerator.ChooseArchetype(sectorID, worldHour, 123), "LOOTER",
    "underrepresented weighted archetype wins")
PNC.DirectorConfig.Population.GROUP_ARCHETYPE_WEIGHTS.LOOTER = oldLooter
PNC.DirectorConfig.Population.GROUP_ARCHETYPE_WEIGHTS.SCAVENGER = oldScavenger

local groupPlan = assert(PNC.GroupGenerator.BuildPlan({ sectorId = sectorID }, onePlayer))
truthy(PNC.GroupGenerator.Validate(groupPlan, onePlayer), "group plan validates")
local groupResult = PNC.GroupGenerator.Commit(groupPlan, onePlayer)
truthy(groupResult.ok, "group transaction commits")
equal(lastMobileSpec.presenceMode, "auto",
    "director mobile group uses canonical auto presence")
truthy(lastMobileSpec.allowLive,
    "director mobile group remains eligible for live materialization")
truthy(PNC.Factions.Get(groupResult.group.factionId).tags.mobileGroup,
    "director mobile faction receives canonical metadata tags")
falsy(string.find(PNC.Factions.Get(groupResult.group.factionId).name,
    "Population ", 1, true) == 1,
    "director mobile faction uses canonical generated naming")
truthy(PNC.AbstractGroups.Get(groupResult.group.id) ~= nil,
    "canonical abstract group registered")
equal(#groupResult.group.memberIds, groupPlan.memberCount, "canonical NPC membership")
equal(groupResult.group.generation.generationId, groupPlan.generationId,
    "group provenance")
local duplicateCommit = PNC.GroupGenerator.Commit(groupPlan, onePlayer)
falsy(duplicateCommit.ok, "generation idempotency")
equal(duplicateCommit.reason, "GENERATION_ID_DUPLICATE", "idempotency reason")

local nearPlan = PNC.Core.DeepCopy(groupPlan)
nearPlan.generationId = "POP_GROUP_9999999"
nearPlan.locationId = location.id
PNC.PopulationSectors.Ensure(sectorID).groupGenerationCooldownUntil = 0
players = { { getX = function() return 700 end, getY = function() return 100 end,
    getZ = function() return 0 end } }
PNC.PopulationSectors.RefreshPlayers()
local nearValid, nearReason = PNC.GroupGenerator.Validate(nearPlan, onePlayer)
falsy(nearValid, "player proximity race rejects")
equal(nearReason, "PLAYER_TOO_CLOSE", "player proximity reason")
players = { { getX = function() return 0 end, getY = function() return 0 end,
    getZ = function() return 0 end } }
PNC.PopulationSectors.RefreshPlayers()

local candidate = PNC.SettlementCandidates.Evaluate(location, "settler", resolved, worldHour)
truthy(candidate.eligible, "valid settlement candidate")
truthy(candidate.score > 0, "candidate score exposed")
local commercialLocation = assert(PNC.AbstractLocations.RegisterSite({
    id = "site_population_commercial", kind = "building",
    home = { x = 700, y = 220, z = 0, radius = 12 },
    bounds = { minX = 690, minY = 210, maxX = 710, maxY = 230,
        minZ = 0, maxZ = 0 } }, { tags = { COMMERCIAL = true },
        resourcePotential = { food = 60, water = 60 } }))
PNC.SettlementCandidates.RegisterLocation(commercialLocation)
local commercialScore = PNC.SettlementCandidates.Evaluate(
    commercialLocation, "settler", resolved, worldHour)
truthy(candidate.score > commercialScore.score,
    "faction-preferred rural location scores higher")
PNC.AbstractWorldStore.Registry.population.siteHistory[location.id] = {
    formerSettlement = true, destroyedAt = worldHour,
    regenerationBlockedUntil = worldHour + 24 }
local blocked = PNC.SettlementCandidates.Evaluate(location, "settler", resolved, worldHour)
falsy(blocked.eligible, "destroyed site blocked")
equal(blocked.reason, "DESTROYED_SITE_COOLDOWN", "site cooldown reason")
PNC.AbstractWorldStore.Registry.population.siteHistory[location.id] = nil

local racePlan = assert(PNC.SettlementGenerator.BuildPlan(
    { sectorId = sectorID }, onePlayer))
players = { { getX = function() return 700 end, getY = function() return 100 end,
    getZ = function() return 0 end } }
PNC.PopulationSectors.RefreshPlayers()
local communitiesBeforeRace = #PNC.Communities.List()
local raceResult = PNC.SettlementGenerator.Commit(racePlan, onePlayer)
falsy(raceResult.ok, "settlement player race rejected")
equal(raceResult.reason, "PLAYER_TOO_CLOSE", "settlement race reason")
equal(#PNC.Communities.List(), communitiesBeforeRace,
    "failed settlement creates no community")
falsy(PNC.SettlementCandidates.HasReservation(
    racePlan.locationId, racePlan.generationId, worldHour),
    "failed settlement releases reservation")
players = { { getX = function() return 0 end, getY = function() return 0 end,
    getZ = function() return 0 end } }
PNC.PopulationSectors.RefreshPlayers()

local settlementPlan = assert(PNC.SettlementGenerator.BuildPlan(
    { sectorId = sectorID }, onePlayer))
truthy(PNC.SettlementGenerator.Validate(settlementPlan, onePlayer),
    "settlement plan validates")
local settlementResult = PNC.SettlementGenerator.Commit(settlementPlan, onePlayer)
truthy(settlementResult.ok, "settlement transaction commits")
equal(lastCommunitySpec.presenceMode, "auto",
    "director settlement uses canonical auto presence")
truthy(lastCommunitySpec.allowLive,
    "director settlement remains eligible for live materialization")
falsy(string.find(PNC.Factions.Get(settlementResult.community.factionID).name,
    "Population ", 1, true) == 1,
    "director settlement faction uses canonical generated naming")
truthy(PNC.Communities.Get(settlementResult.community.id) ~= nil,
    "canonical community registered")
local settlementLocation = PNC.AbstractLocations.Get(settlementPlan.locationId)
equal(settlementResult.community.siteID, settlementLocation.sourceSite.id,
    "canonical site reserved")
equal(PNC.PopulationSectors.CountSettlements(sectorID), 1,
    "settlement index updated")
local settlementDuplicate = PNC.SettlementGenerator.Commit(settlementPlan, onePlayer)
falsy(settlementDuplicate.ok, "settlement idempotency")

local closeLocation = assert(PNC.AbstractLocations.RegisterSite({
    id = "site_population_close", kind = "building",
    home = { x = 780, y = 100, z = 0, radius = 10 },
    bounds = { minX = 775, minY = 95, maxX = 785, maxY = 105,
        minZ = 0, maxZ = 0 } }))
local closeCandidate = PNC.SettlementCandidates.Evaluate(
    closeLocation, "settler", resolved, worldHour)
falsy(closeCandidate.eligible, "settlement spacing rejects candidate")
equal(closeCandidate.reason, "TOO_CLOSE_TO_EXISTING_SETTLEMENT",
    "settlement spacing reason")

local npcCountBeforeParty = 0
for _ in pairs(PNC.Registry.Data) do npcCountBeforeParty = npcCountBeforeParty + 1 end
local oldCommunityMinimum = PNC.DirectorConfig.Population.COMMUNITY_GROUP_MIN_POPULATION
PNC.DirectorConfig.Population.COMMUNITY_GROUP_MIN_POPULATION = 4
local formed, formedReason, party = PNC.CommunityGroupFormation.Try(
    settlementResult.community, worldHour)
truthy(formed, "community party formed from reusable members")
equal(formedReason, "COMMUNITY_GROUP_CREATED", "community formation reason")
equal(party.homeCommunityId, settlementResult.community.id,
    "community party ownership")
equal(#party.memberIds, PNC.DirectorConfig.Population.COMMUNITY_GROUP_SIZE,
    "community party reuses bounded membership")
local npcCountAfterParty = 0
for _ in pairs(PNC.Registry.Data) do npcCountAfterParty = npcCountAfterParty + 1 end
equal(npcCountAfterParty, npcCountBeforeParty,
    "community group formation creates no NPC records")
PNC.DirectorConfig.Population.COMMUNITY_GROUP_MIN_POPULATION = oldCommunityMinimum

PNC.PopulationDirector.LastResolved = resolved
PNC.PopulationDirector.OnSettlementDestroyed(
    settlementResult.community, "test_destroyed", worldHour)
truthy(PNC.PopulationSectors.Ensure(sectorID)
    .settlementGenerationCooldownUntil > worldHour,
    "settlement regeneration cooldown")
truthy(PNC.AbstractWorldStore.Registry.population.siteHistory[settlementLocation.id]
    .regenerationBlockedUntil > worldHour, "destroyed site history")

local existingGroups = #PNC.AbstractGroups.List()
SandboxVars.ProjectHoomans.NPCPopulation = 1
local lowered = PNC.PopulationBudget.Calculate(PNC.PopulationSectors.Get(sectorID), {
    worldAge = worldHour, resolved = PNC.PopulationSandbox.Resolve(),
    playerCount = 1, activeSectorCount = 1 })
equal(lowered.groups.deficit, 0, "lowered population suppresses generation")
equal(#PNC.AbstractGroups.List(), existingGroups, "lowered population deletes nothing")
SandboxVars.ProjectHoomans.NPCPopulation = 4

truthy(PNC.AbstractWorldStore.Save(), "population state saves")
PNC.AbstractWorldStore.Registry = {}
PNC.AbstractWorldStore.Loaded = false
truthy(PNC.AbstractWorldStore.Load(), "population state reloads")
truthy(PNC.AbstractWorldStore.Registry.population.committedGenerationIds[
    groupPlan.generationId] == true, "committed id persisted")
equal(PNC.AbstractWorldStore.Registry.population.worldSeedString,
    "PNC-TEST-WORLD-SEED", "engine world seed string persists")
equal(PNC.AbstractWorldStore.Registry.population.worldSeed, populationSeed,
    "hashed population seed persists")
truthy((PNC.AbstractWorldStore.Registry.population.starterAttempts or 0) > 0,
    "starter attempt diagnostics persist")

players = { { getX = function() return 0 end, getY = function() return 0 end,
    getZ = function() return 0 end } }
PNC.Registry.Data.npc_legacy_population = {
    id = "npc_legacy_population", alive = true, presenceState = "abstract",
    generation = { source = "WORLD_POPULATION_DIRECTOR" },
    runtime = { forceAbstract = true }, x = 10, y = 10, z = 0,
}
truthy(PNC.PopulationDirector.Initialize(true), "population director initializes")
falsy(PNC.Registry.Data.npc_legacy_population.runtime.forceAbstract == true,
    "legacy director NPC is released to normal presence materialization")
equal(PNC.PopulationDirector.BootstrapPhase, "WAITING_DRY",
    "bootstrap begins with grace")
PNC.Scheduler.PumpJobs(PNC.PopulationDirector.StartupGraceUntil - 0.01)
equal(PNC.PopulationDirector.BootstrapPhase, "WAITING_DRY",
    "startup grace prevents reconciliation")
PNC.Scheduler.PumpJobs(PNC.PopulationDirector.StartupGraceUntil)
equal(PNC.PopulationDirector.BootstrapPhase, "WAITING_GENERATION",
    "first post-grace reconciliation is dry")
equal(PNC.GenerationQueue.Count("GROUP"), 0,
    "dry bootstrap does not queue groups")
equal(PNC.GenerationQueue.Count("SETTLEMENT"), 0,
    "dry bootstrap does not queue settlements")
PNC.Scheduler.PumpJobs(PNC.PopulationDirector.StartupGraceUntil
    + PNC.DirectorConfig.Population.BOOTSTRAP_RECONCILE_DELAY_HOURS)
equal(PNC.PopulationDirector.BootstrapPhase, "COMPLETE",
    "live bootstrap follows dry reconciliation")
truthy(#PNC.PopulationLog.GetEntries() > 0, "director log keeps entries")
truthy(string.find(directorLogLines[1] or "", "%[PopulationDirector%]") ~= nil,
    "director log uses searchable prefix")

local stressStarted = os.clock()
PNC.GenerationQueue.Clear()
PNC.PopulationSectors.RebuildIndexes()
for sectorIndex = 1, 40 do
    local stressSectorID = "psector_" .. tostring(sectorIndex) .. "_10"
    PNC.PopulationSectors.MarkRelevant(stressSectorID, true)
    for groupIndex = 1, 3 do
        local id = "agroup_stress_" .. tostring(sectorIndex) .. "_"
            .. tostring(groupIndex)
        local x, y = sectorIndex * 1000 + groupIndex * 10, 10100
        local group = PNC.AbstractWorldTypes.NormalizeGroup({ id = id,
            groupType = groupIndex == 1 and "LOOTER" or "SCAVENGER",
            memberIds = {}, state = "IDLE", mission = "SCAVENGE",
            location = { id = "aloc_stress_" .. sectorIndex .. "_" .. groupIndex,
                type = "TEMPORARY", x = x, y = y, z = 0 } }, id)
        PNC.AbstractWorldStore.Registry.groupsByID[id] = group
        PNC.PopulationSectors.RegisterGroup(group)
    end
end
players = {
    { getX = function() return 1000 end, getY = function() return 10000 end,
        getZ = function() return 0 end },
    { getX = function() return 10000 end, getY = function() return 10000 end,
        getZ = function() return 0 end },
    { getX = function() return 20000 end, getY = function() return 10000 end,
        getZ = function() return 0 end },
    { getX = function() return 40000 end, getY = function() return 10000 end,
        getZ = function() return 0 end },
}
PNC.PopulationSectors.RefreshPlayers()
local stressContext = { worldAge = worldHour, resolved = resolved,
    playerCount = 4, activeSectorCount = 4 }
for _ = 1, 20 do
    PNC.PopulationReconciler.Run("GROUP", worldHour,
        PNC.DirectorConfig.Population.RECONCILE_SECTOR_BUDGET,
        stressContext, false)
end
truthy(PNC.GenerationQueue.Count("GROUP")
    <= PNC.DirectorConfig.Population.HARD_MAX_GENERATION_QUEUE,
    "stress queue stays bounded")
truthy(PNC.PopulationSectors.Repair(16) <= 16,
    "stress index repair stays budgeted")
truthy(os.clock() - stressStarted < 5, "stress accounting remains inexpensive")

print("pnc_population_director_smoke: ok")
