if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Generator = PNC.GroupGenerator
local H = Generator.Internal
local Config = PNC.DirectorConfig.Population
local Sectors = PNC.PopulationSectors
local Locations = PNC.AbstractLocations
local Candidates = PNC.SettlementCandidates
local Groups = PNC.AbstractGroups

function H.CurrentComposition(sectorID)
    local counts = {}
    for groupID in pairs(Sectors.GroupIDs[sectorID] or {}) do
        local group = Groups.Get(groupID)
        if group then counts[group.groupType] = (counts[group.groupType] or 0) + 1 end
    end
    return counts
end

local function hostileActivityMultiplier(sectorID, worldAge)
    local director = PNC.ScopedWorldEventDirector
    if director and type(director.AggregateEffectsForSector) == "function" then
        local agg = director.AggregateEffectsForSector(sectorID, worldAge)
        local mult = agg and agg.effects and tonumber(agg.effects.hostileActivityMultiplier)
        if mult ~= nil then return math.max(0.1, mult) end
    end
    local swe = PsychopatzCore and PsychopatzCore.ScopedWorldEvents
    if swe and type(swe.AggregateEffects) == "function" then
        local agg = swe.AggregateEffects({ global = true }, worldAge)
        local mult = agg and agg.effects and tonumber(agg.effects.hostileActivityMultiplier)
        if mult ~= nil then return math.max(0.1, mult) end
    end
    return 1.0
end

function Generator.GetArchetypeWeights(sectorID, worldAge)
    local counts = H.CurrentComposition(sectorID)
    local age = PNC.PopulationBudget.WorldAgeWeights(worldAge)
    local hostileMult = hostileActivityMultiplier(sectorID, worldAge)
    local sandboxShares = PNC.Sandbox and type(PNC.Sandbox.WorldNPCShareWeights) == "function"
        and PNC.Sandbox.WorldNPCShareWeights() or nil
    local weights = {}
    for archetype, defaultWeight in pairs(Config.GROUP_ARCHETYPE_WEIGHTS) do
        local baseWeight = defaultWeight
        if sandboxShares then
            if archetype == "LOOTER" then
                baseWeight = tonumber(sandboxShares.LOOTER) or defaultWeight
            elseif archetype == "SCAVENGER" then
                baseWeight = tonumber(sandboxShares.SCAVENGER) or defaultWeight
            elseif archetype == "REFUGEE" then
                baseWeight = tonumber(sandboxShares.REFUGEE) or defaultWeight
            elseif archetype == "WANDERER" then
                baseWeight = (tonumber(sandboxShares.REFUGEE) or defaultWeight) * 0.5
            end
        end
        if baseWeight <= 0 then
            weights[archetype] = 0
        else
            local ageWeight = archetype == "REFUGEE" and age.refugee or age.established
            local eventMult = archetype == "LOOTER" and hostileMult or 1.0
            weights[archetype] = math.max(0.01, baseWeight * ageWeight * eventMult)
                / (1 + (counts[archetype] or 0) * 1.75)
        end
    end
    return weights
end

function Generator.ChooseArchetype(sectorID, worldAge, seed)
    local weights = Generator.GetArchetypeWeights(sectorID, worldAge)
    return Sectors.WeightedChoice(weights, seed) or "WANDERER"
end

function H.ChooseLocation(sectorID, resolved, seed)
    local center = Sectors.Center(sectorID)
    if not center then return nil, "invalid_sector" end
    Locations.DiscoverLoadedNear(center.x, center.y, center.z,
        Config.SECTOR_SIZE * 0.75, Config.CANDIDATE_EVALUATION_BUDGET)
    local function selectLocation()
        local best, bestScore
        for _, entry in ipairs(Locations.GetNearby(center.x, center.y,
            Config.SECTOR_SIZE * 0.75, Config.CANDIDATE_EVALUATION_BUDGET * 4)) do
            local location = entry.location
            if Sectors.IDForPosition(location.x, location.y) == sectorID
                and location.sourceSite then
                local distance = Sectors.PlayerDistance(location.x, location.y)
                if distance >= resolved.minPlayerGenerationDistance then
                    local preferred = resolved.preferredPlayerGenerationDistance
                    local score = distance >= preferred
                        and 1000 - math.abs(distance - preferred)
                        or distance - resolved.minPlayerGenerationDistance
                    score = score - (tonumber(location.danger) or 0) * 2
                    score = score + (Sectors.Seed(tostring(seed) .. ":GROUP_SITE:"
                        .. tostring(location.id)) % 2500) / 100
                    if not bestScore or score > bestScore
                        or score == bestScore and location.id < best.id then
                        best, bestScore = location, score
                    end
                end
            end
        end
        return best
    end
    local best = selectLocation()
    if not best and Candidates and Candidates.DiscoverMeta then
        Candidates.DiscoverMeta(sectorID, seed, "GROUP_FALLBACK")
        best = selectLocation()
    end
    return best, best and "selected" or "no_valid_location"
end
