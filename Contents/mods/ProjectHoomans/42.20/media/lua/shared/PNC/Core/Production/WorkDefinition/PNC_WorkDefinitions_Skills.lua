PNC = PNC or {}
PNC.WorkDefinitions = PNC.WorkDefinitions or {}

local Definitions = PNC.WorkDefinitions

function Definitions.NormalizeProductionSkillId(skillId)
    local id = tostring(skillId or "")
    if id == "MetalWelding" or id == "Metalwork" then return "Welding" end
    return id ~= "" and id or nil
end

function Definitions.GetProductionSkillId(descriptor, station)
    local direct = descriptor and Definitions.NormalizeProductionSkillId(
        descriptor.productionSkillId)
    if direct then return direct end
    for _, award in ipairs(descriptor and descriptor.xpAwards or {}) do
        local id = Definitions.NormalizeProductionSkillId(award.skillId)
        if id then return id end
    end
    return station and Definitions.NormalizeProductionSkillId(
        station.productionSkillId) or nil
end

function Definitions.GetProductionSkillLabel(skillId)
    local id = Definitions.NormalizeProductionSkillId(skillId)
    local skill = PNC.SkillCatalog and PNC.SkillCatalog.Find
        and PNC.SkillCatalog.Find(id) or nil
    return skill and skill.display or id or "Other"
end

local function skillOrderIndex(skillId)
    local id = Definitions.NormalizeProductionSkillId(skillId)
    for index, value in ipairs(Definitions.CRAFTING_SKILL_ORDER) do
        if value == id then return index end
    end
    return #Definitions.CRAFTING_SKILL_ORDER + 1
end

function Definitions.GetStationSkillProfile(stationId)
    local station = Definitions.STATIONS[tostring(stationId or "")]
    if not station then return {} end
    local fallback = station.specializationSkills
        or { station.productionSkillId }
    local catalog = PNC.RecipeCatalog
    local generation = catalog and tonumber(catalog.Generation) or nil
    if station._skillProfileGeneration == generation
        and type(station._skillProfile) == "table"
    then
        return station._skillProfile
    end
    local scores, order = {}, {}
    for _, descriptor in ipairs(catalog and catalog.Queries
        and catalog.Queries.List and catalog.Queries.List() or {}) do
        local required = Definitions.GetStationForRecipe(descriptor, "CRAFT")
        if required and required.id == station.id then
            for _, award in ipairs(descriptor.xpAwards or {}) do
                local skillId = Definitions.NormalizeProductionSkillId(
                    award.skillId)
                if skillId then
                    scores[skillId] = (scores[skillId] or 0)
                        + math.max(0, tonumber(award.amount) or 0)
                end
            end
        end
    end
    for skillId, score in pairs(scores) do
        order[#order + 1] = { skillId = skillId, score = score }
    end
    if #order == 0 then
        for index, skillId in ipairs(fallback) do
            if skillId then order[#order + 1] = {
                skillId = skillId, score = 0, fallbackIndex = index,
            } end
        end
    end
    table.sort(order, function(left, right)
        if left.score ~= right.score then return left.score > right.score end
        local leftIndex, rightIndex = skillOrderIndex(left.skillId),
            skillOrderIndex(right.skillId)
        if leftIndex ~= rightIndex then return leftIndex < rightIndex end
        return tostring(left.skillId) < tostring(right.skillId)
    end)
    local profile = {}
    for index, row in ipairs(order) do profile[index] = row.skillId end
    station._skillProfileGeneration, station._skillProfile = generation, profile
    return profile
end

return Definitions
