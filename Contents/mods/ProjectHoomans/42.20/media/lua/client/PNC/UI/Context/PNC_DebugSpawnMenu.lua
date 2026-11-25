PNC = PNC or {}
PNC.DebugSpawnMenu = PNC.DebugSpawnMenu or {}

local Menu = PNC.DebugSpawnMenu

local SPAWN_TYPES = {
    {
        id = "companion",
        tacticalClass = "colonist",
        key = "UI_PNC_SpawnCompanion",
        label = "Companion",
    },
    {
        id = "neutral",
        tacticalClass = "neutral",
        key = "UI_PNC_SpawnNeutral",
        label = "Neutral",
    },
    {
        id = "hostile",
        tacticalClass = "hostile",
        key = "UI_PNC_SpawnHostile",
        label = "Hostile",
    },
}

local GROUP_SPAWN_TYPES = {
    {
        id = "refugee_ambient",
        archetypeID = "refugee",
        mobileControlMode = "ambient",
        mobilePathMode = "random",
        startSettlementTravel = false,
        key = "UI_PNC_SpawnGroupRefugee",
        label = "Refugee Group (Ambient)",
    },
    {
        id = "refugee_en_route",
        archetypeID = "refugee",
        mobileControlMode = "ambient",
        mobilePathMode = "random",
        startSettlementTravel = true,
        key = "UI_PNC_SpawnGroupRefugeeTravel",
        label = "Refugee Group (Visit Settlement)",
    },
    {
        id = "looter_ambient",
        archetypeID = "looter",
        mobileControlMode = "ambient",
        mobilePathMode = "random",
        startSettlementTravel = false,
        key = "UI_PNC_SpawnGroupLooter",
        label = "Looter Group (Ambient)",
    },
    {
        id = "looter_raid",
        archetypeID = "looter",
        mobileControlMode = "strategic",
        mobilePathMode = "player",
        startSettlementTravel = false,
        key = "UI_PNC_SpawnGroupLooterRaid",
        label = "Looter Raid (Hunt Player Base)",
    },
}

local GROUP_SIZES = {
    { size = 3, key = "UI_PNC_SpawnGroupSize3", label = "3 Members" },
    { size = 5, key = "UI_PNC_SpawnGroupSize5", label = "5 Members (Full Squad + Medic)" },
}

local EQUIPMENT_CHOICES = {
    { mode = nil, key = "UI_PNC_SpawnEquipmentChances", label = "Sandbox Equipment Chances" },
    { mode = "melee", key = "UI_PNC_SpawnEquipmentMelee", label = "Melee Weapon" },
    { mode = "ranged", key = "UI_PNC_SpawnEquipmentRanged", label = "Ranged Weapon" },
    { mode = "both", key = "UI_PNC_SpawnEquipmentBoth", label = "Melee + Ranged Weapons" },
}

local function tr(key, fallback)
    local value = getText and PNC.Translation and PNC.Translation.GetKey
        and PNC.Translation.GetKey(key) or nil
    if not value or value == "" or value == key then
        return fallback
    end
    return value
end

local function canUseDebug()
    return PNC.Client
        and PNC.Client.CanUseDebug
        and PNC.Client.CanUseDebug() == true
end

local function sendSpawn(
    _, square, spawnType, tacticalClass, equipmentMode
)
    if not canUseDebug() then
        return false
    end
    local payload = {
        variant = spawnType,
        tacticalClass = tacticalClass,
        x = square:getX(),
        y = square:getY(),
        z = square:getZ(),
    }
    if equipmentMode then
        payload.equipmentSpawnMode = equipmentMode
    end
    return PNC.Client.SendDebug("spawn", payload)
end

local function sendMobileGroupSpawn(_, square, groupDef, groupSize)
    if not canUseDebug() or type(groupDef) ~= "table" then
        return false
    end
    return PNC.Client.SendDebug("spawn_mobile_group", {
        archetypeID = groupDef.archetypeID,
        mobileControlMode = groupDef.mobileControlMode,
        mobilePathMode = groupDef.mobilePathMode,
        startSettlementTravel = groupDef.startSettlementTravel == true,
        groupSize = tonumber(groupSize) or 3,
        presenceMode = "live",
        x = square:getX(),
        y = square:getY(),
        z = square:getZ(),
    })
end

local function addEquipmentChoices(
    context, parent, square, spawnType, tacticalClass
)
    local equipmentMenu = ISContextMenu:getNew(context)
    local i
    local choice
    context:addSubMenu(parent, equipmentMenu)
    for i = 1, #EQUIPMENT_CHOICES do
        choice = EQUIPMENT_CHOICES[i]
        equipmentMenu:addOption(
            tr(choice.key, choice.label),
            nil,
            sendSpawn,
            square,
            spawnType,
            tacticalClass,
            choice.mode
        )
    end
    return equipmentMenu
end

local function addGroupSizeChoices(context, parent, square, groupDef)
    local sizeMenu = ISContextMenu:getNew(context)
    local i
    local choice
    context:addSubMenu(parent, sizeMenu)
    for i = 1, #GROUP_SIZES do
        choice = GROUP_SIZES[i]
        sizeMenu:addOption(
            tr(choice.key, choice.label),
            nil,
            sendMobileGroupSpawn,
            square,
            groupDef,
            choice.size
        )
    end
    return sizeMenu
end

function Menu.Add(context, square)
    local root
    local rootOption
    local singleOption
    local singleMenu
    local groupOption
    local groupMenu
    local spawnType
    local spawnOption
    local groupDef
    local i
    if not canUseDebug() or not context or not square or not ISContextMenu then
        return nil
    end
    root = ISContextMenu:getNew(context)
    rootOption = context:addOption(
        tr("UI_PNC_Spawn", "[Debug] Spawn Hoomans"))
    context:addSubMenu(rootOption, root)

    -- Single NPC submenu (existing standalone debug spawns)
    singleMenu = ISContextMenu:getNew(root)
    singleOption = root:addOption(tr("UI_PNC_SpawnSingle", "Single"))
    root:addSubMenu(singleOption, singleMenu)
    for i = 1, #SPAWN_TYPES do
        spawnType = SPAWN_TYPES[i]
        spawnOption = singleMenu:addOption(
            tr(spawnType.key, spawnType.label))
        addEquipmentChoices(
            singleMenu,
            spawnOption,
            square,
            spawnType.id,
            spawnType.tacticalClass
        )
    end

    -- Group submenu (production MobileGroupDirector pipeline)
    groupMenu = ISContextMenu:getNew(root)
    groupOption = root:addOption(tr("UI_PNC_SpawnGroup", "Group"))
    root:addSubMenu(groupOption, groupMenu)
    for i = 1, #GROUP_SPAWN_TYPES do
        groupDef = GROUP_SPAWN_TYPES[i]
        spawnOption = groupMenu:addOption(
            tr(groupDef.key, groupDef.label))
        addGroupSizeChoices(groupMenu, spawnOption, square, groupDef)
    end

    return root
end

return Menu
