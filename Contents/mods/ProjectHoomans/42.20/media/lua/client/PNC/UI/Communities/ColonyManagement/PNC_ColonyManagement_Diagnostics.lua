require "ISUI/ISTickBox"

local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
local Diagnostics = {}

local function debugAvailable()
    if PNC.Client and PNC.Client.CanUseDebug then
        return PNC.Client.CanUseDebug() == true
    end
    if isDebugEnabled then return isDebugEnabled() == true end
    return getCore and getCore() and getCore():getDebug() == true or false
end

local function serialize(fields)
    local output = {}
    for _, key in ipairs({
        "source", "tab", "selected", "people", "attention",
        "rows", "pane", "list", "scrollbar",
    }) do
        if fields and fields[key] ~= nil then
            output[#output + 1] = key .. "=" .. tostring(fields[key])
        end
    end
    return table.concat(output, " ")
end

function Diagnostics.IsAvailable()
    return debugAvailable()
end

function Diagnostics.IsEnabled(window)
    return debugAvailable() and window.diagnosticsEnabled == true
end

function Diagnostics.Log(window, event, fields)
    if not Diagnostics.IsEnabled(window) then return end
    local suffix = serialize(fields)
    local message = "colony_ui event=" .. tostring(event)
    if suffix ~= "" then message = message .. " " .. suffix end
    if PNC.Core and PNC.Core.Log then
        PNC.Core.Log("DEBUG", message)
    else
        print("[PNC][DEBUG] " .. message)
    end
end

function Diagnostics.SetEnabled(window, enabled)
    window.diagnosticsEnabled = debugAvailable() and enabled == true
    PNC.ColonyManagementUI.DiagnosticsEnabled =
        window.diagnosticsEnabled == true
    -- The same opt-in also enables the concise server-side supply transaction
    -- trace. This makes the checkbox useful for diagnosing needs failures in
    -- SP and MP without enabling broad or per-tick logging.
    if PNC.Client and PNC.Client.SendDebug then
        PNC.Client.SendDebug("needs_debug_action", {
            operation = "supply_logging",
            enabled = window.diagnosticsEnabled == true,
        })
    end
    Diagnostics.Log(window, "diagnostics_changed", {
        source = window.diagnosticsEnabled and "enabled" or "disabled",
    })
end

function Diagnostics.CreateToggle(window)
    if not debugAvailable() then return nil end
    local toggle = ISTickBox:new(0, 0, 150, 28, "", window,
        function(target, _, selected)
            Diagnostics.SetEnabled(target, selected == true)
        end)
    toggle:initialise()
    toggle:instantiate()
    toggle:addOption(Shared.Tr(Shared.DIAGNOSTICS_LABEL_KEY,
        "UI DIAGNOSTICS"), 1)
    window.diagnosticsEnabled =
        PNC.ColonyManagementUI.DiagnosticsEnabled == true
    toggle:setSelected(1, window.diagnosticsEnabled)
    toggle.psychopatzPreferredWidth = 152
    window:addChild(toggle)
    return toggle
end

return Diagnostics
