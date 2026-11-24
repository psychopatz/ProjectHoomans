-- Build 42 vanilla XP curves, multipliers, and native weapon-category skill mapping.
PNC = PNC or {}
PNC.Skills = PNC.Skills or {}

local Curves = {}
PNC.Skills.Curves = Curves

local ACTIVE_THRESHOLDS = {
    75, 150, 300, 750, 1500, 3000, 4500, 6000, 7500, 9000,
}

local PASSIVE_THRESHOLDS = {
    1500, 3000, 6000, 9000, 18000, 30000, 60000, 90000, 120000, 150000,
}

local PASSIVE_SKILLS = {
    Fitness = true,
    Strength = true,
}

local COMBAT_SKILLS = {
    Axe = true,
    LongBlade = true,
    LongBlunt = true,
    ShortBlade = true,
    ShortBlunt = true,
    Spear = true,
    Aiming = true,
}

local CRAFTING_SKILLS = {
    Blacksmithing = true,
    Carpentry = true,
    Carving = true,
    Cooking = true,
    Electrical = true,
    Glassmaking = true,
    Knapping = true,
    Masonry = true,
    Mechanics = true,
    Pottery = true,
    Tailoring = true,
    Welding = true,
}

local CATEGORY_TO_SKILL = {
    axe = "Axe",
    longblade = "LongBlade",
    smallblade = "ShortBlade",
    shortblade = "ShortBlade",
    blunt = "LongBlunt",
    longblunt = "LongBlunt",
    smallblunt = "ShortBlunt",
    shortblunt = "ShortBlunt",
    spear = "Spear",
    firearm = "Aiming",
    ranged = "Aiming",
}

local weaponSkillCache = {}

function Curves.IsPassive(skillID)
    return PASSIVE_SKILLS[tostring(skillID or "")] == true
end

function Curves.NormalizeSkillID(skillID)
    local id = tostring(skillID or "")
    if id == "Woodwork" then return "Carpentry" end
    if id == "MetalWelding" or id == "Metalwork" then return "Welding" end
    if id == "Doctor" then return "FirstAid" end
    if id == "Farming" then return "Agriculture" end
    if id == "Blunt" then return "LongBlunt" end
    if id == "SmallBlunt" then return "ShortBlunt" end
    if id == "SmallBlade" then return "ShortBlade" end
    if id == "Lightfoot" then return "Lightfooted" end
    if id == "Sneak" then return "Sneaking" end
    return id ~= "" and id or nil
end

function Curves.GetThreshold(skillID, level)
    local idx = math.max(1, math.min(10, math.floor(tonumber(level) or 0) + 1))
    if Curves.IsPassive(skillID) then
        return PASSIVE_THRESHOLDS[idx]
    end
    return ACTIVE_THRESHOLDS[idx]
end

local function hasTrait(record, traitID)
    local traits = record and record.traits or nil
    if type(traits) ~= "table" then return false end
    if traits[traitID] == true then return true end
    local lowered = string.lower(traitID)
    for i = 1, #traits do
        if string.lower(tostring(traits[i] or "")) == lowered then
            return true
        end
    end
    return false
end

local function sandboxGlobalXPMultiplier(isPassive)
    local vars = SandboxVars
    if type(vars) ~= "table" then return 1.0 end
    if isPassive and vars.XpMultiplierAffectsPassive == false then
        return 1.0
    end
    local mult = tonumber(vars.XpMultiplier)
    if mult and mult > 0 then return mult end
    return 1.0
end

function Curves.ResolveXPMultiplier(record, skillID, baseLevel, options)
    options = type(options) == "table" and options or {}
    if options.noMultiplier == true then return 1.0 end
    local passive = Curves.IsPassive(skillID)
    local mod = 1.0
    if not passive then
        local lvl = math.max(0, math.floor(tonumber(baseLevel) or 0))
        if lvl == 0 then
            mod = 0.25
        elseif lvl == 1 then
            mod = skillID == "Sprinting" and 1.25 or 1.0
        elseif lvl == 2 then
            mod = 1.33
        else
            mod = 1.66
        end
        if hasTrait(record, "FastLearner") then mod = mod * 1.3 end
        if hasTrait(record, "SlowLearner") then mod = mod * 0.7 end
        if hasTrait(record, "Pacifist") and COMBAT_SKILLS[skillID] then
            mod = mod * 0.75
        end
        if hasTrait(record, "Crafty") and CRAFTING_SKILLS[skillID] then
            mod = mod * 1.3
        end
    elseif skillID == "Strength" then
        local proteins = record and record.nutrition
            and tonumber(record.nutrition.proteins)
            or nil
        if proteins ~= nil then
            if proteins > 50 and proteins < 300 then
                mod = mod * 1.5
            elseif proteins < -300 then
                mod = mod * 0.7
            end
        end
    end
    mod = mod * sandboxGlobalXPMultiplier(passive)
    return mod
end

local function resolveFromCategoryList(categories)
    if not categories then return nil end
    if type(categories) == "table" then
        for i = 1, #categories do
            local mapped = CATEGORY_TO_SKILL[string.lower(tostring(categories[i] or ""))]
            if mapped then return mapped end
        end
    elseif categories.size and categories.get then
        local count = categories:size()
        for i = 0, count - 1 do
            local mapped = CATEGORY_TO_SKILL[string.lower(tostring(categories:get(i) or ""))]
            if mapped then return mapped end
        end
    end
    return nil
end

function Curves.ResolveWeaponSkill(fullType, combatMode, weaponItem)
    if tostring(combatMode or "") == "ranged" then return "Aiming" end
    if weaponItem then
        if weaponItem.isRanged and weaponItem:isRanged() == true then
            return "Aiming"
        end
        if weaponItem.getCategories then
            local ok, cats = pcall(weaponItem.getCategories, weaponItem)
            local mapped = ok and resolveFromCategoryList(cats) or nil
            if mapped then return mapped end
        end
    end
    local key = tostring(fullType or "")
    if key == "" then return "Strength" end
    local cached = weaponSkillCache[key]
    if cached ~= nil then return cached end
    if getScriptManager and getScriptManager().getItem then
        local scriptItem = getScriptManager():getItem(key)
        if scriptItem and scriptItem.getCategories then
            local ok, cats = pcall(scriptItem.getCategories, scriptItem)
            local mapped = ok and resolveFromCategoryList(cats) or nil
            if mapped then
                weaponSkillCache[key] = mapped
                return mapped
            end
        end
    end
    local lowered = string.lower(key)
    local resolved = "Strength"
    if lowered:find("shotgun", 1, true) or lowered:find("pistol", 1, true)
        or lowered:find("revolver", 1, true) or lowered:find("rifle", 1, true)
        or lowered:find("gun", 1, true)
    then
        resolved = "Aiming"
    elseif lowered:find("axe", 1, true) or lowered:find("hatchet", 1, true) then
        resolved = "Axe"
    elseif lowered:find("katana", 1, true) or lowered:find("machete", 1, true)
        or lowered:find("longblade", 1, true) or lowered:find("sword", 1, true)
    then
        resolved = "LongBlade"
    elseif lowered:find("spear", 1, true) then
        resolved = "Spear"
    elseif lowered:find("knife", 1, true) or lowered:find("dagger", 1, true)
        or lowered:find("shiv", 1, true) or lowered:find("cleaver", 1, true)
    then
        resolved = "ShortBlade"
    elseif lowered:find("hammer", 1, true) or lowered:find("wrench", 1, true)
        or lowered:find("nightstick", 1, true) or lowered:find("pan", 1, true)
    then
        resolved = "ShortBlunt"
    elseif lowered:find("bat", 1, true) or lowered:find("crowbar", 1, true)
        or lowered:find("pipe", 1, true) or lowered:find("rollingpin", 1, true)
        or lowered:find("shovel", 1, true) or lowered:find("sledge", 1, true)
    then
        resolved = "LongBlunt"
    end
    weaponSkillCache[key] = resolved
    return resolved
end

return Curves
