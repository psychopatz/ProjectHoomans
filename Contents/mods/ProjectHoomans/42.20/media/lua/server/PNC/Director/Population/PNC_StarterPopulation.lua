-- Seeded one-time starter settlement bootstrap for otherwise empty worlds.

if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.StarterPopulation = PNC.StarterPopulation or {}

local Starter = PNC.StarterPopulation
local Config = PNC.DirectorConfig.Population
local Store = PNC.AbstractWorldStore
local Sectors = PNC.PopulationSectors
local Candidates = PNC.SettlementCandidates
local Queue = PNC.GenerationQueue
local Log = PNC.PopulationLog

Starter.LastRun = Starter.LastRun or nil

local function data()
    Store.EnsureLoaded()
    return Store.Registry.population
end

local function activeSettlement()
    for _, community in ipairs(PNC.Communities.List()) do
        if community.status == "active" and community.mode ~= "nomadic" then
            return community
        end
    end
    return nil
end

function Starter.IsPending()
    return data().bootstrapCompleted ~= true
end

function Starter.Initialize(now)
    local population = data()
    local existing = activeSettlement()
    local seed, seedString = Sectors.WorldSeed()
    if existing and population.bootstrapCompleted ~= true then
        population.bootstrapCompleted = true
        population.bootstrapCompletedAt = tonumber(now) or Store.WorldAgeHours()
        population.starterSettlementId = existing.id
        Store.Touch("population_starter_adopted")
        Log.Info("STARTER_SETTLEMENT_ADOPTED", { communityId = existing.id,
            populationSeed = seed, worldSeed = seedString })
    end
    return population.bootstrapCompleted ~= true
end

function Starter.MarkCommitted(community, now)
    if not community then return false end
    local population = data()
    population.bootstrapCompleted = true
    population.bootstrapCompletedAt = tonumber(now) or Store.WorldAgeHours()
    population.starterSettlementId = community.id
    Store.Touch("population_starter_completed")
    local memberCount = 0
    for _ in pairs(community.memberIDs or {}) do memberCount = memberCount + 1 end
    Log.Info("STARTER_SETTLEMENT_READY", { communityId = community.id,
        factionId = community.factionID,
        sectorId = Sectors.IDForPosition(community.home.x, community.home.y),
        population = memberCount })
    return true
end

function Starter.Run(now, force)
    now = tonumber(now) or Store.WorldAgeHours()
    local population = data()
    local existing = activeSettlement()
    if existing then
        Starter.MarkCommitted(existing, now)
        return true, "starter_already_present", { communityId = existing.id }
    end
    if population.bootstrapCompleted == true and force ~= true then
        return false, "starter_completed"
    end
    local resolved = PNC.PopulationSandbox.Resolve()
    if not resolved.enabled or not resolved.settlementsEnabled then
        return false, "settlement_generation_disabled"
    end
    local sectors = Sectors.ListRelevant()
    if #sectors == 0 or #Sectors.PlayerPositions == 0 then
        return false, "no_active_population_sector"
    end
    population.starterAttempts = (tonumber(population.starterAttempts) or 0) + 1
    Store.Touch("population_starter_attempt")
    local worldSeed, seedString = Sectors.WorldSeed()
    -- Prefer the outer part of the player's relevant footprint so a freshly
    -- discovered house can also pass the anti-pop-in distance rule. Equal
    -- distances are shuffled deterministically by the world's seed/attempt.
    table.sort(sectors, function(a, b)
        local aCenter, bCenter = Sectors.Center(a.id), Sectors.Center(b.id)
        local aDistance = aCenter and Sectors.PlayerDistance(
            aCenter.x, aCenter.y) or 0
        local bDistance = bCenter and Sectors.PlayerDistance(
            bCenter.x, bCenter.y) or 0
        if aDistance ~= bDistance then return aDistance > bDistance end
        local prefix = tostring(worldSeed) .. ":STARTER_SECTOR:"
            .. tostring(population.starterAttempts) .. ":"
        local aRank = Sectors.Seed(prefix .. a.id)
        local bRank = Sectors.Seed(prefix .. b.id)
        return aRank == bRank and a.id < b.id or aRank < bRank
    end)
    local queried, discovered = 0, 0
    local selectedSector
    local diagnostics = {}
    for _, sector in ipairs(sectors) do
        if queried >= Config.STARTER_META_SECTOR_BUDGET then break end
        if sector.active or sector.relevant then
            queried = queried + 1
            local querySeed = Sectors.Seed(table.concat({ tostring(worldSeed),
                "STARTER_SITE", sector.id,
                tostring(population.starterAttempts) }, ":"))
            local found, diagnostic = Candidates.DiscoverStarter(
                sector.id, querySeed)
            local eligible = Candidates.Best(sector.id, "settler", resolved,
                now, Config.STARTER_META_CANDIDATE_LIMIT, querySeed)
            diagnostic.eligibleLocationId = eligible and eligible.locationId or nil
            diagnostic.eligibleScore = eligible and eligible.score or nil
            diagnostics[#diagnostics + 1] = diagnostic
            discovered = discovered + found
            if eligible then
                selectedSector = sector.id
                break
            end
        end
    end
    local queued, reason = false, "no_starter_candidate"
    local groupQueued, groupReason = false, "starter_settlement_not_queued"
    if selectedSector then
        queued, reason = Queue.Enqueue("SETTLEMENT", {
            sectorId = selectedSector,
            qualifier = "STARTER",
            priority = 100,
            source = "WORLD_POPULATION_BOOTSTRAP",
        }, now)
        if reason == "queue_duplicate" then queued, reason = true, "already_queued" end
        if queued then
            groupQueued, groupReason = Queue.Enqueue("GROUP", {
                sectorId = selectedSector,
                qualifier = "STARTER",
                priority = 90,
                source = "WORLD_POPULATION_BOOTSTRAP",
            }, now)
            if groupReason == "queue_duplicate" then
                groupQueued, groupReason = true, "already_queued"
            end
        end
    end
    Starter.LastRun = { at = now, attempt = population.starterAttempts,
        worldSeed = seedString, populationSeed = worldSeed,
        sectorsQueried = queried, discovered = discovered,
        selectedSectorId = selectedSector, queued = queued == true,
        reason = reason, groupQueued = groupQueued == true,
        groupReason = groupReason, diagnostics = diagnostics }
    local fields = { attempt = population.starterAttempts,
        populationSeed = worldSeed, worldSeed = seedString,
        sectorsQueried = queried, discovered = discovered,
        sectorId = selectedSector, queued = queued == true, reason = reason,
        groupQueued = groupQueued == true, groupReason = groupReason }
    if queued then Log.Info("STARTER_SETTLEMENT_QUEUED", fields)
    else Log.Warn("STARTER_SETTLEMENT_DEFERRED", fields) end
    return queued == true, reason, Starter.LastRun
end

function Starter.GetDebugSnapshot()
    local population = data()
    return {
        pending = population.bootstrapCompleted ~= true,
        completed = population.bootstrapCompleted == true,
        completedAt = population.bootstrapCompletedAt,
        settlementId = population.starterSettlementId,
        attempts = population.starterAttempts,
        populationSeed = population.worldSeed,
        worldSeed = population.worldSeedString,
        lastRun = PNC.Core.DeepCopy(Starter.LastRun),
    }
end

return Starter
