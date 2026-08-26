if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CommunitySiteResolver = PNC.CommunitySiteResolver or {}
PNC.CommunitySiteResolverInternal =
    PNC.CommunitySiteResolverInternal or {}

local Resolver = PNC.CommunitySiteResolver
local H = PNC.CommunitySiteResolverInternal
local Constants = PNC.CommunityConstants
local Types = PNC.CommunityTypes
local CommunityMath = PNC.CommunityMath

function H.SiteIsAvailable(site)
    if not site then return false end
    local existing = PNC.Communities.GetSite(site.id)
    return existing == nil or existing.status == "vacant"
end

function H.ListValues(list)
    local output = {}
    if not list then return output end
    local size = H.InvokeNumber(list, "size")
    if size == nil or not list.get then return output end
    size = math.floor(size)
    if size <= 0 then return output end
    local index
    for index = 0, size - 1 do
        local ok
        local value
        ok, value = pcall(list.get, list, index)
        if ok and value then output[#output + 1] = value end
    end
    return output
end

function H.DefinitionContains(definition, roomName)
    if not definition or not definition.containsRoom then
        return false
    end
    local ok
    local result
    ok, result = pcall(
        definition.containsRoom,
        definition,
        roomName
    )
    return ok and result == true
end

function H.DefinitionIsHouse(definition)
    local bedroom = H.DefinitionContains(
        definition,
        "bedroom"
    ) or H.DefinitionContains(
        definition,
        "bedroom2"
    )
    local kitchen = H.DefinitionContains(
        definition,
        "kitchen"
    ) or H.DefinitionContains(
        definition,
        "kitchen2"
    )
    local living = H.DefinitionContains(
        definition,
        "livingroom"
    ) or H.DefinitionContains(
        definition,
        "livingroom2"
    )
    return bedroom and (kitchen or living)
end

function Resolver.IsResidentialDefinition(definition)
    return H.DefinitionIsHouse(definition)
end

function H.AddCandidate(
    candidates,
    seen,
    definition,
    z,
    options,
    assumeHouse
)
    if assumeHouse ~= true
        and not H.DefinitionIsHouse(definition)
    then
        return
    end
    local site = Resolver.DescribeBuildingDefinition(
        definition,
        z,
        options
    )
    if site and not seen[site.id]
        and H.SiteIsAvailable(site)
        and (
            type(options.siteFilter) ~= "function"
            or options.siteFilter(site) == true
        )
    then
        seen[site.id] = true
        candidates[#candidates + 1] = site
    end
end

function H.AddLoadedBuildingCandidates(
    candidates,
    seen,
    z,
    options
)
    local cell = getCell and getCell() or nil
    local buildings = cell
        and H.InvokeObject(cell, "getBuildingList") or nil
    for _, building in ipairs(H.ListValues(buildings)) do
        if H.InvokeBoolean(building, "isResidential")
            and not H.InvokeBoolean(building, "isToxic")
        then
            local definition =
                H.InvokeObject(building, "getDef")
            H.AddCandidate(
                candidates,
                seen,
                definition,
                z,
                options,
                true
            )
        end
    end
end

function H.RandomCandidateIndex(count, options)
    local requested = math.floor(
        tonumber(options.randomIndex) or 0
    )
    if requested >= 1 and requested <= count then
        return requested
    end
    if ZombRand then
        local ok
        local value
        ok, value = pcall(ZombRand, count)
        value = ok and tonumber(value) or nil
        if value then
            return (math.floor(value) % count) + 1
        end
    end
    return 1
end
