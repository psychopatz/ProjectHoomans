PNC = PNC or {}
PNC.MapCommands = PNC.MapCommands or {}

local Commands = PNC.MapCommands
local Deps = Commands._ProviderDeps or {}
local selectionLabel = Deps.selectionLabel
local isProviderVisible = Deps.isProviderVisible
local populateProvider = Deps.populateProvider

function Commands.BuildContext(map, x, y, target)
    local playerNum = tonumber(map and map.playerNum) or 0
    local context = ISContextMenu.get(
        playerNum,
        x + map:getAbsoluteX(),
        y + map:getAbsoluteY()
    )
    local root = context:addOption(
        "NPC Commands — " .. selectionLabel()
    )
    local submenu = ISContextMenu:getNew(context)
    context:addSubMenu(root, submenu)
    local i
    local provider

    for i = 1, #Commands.Ordered do
        provider = Commands.Ordered[i]
        if isProviderVisible(provider, target, map) then
            populateProvider(submenu, provider, target, map)
        end
    end
    return context
end

function Commands.OpenForSelection(raw, centerX, centerY, zoom)
    if Commands.SetSelection(raw) <= 0 then return false end
    local first = Commands.Selection[1]
    centerX = tonumber(centerX) or first.x
    centerY = tonumber(centerY) or first.y
    if not ISWorldMap or not ISWorldMap.ShowWorldMap then return false end
    ISWorldMap.ShowWorldMap(0, centerX, centerY, tonumber(zoom) or 15)
    local map = ISWorldMap_instance or ISWorldMap.instance
    if not map then
        Commands.ClearSelection()
        return false
    end
    map._pncCommandMode = true
    -- The normal single-player map may pause simulation. Command mode is a
    -- live tactical/debug view, so journeys must keep advancing while open.
    if ISWorldMap.shouldPause and ISWorldMap.shouldPause()
        and getGameSpeed and getGameSpeed() == 0
        and setGameSpeed
    then
        setGameSpeed(1)
    end
    return true
end

function Commands.OpenForNPC(snapshot)
    return Commands.OpenForSelection(
        snapshot,
        snapshot and snapshot.x,
        snapshot and snapshot.y,
        15
    )
end


return Commands
