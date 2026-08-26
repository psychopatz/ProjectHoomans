PNC = PNC or {}
PNC.Visuals = PNC.Visuals or {}

local Visuals = PNC.Visuals
local Profiles = PNC.VisualProfiles
local Core = PNC.Core

local function isNetworkedGame()
    return (isClient and isClient() == true)
        or (isServer and isServer() == true)
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
        immutableColor = makeImmutableColor(appearance.skinColor)
        if immutableColor and humanVisual.setSkinColor then
            pcall(humanVisual.setSkinColor, humanVisual, immutableColor)
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
    if not bodyLocation then
        return false
    end
    if Core and Core.ProtectClothingFromFall then
        Core.ProtectClothingFromFall(item)
    end
    return pcall(function()
        zombie:setWornItem(bodyLocation, item)
    end)
end

function Visuals.AddClothingVisual(zombie, fullType, visualState)
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
    if visualState then
        if visualState.baseTexture ~= nil
            and itemVisual.setBaseTexture
        then
            itemVisual:setBaseTexture(
                tonumber(visualState.baseTexture) or -1
            )
        end
        if visualState.textureChoice ~= nil
            and itemVisual.setTextureChoice
        then
            itemVisual:setTextureChoice(
                tonumber(visualState.textureChoice) or -1
            )
        end
        if visualState.decal ~= nil
            and itemVisual.setDecal
        then
            itemVisual:setDecal(tostring(visualState.decal))
        end
        if visualState.tint
            and ImmutableColor
            and itemVisual.setTint
        then
            itemVisual:setTint(ImmutableColor.new(
                tonumber(visualState.tint.r) or 1,
                tonumber(visualState.tint.g) or 1,
                tonumber(visualState.tint.b) or 1,
                1
            ))
        end
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

-- Multiplayer bodies keep their worn inventory and ItemVisuals under server
-- ownership.  The client may repair human-only fields, but must never clear or
-- rebuild clothing: native zombie/equipment packets apply those collections.
function Visuals.ApplyReplicaAppearance(zombie, appearance, isFemale)
    local humanVisual
    if not zombie or not appearance then
        return false, "missing_body_or_appearance"
    end
    humanVisual = zombie.getHumanVisual and zombie:getHumanVisual() or nil
    clearBodySoiledState(humanVisual)
    Visuals.MaintainHumanAppearance(
        zombie,
        appearance,
        isFemale,
        true
    )
    return true, "replica_appearance"
end

function Visuals.HasClothingVisuals(zombie)
    local itemVisuals
    if not zombie or not zombie.getItemVisuals then
        return false
    end
    itemVisuals = zombie:getItemVisuals()
    return itemVisuals
        and itemVisuals.size
        and itemVisuals:size() > 0
        or false
end

function Visuals.ApplyHumanVisuals(zombie, record)
    local appearance
    if not zombie or not record then
        return
    end
    appearance = Profiles.RollAppearance(record)
    if isNetworkedGame() then
        Visuals.ApplyReplicaAppearance(
            zombie,
            appearance,
            record.isFemale == true
        )
    else
        Visuals.ApplyResolvedAppearance(
            zombie,
            appearance,
            record.isFemale == true
        )
    end
end
