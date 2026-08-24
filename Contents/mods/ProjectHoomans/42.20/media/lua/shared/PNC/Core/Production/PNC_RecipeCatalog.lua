-- Runtime-only catalog of normal Build 42 CraftRecipe definitions.
-- PZ/mod recipe objects are an external boundary; descriptors are primitive
-- snapshots and are never persisted by this domain.

PNC = PNC or {}
PNC.RecipeCatalog = PNC.RecipeCatalog or {}

local Catalog = PNC.RecipeCatalog

Catalog.ByKey = Catalog.ByKey or {}
Catalog.ByResult = Catalog.ByResult or {}
Catalog.ByIngredient = Catalog.ByIngredient or {}
Catalog.Unsupported = Catalog.Unsupported or {}
Catalog.Order = Catalog.Order or {}
Catalog.Generation = tonumber(Catalog.Generation) or 0
Catalog.Ready = Catalog.Ready == true
Catalog.Diagnostics = Catalog.Diagnostics or {}
Catalog.Commands = Catalog.Commands or {}
Catalog.Queries = Catalog.Queries or {}

local function call(object, method, ...)
    if not object or type(object[method]) ~= "function" then
        return nil, "METHOD_UNAVAILABLE:" .. tostring(method)
    end
    local ok, value = pcall(object[method], object, ...)
    if not ok then return nil, tostring(value) end
    return value
end

local function listValues(list)
    local output = {}
    if not list then return output end
    if type(list) == "table" and not list.size then
        for index = 1, #list do output[#output + 1] = list[index] end
        return output
    end
    local size, reason = call(list, "size")
    if type(size) ~= "number" then return nil, reason or "LIST_SIZE_UNAVAILABLE" end
    for index = 0, size - 1 do
        local value
        value, reason = call(list, "get", index)
        if reason then return nil, reason end
        output[#output + 1] = value
    end
    return output
end

local function bool(object, method)
    local value = call(object, method)
    return value == true
end

local function itemFullType(item)
    local value = call(item, "getFullName")
        or call(item, "getScriptObjectFullType")
        or call(item, "getFullType")
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function normalizeResource(script, output)
    if bool(script, "isAutomationOnly") then return nil end
    local candidates = call(script, output and "getPossibleResultItems"
        or "getPossibleInputItems")
    local values, reason = listValues(candidates)
    if not values then return nil, reason end
    local types = {}
    local seen = {}
    for index = 1, #values do
        local fullType = itemFullType(values[index])
        if fullType and not seen[fullType] then
            seen[fullType] = true
            types[#types + 1] = fullType
        end
    end
    if #types == 0 then return nil, "NON_ITEM_OR_EMPTY_RESOURCE" end
    table.sort(types)
    local amount = call(script, "getIntAmount")
        or call(script, "getAmount") or 1
    return {
        itemTypes = types,
        amount = math.max(1, math.floor(tonumber(amount) or 1)),
        keep = not output and bool(script, "isKeep") or false,
        tool = not output and bool(script, "isTool") or false,
        consumed = not output and not bool(script, "isKeep")
            and not bool(script, "isTool") or false,
    }
end

local function normalizeSkills(recipe)
    local output = {}
    local count = tonumber(call(recipe, "getRequiredSkillCount")) or 0
    for index = 0, count - 1 do
        local required, reason = call(recipe, "getRequiredSkill", index)
        if reason then return nil, reason end
        local perk = call(required, "getPerk")
        local id = perk and (call(perk, "getId") or call(perk, "getName"))
        local level = tonumber(call(required, "getLevel"))
        if id and level then
            output[#output + 1] = { skillId = tostring(id), level = level }
        end
    end
    table.sort(output, function(left, right)
        return left.skillId < right.skillId
    end)
    return output
end

local function normalizeRecipe(recipe)
    local key = call(recipe, "getScriptObjectFullType")
    if not key or tostring(key) == "" then
        local moduleName = call(recipe, "getModuleName")
        local name = call(recipe, "getName")
        if moduleName and name then key = tostring(moduleName) .. "." .. tostring(name) end
    end
    key = tostring(key or "")
    if key == "" then return nil, "RECIPE_KEY_UNAVAILABLE" end

    local inputs, reason = listValues(call(recipe, "getInputs"))
    if not inputs then return nil, reason or "INPUTS_UNAVAILABLE" end
    local outputs
    outputs, reason = listValues(call(recipe, "getOutputs"))
    if not outputs then return nil, reason or "OUTPUTS_UNAVAILABLE" end

    local normalizedInputs = {}
    for index = 1, #inputs do
        local row, why = normalizeResource(inputs[index], false)
        if row then normalizedInputs[#normalizedInputs + 1] = row
        elseif why ~= "NON_ITEM_OR_EMPTY_RESOURCE" then return nil, why end
    end
    local normalizedOutputs = {}
    for index = 1, #outputs do
        local row, why = normalizeResource(outputs[index], true)
        if row then normalizedOutputs[#normalizedOutputs + 1] = row
        elseif why ~= "NON_ITEM_OR_EMPTY_RESOURCE" then return nil, why end
    end
    if #normalizedOutputs == 0 then return nil, "NO_ITEM_OUTPUT" end

    local skills
    skills, reason = normalizeSkills(recipe)
    if not skills then return nil, reason or "SKILLS_UNAVAILABLE" end
    local category = tostring(call(recipe, "getCategory") or "")
    local moduleName = tostring(call(recipe, "getModuleName")
        or string.match(key, "^([^.]+)%.") or "")
    return {
        key = key,
        name = tostring(call(recipe, "getName") or key),
        displayName = tostring(call(recipe, "getTranslationName")
            or call(recipe, "getName") or key),
        sourceModule = moduleName,
        category = category,
        inputs = normalizedInputs,
        outputs = normalizedOutputs,
        resultFullType = normalizedOutputs[1].itemTypes[1],
        resultQuantity = normalizedOutputs[1].amount,
        requiredSkills = skills,
        craftTime = tonumber(call(recipe, "getTime")) or 100,
        needToBeLearn = call(recipe, "needToBeLearn") == true,
        supported = true,
    }
end

local function addIndex(index, key, recipeKey)
    if not key then return end
    local bucket = index[key]
    if not bucket then bucket = {}; index[key] = bucket end
    bucket[#bucket + 1] = recipeKey
end

function Catalog.Commands.Rebuild(recipes)
    local started = getTimeInMillis and getTimeInMillis() or 0
    local source, reason = listValues(recipes)
    if not source then return false, reason or "RECIPE_LIST_UNAVAILABLE" end
    local byKey, byResult, byIngredient = {}, {}, {}
    local unsupported, order = {}, {}
    local normalizedCount = 0
    local modules = {}
    for index = 1, #source do
        local ok, descriptor, why = pcall(normalizeRecipe, source[index])
        if ok and descriptor and not byKey[descriptor.key] then
            byKey[descriptor.key] = descriptor
            order[#order + 1] = descriptor.key
            normalizedCount = normalizedCount + 1
            modules[descriptor.sourceModule] = (modules[descriptor.sourceModule] or 0) + 1
            for outputIndex = 1, #descriptor.outputs do
                for typeIndex = 1, #descriptor.outputs[outputIndex].itemTypes do
                    addIndex(byResult,
                        descriptor.outputs[outputIndex].itemTypes[typeIndex], descriptor.key)
                end
            end
            for inputIndex = 1, #descriptor.inputs do
                for typeIndex = 1, #descriptor.inputs[inputIndex].itemTypes do
                    addIndex(byIngredient,
                        descriptor.inputs[inputIndex].itemTypes[typeIndex], descriptor.key)
                end
            end
        else
            unsupported[#unsupported + 1] = {
                index = index,
                reason = tostring(ok and (why or "DUPLICATE_RECIPE_KEY")
                    or descriptor or "NORMALIZATION_FAILED"),
            }
        end
    end
    table.sort(order)
    Catalog.ByKey, Catalog.ByResult, Catalog.ByIngredient = byKey, byResult, byIngredient
    Catalog.Unsupported, Catalog.Order = unsupported, order
    Catalog.Generation = Catalog.Generation + 1
    Catalog.Ready = true
    Catalog.Diagnostics = {
        inspected = #source,
        normalized = normalizedCount,
        unsupported = #unsupported,
        recipesByModule = modules,
        multipleProducers = 0,
        buildDurationMs = math.max(0,
            (getTimeInMillis and getTimeInMillis() or started) - started),
        generation = Catalog.Generation,
    }
    for _, bucket in pairs(byResult) do
        if #bucket > 1 then
            Catalog.Diagnostics.multipleProducers =
                Catalog.Diagnostics.multipleProducers + 1
        end
    end
    return true, Catalog.Diagnostics
end

function Catalog.Commands.BuildFromScripts(manager)
    manager = manager or (ScriptManager and ScriptManager.instance)
    if not manager or not manager.getAllCraftRecipes then
        return false, "SCRIPT_MANAGER_UNAVAILABLE"
    end
    local ok, recipes = pcall(manager.getAllCraftRecipes, manager)
    if not ok or not recipes then return false, "CRAFT_RECIPES_UNAVAILABLE" end
    return Catalog.Commands.Rebuild(recipes)
end

function Catalog.Queries.Get(key) return Catalog.ByKey[tostring(key or "")] end
function Catalog.Queries.GetProducerKeys(fullType)
    local source = Catalog.ByResult[tostring(fullType or "")] or {}
    local output = {}; for index = 1, #source do output[index] = source[index] end
    return output
end
function Catalog.Queries.GetIngredientKeys(fullType)
    local source = Catalog.ByIngredient[tostring(fullType or "")] or {}
    local output = {}; for index = 1, #source do output[index] = source[index] end
    return output
end
function Catalog.Queries.List()
    local output = {}
    for index = 1, #Catalog.Order do
        output[index] = Catalog.ByKey[Catalog.Order[index]]
    end
    return output
end
function Catalog.Queries.Diagnostics()
    local output = {}; for key, value in pairs(Catalog.Diagnostics) do output[key] = value end
    return output
end

local function buildOnce()
    if not Catalog.Ready then Catalog.Commands.BuildFromScripts() end
end
if Events and Events.OnGameStart then Events.OnGameStart.Add(buildOnce) end
if Events and Events.OnServerStarted then Events.OnServerStarted.Add(buildOnce) end

return Catalog
