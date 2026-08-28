-- Per-NPC recipe and literature knowledge.
--
-- The durable representation deliberately contains sorted arrays only.  The
-- lookup maps used by the scheduler live under record.runtime and are rebuilt
-- from the compact arrays when the revision changes.

PNC = PNC or {}
PNC.RecipeKnowledge = PNC.RecipeKnowledge or {}

local Knowledge = PNC.RecipeKnowledge
Knowledge.Commands = Knowledge.Commands or {}
Knowledge.Queries = Knowledge.Queries or {}
Knowledge.Internal = Knowledge.Internal or {}
local SCHEMA_VERSION = 1
local MAX_RECIPES = 4096
local MAX_BOOKS = 512
local MAX_KEY_LENGTH = 160

Knowledge.SCHEMA_VERSION = SCHEMA_VERSION
Knowledge.MODDATA_KEY = "PNC_RecipeKnowledge"

local function cleanList(source, limit, maxLength)
    local output, seen = {}, {}
    if type(source) ~= "table" then return output end
    for index = 1, #source do
        local value = tostring(source[index] or "")
        if value ~= "" and #value <= maxLength and not seen[value] then
            seen[value] = true
            output[#output + 1] = value
            if #output >= limit then break end
        end
    end
    table.sort(output)
    return output
end

local function copyList(source)
    local output = {}
    for index = 1, #(source or {}) do output[index] = source[index] end
    return output
end

local function rawList(raw, longName, shortName, legacyName)
    if type(raw) ~= "table" then return nil end
    return raw[longName] or raw[shortName] or raw[legacyName]
end

function Knowledge.Normalize(raw)
    raw = type(raw) == "table" and raw or {}
    return {
        schemaVersion = SCHEMA_VERSION,
        revision = math.max(0, math.floor(tonumber(raw.revision or raw.n) or 0)),
        learnedRecipeKeys = cleanList(
            rawList(raw, "learnedRecipeKeys", "r", "recipes"),
            MAX_RECIPES, MAX_KEY_LENGTH
        ),
        readBookTypes = cleanList(
            rawList(raw, "readBookTypes", "b", "books"),
            MAX_BOOKS, MAX_KEY_LENGTH
        ),
    }
end

local function stateFor(record)
    if type(record) ~= "table" then return nil end
    local current = record.recipeKnowledge
    if type(current) ~= "table"
        or tonumber(current.schemaVersion) ~= SCHEMA_VERSION
        or type(current.learnedRecipeKeys) ~= "table"
        or type(current.readBookTypes) ~= "table"
    then
        record.recipeKnowledge = Knowledge.Normalize(current)
    end
    record.runtime = record.runtime or {}
    local cache = record.runtime.recipeKnowledgeIndex
    if not cache or cache.revision ~= record.recipeKnowledge.revision then
        local learned, books = {}, {}
        for index = 1, #record.recipeKnowledge.learnedRecipeKeys do
            learned[record.recipeKnowledge.learnedRecipeKeys[index]] = true
        end
        for index = 1, #record.recipeKnowledge.readBookTypes do
            books[record.recipeKnowledge.readBookTypes[index]] = true
        end
        cache = { revision = record.recipeKnowledge.revision,
            learned = learned, books = books }
        record.runtime.recipeKnowledgeIndex = cache
    end
    return record.recipeKnowledge, cache
end

Knowledge.Internal.StateFor = stateFor

local function appendUnique(list, value, limit, maxLength)
    value = tostring(value or "")
    if value == "" or #value > maxLength then return false end
    for index = 1, #list do
        if list[index] == value then return false end
    end
    if #list >= limit then return false end
    list[#list + 1] = value
    table.sort(list)
    return true
end

local function touch(record, reason)
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, reason or "recipe_knowledge")
    end
    if PNC.Tasking and PNC.Tasking.Events
        and PNC.Tasking.Events.Emit
    then
        PNC.Tasking.Events.Emit("RECIPE_KNOWLEDGE_CHANGED", {
            npcId = record.id, source = "RecipeKnowledge",
            entityId = record.id,
        })
    end
end

function Knowledge.Queries.State(record)
    local state = stateFor(record)
    return state and Knowledge.Normalize(state) or nil
end

function Knowledge.Queries.HasRecipe(record, recipeKey)
    local _, cache = stateFor(record)
    return cache ~= nil and cache.learned[tostring(recipeKey or "")] == true
end

function Knowledge.Queries.HasReadBook(record, fullType)
    local _, cache = stateFor(record)
    return cache ~= nil and cache.books[tostring(fullType or "")] == true
end

function Knowledge.Queries.RequiresBook(descriptor)
    return type(descriptor) == "table" and descriptor.needToBeLearn ~= false
end

function Knowledge.Queries.CanCraft(record, descriptor)
    if type(descriptor) == "number" or type(descriptor) == "string" then
        local resolved = PNC.RecipeKnowledgeRegistry
            and PNC.RecipeKnowledgeRegistry.Queries
            and PNC.RecipeKnowledgeRegistry.Queries.Resolve(descriptor)
        descriptor = resolved and resolved.descriptor or nil
    end
    if not descriptor then return false, "RECIPE_UNAVAILABLE" end
    if not Knowledge.Queries.RequiresBook(descriptor) then return true end
    if Knowledge.Queries.HasRecipe(record, descriptor.key) then return true end
    return false, "RECIPE_BOOK_REQUIRED"
end

function Knowledge.Commands.LearnRecipe(record, recipeKey)
    local state = stateFor(record)
    if not state then return false, "NPC_REQUIRED" end
    if not appendUnique(state.learnedRecipeKeys, recipeKey,
        MAX_RECIPES, MAX_KEY_LENGTH)
    then
        return false, "RECIPE_ALREADY_KNOWN"
    end
    state.revision = state.revision + 1
    record.runtime.recipeKnowledgeIndex = nil
    touch(record, "recipe_knowledge")
    return true, "RECIPE_KNOWN"
end

function Knowledge.Serialize(record)
    local state = stateFor(record)
    if not state or (#state.learnedRecipeKeys == 0
        and #state.readBookTypes == 0)
    then return nil end
    return {
        schemaVersion = SCHEMA_VERSION,
        revision = state.revision,
        learnedRecipeKeys = copyList(state.learnedRecipeKeys),
        readBookTypes = copyList(state.readBookTypes),
    }
end

function Knowledge.BindLiveBody(record, body)
    local state = stateFor(record)
    if not state or not body or type(body.getModData) ~= "function" then
        return false
    end
    local modData = body:getModData()
    if #state.learnedRecipeKeys == 0 and #state.readBookTypes == 0 then
        modData[Knowledge.MODDATA_KEY] = nil
        return true
    end
    local payload = { v = SCHEMA_VERSION, n = state.revision }
    if #state.learnedRecipeKeys > 0 then
        payload.r = copyList(state.learnedRecipeKeys)
    end
    if #state.readBookTypes > 0 then
        payload.b = copyList(state.readBookTypes)
    end
    modData[Knowledge.MODDATA_KEY] = payload
    return true
end

require "PNC/Core/Production/PNC_RecipeKnowledge_Literature"

return Knowledge
