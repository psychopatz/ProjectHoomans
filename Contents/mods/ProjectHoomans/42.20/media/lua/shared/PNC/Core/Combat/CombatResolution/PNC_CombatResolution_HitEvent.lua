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

function Resolution.ResolveWoundType(attackType, weaponItem, requestedType)
    requestedType = tostring(requestedType or "")
    if requestedType == "scratch" or requestedType == "laceration"
        or requestedType == "bite" or requestedType == "bullet"
    then
        return requestedType
    end
    if attackType == "ranged" then return "bullet" end
    return weaponItem and "laceration" or "scratch"
end

function Resolution.BuildHitEvent(attackerRecord, target, options)
    options = options or {}
    local attackType = tostring(options.attackType or "melee")
    local weaponItem = options.weaponItem
    return {
        amount = math.max(0, tonumber(options.damage or options.amount) or 0),
        attackType = attackType,
        attackKind = tostring(options.attackKind or attackType),
        partId = Resolution.ChooseBodyPartId(options.partId),
        woundType = Resolution.ResolveWoundType(attackType, weaponItem, options.woundType),
        attackerID = options.attackerID or attackerRecord and attackerRecord.id or nil,
        attackerKind = tostring(options.attackerKind or "npc"),
        attackerOnlineID = options.attackerOnlineID,
        attackerUsername = options.attackerUsername,
        weaponFullType = options.weaponFullType or weaponFullType(weaponItem),
        weaponItem = weaponItem,
        x = options.x,
        y = options.y,
        z = options.z,
        targetKind = target and target.kind or nil,
    }
end

return Resolution
