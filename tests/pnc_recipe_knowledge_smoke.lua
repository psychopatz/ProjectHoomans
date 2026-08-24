local T = require "tests/support/test"
T.addPackagePaths()

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, entry in pairs(value) do output[key] = copy(entry) end
    return output
end

local descriptor = {
    key = "Base.MakeWoodenSpear", name = "Make Wooden Spear",
    needToBeLearn = true,
}
local catalog = {
    Queries = {
        Get = function(_, key)
            return tostring(key) == descriptor.key and descriptor or nil
        end,
        List = function() return { descriptor } end,
    },
}
local xpCalls = 0
PNC = {
    Core = { DeepCopy = copy },
    RecipeCatalog = catalog,
    Skills = { AddXP = function() xpCalls = xpCalls + 1; return true end },
}

local Knowledge = require "PNC/Core/Production/PNC_RecipeKnowledge"
local record = { id = "npc-1", recruited = true, runtime = {} }
local item = {
    getFullType = function() return "Base.BookSpear" end,
    getLearnedRecipes = function()
        return { size = function() return 1 end,
            get = function(_, index)
                return index == 0 and "Make Wooden Spear" or nil
            end }
    end,
    getSkillTrained = function() return "Carpentry" end,
    getLvlSkillTrained = function() return 2 end,
}

T.falsy(Knowledge.Queries.CanCraft(record, descriptor),
    "book recipe starts unknown")
local bodyData = {}
local readCalled = false
local body = {
    getModData = function() return bodyData end,
    ReadLiterature = function(_, nativeItem)
        readCalled = nativeItem == item
    end,
}
local ok, reason, details = Knowledge.Commands.ReadBook(record, item, {
    fullType = "Base.BookSpear", liveBody = body, nativeItem = item,
})
T.truthy(ok, "book read")
T.equal(reason, "BOOK_READ", "book read reason")
T.truthy(readCalled, "engine literature call")
T.equal(details.skillID, "Carpentry", "skill book metadata")
T.equal(xpCalls, 1, "skill book xp")
T.truthy(Knowledge.Queries.HasRecipe(record, descriptor.key),
    "recipe learned by book")
T.truthy(Knowledge.Queries.HasReadBook(record, "Base.BookSpear"),
    "book persisted in npc state")
T.truthy(Knowledge.Queries.CanCraft(record, descriptor),
    "learned recipe can craft")
T.equal(bodyData.PNC_RecipeKnowledge.v, 1, "compact body moddata version")
T.equal(bodyData.PNC_RecipeKnowledge.r[1], descriptor.key,
    "compact body recipe array")

local saved = Knowledge.Serialize(record)
T.equal(#saved.learnedRecipeKeys, 1, "compact persisted recipe array")
T.equal(#saved.readBookTypes, 1, "compact persisted book array")
local normalized = Knowledge.Normalize({ v = 1, n = saved.revision,
    r = saved.learnedRecipeKeys, b = saved.readBookTypes })
T.equal(normalized.learnedRecipeKeys[1], descriptor.key,
    "short persisted form normalizes")
T.equal(Knowledge.Commands.ReadBook(record, item, {
    fullType = "Base.BookSpear" }), true, "duplicate read is idempotent")
T.equal(Knowledge.Queries.CanCraft(record, {
    key = "Base.FreeRecipe", needToBeLearn = false }), true,
    "recipes without literature remain available")

T.finish("pnc_recipe_knowledge_smoke")
