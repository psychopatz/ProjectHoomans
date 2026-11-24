-- Canonical world-item scavenge category definitions.
PNC = PNC or {}
PNC.WorldItemCategories = PNC.WorldItemCategories or {}

local Categories = PNC.WorldItemCategories

Categories.ORDER = {
    "food",
    "water",
    "medical",
    "weapons",
    "ammo",
    "tools",
    "materials",
    "clothing",
}

Categories.DEFINITIONS = {
    food = {
        id = "food",
        order = 10,
        labelKey = "UI_PNC_ScavengeCategory_Food",
        label = "Food",
    },
    water = {
        id = "water",
        order = 20,
        labelKey = "UI_PNC_ScavengeCategory_Water",
        label = "Water",
    },
    medical = {
        id = "medical",
        order = 30,
        labelKey = "UI_PNC_ScavengeCategory_Medical",
        label = "Medical",
    },
    weapons = {
        id = "weapons",
        order = 40,
        labelKey = "UI_PNC_ScavengeCategory_Weapons",
        label = "Weapons",
    },
    ammo = {
        id = "ammo",
        order = 50,
        labelKey = "UI_PNC_ScavengeCategory_Ammo",
        label = "Ammo",
    },
    tools = {
        id = "tools",
        order = 60,
        labelKey = "UI_PNC_ScavengeCategory_Tools",
        label = "Tools",
    },
    materials = {
        id = "materials",
        order = 70,
        labelKey = "UI_PNC_ScavengeCategory_Materials",
        label = "Materials",
    },
    clothing = {
        id = "clothing",
        order = 80,
        labelKey = "UI_PNC_ScavengeCategory_Clothing",
        label = "Clothing",
    },
}

local ALIASES = {
    drink = "water",
    hydration = "water",
    meds = "medical",
    firstaid = "medical",
    weapon = "weapons",
    firearm = "weapons",
    ammunition = "ammo",
    tool = "tools",
    material = "materials",
    clothes = "clothing",
    apparel = "clothing",
}

function Categories.ResolveID(raw)
    local key = string.lower(tostring(raw or ""))
    if Categories.DEFINITIONS[key] then return key end
    return ALIASES[key]
end

function Categories.Get(id)
    local resolved = Categories.ResolveID(id)
    return resolved and Categories.DEFINITIONS[resolved] or nil
end

function Categories.List()
    local output = {}
    for index = 1, #Categories.ORDER do
        output[#output + 1] = Categories.DEFINITIONS[Categories.ORDER[index]]
    end
    return output
end

function Categories.Defaults(defaultValue)
    local output = {}
    local enabled = defaultValue == true
    for index = 1, #Categories.ORDER do
        output[Categories.ORDER[index]] = enabled
    end
    return output
end

function Categories.NormalizeCategories(value)
    local output = Categories.Defaults(false)
    if type(value) ~= "table" then return output end
    for key, entry in pairs(value) do
        local resolved = Categories.ResolveID(key)
        if resolved and entry == true then
            output[resolved] = true
        elseif type(key) == "number" and type(entry) == "string" then
            local fromList = Categories.ResolveID(entry)
            if fromList then output[fromList] = true end
        end
    end
    return output
end

function Categories.HasAnyEnabled(value)
    if type(value) ~= "table" then return false end
    for index = 1, #Categories.ORDER do
        if value[Categories.ORDER[index]] == true then
            return true
        end
    end
    return false
end

return Categories
