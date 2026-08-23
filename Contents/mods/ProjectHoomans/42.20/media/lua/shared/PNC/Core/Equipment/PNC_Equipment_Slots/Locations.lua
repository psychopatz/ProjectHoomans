PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}

local Equipment = PNC.Equipment
Equipment.Internal = Equipment.Internal or {}

local Internal = Equipment.Internal

Internal.ManagedAttachmentTypes = {
    Back = true,
    HolsterLeft = true,
    HolsterRight = true,
    HolsterShoulder = true,
    SmallBeltLeft = true,
    SmallBeltRight = true,
    WebbingLeft = true,
    WebbingRight = true,
}

Internal.ManagedSlotTypePriority = {
    HolsterRight = 1,
    HolsterLeft = 2,
    HolsterShoulder = 3,
    SmallBeltLeft = 4,
    SmallBeltRight = 5,
    WebbingLeft = 6,
    WebbingRight = 7,
    Back = 8,
}

Internal.AttachmentTypeSlotPriority = {
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

Internal.BodyLocationsOrdered = {
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

Internal.BodyLocationPriority = nil
Internal.BodyLocationCanonical = nil
Internal.AttachmentLocationToType = nil

function Internal.NormalizeString(value)
    if value == nil or value == "" then
        return nil
    end
    return tostring(value)
end

function Internal.NormalizeStringMap(source)
    local output = {}
    local key
    local value
    if type(source) ~= "table" then
        return output
    end
    for key, value in pairs(source) do
        key = Internal.NormalizeString(key)
        value = Internal.NormalizeString(value)
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
    if Internal.BodyLocationCanonical then
        return Internal.BodyLocationCanonical
    end
    map = {}
    for i = 1, #Internal.BodyLocationsOrdered do
        canonical = Internal.BodyLocationsOrdered[i]
        map[string.lower(canonical)] = canonical
    end
    Internal.BodyLocationCanonical = map
    return Internal.BodyLocationCanonical
end

function Internal.NormalizeBodyLocation(value)
    local lowered
    local stripped
    local canonical
    value = Internal.NormalizeString(value)
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

function Internal.NormalizeWornMap(source)
    local output = {}
    local key
    local value
    if type(source) ~= "table" then
        return output
    end
    for key, value in pairs(source) do
        key = Internal.NormalizeBodyLocation(key)
        value = Internal.NormalizeString(value)
        if key and value then
            output[key] = value
        end
    end
    return output
end
