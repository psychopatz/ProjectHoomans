require "ISUI/ISContextMenu"

local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local LayoutOverlay = require "PNC/UI/Communities/ColonyManagement/PNC_SettlementLayoutOverlay"

PNC = PNC or {}
PNC.ColonyManagementContext = PNC.ColonyManagementContext or {}

local Context = PNC.ColonyManagementContext

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function ownedSettlement()
    local snapshot = PNC.Network and PNC.Network.ClientState
        and PNC.Network.ClientState.colonyManagement or nil
    local settlement = snapshot and snapshot.settlement or nil
    local faction = snapshot and snapshot.faction or nil
    if not settlement or not faction then return nil end
    if tostring(settlement.factionId or "") ~= tostring(faction.id or "") then
        return nil
    end
    return settlement
end

function Context.GetOwnedSettlement()
    return ownedSettlement()
end

function Context.ContainsSquare(settlement, square)
    local region = settlement and settlement.geometry
        and settlement.geometry.region or nil
    return square ~= nil and region ~= nil and GridRegion.containsPoint(
        region, square:getX(), square:getY(), square:getZ()) == true
end

local function openManagement()
    if PNC.ColonyManagementUI and PNC.ColonyManagementUI.Open then
        PNC.ColonyManagementUI.Open()
        return true
    end
    return false
end

local function toggleOverlay(settlement)
    LayoutOverlay.Toggle(settlement)
    return true
end

function Context.Add(context, square)
    if not context or not square then return false end
    local settlement = ownedSettlement()
    if not Context.ContainsSquare(settlement, square) then return false end

    local root = context:addOption(
        tr("UI_PNC_ColonyContext_Manage", "Manage Colony"))
    local submenu = ISContextMenu:getNew(context)
    context:addSubMenu(root, submenu)
    submenu:addOption(tr("UI_PNC_ColonyContext_Open",
        "Open Colony Management"), nil, openManagement)
    local overlayKey = LayoutOverlay.IsEnabled()
        and "UI_PNC_ColonyContext_HideOverlay"
        or "UI_PNC_ColonyContext_ShowOverlay"
    local overlayFallback = LayoutOverlay.IsEnabled()
        and "Turn Off Base Overlay" or "Turn On Base Overlay"
    submenu:addOption(tr(overlayKey, overlayFallback), settlement, toggleOverlay)
    return true
end

local function requestOwnedSettlement()
    if PNC.Client and PNC.Client.RequestColonyManagement then
        PNC.Client.RequestColonyManagement()
    end
end

local function onFillWorldObjectContextMenu(_, context, worldObjects, test)
    if test or not context then return end
    local square = PNC.NPCSelection and PNC.NPCSelection.GetWorldSquare
        and PNC.NPCSelection.GetWorldSquare(worldObjects) or nil
    Context.Add(context, square)
end

if Context.eventsInstalled ~= true then
    if Events and Events.OnFillWorldObjectContextMenu then
        Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
    end
    if Events and Events.OnGameStart then
        Events.OnGameStart.Add(requestOwnedSettlement)
    end
    if Events and Events.OnCreatePlayer then
        Events.OnCreatePlayer.Add(requestOwnedSettlement)
    end
    Context.eventsInstalled = true
end

Context.OnFillWorldObjectContextMenu = onFillWorldObjectContextMenu
Context.RequestOwnedSettlement = requestOwnedSettlement

return Context
