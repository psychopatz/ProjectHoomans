-- Hidden makeup definitions are wearable face layers with separate UI metadata.
local Cosmetics = {}
local products = {
    makeupfullface = "MakeupFoundation",
    makeupeyes = "MakeupEyeshadow",
    makeupeyesshadow = "MakeupEyeshadow",
    makeuplips = "Lipstick",
}

local function locationKey(location)
    local suffix = tostring(location or ""):match("([^:]+)$") or ""
    return suffix:lower():gsub("[^%w]", "")
end

function Cosmetics.IsMakeup(location)
    return products[locationKey(location)] ~= nil
end

function Cosmetics.Labels()
    local labels = {}
    for _, entry in ipairs(MakeUpDefinitions and MakeUpDefinitions.makeup or {}) do
        if entry.item and entry.name then
            local key = "MakeUpType_" .. entry.name
            local label = getText and getText(key)
            if label and label ~= key then labels[entry.item] = label end
        end
    end
    return labels
end

function Cosmetics.FallbackLabel(id)
    local name = tostring(id):match("[^.]+$") or tostring(id)
    name = name:gsub("^[Mm][Aa][Kk][Ee][Uu][Pp]_?", ""):gsub("_", " ")
    name = name:gsub("(%l)(%u)", "%1 %2"):gsub("(%a)(%d)", "%1 %2")
    return name ~= "" and name or id
end

function Cosmetics.Texture(script, location)
    if not getTexture then return nil end
    local product = products[locationKey(location)]
    if not product then return nil end
    -- Face layers use a full-body UV image with only a few painted pixels.
    -- The matching product is a readable inventory icon at tile size.
    local icon = getTexture("Item_" .. product)
    if icon then return icon end
    local asset = script.getClothingItemAsset and script:getClothingItemAsset()
    local textures = asset and asset.getBaseTextures and asset:getBaseTextures()
    if textures and textures:size() > 0 then
        local path = tostring(textures:get(0)):gsub("\\", "/")
        return getTexture("media/textures/" .. path .. ".png")
    end
end

local blockers = {
    eyes = true, mask = true, maskeyes = true, maskfull = true,
    fullhat = true, fullsuithead = true, fullsuitheadscba = true,
    scba = true, scbanotank = true, hat = true, hathelmet = true,
}

function Cosmetics.FacePreview(spec)
    if not spec then return nil end
    local copy = PNC.NPCAuthoring.Registry.Copy(spec)
    local equipment, appearance = copy.equipment, copy.appearance
    for location in pairs(equipment and equipment.worn or {}) do
        if blockers[locationKey(location)] then
            equipment.worn[location] = nil
            if equipment.wornVisuals then equipment.wornVisuals[location] = nil end
        end
    end
    if appearance then
        -- The worn map already contains the resolved outfit, including makeup.
        appearance.outfit, appearance.outfitItems, appearance.outfitItemSpecs = nil, {}, {}
    end
    copy.key = tostring(copy.key or copy.id or "") .. ":makeup"
    return copy
end

return Cosmetics
