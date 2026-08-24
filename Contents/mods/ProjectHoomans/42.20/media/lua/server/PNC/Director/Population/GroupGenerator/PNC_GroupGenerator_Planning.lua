if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Generator = PNC.GroupGenerator
local H = Generator.Internal
local Config = PNC.DirectorConfig.Population
local Sectors = PNC.PopulationSectors
local Locations = PNC.AbstractLocations
local Groups = PNC.AbstractGroups
local Store = PNC.AbstractWorldStore

function Generator.BuildPlan(request, context)
    request, context = request or {}, context or {}
    local resolved = context.resolved or PNC.PopulationSandbox.Resolve()
    local generationID, serial = Sectors.NextGenerationID("GROUP")
    local seed = Sectors.GenerationSeed("GROUP", request.sectorId, serial,
        request.source)
    local archetype = Generator.ChooseArchetype(request.sectorId,
        context.worldAge, seed)
    local location, reason = H.ChooseLocation(request.sectorId, resolved, seed)
    if not location then return nil, reason end
    local range = Config.GROUP_SIZE_MAX - Config.GROUP_SIZE_MIN + 1
    return PNC.GroupGenerationPlan.New({
        generationId = generationID, sectorId = request.sectorId,
        source = request.source, archetype = archetype,
        factionArchetypeId = Config.GROUP_FACTION_ARCHETYPES[archetype],
        locationId = location.id, initialMission = "SCAVENGE",
        memberCount = Config.GROUP_SIZE_MIN + seed % range, seed = seed,
    }), "planned"
end

function Generator.Validate(plan, context)
    context = context or {}
    local resolved = context.resolved or PNC.PopulationSandbox.Resolve()
    if not plan or not plan.generationId then return false, "INVALID_PLAN" end
    if Sectors.IsCommitted(plan.generationId) then return false, "GENERATION_ID_DUPLICATE" end
    if not resolved.enabled or not resolved.groupsEnabled then return false, "GENERATION_DISABLED" end
    if #Groups.List() >= Config.HARD_MAX_ABSTRACT_GROUPS then return false, "HARD_CAP_REACHED" end
    if Sectors.CountAllGroups(plan.sectorId) >= Config.HARD_MAX_GROUPS_PER_SECTOR then
        return false, "SECTOR_HARD_CAP_REACHED"
    end
    local sector = Sectors.Get(plan.sectorId)
    if not sector or not sector.relevant then return false, "SECTOR_NOT_RELEVANT" end
    local now = tonumber(context.worldAge) or Store.WorldAgeHours()
    if now < (tonumber(sector.groupGenerationCooldownUntil) or 0) then
        return false, "GENERATION_COOLDOWN"
    end
    local budget = PNC.PopulationBudget.Calculate(sector, context)
    if budget.groups.deficit <= 0 then return false, "NO_DEFICIT" end
    local location = Locations.Get(plan.locationId)
    if not location or not location.sourceSite then return false, "INVALID_LOCATION" end
    if Sectors.IDForPosition(location.x, location.y) ~= plan.sectorId then
        return false, "WRONG_SECTOR"
    end
    if Sectors.LivePlayerDistance(location.x, location.y)
        < resolved.minPlayerGenerationDistance then return false, "PLAYER_TOO_CLOSE" end
    if not PNC.FactionArchetypes.Get(plan.factionArchetypeId) then
        return false, "INVALID_FACTION"
    end
    return true, "VALID"
end
