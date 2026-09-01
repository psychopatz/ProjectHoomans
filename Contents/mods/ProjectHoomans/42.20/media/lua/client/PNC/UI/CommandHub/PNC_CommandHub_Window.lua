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

local function titleText()
    local value = getText and getText("UI_PNC_CommandHub_Title") or nil
    return value and value ~= "" and value ~= "UI_PNC_CommandHub_Title"
        and value or "COLONY"
end

function Hub.ToggleChild(id, owner)
    local controller = Hub.ChildController
    if controller and controller.Toggle then
        return controller.Toggle(id, owner)
    end
    return false
end

function Hub.Sync()
    return CoreHub.Sync()
end

function Hub.Open(options)
    options = options or {}
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
