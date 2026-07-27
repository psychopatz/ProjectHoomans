PNC = PNC or {}
PNC.BandageMenu = PNC.BandageMenu or {}

local BandageMenu = PNC.BandageMenu

local function newSubMenu(menu)
    if menu and menu.getNew then
        return menu:getNew(menu)
    end
    if ISContextMenu and ISContextMenu.getNew then
        return ISContextMenu:getNew(menu)
    end
    return nil
end

function BandageMenu.AddMaterialOptions(
    menu,
    parentOption,
    player,
    onSelect,
    available,
    suppliedEntries
)
    local entries = type(suppliedEntries) == "table" and suppliedEntries
        or PNC.Treatment and PNC.Treatment.ListBandages
            and PNC.Treatment.ListBandages(player) or {}
    local subMenu
    local i
    if not menu or not parentOption then
        return 0
    end
    if #entries <= 0 or available == false then
        parentOption.notAvailable = true
    end
    if #entries <= 0 then
        return 0
    end
    subMenu = newSubMenu(menu)
    if not subMenu then
        parentOption.notAvailable = true
        return 0
    end
    menu:addSubMenu(parentOption, subMenu)
    for i = 1, #entries do
        local entry = entries[i]
        local bandageType = tostring(entry.fullType)
        local itemOption = subMenu:addOption(
            tostring(entry.name) .. " (" .. tostring(entry.count) .. ")",
            nil,
            function()
                if available ~= false and type(onSelect) == "function" then
                    onSelect(bandageType)
                end
            end
        )
        itemOption.itemForTexture = entry.item
        if available == false then
            itemOption.notAvailable = true
        end
    end
    return #entries
end

return BandageMenu
