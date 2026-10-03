local function newSubMenu(context, title)
    local option = context:addOption(title)
    local submenu = ISContextMenu:getNew(context)
    context:addSubMenu(option, submenu)
    return submenu
end

local function sendMapDebug(window, item, action, payload)
    payload = payload or {}
    payload.id = item.id
    if PNC.Client and PNC.Client.SendDebug then
        PNC.Client.SendDebug(action, payload)
    end
    window:requestRoster(false)
end

local EQUIPMENT_PRESETS = {
    primary = {
        { "Hammer", "Base.Hammer" },
        { "Kitchen Knife", "Base.KitchenKnife" },
        { "Baseball Bat", "Base.BaseballBat" },
        { "Crowbar", "Base.Crowbar" },
        { "Hand Axe", "Base.HandAxe" },
        { "Pipe Wrench", "Base.PipeWrench" },
        { "Shovel", "Base.Shovel" },
        { "Pistol", "Base.Pistol" },
        { "Revolver", "Base.Revolver" },
        { "Double Barrel Shotgun", "Base.DoubleBarrelShotgun" },
    },
    back = {
        { "Schoolbag", "Base.Bag_Schoolbag" },
        { "Duffel Bag", "Base.Bag_DuffelBag" },
        { "Hiking Bag", "Base.Bag_BigHikingBag" },
        { "ALICE Pack", "Base.Bag_ALICEpack" },
        { "Baseball Bat", "Base.BaseballBat" },
        { "Crowbar", "Base.Crowbar" },
        { "Shovel", "Base.Shovel" },
        { "Shotgun", "Base.DoubleBarrelShotgun" },
    },
    belt = {
        { "Hammer", "Base.Hammer" },
        { "Kitchen Knife", "Base.KitchenKnife" },
        { "Hand Axe", "Base.HandAxe" },
        { "Pipe Wrench", "Base.PipeWrench" },
        { "Pistol", "Base.Pistol" },
    },
}

local function sendEquipmentDebug(
    window,
    item,
    slotKind,
    slotName,
    fullType
)
    sendMapDebug(window, item, "set_equipment_slot", {
        slotKind = slotKind,
        slotName = slotName,
        fullType = fullType,
    })
end

local function addEquipmentSlotMenu(
    window,
    context,
    item,
    title,
    slotKind,
    slotName,
    presets
)
    local submenu = newSubMenu(context, title)
    submenu:addOption("Clear slot", nil, function()
        sendEquipmentDebug(
            window,
            item,
            slotKind,
            slotName,
            nil
        )
    end)
    for _, preset in ipairs(presets or {}) do
        local label = preset[1]
        local fullType = preset[2]
        submenu:addOption(label, nil, function()
            sendEquipmentDebug(
                window,
                item,
                slotKind,
                slotName,
                fullType
            )
        end)
    end
    return submenu
end

function ISPNCNPCMonitor:onEquipment(button)
    local item = self:getSelectedDiagnostic()
    local context
    local x
    local y
    if not item or not button then return end
    x = button.getAbsoluteX and button:getAbsoluteX() or getMouseX()
    y = button.getAbsoluteY and (
        button:getAbsoluteY()
            + (button.getHeight and button:getHeight()
                or button.height or 0)
    ) or getMouseY()
    context = ISContextMenu.get(0, x, y)
    context:addOption("Copy my complete loadout", nil, function()
        sendMapDebug(self, item, "copy_player_loadout", {})
    end)
    context:addOption("Copy my held weapon", nil, function()
        local player = getSpecificPlayer and getSpecificPlayer(0) or nil
        local held = player and player.getPrimaryHandItem
            and player:getPrimaryHandItem() or nil
        sendMapDebug(self, item, "copy_held_weapon", {
            weaponFullType = held and held.getFullType
                and held:getFullType() or nil,
        })
    end)
    context:addOption("Clear complete loadout", nil, function()
        sendMapDebug(self, item, "clear_equipment", {})
    end)
    addEquipmentSlotMenu(
        self,
        context,
        item,
        "Primary hand",
        "primary",
        "",
        EQUIPMENT_PRESETS.primary
    )
    addEquipmentSlotMenu(
        self,
        context,
        item,
        "Secondary hand",
        "secondary",
        "",
        EQUIPMENT_PRESETS.belt
    )
    addEquipmentSlotMenu(
        self,
        context,
        item,
        "Back / bag",
        "attached",
        "Back",
        EQUIPMENT_PRESETS.back
    )
    for _, slot in ipairs({
        { "Right holster", "HolsterRight" },
        { "Left holster", "HolsterLeft" },
        { "Left belt", "SmallBeltLeft" },
        { "Right belt", "SmallBeltRight" },
    }) do
        addEquipmentSlotMenu(
            self,
            context,
            item,
            slot[1],
            "attached",
            slot[2],
            EQUIPMENT_PRESETS.belt
        )
    end
end

function ISPNCNPCMonitor:onMapMarker(button)
    local item = self:getSelectedDiagnostic()
    local presentation
    local context
    local visibility
    local roles
    local icons
    local x
    local y
    if not item or not button then return end
    presentation = item.mapPresentation or {}
    x = button.getAbsoluteX and button:getAbsoluteX() or getMouseX()
    y = button.getAbsoluteY and (
        button:getAbsoluteY()
            + (button.getHeight and button:getHeight() or button.height or 0)
    ) or getMouseY()
    context = ISContextMenu.get(0, x, y)

    visibility = newSubMenu(context, "Visibility: "
        .. tostring(presentation.visibility or "all"))
    for _, mode in ipairs({
        { "all", "All Players" },
        { "known", "Known Players Only" },
        { "selected", "Selected NPC Only" },
        { "hidden", "Hidden" },
    }) do
        local modeID = mode[1]
        visibility:addOption(mode[2], nil, function()
            sendMapDebug(self, item, "set_map_presentation", {
                visibility = modeID,
            })
        end)
    end

    context:addOption("Known to Me", nil, function()
        sendMapDebug(self, item, "set_map_known", { known = true })
    end)
    context:addOption("Forget Me", nil, function()
        sendMapDebug(self, item, "set_map_known", { known = false })
    end)

    roles = newSubMenu(context, "Role Postfix")
    roles:addOption("None", nil, function()
        sendMapDebug(self, item, "set_map_presentation", {
            clearRole = true,
        })
    end)
    for _, role in ipairs({
        { "trader", "Trader" },
        { "quest giver", "Quest Giver" },
        { "guard", "Guard" },
        { "worker", "Worker" },
    }) do
        local roleTag = role[1]
        roles:addOption(role[2], nil, function()
            sendMapDebug(self, item, "set_map_presentation", {
                roleTag = roleTag,
            })
        end)
    end

    icons = newSubMenu(context, "Marker Icon")
    icons:addOption("None", nil, function()
        sendMapDebug(self, item, "set_map_presentation", {
            clearIcon = true,
        })
    end)
    for _, icon in ipairs({
        { "trader", "Trader (T)" },
        { "quest_giver", "Quest Giver (!)" },
        { "guard", "Guard (G)" },
        { "worker", "Worker (W)" },
    }) do
        local iconID = icon[1]
        icons:addOption(icon[2], nil, function()
            sendMapDebug(self, item, "set_map_presentation", {
                iconID = iconID,
            })
        end)
    end

    context:addOption("Preset: Trader", nil, function()
        sendMapDebug(self, item, "set_map_presentation", {
            roleTag = "trader",
            iconID = "trader",
        })
    end)
    context:addOption("Preset: Quest Giver", nil, function()
        sendMapDebug(self, item, "set_map_presentation", {
            roleTag = "quest giver",
            iconID = "quest_giver",
        })
    end)
end
