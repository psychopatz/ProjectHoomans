-- Facility build catalog and eligibility model.
--
-- This provider owns facility option normalization, cost availability, recipe
-- metadata, and technology prerequisites.  The modal retains window layout,
-- card rendering, and user interaction while consuming BuildUI.BuildOptions.

require "PsychopatzCore/UI/PsychopatzUI"
local FacilityState = require "PNC/Core/Settlement/PNC_FacilityState"

PNC = PNC or {}
PNC.FacilityBuildUI = PNC.FacilityBuildUI or {}

local BuildUI = PNC.FacilityBuildUI
local UI = PsychopatzCore.UI
local ImageResolver = UI.ImageResolver
    or require "PsychopatzCore/UI/Components/PsychopatzImageResolver"

local function tr(key, fallback)
    local value = getText and PNC.Translation.GetKey(key) or nil
    if not value or value == key then return fallback end
    return value
end

local function playerCount(fullType)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local inventory = player and player.getInventory and player:getInventory() or nil
    if not inventory or not inventory.getItemsFromType then return 0 end
    local values = inventory:getItemsFromType(fullType, true)
    if not values then return 0 end
    local size = values.size and tonumber(values:size()) or 0
    if type(values.get) ~= "function" then return size end
    -- Sum units, not stacks: one stack can hold more than one unit, and the
    -- server reserves real units.
    local total = 0
    for index = 0, size - 1 do
        local item = values:get(index)
        total = total + math.max(1, math.floor(tonumber(
            item and item.getCount and item:getCount() or 1) or 1))
    end
    return total
end

local function humanizeIdentifier(value)
    local text = tostring(value or "")
    text = text:match("([^%.]+)$") or text
    text = string.gsub(text, "[_%-]+", " ")
    if text == "" then return text end
    return string.upper(string.sub(text, 1, 1)) .. string.sub(text, 2)
end

local function stockpileCount(storage, fullType)
    if type(fullType) == "table" then
        local best = 0
        for _, candidate in ipairs(fullType) do
            best = math.max(best, stockpileCount(storage, candidate))
        end
        return best
    end
    local total = 0
    for _, row in ipairs(storage and storage.rows or {}) do
        if tostring(row.fullType or "") == tostring(fullType or "") then
            total = total + math.max(0, math.floor(tonumber(row.quantity) or 0))
        end
    end
    return total
end

local function buildDescriptorFor(definition)
    if not definition or definition.directWorkstation ~= true then return nil end
    local objectInfoName = definition.buildRecipeObjectInfoName
        or definition.entityScript
    local catalog = PNC.BuildRecipeCatalog
    if not catalog then return nil end
    local aliases = {
        objectInfoName,
        definition.entityScript,
        definition.stationId,
        tr(definition.displayNameKey, humanizeIdentifier(definition.id)),
    }
    if catalog.Queries and catalog.Queries.FindForAliases then
        local descriptor = catalog.Queries.FindForAliases(aliases)
        if descriptor then return descriptor end
    end
    if catalog.Get and objectInfoName then
        local descriptor = catalog.Get(objectInfoName)
        if descriptor then return descriptor end
    end
    if catalog.Queries and catalog.Queries.FindForObjectInfo
        and objectInfoName
    then
        local descriptor = catalog.Queries.FindForObjectInfo(objectInfoName)
        if descriptor then return descriptor end
    end
    if catalog.Queries and catalog.Queries.FindNativeObjectInfo
        and objectInfoName
    then
        local info = catalog.Queries.FindNativeObjectInfo(objectInfoName)
        if info then
            return {
                objectInfoName = tostring(objectInfoName),
                displayName = tr(definition.displayNameKey,
                    humanizeIdentifier(definition.id)),
                category = definition.category,
                nativeObjectInfo = info,
                nativeOnly = true,
                requirements = {},
            }
        end
    end
    return nil
end

local function descriptorTexture(descriptor)
    return descriptor
        and (ImageResolver.Resolve(descriptor) or descriptor.iconTexture)
        or nil
end


local function recipeFor(definition, descriptor)
    if descriptor and type(descriptor.requirements) == "table" then
        return descriptor.requirements
    end
    local recipe = definition and (definition.buildCosts
        or definition.buildCost) or {}
    if recipe.fullType then return { recipe } end
    return recipe
end

local function costTypes(cost)
    if type(cost) ~= "table" then return {} end
    if type(cost.itemTypes) == "table" and #cost.itemTypes > 0 then
        return cost.itemTypes
    end
    local fullType = cost.fullType or cost.itemType
    return fullType and { tostring(fullType) } or {}
end

local function costLabel(cost)
    local labels = {}
    for _, fullType in ipairs(costTypes(cost)) do
        labels[#labels + 1] = getItemNameFromFullType
            and tostring(getItemNameFromFullType(fullType) or fullType)
            or tostring(fullType)
    end
    return table.concat(labels, " / ")
end

local function productionCategory(definition, descriptor, primarySkill)
    local work = PNC.WorkDefinitions
    local valid = {}
    for _, skillId in ipairs(work and work.CRAFTING_SKILL_ORDER or {}) do
        valid[tostring(skillId)] = true
    end
    local nativeCategory = descriptor and tostring(descriptor.category or "")
    if nativeCategory ~= "" and valid[nativeCategory] then
        return nativeCategory
    end
    if definition and definition.directWorkstation == true
        and primarySkill and valid[tostring(primarySkill)]
    then
        return tostring(primarySkill)
    end
    return tostring(definition and definition.category or "production")
end


local function technologyKnown(research, technologyId)
    if not technologyId then return true end
    for _, id in ipairs(research and research.learnedTechnologyIds or {}) do
        if tostring(id) == tostring(technologyId) then return true end
    end
    return false
end

-- Name the research a facility is waiting on. A bare "RESEARCH REQUIRED" read
-- as an unresolvable gate because nothing in the tab said which technology, and
-- the research entry is only discoverable by its own name in the tree.
local function technologyLabel(technologyId)
    technologyId = tostring(technologyId or "")
    if technologyId == "" then return nil end
    local research = PNC.ColonyResearchDefinitions
    local entry = research and research.Get
        and research.Get(technologyId) or nil
    local labelKey = entry and entry.labelKey or nil
    if labelKey then
        local label = tr(labelKey, technologyId)
        if label and label ~= "" then return label end
    end
    -- Definitions unavailable (isolated tests, partial load): keep the line
    -- readable instead of printing the raw namespaced id.
    local separator = string.find(technologyId, ":", 1, true)
    local text = separator and string.sub(technologyId, separator + 1)
        or technologyId
    if text == "" then return technologyId end
    return string.upper(string.sub(text, 1, 1)) .. string.sub(text, 2)
end

local function stockpileState(settlement)
    local exists, built = false, false
    for _, facility in ipairs(settlement and settlement.facilities or {}) do
        if facility.definitionId == "stockpile" then
            exists = true
            built = FacilityState.IsBuilt(facility)
            break
        end
    end
    return exists, built
end

local function facilitySkillProfile(definition)
    local work = PNC.WorkDefinitions
    local profile = work and work.GetStationSkillProfile
        and work.GetStationSkillProfile(definition and definition.stationId)
        or nil
    if type(profile) == "table" and #profile > 0 then return profile end
    return definition and definition.specializationSkills or {}
end

local function buildOptions(settlement, storage, research)
    local values = {}
    local ids = {}
    for id, _ in pairs(PNC.FacilityDefinitions.ByID or {}) do ids[#ids + 1] = id end
    table.sort(ids)
    local stockpileExists, stockpileBuilt = stockpileState(settlement)
    for _, id in ipairs(ids) do
        local definition = PNC.FacilityDefinitions.Get(id)
        local level = PNC.FacilityDefinitions.GetLevel(id, 1)
        if definition and definition.legacyOnly ~= true then
        local buildDescriptor = buildDescriptorFor(definition)
        local skillProfile = facilitySkillProfile(definition)
        local primarySkill = skillProfile[1]
        local skillLabel = primarySkill
            and PNC.WorkDefinitions.GetProductionSkillLabel(primarySkill)
            or tr("UI_PNC_Facility_SkillOther", "Other production")
        local costParts, sourceParts = {}, {}
        local affordable = true
        local costs = recipeFor(definition, buildDescriptor)
        for _, cost in ipairs(costs) do
            local required = math.max(0, math.floor(tonumber(
                cost.amount or cost.quantity) or 0))
            local types = costTypes(cost)
            local stored = stockpileCount(storage, types)
            local fromPlayer = definition.bootstrapFromPlayer == true
                and playerCount(types[1]) or 0
            local available = definition.bootstrapFromPlayer == true
                and fromPlayer or stored
            if available < required then affordable = false end
            costParts[#costParts + 1] = tostring(required) .. " "
                .. costLabel(cost) .. " (" .. tostring(available)
                .. " " .. tr("UI_PNC_Facility_MaterialTotal", "total") .. ")"
            sourceParts[#sourceParts + 1] = tostring(available) .. " "
                .. (definition.bootstrapFromPlayer == true
                    and tr("UI_PNC_Facility_MaterialPlayer", "player")
                    or tr("UI_PNC_Facility_MaterialStockpile", "stockpile"))
        end
        local hqReady = (tonumber(settlement.hqLevel) or 0)
            >= (tonumber(level and level.requiredHQLevel) or 1)
        local technologyReady = technologyKnown(research,
            definition.requiredTechnology)
        local recipeReady = definition.directWorkstation ~= true
            or (buildDescriptor ~= nil and buildDescriptor.nativeOnly ~= true)
        local prerequisiteReady = id == "stockpile" or stockpileBuilt
        local singletonReady = id ~= "stockpile" or not stockpileExists
        local status = not singletonReady and tr(
                "UI_PNC_Facility_StockpileExists", "ALREADY BUILT OR PLANNED")
            or not prerequisiteReady and tr(
                "UI_PNC_Facility_StockpileRequired", "BUILD STOCKPILE FIRST")
            or not recipeReady and tr(
                "UI_PNC_Facility_BuildRecipeUnavailable",
                "BUILD RECIPE UNAVAILABLE")
            or hqReady and affordable and technologyReady
            and tr("UI_PNC_Facility_Available", "AVAILABLE")
            or not hqReady and tr("UI_PNC_Facility_RequiresHQ", "HQ LEVEL TOO LOW")
            or not technologyReady and (tr(
                "UI_PNC_Facility_RequiresTechnology", "RESEARCH REQUIRED")
                .. ": " .. tostring(
                    technologyLabel(definition.requiredTechnology)))
            or tr("UI_PNC_Facility_MissingMaterials", "NEED MORE MATERIALS")
        values[#values + 1] = {
            id = id,
            category = productionCategory(definition, buildDescriptor,
                primarySkill),
            name = definition.buildDisplayNameKey
                and tr(definition.buildDisplayNameKey,
                    buildDescriptor and buildDescriptor.displayName
                    or tr(definition.displayNameKey, id))
                or buildDescriptor and buildDescriptor.displayName
                or tr(definition.displayNameKey, id),
            description = tr(definition.descriptionKey, id),
            texture = descriptorTexture(buildDescriptor)
                or getTexture and definition.iconPath
                and getTexture(definition.iconPath) or nil,
            costText = table.concat(costParts, " | "),
            sourceText = table.concat(sourceParts, " | "),
            skillText = tr("UI_PNC_Facility_Skill", "SKILL") .. ": "
                .. skillLabel,
            productionSkillId = primarySkill,
            productionSkills = skillProfile,
            buildRecipe = buildDescriptor,
            previewTiles = buildDescriptor and buildDescriptor.previewTiles
                or nil,
            buildRecipeObjectInfoName = buildDescriptor
                and buildDescriptor.objectInfoName or nil,
            buildMaterials = costs,
            requiredTechnology = definition.requiredTechnology,
            directWorkstation = definition.directWorkstation == true,
            enabled = recipeReady and hqReady and affordable and technologyReady
                and prerequisiteReady and singletonReady,
            status = status,
        }
        end
    end
    table.sort(values, function(left, right)
        local leftSkill = PNC.WorkDefinitions and PNC.WorkDefinitions.CRAFTING_SKILL_ORDER
            or {}
        local function rank(option)
            for index, skill in ipairs(leftSkill) do
                if skill == option.productionSkillId then return index end
            end
            return #leftSkill + 1
        end
        local leftRank, rightRank = rank(left), rank(right)
        if leftRank ~= rightRank then return leftRank < rightRank end
        if tostring(left.category) ~= tostring(right.category) then
            return tostring(left.category) < tostring(right.category)
        end
        return tostring(left.name) < tostring(right.name)
    end)
    return values
end

BuildUI.BuildOptions = buildOptions


return BuildUI
