PNC = PNC or {}
PNC.DebugSpawnMenu = PNC.DebugSpawnMenu or {}

local Menu = PNC.DebugSpawnMenu

local FACTIONS = {
    { id = "colonist", key = "UI_PNC_SpawnCompanion", label = "Companion" },
    { id = "neutral", key = "UI_PNC_SpawnNeutral", label = "Neutral" },
    { id = "hostile", key = "UI_PNC_SpawnHostile", label = "Hostile" },
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

local function sendSpawn(_, square, faction, equipmentMode)
    local payload = {
        variant = faction,
        faction = faction,
        x = square:getX(),
        y = square:getY(),
        z = square:getZ(),
    }
    if equipmentMode then
        payload.equipmentSpawnMode = equipmentMode
    end
    return PNC.Client.SendDebug("spawn", payload)
end

local function addEquipmentChoices(context, parent, square, faction)
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
            faction,
            choice.mode
        )
    end
    return equipmentMenu
end

function Menu.Add(context, square)
    local root
    local rootOption
    local faction
    local factionOption
    local i
    if not context or not square or not ISContextMenu then
        return nil
    end
    root = ISContextMenu:getNew(context)
    rootOption = context:addOption(tr("UI_PNC_Spawn", "PNC Spawn"))
    context:addSubMenu(rootOption, root)
    for i = 1, #FACTIONS do
        faction = FACTIONS[i]
        factionOption = root:addOption(tr(faction.key, faction.label))
        addEquipmentChoices(root, factionOption, square, faction.id)
    end
    return root
end

return Menu
