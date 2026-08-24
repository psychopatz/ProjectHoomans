local Knowledge = PNC.RecipeKnowledge
local stateFor = Knowledge.Internal.StateFor
local MAX_RECIPES, MAX_BOOKS, MAX_KEY_LENGTH = 4096, 512, 160

local function call(object, method, ...)
    if not object or type(object[method]) ~= "function" then return nil end
    local ok, value = pcall(object[method], object, ...)
    return ok and value or nil
end

local function listValues(list)
    local output = {}
    if type(list) == "table" and not list.size then
        for index = 1, #list do output[#output + 1] = list[index] end
        return output
    end
    local size = call(list, "size")
    if type(size) ~= "number" then return output end
    for index = 0, size - 1 do output[#output + 1] = call(list, "get", index) end
    return output
end

local function itemFullType(item, fallback)
    local fullType = call(item, "getFullType")
        or call(item, "getFullName")
        or call(item, "getScriptObjectFullType")
    return tostring(fullType or fallback or "")
end

local function recipeKeyFor(token)
    token = tostring(token or "")
    if token == "" then return nil end
    local catalog = PNC.RecipeCatalog
    local direct = catalog and catalog.Queries and catalog.Queries.Get(token)
    if direct then return direct.key end
    if catalog and catalog.Queries and catalog.Queries.List then
        for _, descriptor in ipairs(catalog.Queries.List() or {}) do
            if descriptor.name == token or descriptor.key == token then
                return descriptor.key
            end
        end
    end
    return nil
end

function Knowledge.Queries.BookDetails(item, fallbackFullType)
    local recipes, keys = listValues(call(item, "getLearnedRecipes")), {}
    for index = 1, #recipes do
        local key = recipeKeyFor(recipes[index])
        if key then keys[#keys + 1] = key end
    end
    local skillID = call(item, "getSkillTrained")
    skillID = skillID and tostring(skillID) or ""
    local consumeOnRead = false
    if item and item.hasTag and ItemTag and ItemTag.CONSUME_ON_READ then
        consumeOnRead = call(item, "hasTag", ItemTag.CONSUME_ON_READ) == true
    end
    return { fullType = itemFullType(item, fallbackFullType),
        recipeKeys = keys, skillID = skillID ~= "" and skillID or nil,
        skillLevel = tonumber(call(item, "getLvlSkillTrained")) or 0,
        consumeOnRead = consumeOnRead,
        relevant = #keys > 0 or skillID ~= "" }
end

local function appendUnique(list, value, limit, maxLength)
    value = tostring(value or "")
    if value == "" or #value > maxLength then return false end
    for index = 1, #list do if list[index] == value then return false end end
    if #list >= limit then return false end
    list[#list + 1] = value; table.sort(list); return true
end

local function touch(record)
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "recipe_knowledge")
    end
    if PNC.Tasking and PNC.Tasking.Commands
        and PNC.Tasking.Commands.MarkDirty
    then
        PNC.Tasking.Commands.MarkDirty(record.id, "RECIPE_KNOWLEDGE_CHANGED")
    end
end

function Knowledge.Commands.ReadBook(record, item, options)
    options = type(options) == "table" and options or {}
    local state = stateFor(record)
    if not state then return false, "NPC_REQUIRED" end
    local details = Knowledge.Queries.BookDetails(item, options.fullType)
    if not details.relevant then return false, "BOOK_NOT_RELEVANT" end
    if Knowledge.Queries.HasReadBook(record, details.fullType)
        and not options.allowRepeat
    then return true, "BOOK_ALREADY_READ", details end
    local nativeBody, nativeItem = options.liveBody, options.nativeItem or item
    if nativeBody and nativeItem then
        local ok = pcall(function() nativeBody:ReadLiterature(nativeItem) end)
        if not ok then return false, "NPC_LITERATURE_READ_FAILED" end
    end
    local changed = appendUnique(state.readBookTypes, details.fullType,
        MAX_BOOKS, MAX_KEY_LENGTH)
    for index = 1, #details.recipeKeys do
        if appendUnique(state.learnedRecipeKeys, details.recipeKeys[index],
            MAX_RECIPES, MAX_KEY_LENGTH) then changed = true end
    end
    if details.skillID and PNC.Skills and PNC.Skills.AddXP then
        PNC.Skills.AddXP(record, details.skillID,
            30 + math.max(0, details.skillLevel) * 15)
    end
    if changed then
        state.revision = state.revision + 1
        record.runtime.recipeKnowledgeIndex = nil
        touch(record)
    end
    if options.liveBody then Knowledge.BindLiveBody(record, options.liveBody) end
    return true, changed and "BOOK_READ" or "BOOK_ALREADY_READ", details
end

return Knowledge
