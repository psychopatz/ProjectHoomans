PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}

local Equipment = PNC.Equipment

local MANAGED_ATTACHMENT_TYPES = {
    Back = true,
    HolsterLeft = true,
    HolsterRight = true,
    HolsterShoulder = true,
    SmallBeltLeft = true,
    SmallBeltRight = true,
    WebbingLeft = true,
    WebbingRight = true,
}

local MANAGED_SLOT_TYPE_PRIORITY = {
    HolsterRight = 1,
    HolsterLeft = 2,
    HolsterShoulder = 3,
    SmallBeltLeft = 4,
    SmallBeltRight = 5,
    WebbingLeft = 6,
    WebbingRight = 7,
    Back = 8,
}

local ATTACHMENT_TYPE_SLOT_PRIORITY = {
    BigBlade = { "Back" },
    BigWeapon = { "Back" },
    Guitar = { "Back" },
    GuitarAcoustic = { "Back" },
    Hammer = { "SmallBeltLeft", "SmallBeltRight" },
    HammerRotated = { "SmallBeltLeft", "SmallBeltRight" },
    Holster = { "HolsterRight", "HolsterLeft", "HolsterShoulder" },
    HolsterSmall = { "HolsterRight", "HolsterLeft", "HolsterShoulder" },
    Knife = { "SmallBeltLeft", "SmallBeltRight", "WebbingLeft", "WebbingRight" },
    MeatCleaver = { "SmallBeltLeft", "SmallBeltRight" },
    Nightstick = { "SmallBeltLeft", "SmallBeltRight" },
    NotKnife = { "SmallBeltLeft", "SmallBeltRight" },
    Pan = { "Back" },
    Racket = { "Back" },
    Rifle = { "Back" },
    Saucepan = { "Back" },
    Screwdriver = { "SmallBeltLeft", "SmallBeltRight" },
    Shovel = { "Back" },
    Sword = { "Back", "SmallBeltLeft", "SmallBeltRight" },
    Walkie = { "SmallBeltLeft", "SmallBeltRight", "WebbingLeft", "WebbingRight" },
    Webbing = { "WebbingLeft", "WebbingRight" },
    Wrench = { "SmallBeltLeft", "SmallBeltRight" },
}

local BODY_LOCATIONS_ORDERED = {
    "UnderwearBottom", "UnderwearTop", "UnderwearExtra1", "UnderwearExtra2", "Underwear", "Codpiece", "Torso1Legs1", "Legs1",
    "Ears", "EarTop", "Nose", "Hat", "FullHat", "SCBA",
    "Mask", "MaskEyes", "Eyes", "RightEye", "LeftEye",
    "Neck", "Necklace", "Necklace_Long", "Gorget", "Scarf",
    "Pants", "Pants_Skinny", "PantsExtra", "ShortPants", "ShortsShort", "LongSkirt", "Skirt", "Dress", "LongDress",
    "TankTop", "Tshirt", "ShortSleeveShirt", "Shirt", "Jersey",
    "VestTexture", "Sweater", "SweaterHat", "TorsoExtraVest", "Cuirass", "TorsoExtra",
    "Jacket", "JacketHat", "Jacket_Down", "JacketHat_Bulky", "Jacket_Bulky", "JacketSuit", "FullTop",
    "RightWrist", "Right_MiddleFinger", "Right_RingFinger", "LeftWrist", "Left_MiddleFinger", "Left_RingFinger", "Hands", "HandsRight", "HandsLeft",
    "BathRobe", "FullSuit", "FullSuitHead", "Boilersuit", "Tail", "TorsoExtraVestBullet",
    "ShoulderpadRight", "ShoulderpadLeft", "Elbow_Right", "Elbow_Left", "ForeArm_Right", "ForeArm_Left",
    "Thigh_Right", "Thigh_Left", "Knee_Right", "Knee_Left", "Calf_Right", "Calf_Left",
    "FannyPackFront", "FannyPackBack", "Webbing", "Back",
    "AmmoStrap", "AnkleHolster", "BeltExtra", "ShoulderHolster",
    "Socks", "Shoes"
}

local BODY_LOCATION_PRIORITY = nil
local BODY_LOCATION_CANONICAL = nil
local ATTACHMENT_LOCATION_TO_TYPE = nil

local function normalizeString(value)
    if value == nil or value == "" then
        return nil
    end
    return tostring(value)
end

local function normalizeStringMap(source)
    local output = {}
    local key
    local value
    if type(source) ~= "table" then
        return output
    end
    for key, value in pairs(source) do
        key = normalizeString(key)
        value = normalizeString(value)
        if key and value then
            output[key] = value
        end
    end
    return output
end

local function getBodyLocationCanonical()
    local map
    local i
    local canonical
    if BODY_LOCATION_CANONICAL then
        return BODY_LOCATION_CANONICAL
    end
    map = {}
    for i = 1, #BODY_LOCATIONS_ORDERED do
        canonical = BODY_LOCATIONS_ORDERED[i]
        map[string.lower(canonical)] = canonical
    end
    BODY_LOCATION_CANONICAL = map
    return BODY_LOCATION_CANONICAL
end

local function normalizeBodyLocation(value)
    local lowered
    local stripped
    local canonical
    value = normalizeString(value)
    if not value then
        return nil
    end
    lowered = string.lower(value)
    stripped = string.match(lowered, "([^:%.]+)$") or lowered
    canonical = getBodyLocationCanonical()[stripped]
    if canonical then
        return canonical
    end
    return value
end

local function normalizeWornMap(source)
    local output = {}
    local key
    local value
    if type(source) ~= "table" then
        return output
    end
    for key, value in pairs(source) do
        key = normalizeBodyLocation(key)
        value = normalizeString(value)
        if key and value then
            output[key] = value
        end
    end
    return output
end

local function normalizeVisualColor(source)
    if type(source) ~= "table" then
        return nil
    end
    return {
        r = tonumber(source.r) or 1,
        g = tonumber(source.g) or 1,
        b = tonumber(source.b) or 1,
    }
end

local function normalizeVisualState(source, fullType)
    local state = type(source) == "table" and source or nil
    if not state or not fullType
        or (
            state.fullType ~= nil
            and tostring(state.fullType) ~= tostring(fullType)
        )
    then
        return nil
    end
    return {
        fullType = tostring(fullType),
        baseTexture = tonumber(state.baseTexture),
        textureChoice = tonumber(state.textureChoice),
        decal = normalizeString(state.decal),
        tint = normalizeVisualColor(state.tint),
        modelIndex = tonumber(state.modelIndex),
        customColor = state.customColor == true,
        color = normalizeVisualColor(state.color),
    }
end

local function normalizeWornVisualMap(source, worn)
    local output = {}
    local location
    local state
    local fullType
    if type(source) ~= "table" then
        return output
    end
    for rawLocation, rawState in pairs(source) do
        location = normalizeBodyLocation(rawLocation)
        state = type(rawState) == "table" and rawState or nil
        fullType = location and worn[location] or nil
        output[location] = normalizeVisualState(state, fullType)
    end
    return output
end

function Equipment.VisualStateFromItemState(itemState, fullType)
    local tint
    if type(itemState) ~= "table" then return nil end
    if itemState.visualFullType ~= nil
        and tostring(itemState.visualFullType)
            ~= tostring(fullType or "")
    then
        return nil
    end
    if itemState.visualTintR ~= nil
        and itemState.visualTintG ~= nil
        and itemState.visualTintB ~= nil
    then
        tint = {
            r = tonumber(itemState.visualTintR) or 1,
            g = tonumber(itemState.visualTintG) or 1,
            b = tonumber(itemState.visualTintB) or 1,
        }
    end
    if itemState.visualBaseTexture == nil
        and itemState.visualTextureChoice == nil
        and itemState.visualDecal == nil
        and itemState.visualModelIndex == nil
        and itemState.visualColorR == nil
        and itemState.visualColorG == nil
        and itemState.visualColorB == nil
        and tint == nil
    then
        return nil
    end
    return {
        fullType = fullType and tostring(fullType) or nil,
        baseTexture = tonumber(itemState.visualBaseTexture),
        textureChoice = tonumber(itemState.visualTextureChoice),
        decal = itemState.visualDecal
            and tostring(itemState.visualDecal) or nil,
        tint = tint,
        modelIndex = tonumber(itemState.visualModelIndex),
        customColor = itemState.visualCustomColor == true,
        color = itemState.visualColorR ~= nil
            and itemState.visualColorG ~= nil
            and itemState.visualColorB ~= nil
            and {
                r = tonumber(itemState.visualColorR) or 1,
                g = tonumber(itemState.visualColorG) or 1,
                b = tonumber(itemState.visualColorB) or 1,
            }
            or nil,
    }
end

function Equipment.StoreVisualStateInItemState(item, visualState)
    local state
    local tint
    if type(item) ~= "table" or type(visualState) ~= "table" then
        return false
    end
    item.itemState = type(item.itemState) == "table"
        and item.itemState or {}
    state = item.itemState
    tint = visualState.tint
    state.visualFullType = visualState.fullType
        and tostring(visualState.fullType)
        or item.type and tostring(item.type)
        or nil
    state.visualBaseTexture = tonumber(visualState.baseTexture)
    state.visualTextureChoice = tonumber(visualState.textureChoice)
    state.visualDecal = visualState.decal
        and tostring(visualState.decal) or nil
    state.visualTintR = tint and tonumber(tint.r) or nil
    state.visualTintG = tint and tonumber(tint.g) or nil
    state.visualTintB = tint and tonumber(tint.b) or nil
    state.visualModelIndex = tonumber(visualState.modelIndex)
    state.visualCustomColor = visualState.customColor == true
        and true or nil
    state.visualColorR = visualState.color
        and tonumber(visualState.color.r) or nil
    state.visualColorG = visualState.color
        and tonumber(visualState.color.g) or nil
    state.visualColorB = visualState.color
        and tonumber(visualState.color.b) or nil
    return true
end

local function getBodyLocationPriority()
    local i
    if BODY_LOCATION_PRIORITY then
        return BODY_LOCATION_PRIORITY
    end
    BODY_LOCATION_PRIORITY = {}
    for i = 1, #BODY_LOCATIONS_ORDERED do
        BODY_LOCATION_PRIORITY[BODY_LOCATIONS_ORDERED[i]] = i
    end
    return BODY_LOCATION_PRIORITY
end

local function getAttachmentLocationToType()
    local map
    local _
    local def
    local attachmentType
    local location
    if ATTACHMENT_LOCATION_TO_TYPE then
        return ATTACHMENT_LOCATION_TO_TYPE
    end
    map = {}
    if ISHotbarAttachDefinition then
        for _, def in pairs(ISHotbarAttachDefinition) do
            if type(def) == "table" and def.attachments then
                for attachmentType, location in pairs(def.attachments) do
                    if attachmentType and location and not map[location] then
                        map[location] = def.type
                    end
                end
            end
        end
    end
    ATTACHMENT_LOCATION_TO_TYPE = map
    return ATTACHMENT_LOCATION_TO_TYPE
end

function Equipment.NormalizeLoadoutSpec(loadoutSpec)
    local source = type(loadoutSpec) == "table" and loadoutSpec or {}
    local worn = normalizeWornMap(source.worn)
    local primaryFullType = normalizeString(source.primaryFullType)
    return {
        primaryFullType = primaryFullType,
        primaryVisual = normalizeVisualState(
            source.primaryVisual,
            primaryFullType
        ),
        secondaryFullType = normalizeString(source.secondaryFullType),
        worn = worn,
        wornVisuals = normalizeWornVisualMap(
            source.wornVisuals,
            worn
        ),
        attached = normalizeStringMap(source.attached),
    }
end

function Equipment.EnsureRecordEquipment(record)
    if not record then
        return Equipment.NormalizeLoadoutSpec(nil)
    end
    record.equipment = Equipment.NormalizeLoadoutSpec(record.equipment)
    return record.equipment
end

function Equipment.SetLoadout(record, loadoutSpec)
    if not record then
        return false
    end
    record.equipment = Equipment.NormalizeLoadoutSpec(loadoutSpec)
    return true
end

function Equipment.SetPrimary(record, fullType)
    local equipment
    local previous
    if not record then
        return false
    end
    equipment = Equipment.EnsureRecordEquipment(record)
    previous = equipment.primaryFullType
    equipment.primaryFullType = normalizeString(fullType)
    if tostring(previous or "")
        ~= tostring(equipment.primaryFullType or "")
    then
        equipment.primaryVisual = nil
    end
    return true
end

function Equipment.SetSecondary(record, fullType)
    local equipment
    if not record then
        return false
    end
    equipment = Equipment.EnsureRecordEquipment(record)
    equipment.secondaryFullType = normalizeString(fullType)
    return true
end

local function setSlotValue(record, collectionName, location, fullType, normalizeLocation)
    local equipment
    local previous
    location = normalizeLocation(location)
    if not record or not location then
        return false
    end
    equipment = Equipment.EnsureRecordEquipment(record)
    previous = equipment[collectionName][location]
    fullType = normalizeString(fullType)
    if fullType then
        equipment[collectionName][location] = fullType
    else
        equipment[collectionName][location] = nil
    end
    if collectionName == "worn"
        and tostring(previous or "") ~= tostring(fullType or "")
    then
        equipment.wornVisuals[location] = nil
    end
    return true
end

function Equipment.SetAttached(record, location, fullType)
    return setSlotValue(record, "attached", location, fullType, normalizeString)
end

function Equipment.SetWorn(record, bodyLocation, fullType)
    return setSlotValue(record, "worn", bodyLocation, fullType, normalizeBodyLocation)
end

function Equipment.ResolveAttachedSlotType(location)
    if not location or location == "" then
        return nil
    end
    return getAttachmentLocationToType()[tostring(location)]
end

function Equipment.ResolveAttachedLocation(item, preferredSlotType, occupiedLocations)
    local attachmentType
    local preferredLookup = {}
    local entries = {}
    local i
    local _
    local def
    local location
    local preferredTypes

    if not item or not item.getAttachmentType or not ISHotbarAttachDefinition then
        return nil, nil
    end

    attachmentType = item:getAttachmentType()
    if not attachmentType or attachmentType == "" then
        return nil, nil
    end

    preferredTypes = ATTACHMENT_TYPE_SLOT_PRIORITY[attachmentType] or {}
    for i = 1, #preferredTypes do
        preferredLookup[preferredTypes[i]] = i
    end
    if preferredSlotType and not preferredLookup[preferredSlotType] then
        preferredLookup[preferredSlotType] = 0
    end

    for _, def in pairs(ISHotbarAttachDefinition) do
        if type(def) == "table" and MANAGED_ATTACHMENT_TYPES[def.type] and def.attachments then
            location = def.attachments[attachmentType]
            if location and location ~= "" and not (occupiedLocations and occupiedLocations[location]) then
                entries[#entries + 1] = {
                    location = location,
                    slotType = def.type,
                    preferred = preferredLookup[def.type] or 999,
                    fallback = MANAGED_SLOT_TYPE_PRIORITY[def.type] or 999,
                }
            end
        end
    end

    table.sort(entries, function(left, right)
        if left.preferred ~= right.preferred then
            return left.preferred < right.preferred
        end
        if left.fallback ~= right.fallback then
            return left.fallback < right.fallback
        end
        return tostring(left.location) < tostring(right.location)
    end)

    if entries[1] then
        return entries[1].location, entries[1].slotType
    end
    return nil, nil
end

function Equipment.SetAttachedByItem(record, fullType, preferredSlotType)
    local item
    local createReason
    local location
    if not record then
        return false, "missing_record"
    end
    item, createReason = Equipment.CreateItem(fullType)
    if not item then
        return false, createReason or "invalid_full_type"
    end
    location = Equipment.ResolveAttachedLocation(item, preferredSlotType)
    if not location then
        return false, "no_attachment_location"
    end
    Equipment.SetAttached(record, location, fullType)
    return true, location
end

function Equipment.GetOrderedWornEntries(equipment)
    local entries = {}
    local priority = getBodyLocationPriority()
    local bodyLocation
    local fullType
    equipment = Equipment.NormalizeLoadoutSpec(equipment)
    for bodyLocation, fullType in pairs(equipment.worn) do
        entries[#entries + 1] = {
            bodyLocation = bodyLocation,
            fullType = fullType,
            priority = priority[bodyLocation] or 999,
        }
    end
    table.sort(entries, function(left, right)
        if left.priority ~= right.priority then
            return left.priority < right.priority
        end
        return tostring(left.bodyLocation) < tostring(right.bodyLocation)
    end)
    return entries
end

function Equipment.GetOrderedAttachedEntries(equipment)
    local entries = {}
    local location
    local fullType
    equipment = Equipment.NormalizeLoadoutSpec(equipment)
    for location, fullType in pairs(equipment.attached) do
        entries[#entries + 1] = {
            location = location,
            fullType = fullType,
            slotType = Equipment.ResolveAttachedSlotType(location),
        }
    end
    table.sort(entries, function(left, right)
        return tostring(left.location) < tostring(right.location)
    end)
    return entries
end

local function readVisualValue(visual, methodName, ...)
    local method
    local ok
    local value
    if not visual then return nil end
    method = visual[methodName]
    if type(method) ~= "function" then return nil end
    ok, value = pcall(method, visual, ...)
    return ok and value or nil
end

local function visualStateSignature(state)
    local tint = state and state.tint or {}
    local color = state and state.color or {}
    return table.concat({
        tostring(state and state.fullType or ""),
        tostring(state and state.baseTexture or ""),
        tostring(state and state.textureChoice or ""),
        tostring(state and state.decal or ""),
        tostring(tint.r or ""),
        tostring(tint.g or ""),
        tostring(tint.b or ""),
        tostring(state and state.modelIndex or ""),
        tostring(state and state.customColor == true),
        tostring(color.r or ""),
        tostring(color.g or ""),
        tostring(color.b or ""),
    }, ":")
end

function Equipment.CaptureItemVisualState(item, fullType)
    local visual
    local clothingItem
    local tint
    local modelIndex
    local customColor
    local color
    if not item then return nil end
    visual = item.getVisual and item:getVisual() or nil
    clothingItem = item.getClothingItem
        and item:getClothingItem() or nil
    tint = visual and readVisualValue(
        visual, "getTint", clothingItem
    ) or nil
    modelIndex = item.getModelIndex
        and tonumber(item:getModelIndex()) or nil
    customColor = item.isCustomColor
        and item:isCustomColor() == true or false
    if item.getColorRed
        and item.getColorGreen
        and item.getColorBlue
    then
        color = {
            r = tonumber(item:getColorRed()),
            g = tonumber(item:getColorGreen()),
            b = tonumber(item:getColorBlue()),
        }
    end
    return {
        fullType = fullType
            or item.getFullType
                and tostring(item:getFullType())
            or nil,
        baseTexture = visual and tonumber(readVisualValue(
            visual, "getBaseTexture"
        )) or nil,
        textureChoice = visual and tonumber(readVisualValue(
            visual, "getTextureChoice"
        )) or nil,
        decal = visual and readVisualValue(
            visual, "getDecal", clothingItem
        ) or nil,
        tint = tint and {
            r = tonumber(tint:getRedFloat()),
            g = tonumber(tint:getGreenFloat()),
            b = tonumber(tint:getBlueFloat()),
        } or nil,
        modelIndex = modelIndex,
        customColor = customColor,
        color = color,
    }
end

function Equipment.BuildPrimaryVisualSummary(record)
    local registry = PNC.Registry
    local equipment = record
        and Equipment.EnsureRecordEquipment(record) or nil
    local inventory = record and record.inventory or nil
    local itemID = inventory and inventory.equipped
        and inventory.equipped.primary or nil
    local inventoryItem = itemID and inventory.items
        and inventory.items[itemID] or nil
    local state = inventoryItem
        and Equipment.VisualStateFromItemState(
            inventoryItem.itemState,
            inventoryItem.type
        ) or equipment and equipment.primaryVisual or nil
    local item
    local body
    local attachedItems
    local entry
    local attachedItem
    local i
    if state then
        if equipment then equipment.primaryVisual = state end
        return state
    end
    if not equipment or not equipment.primaryFullType then return nil end
    body = registry and registry.GetLiveZombie
        and registry.GetLiveZombie(record and record.id) or nil
    item = body and body.getPrimaryHandItem
        and body:getPrimaryHandItem() or nil
    if item and item.getFullType
        and tostring(item:getFullType() or "")
            ~= tostring(equipment.primaryFullType)
    then
        item = nil
    end
    if not item and body and body.getAttachedItems then
        attachedItems = body:getAttachedItems()
        if attachedItems and attachedItems.size
            and attachedItems.get
        then
            for i = 0, attachedItems:size() - 1 do
                entry = attachedItems:get(i)
                attachedItem = entry and entry.getItem
                    and entry:getItem() or nil
                if attachedItem
                    and attachedItem.getFullType
                    and tostring(attachedItem:getFullType() or "")
                        == tostring(equipment.primaryFullType)
                then
                    item = attachedItem
                    break
                end
            end
        end
    end
    if not item then
        item = Equipment.CreateItem(equipment.primaryFullType)
    end
    state = Equipment.CaptureItemVisualState(
        item,
        equipment.primaryFullType
    )
    if not state then return nil end
    equipment.primaryVisual = state
    if inventoryItem then
        Equipment.StoreVisualStateInItemState(
            inventoryItem,
            state
        )
    end
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "equipment_visuals")
    end
    return state
end

-- Capture the concrete visual choices of the server's real worn inventory.
-- Item type alone is insufficient: many PZ clothes and bags randomly select
-- a base texture, texture choice, or tint when an ItemVisual is constructed.
function Equipment.BuildWornVisualSummary(record)
    local registry = PNC.Registry
    local body = registry and registry.GetLiveZombie
        and registry.GetLiveZombie(record and record.id) or nil
    local wornItems = body and body.getWornItems
        and body:getWornItems() or nil
    local output = {}
    local i
    local entry
    local item
    local location
    local captured
    local changed = false
    local inventory = record and record.inventory or nil
    local inventoryItem
    local itemID
    local equipment = record
        and Equipment.EnsureRecordEquipment(record) or nil
    if equipment and PNC.Core and PNC.Core.DeepCopy then
        output = PNC.Core.DeepCopy(
            equipment.wornVisuals or {}
        )
    end
    if not wornItems or not wornItems.size then
        return output
    end
    for i = 0, wornItems:size() - 1 do
        entry = wornItems:get(i)
        item = entry and entry.getItem and entry:getItem() or nil
        location = entry and entry.getLocation
            and entry:getLocation() or nil
        if item and location then
            captured = Equipment.CaptureItemVisualState(item)
            if captured then
                output[tostring(location)] = captured
                itemID = inventory and inventory.worn
                    and inventory.worn[tostring(location)] or nil
                inventoryItem = itemID and inventory.items
                    and inventory.items[itemID] or nil
                if inventoryItem
                    and visualStateSignature(
                        Equipment.VisualStateFromItemState(
                            inventoryItem.itemState,
                            inventoryItem.type
                        )
                    ) ~= visualStateSignature(captured)
                then
                    Equipment.StoreVisualStateInItemState(
                        inventoryItem,
                        captured
                    )
                    changed = true
                end
                if equipment
                    and visualStateSignature(
                        equipment.wornVisuals[location]
                    ) ~= visualStateSignature(captured)
                then
                    equipment.wornVisuals[location] = captured
                    changed = true
                end
            end
        end
    end
    if changed
        and PNC.Registry
        and PNC.Registry.MarkDirty
    then
        PNC.Registry.MarkDirty(
            record,
            "equipment_visuals"
        )
    end
    return output
end

function Equipment.CaptureCharacterLoadout(character)
    local loadout = Equipment.NormalizeLoadoutSpec(nil)
    local primary
    local secondary
    local wornItems
    local attachedItems
    local i
    local entry
    local item
    local location

    if not character then
        return nil, "missing_character"
    end

    primary = character.getPrimaryHandItem and character:getPrimaryHandItem() or nil
    if primary and primary.getFullType then
        loadout.primaryFullType = normalizeString(primary:getFullType())
    end

    secondary = character.getSecondaryHandItem and character:getSecondaryHandItem() or nil
    if secondary and secondary ~= primary and secondary.getFullType then
        loadout.secondaryFullType = normalizeString(secondary:getFullType())
    end

    wornItems = character.getWornItems and character:getWornItems() or nil
    if wornItems and wornItems.size then
        for i = 0, wornItems:size() - 1 do
            entry = wornItems:get(i)
            item = entry and entry.getItem and entry:getItem() or nil
            location = entry and entry.getLocation and entry:getLocation() or nil
            if not location and item and item.getBodyLocation then
                location = item:getBodyLocation()
            end
            if item and item.getFullType and location and location ~= "" then
                loadout.worn[tostring(location)] = tostring(item:getFullType())
            end
        end
    end

    attachedItems = character.getAttachedItems and character:getAttachedItems() or nil
    if attachedItems and attachedItems.size then
        for i = 0, attachedItems:size() - 1 do
            entry = attachedItems:get(i)
            item = entry and entry.getItem and entry:getItem() or nil
            location = entry and entry.getLocation and entry:getLocation() or nil
            if item and item.getFullType and location and location ~= "" then
                loadout.attached[tostring(location)] = tostring(item:getFullType())
            end
        end
    end

    return Equipment.NormalizeLoadoutSpec(loadout), "captured"
end

function Equipment.CopyCharacterLoadout(record, character)
    local loadout
    local reason
    if not record then
        return false, "missing_record"
    end
    loadout, reason = Equipment.CaptureCharacterLoadout(character)
    if not loadout then
        return false, reason or "capture_failed"
    end
    record.equipment = loadout
    return true, reason or "captured"
end
