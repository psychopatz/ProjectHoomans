-- Inspect the loaded clothing asset. Script module and mod ownership are
-- irrelevant once the engine has resolved the item's clothing definition.
local Variants = {}
local palette = {
    { "000000", 0.08, 0.08, 0.08 }, { "FFFFFF", 1, 1, 1 },
    { "929292", 0.57, 0.57, 0.57 }, { "9F382D", 0.62, 0.22, 0.18 },
    { "BA7647", 0.73, 0.46, 0.28 }, { "BCA650", 0.74, 0.65, 0.31 },
    { "52754C", 0.32, 0.46, 0.30 }, { "436A9A", 0.26, 0.42, 0.60 },
    { "79618D", 0.47, 0.38, 0.55 }, { "AF6482", 0.69, 0.39, 0.51 },
}

local function textures(groups, values, field, key, label, state)
    if not values or values:size() < 2 then return end
    local group = { field = field, key = key, label = label, options = {} }
    local selected = (tonumber(state[field]) or -1) + 1
    for index = 0, values:size() - 1 do
        local path = tostring(values:get(index))
        local name = string.match(path, "([^/]+)$") or path
        group.options[index + 1] = { value = index, label = name }
    end
    group.selected = math.max(1, math.min(#group.options, selected))
    groups[#groups + 1] = group
end

-- Build 42 exposes native decal selection through ItemVisual. Sample the
-- active asset's decal group once per visited item, including loaded mods.
function Variants.Decals(item, original)
    local options, seen = {}, {}
    local clothing = item.getClothingItem and item:getClothingItem()
    if not clothing or not clothing.getDecalGroup or not ItemVisual or not ItemVisual.new
        or clothing.isReady and not clothing:isReady() then return options end
    local group = clothing:getDecalGroup()
    if not group or group == "" then return options end
    local function add(name)
        if not name or name == "" or seen[name] then return end
        seen[name] = true
        options[#options + 1] = { value = name, label = name }
    end
    add(original.decal)
    local probe = ItemVisual.new()
    for _ = 1, 20 do
        probe:setDecal(nil)
        add(probe:getDecal(clothing))
    end
    return options
end

function Variants.Describe(item, state, decals)
    local groups = {}
    local clothing = item.getClothingItem and item:getClothingItem()
    if not clothing or clothing.isReady and not clothing:isReady() then return groups end
    state = state or {}
    textures(groups, clothing:getBaseTextures(), "baseTexture",
        "UI_PNC_Authoring_BaseDesign", "Base design", state)
    textures(groups, clothing:getTextureChoices(), "textureChoice",
        "UI_PNC_Authoring_Design", "Design", state)
    if decals and #decals > 1 then
        local selected = 1
        for index, option in ipairs(decals) do
            if option.value == state.decal then selected = index end
        end
        groups[#groups + 1] = { field = "decal", key = "UI_PNC_Authoring_Print",
            label = "Print", options = decals, selected = selected }
    end
    if clothing.getAllowRandomHue and clothing:getAllowRandomHue() then
        local options = { { value = false, key = "UI_PNC_Authoring_OriginalColor", label = "Original color" } }
        local selected = 1
        for index = -4, 4 do
            local value = index / 5
            options[#options + 1] = { value = value, label = tostring(index * 20) .. "%" }
            if state.hue and math.abs(state.hue - value) < .005 then selected = #options end
        end
        groups[#groups + 1] = { field = "hue", key = "UI_PNC_Authoring_Hue",
            label = "Hue shift", options = options, selected = selected }
    end
    if clothing:getAllowRandomTint() or state.customColor then
        local current = state.customColor and state.color or state.tint
        local options = { { value = false, key = "UI_PNC_Authoring_OriginalColor", label = "Original color" } }
        local selected = 1
        for _, color in ipairs(palette) do
            local value = { r = color[2], g = color[3], b = color[4] }
            options[#options + 1] = { value = value, label = "#" .. color[1] }
            if current and math.abs(current.r - value.r) < .005
                and math.abs(current.g - value.g) < .005 and math.abs(current.b - value.b) < .005 then
                selected = #options
            end
        end
        groups[#groups + 1] = { field = "color", key = "UI_PNC_Authoring_ItemColor",
            label = "Color", options = options, selected = selected }
    end
    return groups
end

function Variants.Apply(item, spec, original, field, value)
    local equipment = PNC.Equipment
    local state = equipment.VisualStateFromItemState(spec.itemState, spec.type) or { fullType = spec.type }
    if field == "color" then
        state.color = value or original.color
        state.tint = value or original.tint
        state.customColor = value ~= false or original.customColor == true
    elseif field == "hue" then
        state.hue = value or original.hue
    else
        state[field] = value
    end
    equipment.StoreVisualStateInItemState(spec, state)
    equipment.Internal.applyItemVisualState(item, state)
end

return Variants
