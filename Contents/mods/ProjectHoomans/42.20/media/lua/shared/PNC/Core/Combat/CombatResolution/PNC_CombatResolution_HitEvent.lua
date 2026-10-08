local Resolution = PNC.CombatResolution

local BODY_PART_FALLBACK = {
    { id = "Head", weight = 5 },
    { id = "Neck", weight = 3 },
    { id = "Torso_Upper", weight = 18 },
    { id = "Torso_Lower", weight = 14 },
    { id = "Groin", weight = 5 },
    { id = "UpperArm_L", weight = 6 },
    { id = "UpperArm_R", weight = 6 },
    { id = "ForeArm_L", weight = 5 },
    { id = "ForeArm_R", weight = 5 },
    { id = "Hand_L", weight = 3 },
    { id = "Hand_R", weight = 3 },
    { id = "UpperLeg_L", weight = 8 },
    { id = "UpperLeg_R", weight = 8 },
    { id = "LowerLeg_L", weight = 6 },
    { id = "LowerLeg_R", weight = 6 },
    { id = "Foot_L", weight = 2 },
    { id = "Foot_R", weight = 2 },
}

local function bodyPartDefinitions()
    local wounds = PNC.NPCWounds
    local definitions = {}
    local i
    local id
    local part
    if wounds and wounds.PartOrder and wounds.Parts then
        for i = 1, #wounds.PartOrder do
            id = wounds.PartOrder[i]
            part = wounds.Parts[id]
            if part then
                definitions[#definitions + 1] = {
                    id = id,
                    weight = math.max(1, tonumber(part.weight) or 1),
                }
            end
        end
    end
    return #definitions > 0 and definitions or BODY_PART_FALLBACK
end

local function weaponFullType(weaponItem)
    return weaponItem and weaponItem.getFullType and tostring(weaponItem:getFullType() or "") or nil
end

local function safeMethod(object, methodName)
    local method
    local ok
    local value
    if not object then return nil end
    method = object[methodName]
    if type(method) ~= "function" then return nil end
    ok, value = pcall(method, object)
    return ok and value or nil
end

local function looksLikeRangedWeapon(weaponItem, fullType)
    local ranged
    local weaponType
    local normalized
    local descriptor
    if not weaponItem and not fullType then return false end
    ranged = safeMethod(weaponItem, "isRanged")
    if ranged == true then return true end
    ranged = safeMethod(weaponItem, "isRangedWeapon")
    if ranged == true then return true end
    weaponType = safeMethod(weaponItem, "getWeaponType")
    normalized = string.lower(tostring(weaponType or ""))
    if normalized ~= "" and (
        string.find(normalized, "firearm", 1, true)
        or string.find(normalized, "handgun", 1, true)
        or string.find(normalized, "pistol", 1, true)
        or string.find(normalized, "rifle", 1, true)
        or string.find(normalized, "shotgun", 1, true)
    ) then
        return true
    end
    normalized = string.lower(tostring(fullType or weaponFullType(weaponItem) or ""))
    if normalized ~= "" and (
        string.find(normalized, "firearm", 1, true)
        or string.find(normalized, "handgun", 1, true)
        or string.find(normalized, "pistol", 1, true)
        or string.find(normalized, "rifle", 1, true)
        or string.find(normalized, "shotgun", 1, true)
        or string.find(normalized, "revolver", 1, true)
        or string.find(normalized, "smg", 1, true)
    ) then
        return true
    end
    if PNC.Equipment
        and PNC.Equipment.Internal
        and PNC.Equipment.Internal.buildWeaponDescriptor
        and normalized ~= ""
    then
        local ok
        ok, descriptor = pcall(
            PNC.Equipment.Internal.buildWeaponDescriptor,
            fullType or weaponFullType(weaponItem),
            false
        )
        if ok and descriptor and descriptor.hasUsableFirearm == true then
            return true
        end
    end
    return false
end

local function isRangedAttack(attackType, attackKind, weaponItem, fullType)
    local normalizedType = string.lower(tostring(attackType or ""))
    local normalizedKind = string.lower(tostring(attackKind or ""))
    if normalizedType == "ranged" then return true end
    if normalizedKind == "ranged"
        or string.find(normalizedKind, "ranged", 1, true)
        or string.find(normalizedKind, "firearm", 1, true)
    then
        return true
    end
    return looksLikeRangedWeapon(weaponItem, fullType)
end

function Resolution.ChooseBodyPartId(requestedPartId)
    local requested = requestedPartId and tostring(requestedPartId) or nil
    local definitions = bodyPartDefinitions()
    local total = 0
    local selectedRoll
    local i
    if requested then
        for i = 1, #definitions do
            if definitions[i].id == requested then return requested end
        end
    end
    for i = 1, #definitions do
        total = total + definitions[i].weight
    end
    selectedRoll = ZombRand and ZombRand(math.max(1, total)) or math.floor(total * 0.5)
    for i = 1, #definitions do
        selectedRoll = selectedRoll - definitions[i].weight
        if selectedRoll < 0 then return definitions[i].id end
    end
    return "Torso_Upper"
end

function Resolution.ResolveWoundType(
    attackType,
    weaponItem,
    requestedType,
    attackKind,
    requestedWeaponFullType
)
    local normalizedRequested = string.lower(tostring(requestedType or ""))
    local ranged = isRangedAttack(
        attackType,
        attackKind,
        weaponItem,
        requestedWeaponFullType
    )
    -- A stale action or compatibility caller may still label a firearm hit as
    -- melee/laceration. A firearm is never a laceration in this wound model;
    -- normalize only the ambiguous cut/scratch defaults and preserve explicit
    -- bite/bullet requests from other authoritative damage sources.
    if ranged and (
        normalizedRequested == ""
        or normalizedRequested == "scratch"
        or normalizedRequested == "laceration"
    ) then
        return "bullet"
    end
    if normalizedRequested == "scratch"
        or normalizedRequested == "laceration"
        or normalizedRequested == "bite"
        or normalizedRequested == "bullet"
    then
        return normalizedRequested
    end
    if ranged then return "bullet" end
    return weaponItem and "laceration" or "scratch"
end

function Resolution.BuildHitEvent(attackerRecord, target, options)
    options = options or {}
    local attackType = tostring(options.attackType or "melee")
    local attackKind = tostring(options.attackKind or attackType)
    local weaponItem = options.weaponItem
    local resolvedWeaponFullType = options.weaponFullType
        or weaponFullType(weaponItem)
    return {
        amount = math.max(0, tonumber(options.damage or options.amount) or 0),
        attackType = attackType,
        attackKind = attackKind,
        partId = Resolution.ChooseBodyPartId(options.partId),
        woundType = Resolution.ResolveWoundType(
            attackType,
            weaponItem,
            options.woundType,
            attackKind,
            resolvedWeaponFullType
        ),
        attackerID = options.attackerID or attackerRecord and attackerRecord.id or nil,
        attackerKind = tostring(options.attackerKind or "npc"),
        attackerOnlineID = options.attackerOnlineID,
        attackerUsername = options.attackerUsername,
        weaponFullType = resolvedWeaponFullType,
        weaponItem = weaponItem,
        x = options.x,
        y = options.y,
        z = options.z,
        targetKind = target and target.kind or nil,
        groupAlert = options.groupAlert == true
            or target and target.groupAlert == true or false,
        ownerDefense = options.ownerDefense == true
            or target and target.ownerDefense == true or false,
        alertSequence = options.alertSequence
            or target and target.alertSequence or nil,
        alertRadius = options.alertRadius
            or target and target.alertRadius or nil,
        alertOnly = options.alertOnly == true
            or target and target.alertOnly == true or false,
    }
end

return Resolution
