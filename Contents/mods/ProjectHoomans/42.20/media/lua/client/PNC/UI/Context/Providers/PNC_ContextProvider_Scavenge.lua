-- Context menu provider allowing the player to select following companion loot categories.
PNC = PNC or {}
PNC.ContextHub = PNC.ContextHub or {}

local ContextHub = PNC.ContextHub
local Commands = PNC.CompanionCommands
local Provider = { id = "scavenge" }

local function tr(key, fallback)
    local value = getText and PNC.Translation and PNC.Translation.GetKey
        and PNC.Translation.GetKey(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function target(entry)
    return entry and (entry.record or entry.snapshot) or nil
end

local function followsPlayer(record, player)
    if not record or not player then return false end
    if record.followingCurrentPlayer ~= nil then
        return record.followingCurrentPlayer == true
    end
    local order = record.orderSpec or {}
    if tostring(order.kind or "")
        ~= tostring(PNC.Const and PNC.Const.ORDER_FOLLOW or "follow")
    then return false end
    local ownerOnlineID = tonumber(order.ownerOnlineID or record.ownerOnlineID)
    local playerOnlineID = player.getOnlineID
        and tonumber(player:getOnlineID()) or nil
    if ownerOnlineID ~= nil and playerOnlineID ~= nil then
        return ownerOnlineID == playerOnlineID
    end
    local ownerUsername = tostring(
        order.ownerUsername or record.ownerUsername or "")
    local username = player.getUsername
        and tostring(player:getUsername() or "") or ""
    return username ~= "" and ownerUsername == username
end

local function markChecked(menu, option, checked)
    if menu and menu.setOptionChecked and option then
        menu:setOptionChecked(option, checked == true)
    end
    if option then
        ContextHub.ApplyOptionPresentation(option, {
            color = checked == true and "good" or nil,
        })
    end
end

function Provider.isEnabled(entry, player)
    local record = target(entry)
    local authority = PNC.ClientCompanionAuthority
    local commandable
    if authority and authority.CanPlayerCommand then
        commandable = authority.CanPlayerCommand(record, player,
            PNC.Const.COMPANION_COMMAND_RADIUS) == true
    else
        commandable = Commands and Commands.CanPlayerCommand
            and Commands.CanPlayerCommand(record, player,
                PNC.Const.COMPANION_COMMAND_RADIUS) == true
    end
    return commandable and followsPlayer(record, player)
end

function Provider.addOptions(menu, entry)
    local client = PNC.Client
    local policy = client and client.GetScavengePolicy and client.GetScavengePolicy() or {}
    local categories = policy.categories or {}
    local enabled = policy.enabled ~= false
    local prefs = policy.preferences or { containers = true, floorItems = true, corpses = true }

    local scavengingMenu = ISContextMenu:getNew(menu)
    local root = menu:addOption(tr("UI_PNC_Scavenge_Context", "Follow Scavenge Categories"))
    menu:addSubMenu(root, scavengingMenu)

    local toggleOpt = scavengingMenu:addOption(enabled
        and tr("UI_PNC_Scavenge_AutoOn", "Auto-Loot When Following: ON")
        or tr("UI_PNC_Scavenge_AutoOff", "Auto-Loot When Following: OFF"), nil, function()
            if client and client.SetScavengeEnabled then
                client.SetScavengeEnabled(not enabled)
            end
        end)
    if toggleOpt then
        ContextHub.ApplyOptionPresentation(toggleOpt, {
            color = enabled and "good" or "bad",
        })
        if scavengingMenu.setOptionChecked then
            scavengingMenu:setOptionChecked(toggleOpt, enabled)
        end
    end

    local catDefs = PNC.WorldItemCategories and PNC.WorldItemCategories.List
        and PNC.WorldItemCategories.List() or {
            { id = "food", labelKey = "UI_PNC_ScavengeCategory_Food", label = "Food" },
            { id = "water", labelKey = "UI_PNC_ScavengeCategory_Water", label = "Water" },
            { id = "medical", labelKey = "UI_PNC_ScavengeCategory_Medical", label = "Medical" },
            { id = "weapons", labelKey = "UI_PNC_ScavengeCategory_Weapons", label = "Weapons" },
            { id = "ammo", labelKey = "UI_PNC_ScavengeCategory_Ammo", label = "Ammo" },
            { id = "tools", labelKey = "UI_PNC_ScavengeCategory_Tools", label = "Tools" },
            { id = "materials", labelKey = "UI_PNC_ScavengeCategory_Materials", label = "Materials" },
            { id = "clothing", labelKey = "UI_PNC_ScavengeCategory_Clothing", label = "Clothing" },
        }

    for index = 1, #catDefs do
        local def = catDefs[index]
        local active = categories[def.id] == true
        local opt = scavengingMenu:addOption(tr(def.labelKey, def.label), nil, function()
            if client and client.SetScavengeCategory then
                client.SetScavengeCategory(def.id, not active)
            end
        end)
        markChecked(scavengingMenu, opt, active)
    end

    local sourcesMenu = ISContextMenu:getNew(scavengingMenu)
    local sourcesRoot = scavengingMenu:addOption(tr("UI_PNC_Scavenge_Sources", "Loot Sources"))
    scavengingMenu:addSubMenu(sourcesRoot, sourcesMenu)
    for _, src in ipairs({
        { key = "containers", label = tr("UI_PNC_Scavenge_Containers", "Containers") },
        { key = "floorItems", label = tr("UI_PNC_Scavenge_Floor", "Floor Items") },
        { key = "corpses", label = tr("UI_PNC_Scavenge_Corpses", "Corpses") },
    }) do
        local checked = prefs[src.key] ~= false
        local opt = sourcesMenu:addOption(src.label, nil, function()
            if client and client.SetScavengePreferences then
                local nextPrefs = {
                    containers = prefs.containers ~= false,
                    floorItems = prefs.floorItems ~= false,
                    corpses = prefs.corpses ~= false,
                }
                nextPrefs[src.key] = not checked
                client.SetScavengePreferences(nextPrefs)
            end
        end)
        markChecked(sourcesMenu, opt, checked)
    end

    scavengingMenu:addOption(tr("UI_PNC_Scavenge_Clear", "Clear Categories"), nil, function()
        if client and client.SetScavengeCategories then
            client.SetScavengeCategories({})
        end
    end)
end

ContextHub.RegisterProvider(Provider)

return Provider
