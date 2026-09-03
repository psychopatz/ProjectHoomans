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
Catalog.Initialized = Catalog.Initialized == true

local function call(object, method, ...)
    if not object or type(object[method]) ~= "function" then return nil end
    local ok, value = pcall(object[method], object, ...)
    return ok and value or nil
end

local function shortObjectInfoName(value)
    local text = tostring(value or "")
    local short = text:match("([^%.]+)$")
    return short or text
end

local function normalizeLookup(value)
    return string.lower(string.gsub(shortObjectInfoName(value), "[^%w]", ""))
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

local function normalizeXPAwards(recipe)
    local output = {}
    local count = tonumber(call(recipe, "getXPAwardCount")) or 0
    for index = 0, count - 1 do
        local award = call(recipe, "getXPAward", index)
        local id = skillId(call(award, "getPerk"))
        local amount = tonumber(call(award, "getAmount"))
        if id and amount and amount > 0 then
            output[#output + 1] = {
                skillId = id,
                amount = amount,
            }
        end
    end
    return output
end

local function objectInfos()
    if not SpriteConfigManager
        or type(SpriteConfigManager.GetObjectInfoList) ~= "function"
    then return {} end
    local ok, list = pcall(SpriteConfigManager.GetObjectInfoList)
    return ok and values(list) or {}
end

local function nativeObjectInfo(objectInfoName)
    if not SpriteConfigManager
        or type(SpriteConfigManager.GetObjectInfo) ~= "function"
    then return nil end
    local candidates = {
        tostring(objectInfoName or ""),
        shortObjectInfoName(objectInfoName),
    }
    local seen = {}
    for _, candidate in ipairs(candidates) do
        if candidate ~= "" and not seen[candidate] then
            seen[candidate] = true
            local ok, info = pcall(SpriteConfigManager.GetObjectInfo,
                candidate)
            if ok and info then return info end
        end
    end
    return nil
end

local function previewFace(info)
    if not info then return nil end
    -- ObjectInfo's icon is only the first tile. Keep the native face geometry
    -- as primitive metadata so client UI can compose the complete preview.
    -- The placement cursor starts at nSprite 1, which maps to the west face
    -- in Build 42. Prefer that orientation for the build-card preview.
    local faces = { "w", "single", "n", "s", "e" }
    for _, faceName in ipairs(faces) do
        local face = call(info, "getFace", faceName)
        local width = tonumber(call(face, "getWidth")) or 0
        local height = tonumber(call(face, "getHeight")) or 0
        local zLayers = tonumber(call(face, "getzLayers")) or 0
        local tiles = {}
        for z = 0, zLayers - 1 do
            for x = 0, width - 1 do
                for y = 0, height - 1 do
                    local tile = call(face, "getTileInfo", x, y, z)
                    local spriteName = call(tile, "getSpriteName")
                    local empty = call(tile, "isEmpty")
                    if spriteName and tostring(spriteName) ~= ""
                        and empty ~= true
                    then
                        tiles[#tiles + 1] = {
                            x = x, y = y, z = z,
                            spriteName = tostring(spriteName),
                        }
                    end
                end
            end
        end
        if #tiles > 0 then
            return {
                face = faceName, width = width, height = height,
                zLayers = zLayers,
                masterX = tonumber(call(face, "getMasterX")) or 0,
                masterY = tonumber(call(face, "getMasterY")) or 0,
                masterZ = tonumber(call(face, "getMasterZ")) or 0,
                tiles = tiles,
            }
        end
    end
    return nil
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
    local iconTexture = call(info, "getIconTexture")
    local iconName = call(recipe, "getIconName")
        or call(info, "getMainSpriteNameUI")
    return {
        id = objectInfoName,
        recipeKey = objectInfoName,
        objectInfoName = objectInfoName,
        displayName = displayName,
        recipeName = recipeName,
        category = category,
        iconName = iconName and tostring(iconName) or nil,
        -- These are native runtime objects and intentionally remain runtime
        -- only. iconTexture is a one-tile fallback; previewTiles contains the
        -- complete native face for multi-tile object previews.
        iconTexture = iconTexture,
        previewTiles = previewFace(info),
        buildWork = math.max(1, tonumber(call(recipe, "getTime")) or 100),
        requiredSkills = normalizeSkills(recipe),
        xpAwards = normalizeXPAwards(recipe),
        requirements = normalizeRequirements(recipe),
        nativeObjectInfo = info,
        nativeRecipe = recipe,
    }
end

function Catalog.Build(force)
    if Catalog.Initialized and force ~= true then
        return Catalog.Queries.List()
    end
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
    Catalog.Initialized = true
    return Catalog.Queries.List()
end

function Catalog.Invalidate()
    Catalog.Initialized = false
end

function Catalog.Get(objectInfoName)
    objectInfoName = tostring(objectInfoName or "")
    if not Catalog.Initialized then Catalog.Build() end
    local direct = Catalog.ByObject[objectInfoName]
    if direct then return direct end
    local short = shortObjectInfoName(objectInfoName)
    return short ~= objectInfoName and Catalog.ByObject[short] or nil
end

-- Facility definitions store the native object identity, not a copied
-- material/icon payload. Keep a small catalog-level resolver for callers
-- that may have an alias or an entity-script name instead of the exact
-- object-info key.
function Catalog.Queries.FindForObjectInfo(objectInfoName)
    objectInfoName = tostring(objectInfoName or "")
    if objectInfoName == "" then return nil end
    local direct = Catalog.Get(objectInfoName)
    if direct then return direct end
    local short = shortObjectInfoName(objectInfoName)
    for _, value in ipairs(Catalog.Queries.List()) do
        if tostring(value.objectInfoName or "") == objectInfoName
            or tostring(value.id or "") == objectInfoName
            or tostring(value.objectInfoName or "") == short
            or tostring(value.id or "") == short
        then
            return Catalog.ByObject[value.objectInfoName]
        end
    end
    return nil
end

function Catalog.Queries.FindForAliases(aliases)
    local valuesToTry = type(aliases) == "table" and aliases or { aliases }
    local normalized = {}
    for _, aliasValue in ipairs(valuesToTry) do
        local alias = tostring(aliasValue or "")
        if alias ~= "" then
            local direct = Catalog.Queries.FindForObjectInfo(alias)
            if direct then return direct end
            normalized[#normalized + 1] = normalizeLookup(alias)
        end
    end
    if #normalized == 0 then return nil end
    for _, value in ipairs(Catalog.Queries.List()) do
        local keys = { value.objectInfoName, value.id, value.recipeName,
            value.displayName }
        for _, key in ipairs(keys) do
            local normalizedKey = normalizeLookup(key)
            for _, normalizedAlias in ipairs(normalized) do
                if normalizedKey ~= "" and normalizedKey == normalizedAlias
                then
                    return Catalog.ByObject[value.objectInfoName]
                end
            end
        end
    end
    return nil
end

function Catalog.Queries.FindNativeObjectInfo(objectInfoName)
    return nativeObjectInfo(objectInfoName)
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
                xpAwards = PNC.Core and PNC.Core.DeepCopy
                    and PNC.Core.DeepCopy(descriptorValue.xpAwards)
                    or descriptorValue.xpAwards,
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
