-- Runtime catalog for Build 42 entity recipes.  Only primitive descriptors
-- cross the colony-management snapshot; native recipe/object objects stay in
-- this runtime cache and are resolved again when a build is completed.
PNC = PNC or {}
PNC.BuildRecipeCatalog = PNC.BuildRecipeCatalog or {}

local Catalog = PNC.BuildRecipeCatalog
Catalog.ByObject = Catalog.ByObject or {}
Catalog.Order = Catalog.Order or {}
Catalog.Generation = tonumber(Catalog.Generation) or 0
Catalog.Queries = Catalog.Queries or {}

local function call(object, method, ...)
    if not object or type(object[method]) ~= "function" then return nil end
    local ok, value = pcall(object[method], object, ...)
    return ok and value or nil
end

local function values(list)
    local output = {}
    if not list then return output end
    if type(list) == "table" and not list.size then
        for index = 1, #list do output[#output + 1] = list[index] end
        return output
    end
    local size = call(list, "size")
    if type(size) ~= "number" then return output end
    for index = 0, size - 1 do
        output[#output + 1] = call(list, "get", index)
    end
    return output
end

local function itemType(item)
    return tostring(call(item, "getFullName")
        or call(item, "getScriptObjectFullType")
        or call(item, "getFullType") or "")
end

local function normalizeRequirements(recipe)
    local output = {}
    for _, input in ipairs(values(call(recipe, "getInputs"))) do
        local types, seen = {}, {}
        for _, item in ipairs(values(call(input, "getPossibleInputItems"))) do
            local fullType = itemType(item)
            if fullType ~= "" and not seen[fullType] then
                seen[fullType] = true
                types[#types + 1] = fullType
            end
        end
        if #types > 0 then
            table.sort(types)
            local itemCount = call(input, "isItemCount") == true
            local amount = itemCount and call(input, "getIntAmount")
                or call(input, "getAmount")
            output[#output + 1] = {
                itemTypes = types,
                amount = math.max(1, math.floor(tonumber(amount) or 1)),
                consumed = call(input, "isKeep") ~= true
                    and call(input, "isTool") ~= true,
            }
        end
    end
    return output
end

local function skillId(perk)
    local id = call(perk, "getId") or call(perk, "getName")
    if not id and perk then id = perk.name end
    return id and tostring(id) or nil
end

local function normalizeSkills(recipe)
    local output = {}
    local count = tonumber(call(recipe, "getRequiredSkillCount")) or 0
    for index = 0, count - 1 do
        local required = call(recipe, "getRequiredSkill", index)
        local id = skillId(call(required, "getPerk"))
        local level = tonumber(call(required, "getLevel"))
        if id and level then
            output[#output + 1] = { skillId = id, level = level }
        end
    end
    table.sort(output, function(left, right)
        return left.skillId < right.skillId
    end)
    return output
end

local function objectInfos()
    if not SpriteConfigManager
        or type(SpriteConfigManager.GetObjectInfoList) ~= "function"
    then return {} end
    local ok, list = pcall(SpriteConfigManager.GetObjectInfoList)
    return ok and values(list) or {}
end

local function descriptor(info)
    local objectInfoName = tostring(call(info, "getName") or "")
    local entityRecipe = call(info, "getRecipe")
    local recipe = call(entityRecipe, "getCraftRecipe")
    if objectInfoName == "" or not recipe then return nil end
    local recipeName = tostring(call(recipe, "getName") or objectInfoName)
    local displayName = tostring(call(recipe, "getTranslationName")
        or recipeName)
    local category = tostring(call(recipe, "getBuildCategory")
        or call(recipe, "getCategory") or "Miscellaneous")
    local iconName = call(info, "getMainSpriteNameUI")
        or call(recipe, "getIconName")
    return {
        id = objectInfoName,
        recipeKey = objectInfoName,
        objectInfoName = objectInfoName,
        displayName = displayName,
        recipeName = recipeName,
        category = category,
        iconName = iconName and tostring(iconName) or nil,
        buildWork = math.max(1, tonumber(call(recipe, "getTime")) or 100),
        requiredSkills = normalizeSkills(recipe),
        requirements = normalizeRequirements(recipe),
        nativeObjectInfo = info,
        nativeRecipe = recipe,
    }
end

function Catalog.Build()
    local byObject, order = {}, {}
    for _, info in ipairs(objectInfos()) do
        local row = descriptor(info)
        if row and not byObject[row.objectInfoName] then
            byObject[row.objectInfoName] = row
            order[#order + 1] = row.objectInfoName
        end
    end
    table.sort(order, function(left, right)
        local a, b = byObject[left], byObject[right]
        if tostring(a.category) ~= tostring(b.category) then
            return tostring(a.category) < tostring(b.category)
        end
        return tostring(a.displayName) < tostring(b.displayName)
    end)
    Catalog.ByObject, Catalog.Order = byObject, order
    Catalog.Generation = Catalog.Generation + 1
    return Catalog.Queries.List()
end

function Catalog.Get(objectInfoName)
    objectInfoName = tostring(objectInfoName or "")
    if not Catalog.ByObject[objectInfoName] then Catalog.Build() end
    return Catalog.ByObject[objectInfoName]
end

function Catalog.Queries.List()
    local output = {}
    for index = 1, #Catalog.Order do
        local descriptorValue = Catalog.ByObject[Catalog.Order[index]]
        if descriptorValue then
            output[#output + 1] = {
                id = descriptorValue.id,
                recipeKey = descriptorValue.recipeKey,
                objectInfoName = descriptorValue.objectInfoName,
                displayName = descriptorValue.displayName,
                recipeName = descriptorValue.recipeName,
                category = descriptorValue.category,
                iconName = descriptorValue.iconName,
                buildWork = descriptorValue.buildWork,
                requiredSkills = PNC.Core and PNC.Core.DeepCopy
                    and PNC.Core.DeepCopy(descriptorValue.requiredSkills)
                    or descriptorValue.requiredSkills,
                requirements = PNC.Core and PNC.Core.DeepCopy
                    and PNC.Core.DeepCopy(descriptorValue.requirements)
                    or descriptorValue.requirements,
            }
        end
    end
    return output
end

Catalog.Queries = Catalog.Queries
return Catalog
