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

local EQUIPMENT_CHOICES = {
    { mode = nil, key = "UI_PNC_SpawnEquipmentChances", label = "Sandbox Equipment Chances" },
    { mode = "melee", key = "UI_PNC_SpawnEquipmentMelee", label = "Melee Weapon" },
    { mode = "ranged", key = "UI_PNC_SpawnEquipmentRanged", label = "Ranged Weapon" },
    { mode = "both", key = "UI_PNC_SpawnEquipmentBoth", label = "Melee + Ranged Weapons" },
}

local function tr(key, fallback)
    local value = getText and getText(key) or nil
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

function Menu.Add(context, square)
    local root
    local rootOption
    local spawnType
    local spawnOption
    local i
    if not canUseDebug() or not context or not square or not ISContextMenu then
        return nil
    end
    root = ISContextMenu:getNew(context)
    rootOption = context:addOption(
        tr("UI_PNC_Spawn", "[Debug] Spawn Hoomans"))
    context:addSubMenu(rootOption, root)
    for i = 1, #SPAWN_TYPES do
        spawnType = SPAWN_TYPES[i]
        spawnOption = root:addOption(
            tr(spawnType.key, spawnType.label))
        addEquipmentChoices(
            root,
            spawnOption,
            square,
            spawnType.id,
            spawnType.tacticalClass
        )
    end
    return root
end

return Menu
