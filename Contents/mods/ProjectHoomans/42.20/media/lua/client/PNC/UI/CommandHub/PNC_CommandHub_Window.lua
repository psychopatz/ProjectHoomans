-- Project Hoomans host adapter.
--
-- The actual root window is supplied by PsychopatzCore. This keeps the
-- Hoomans entry point stable while making the host reusable by other mods.
-- Category callbacks continue to route through ChildController.Toggle.
-- The legacy default is persistenceKey = "PNC.CommandHub".

require "PsychopatzCore/UI/PsychopatzUI"
local CoreHub = require "PsychopatzCore/UI/PsychopatzCommandHub"

PNC = PNC or {}
PNC.CommandHub = PNC.CommandHub or {}

local Hub = PNC.CommandHub
Hub.Window = Hub.Window or {}
Hub.Window.Core = CoreHub.Window
ISPNCCommandHubWindow = CoreHub.Window

local function trace(event, message)
    if CoreHub.Trace then CoreHub.Trace(event, message) end
end

local function titleText()
    local value = getText and getText("UI_PNC_CommandHub_Title") or nil
    return value and value ~= "" and value ~= "UI_PNC_CommandHub_Title"
        and value or "COMMAND HUB"
end

local function requestColonySnapshot()
    local state = PNC.Network and PNC.Network.ClientState or nil
    if state and (state.colonyManagement ~= nil or state.colonyBase ~= nil) then
        return
    end
    if PNC.Client and PNC.Client.RequestBaseBootstrap then
        PNC.Client.RequestBaseBootstrap()
    elseif PNC.Client and PNC.Client.RequestColonyManagement then
        PNC.Client.RequestColonyManagement()
    end
end

function Hub.ToggleChild(id, owner)
    local controller = Hub.ChildController
    if controller and controller.Toggle then
        return controller.Toggle(id, owner)
    end
    return false
end

function Hub.OpenBase(owner)
    local window = Hub.instance
    if not window or not window.getIsVisible or not window:getIsVisible() then
        window = Hub.Open()
    end
    if not window then return false end
    local controller = Hub.ChildController
    if not controller then return false end
    if controller.IsOpen and controller.IsOpen("base") then
        local base = PNC.BaseUI
        if base and base.instance and base.instance.bringToTop then
            base.instance:bringToTop()
        end
        if controller.SyncPositions then controller.SyncPositions() end
        return true
    end
    if not controller.Toggle then return false end
    return controller.Toggle("base", owner or window) == true
end

-- Conversation setup enters the world selector directly.  The Base widget is
-- intentionally not opened here: it is the management surface for an
-- established base, while the conversation owns the first claim decision.
function Hub.OpenTerritorySetup(owner)
    trace("pnc_territory_setup_start", "has_owner=" .. tostring(owner ~= nil))
    local window = Hub.instance
    if not window or not window.getIsVisible or not window:getIsVisible() then
        window = Hub.Open()
    end
    if not window then
        trace("pnc_territory_setup_result", "result=false reason=hub_unavailable")
        return false
    end

    local controller = Hub.ChildController
    local actions = CoreHub.Actions
    local actionWindow
    if controller and controller.IsOpen
        and controller.IsOpen("zone") and actions and actions.Open
    then
        actionWindow = actions.Open("zone", window)
    elseif controller and controller.Toggle then
        if controller.CloseAll then controller.CloseAll("switch") end
        actionWindow = controller.Toggle("zone", window)
            and actions and actions.instance or nil
    elseif actions and actions.Open then
        actionWindow = actions.Open("zone", window)
    end
    if not actionWindow and actions then actionWindow = actions.instance end
    if not actionWindow then
        trace("pnc_territory_setup_result",
            "result=false reason=zone_actions_unavailable")
        return false
    end

    local zoneUI = Hub.ZoneUI
    if not zoneUI or type(zoneUI.Open) ~= "function" then
        trace("pnc_territory_setup_result",
            "result=false reason=zone_ui_unavailable")
        return false
    end
    local zoneWindow = zoneUI.Open("base_zone", window, {
        startOperation = "create",
    })
    if not zoneWindow then
        trace("pnc_territory_setup_result",
            "result=false reason=base_zone_window_unavailable")
        return false
    end
    if controller then controller.activeID = "zone" end
    if controller and controller.SyncPositions then controller.SyncPositions() end
    trace("pnc_territory_setup_result",
        "result=true operation=create definition=base_zone")
    return zoneWindow
end

function Hub.Sync()
    return CoreHub.Sync()
end

function Hub.Open(options)
    options = options or {}
    requestColonySnapshot()
    local window = CoreHub.Open({
        title = options.title or titleText(),
        persistenceKey = options.persistenceKey or "PNC.CommandHub",
        resizable = options.resizable ~= false,
        responsiveSpec = options.responsiveSpec or {
            anchor = "top_left",
            offsetX = 18,
            offsetY = 70,
            width = 320,
            height = 230,
            minWidth = 220,
            minHeight = 150,
            maxWidth = 620,
            maxHeight = 820,
        },
    })
    Hub.instance = window
    return window
end

function Hub.Toggle(options)
    local visible = Hub.instance and Hub.instance.getIsVisible
        and Hub.instance:getIsVisible()
    if visible then
        Hub.Close()
        return false
    end
    return Hub.Open(options) ~= nil
end

function Hub.Close()
    if Hub.instance and Hub.instance.close then
        Hub.instance:close()
    else
        CoreHub.Close()
    end
end

return Hub
