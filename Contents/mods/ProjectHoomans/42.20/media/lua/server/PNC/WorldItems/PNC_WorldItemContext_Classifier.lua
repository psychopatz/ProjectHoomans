-- Semantic item classifier and filter matching for world-item interaction.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorldItemContext = PNC.WorldItemContext or {}
PNC.WorldItemContext.Classifier = PNC.WorldItemContext.Classifier or {}

local Classifier = PNC.WorldItemContext.Classifier
local RipRules = PNC.WorldItemContext.RipRules
local Categories = PNC.WorldItemCategories
local Treatment = PNC.Treatment

local function safeCall(obj, method, ...)
    if not obj or type(obj[method]) ~= "function" then return nil end
    local ok, value = pcall(obj[method], obj, ...)
    return ok and value or nil
end

local function isJavaType(item, className)
    if not item or not instanceof then return false end
    local ok, result = pcall(instanceof, item, className)
    return ok and result == true
end

local function hasItemTag(item, tagKey, fallbackName)
    if not item or type(item.hasTag) ~= "function" then return false end
    local tagObj = ItemTag and ItemTag[tagKey] or nil
    if tagObj ~= nil then
        return safeCall(item, "hasTag", tagObj) == true
    end
    if type(item) == "table" and fallbackName ~= nil then
        return safeCall(item, "hasTag", fallbackName) == true
    end
    return false
end

local function classifyFood(item, cat, util)
    local isFood = (util and util.food == true) or isJavaType(item, "Food")
        or safeCall(item, "IsFood") == true or cat == "food"
        or (type(item) == "table" and item.isFood == true)
    if not isFood then return nil end
    local hc = tonumber(safeCall(item, "getHungChange"))
        or tonumber(safeCall(item, "getHungerChange"))
        or (type(item) == "table" and tonumber(item.hungChange)) or 0
    local hunger = util and tonumber(util.hunger) or math.max(0, hc < 0 and -hc or 0)
    local unsafe = (util and util.unsafe == true) or safeCall(item, "isRotten") == true
        or safeCall(item, "isPoison") == true or safeCall(item, "isBurnt") == true
        or (type(item) == "table" and (item.rotten == true or item.poison == true or item.burnt == true))
    if hunger <= 0 and not (util and util.food == true) and cat ~= "food" then return nil end
    return { edible = true, hunger = hunger > 0 and hunger or 0.15, unsafe = unsafe == true }
end

local function isMedicalType(fullType, cat, util)
    local dirty = string.find(tostring(fullType or ""), "Dirty", 1, true) ~= nil
    if (util and util.bandage == true and not dirty)
        or (Treatment and Treatment.IsBandageType and Treatment.IsBandageType(fullType))
    then
        return true, not dirty
    end
    return cat == "firstaid" or cat == "medical", false
end

local function classifyCategories(item, fullType, cat, util, food, isMed, rip)
    local cats = {}
    if food then cats.food = true end
    if (util and util.hydration == true) or safeCall(item, "isWaterSource") == true or cat == "water" then
        cats.water = true
    end
    if isMed then cats.medical = true end
    if isJavaType(item, "HandWeapon") or safeCall(item, "IsWeapon") == true
        or cat == "weapon" or cat == "weapons" or (type(item) == "table" and item.isWeapon == true)
    then
        cats.weapons = true
    end
    if cat == "ammo" or cat == "weaponpart" or safeCall(item, "getMaxAmmo") ~= nil
        or string.find(fullType, "Bullets", 1, true) ~= nil
        or string.find(fullType, "Ammo", 1, true) ~= nil or (type(item) == "table" and item.isAmmo == true)
    then
        cats.ammo = true
    end
    if cat == "tool" or cat == "tools" or hasItemTag(item, "HAMMER", "Hammer")
        or hasItemTag(item, "SCREWDRIVER", "Screwdriver") or hasItemTag(item, "SCISSORS", "Scissors")
        or (type(item) == "table" and item.isTool == true)
    then
        cats.tools = true
    end
    if cat == "material" or cat == "materials" or cat == "junk" or cat == "literature"
        or (type(item) == "table" and item.isMaterial == true)
    then
        cats.materials = true
    end
    if rip or isJavaType(item, "Clothing") or safeCall(item, "IsClothing") == true
        or cat == "clothing" or (type(item) == "table" and item.isClothing == true)
    then
        cats.clothing = true
    end
    return cats
end

function Classifier.InspectItem(item, options)
    if not item then return nil end
    local fullType = tostring(safeCall(item, "getFullType")
        or (type(item) == "table" and (item.fullType or item.type)) or "")
    if fullType == "" then return nil end

    local name = tostring(safeCall(item, "getDisplayName") or safeCall(item, "getName")
        or (type(item) == "table" and item.displayName) or fullType)
    local cat = string.lower(tostring(safeCall(item, "getCategory")
        or (type(item) == "table" and item.category) or ""))
    local util = PNC.ItemUtility and PNC.ItemUtility.DescribeItem
        and PNC.ItemUtility.DescribeItem(item, 1) or nil

    local rip = RipRules and RipRules.InspectRippable
        and RipRules.InspectRippable(item, fullType, cat, options) or nil
    local food = classifyFood(item, cat, util)
    local isMed, isBandage = isMedicalType(fullType, cat, util)
    return {
        fullType = fullType, displayName = name, rawCategory = cat,
        categories = classifyCategories(item, fullType, cat, util, food, isMed, rip),
        food = food, medical = isMed and { isMedical = true, isBandage = isBandage } or nil,
        rippable = rip,
    }
end

function Classifier.MatchesFilter(itemCtx, filter, options)
    if not itemCtx or not filter then return false, 0 end
    options = type(options) == "table" and options or {}
    if type(filter.predicate) == "function" then
        local matched, score = filter.predicate(itemCtx, options)
        return matched == true, tonumber(score) or 1
    end
    if filter.mode == "rip_bandage" then
        local rip = itemCtx.rippable
        if not rip or not rip.canRip or not rip.usableForBandage then return false, 0 end
        if rip.requiresScissors and options.hasScissors ~= true then return false, 0 end
        return true, 10 + (not rip.requiresScissors and 20 or 0)
            + (rip.outputType == "Base.RippedSheets" and 10 or 0) + (rip.clean and 5 or 0)
    end
    local wanted = filter.categories
    if type(wanted) ~= "table" then return false, 0 end
    local best = 0
    for id, enabled in pairs(wanted) do
        local key = Categories and Categories.ResolveID and Categories.ResolveID(id) or tostring(id)
        if enabled == true and itemCtx.categories[key] == true then
            if key == "food" then
                if itemCtx.food and (filter.excludeUnsafe == false or not itemCtx.food.unsafe) then
                    best = math.max(best, 20 + (tonumber(itemCtx.food.hunger) or 0) * 10)
                end
            elseif key == "medical" then
                best = math.max(best, itemCtx.medical and itemCtx.medical.isBandage and 25 or 15)
            else
                best = math.max(best, 10)
            end
        end
    end
    return best > 0, best
end

PNC.WorldItemContext.InspectItem = Classifier.InspectItem

return Classifier
