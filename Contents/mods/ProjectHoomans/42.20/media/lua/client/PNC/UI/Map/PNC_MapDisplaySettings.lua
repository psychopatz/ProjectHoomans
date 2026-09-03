-- Per-client world-map presentation controls.

require "ISUI/Maps/ISWorldMap"

PNC = PNC or {}
PNC.MapDisplay = PNC.MapDisplay or {}

local Display = PNC.MapDisplay
local Menu = PNC.MapHoomansMenu

Display.NamesVisible = Display.NamesVisible == true
if Display.BasesVisible == nil then Display.BasesVisible = true end

local function text(key, fallback)
    local value = getText and getText(key) or nil
    if value and value ~= "" and value ~= key then return value end
    return fallback or key
end

function Display.GetNamesTitle()
    return text(
        Display.NamesVisible and "UI_PNC_MapNamesOn" or "UI_PNC_MapNamesOff",
        Display.NamesVisible and "NPC NAMES: ON" or "NPC NAMES: OFF"
    )
end

function Display.GetNamesTooltip()
    return text(
        Display.NamesVisible and "UI_PNC_MapNamesOnHelp"
            or "UI_PNC_MapNamesOffHelp",
        Display.NamesVisible
            and "Hide ordinary NPC names (selected and hovered names remain visible)"
            or "Show NPC names on the world map"
    )
end

function Display.GetBasesTitle()
    return text(
        Display.BasesVisible and "UI_PNC_MapWorldOn" or "UI_PNC_MapWorldOff",
        Display.BasesVisible and "NPC WORLD: ON" or "NPC WORLD: OFF"
    )
end

function Display.GetBasesTooltip()
    return text(
        Display.BasesVisible and "UI_PNC_MapWorldOnHelp"
            or "UI_PNC_MapWorldOffHelp",
        Display.BasesVisible
            and "Hide generated settlements and abstract survivor groups"
            or "Show generated settlements and abstract survivor groups"
    )
end

function Display.AreNamesVisible()
    return Display.NamesVisible == true
end

function Display.SetNamesVisible(visible)
    Display.NamesVisible = visible == true
    if Menu and Menu.instance and Menu.instance.syncButtons then
        Menu.instance:syncButtons()
    end
    return Display.NamesVisible
end

function Display.AreBasesVisible()
    return Display.BasesVisible == true
end

function Display.SetBasesVisible(visible)
    Display.BasesVisible = visible == true
    if Display.BasesVisible
        and PNC.CommunityDebugOverlay
        and PNC.CommunityDebugOverlay.Update
    then
        PNC.CommunityDebugOverlay.Update(true)
    end
    if Display.BasesVisible
        and PNC.AbstractGroupMapLayer
        and PNC.AbstractGroupMapLayer.Update
    then
        PNC.AbstractGroupMapLayer.Update(true)
    end
    if Menu and Menu.instance and Menu.instance.syncButtons then
        Menu.instance:syncButtons()
    end
    return Display.BasesVisible
end

function Display.ToggleBases()
    return Display.SetBasesVisible(
        not Display.BasesVisible
    )
end

function Display.ToggleNames()
    return Display.SetNamesVisible(not Display.NamesVisible)
end

if Menu and Menu.Register then
    Menu.Register("npc_names", {
        order = 20,
        title = function() return Display.GetNamesTitle() end,
        tooltip = function() return Display.GetNamesTooltip() end,
        onActivate = function() return Display.ToggleNames() end,
    })
    Menu.Register("npc_world", {
        order = 30,
        title = function() return Display.GetBasesTitle() end,
        tooltip = function() return Display.GetBasesTooltip() end,
        onActivate = function() return Display.ToggleBases() end,
    })
end

return Display
