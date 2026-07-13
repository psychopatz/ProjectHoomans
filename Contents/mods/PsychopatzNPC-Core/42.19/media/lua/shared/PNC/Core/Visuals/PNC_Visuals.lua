PNC = PNC or {}
PNC.Visuals = PNC.Visuals or {}

local Visuals = PNC.Visuals
local Profiles = PNC.VisualProfiles

local function normalizeBodyLocation(value)
    local lowered
    local stripped
    local canonical
    local ordered = {
        "UnderwearBottom", "UnderwearTop", "UnderwearExtra1", "UnderwearExtra2", "Underwear", "Codpiece", "Torso1Legs1", "Legs1",
        "Ears", "EarTop", "Nose", "Hat", "FullHat", "SCBA", "Mask", "MaskEyes", "Eyes", "RightEye", "LeftEye",
        "Neck", "Necklace", "Necklace_Long", "Gorget", "Scarf", "Pants", "Pants_Skinny", "PantsExtra", "ShortPants", "ShortsShort",
        "LongSkirt", "Skirt", "Dress", "LongDress", "TankTop", "Tshirt", "ShortSleeveShirt", "Shirt", "Jersey", "VestTexture",
        "Sweater", "SweaterHat", "TorsoExtraVest", "Cuirass", "TorsoExtra", "Jacket", "JacketHat", "Jacket_Down", "JacketHat_Bulky",
        "Jacket_Bulky", "JacketSuit", "FullTop", "RightWrist", "Right_MiddleFinger", "Right_RingFinger", "LeftWrist",
        "Left_MiddleFinger", "Left_RingFinger", "Hands", "HandsRight", "HandsLeft", "BathRobe", "FullSuit", "FullSuitHead",
        "Boilersuit", "Tail", "TorsoExtraVestBullet", "ShoulderpadRight", "ShoulderpadLeft", "Elbow_Right", "Elbow_Left",
        "ForeArm_Right", "ForeArm_Left", "Thigh_Right", "Thigh_Left", "Knee_Right", "Knee_Left", "Calf_Right", "Calf_Left",
        "FannyPackFront", "FannyPackBack", "Webbing", "Back", "AmmoStrap", "AnkleHolster", "BeltExtra", "ShoulderHolster",
        "Socks", "Shoes"
    }
    local i
    value = value and tostring(value) or nil
    if not value then
        return nil
    end
    lowered = string.lower(value)
    stripped = string.match(lowered, "([^:%.]+)$") or lowered
    for i = 1, #ordered do
        canonical = ordered[i]
        if string.lower(canonical) == stripped then
            return canonical
        end
    end
    return value
end

local function makeImmutableColor(color)
    if not color or not ImmutableColor then
        return nil
    end
    return ImmutableColor.new(
        tonumber(color.r) or 0.2,
        tonumber(color.g) or 0.1,
        tonumber(color.b) or 0.1
    )
end

local function clearBodySoiledState(humanVisual)
    local maxIndex
    local i
    local part
    if not humanVisual then
        return
    end
    if humanVisual.removeDirt then
        humanVisual:removeDirt()
    end
    if humanVisual.removeBlood then
        humanVisual:removeBlood()
    end
    if not BloodBodyPartType or not BloodBodyPartType.MAX or not BloodBodyPartType.FromIndex then
        return
    end
    maxIndex = BloodBodyPartType.MAX:index()
    for i = 0, maxIndex - 1 do
        part = BloodBodyPartType.FromIndex(i)
        humanVisual:setBlood(part, 0)
        humanVisual:setDirt(part, 0)
    end
end

function Visuals.ClearBodySoiledState(zombie)
    local humanVisual = zombie and zombie.getHumanVisual and zombie:getHumanVisual() or nil
    clearBodySoiledState(humanVisual)
end

function Visuals.MaintainHumanAppearance(zombie, appearance, isFemale, refreshModel)
    local humanVisual
    local immutableColor
    if not zombie or not appearance then
        return false
    end
    if zombie.setFemaleEtc then
        pcall(zombie.setFemaleEtc, zombie, isFemale == true)
    end
    if zombie.setNoTeeth then
        pcall(zombie.setNoTeeth, zombie, true)
    end
    humanVisual = zombie.getHumanVisual and zombie:getHumanVisual() or nil
    clearBodySoiledState(humanVisual)
    if humanVisual then
        if appearance.skinTexture and humanVisual.setSkinTextureName then
            pcall(humanVisual.setSkinTextureName, humanVisual, appearance.skinTexture)
        end
        if appearance.hairModel and humanVisual.setHairModel then
            pcall(humanVisual.setHairModel, humanVisual, appearance.hairModel)
        end
        if appearance.beardModel and humanVisual.setBeardModel then
            pcall(humanVisual.setBeardModel, humanVisual, appearance.beardModel)
        end
        immutableColor = makeImmutableColor(appearance.hairColor)
        if immutableColor and humanVisual.setHairColor then
            pcall(humanVisual.setHairColor, humanVisual, immutableColor)
        end
        if immutableColor and humanVisual.setBeardColor then
            pcall(humanVisual.setBeardColor, humanVisual, immutableColor)
        end
    end
    if refreshModel == true then
        Visuals.RefreshModel(zombie)
    end
    return true
end

function Visuals.ClearAttachedItems(zombie)
    local attachedItems
    local i
    local entry
    local item
    if not zombie or not zombie.getAttachedItems then
        return
    end
    attachedItems = zombie:getAttachedItems()
    if not attachedItems or not attachedItems.size then
        return
    end
    for i = attachedItems:size() - 1, 0, -1 do
        entry = attachedItems:get(i)
        item = entry and entry.getItem and entry:getItem() or nil
        if item and zombie.removeAttachedItem then
            pcall(function()
                zombie:removeAttachedItem(item)
            end)
        end
    end
end

function Visuals.RefreshModel(zombie)
    if not zombie then
        return
    end
    if zombie.resetModelNextFrame then
        zombie:resetModelNextFrame()
    end
    if zombie.resetModel then
        zombie:resetModel()
    end
end

local function safeSetWornItem(zombie, item)
    local bodyLocation
    if not zombie or not item or not zombie.setWornItem then
        return false
    end
    bodyLocation = item.getBodyLocation and item:getBodyLocation() or nil
    bodyLocation = normalizeBodyLocation(bodyLocation)
    if not bodyLocation or bodyLocation == "" then
        return false
    end
    return pcall(function()
        zombie:setWornItem(bodyLocation, item)
    end)
end

function Visuals.AddClothingVisual(zombie, fullType)
    local itemVisuals
    local itemVisual
    if not zombie or not fullType or not ItemVisual then
        return false, "visual_api_unavailable"
    end
    itemVisuals = zombie.getItemVisuals and zombie:getItemVisuals() or nil
    if not itemVisuals or not itemVisuals.add then
        return false, "missing_item_visuals"
    end
    itemVisual = ItemVisual.new()
    if itemVisual.setItemType then
        itemVisual:setItemType(fullType)
    end
    if itemVisual.setClothingItemName then
        itemVisual:setClothingItemName(fullType)
    end
    itemVisuals:add(itemVisual)
    return true, "visual_added"
end

local function applyBaseOutfitItems(zombie, appearance)
    local equipment = PNC.Equipment
    local items
    local i
    local item
    local reason
    if not zombie or not appearance then
        return
    end
    items = appearance.outfitItems
    if type(items) ~= "table" or not equipment or not equipment.CreateItem then
        return
    end
    for i = 1, #items do
        if not Visuals.AddClothingVisual(zombie, items[i]) then
            item, reason = equipment.CreateItem(items[i])
            if item then
                safeSetWornItem(zombie, item)
            elseif reason and reason ~= "invalid_full_type" then
                PNC.Core.LogWarn("PNC visuals could not create outfit item " .. tostring(items[i]) .. ": " .. tostring(reason))
            end
        end
    end
end

function Visuals.ApplyResolvedAppearance(zombie, appearance, isFemale)
    local humanVisual
    local itemVisuals
    local wornItems

    if not zombie or not appearance then
        return
    end

    if zombie.setFemaleEtc then
        zombie:setFemaleEtc(isFemale == true)
    end

    humanVisual = zombie.getHumanVisual and zombie:getHumanVisual() or nil
    itemVisuals = zombie.getItemVisuals and zombie:getItemVisuals() or nil
    wornItems = zombie.getWornItems and zombie:getWornItems() or nil

    if itemVisuals and itemVisuals.clear then
        itemVisuals:clear()
    end
    if wornItems and wornItems.clear then
        wornItems:clear()
    end

    Visuals.ClearAttachedItems(zombie)
    clearBodySoiledState(humanVisual)

    if zombie.dressInNamedOutfit then
        zombie:dressInNamedOutfit(appearance.outfit)
    end
    applyBaseOutfitItems(zombie, appearance)

    Visuals.MaintainHumanAppearance(zombie, appearance, isFemale, true)
end

function Visuals.ApplyHumanVisuals(zombie, record)
    local appearance
    if not zombie or not record then
        return
    end
    appearance = Profiles.RollAppearance(record)
    Visuals.ApplyResolvedAppearance(zombie, appearance, record.isFemale == true)
end
