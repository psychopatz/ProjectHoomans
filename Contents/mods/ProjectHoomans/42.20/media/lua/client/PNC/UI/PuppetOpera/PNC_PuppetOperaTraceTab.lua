-- Trace and runtime snapshot view for the Puppet Opera builder.

require "ISUI/ISPanel"
require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}

local UI = PsychopatzCore.UI
local Layout = UI.Layout

local function drawTraceItem(list, y, row, alternate)
    local event = row.item
    if alternate then
        list:drawRect(0, y, list:getWidth(), list.itemheight,
            0.12, 0.16, 0.18, 0.20)
    end
    list:drawText(
        "#" .. tostring(event.sequence or row.index)
            .. "  " .. tostring(event.event or "event"),
        8, y + 5,
        0.88, 0.92, 0.98, 1,
        UIFont.Small
    )
    list:drawText(
        "phase=" .. tostring(event.phase or "-")
            .. "  actor=" .. tostring(event.actor or "-")
            .. "  reason=" .. tostring(event.reason or "-"),
        8, y + 24,
        0.62, 0.76, 0.84, 1,
        UIFont.Small
    )
    return y + list.itemheight
end

ISPNCPuppetOperaTraceTab = ISPanel:derive("ISPNCPuppetOperaTraceTab")

function ISPNCPuppetOperaTraceTab:initialise()
    ISPanel.initialise(self)
    self:noBackground()
end

function ISPNCPuppetOperaTraceTab:createChildren()
    ISPanel.createChildren(self)
    self.trace = UI.CreateList(self, {
        itemHeight = 48,
        doDrawItem = drawTraceItem,
    })
    self.snapshot = UI.CreateKeyValueList(self, {
        itemHeight = 25,
        valueXRatio = 0.34,
        ellipsize = false,
        labelX = 8,
        labelY = 6,
        valueY = 6,
        drawSelection = false,
    })
end

function ISPNCPuppetOperaTraceTab:setContext(window)
    self.ownerWindow = window
    self.model = window and window.model or nil
    self:refresh()
end

function ISPNCPuppetOperaTraceTab:refresh()
    if not self.model or not self.trace then return end
    self.trace:clear()
    for _, event in ipairs(self.model.GetTrace()) do
        self.trace:addItem(event.event or "event", event)
    end
    self.snapshot:clear()
    local snapshot = self.model.GetSnapshot()
    local status, errorText = self.model.GetStatus()
    self.snapshot:addItem("Status", {
        label = "Status", value = tostring(status), warning = errorText ~= nil,
    })
    self.snapshot:addItem("Blueprint", {
        label = "Blueprint", value = self.model.GetBlueprintID(),
    })
    self.snapshot:addItem("Session", {
        label = "Session", value = snapshot and snapshot.sessionId or "-",
    })
    self.snapshot:addItem("Phase", {
        label = "Phase", value = snapshot and snapshot.phase or "idle",
    })
    self.snapshot:addItem("Revision", {
        label = "Revision", value = snapshot and snapshot.revision or "-",
    })
    self.snapshot:addItem("Error", {
        label = "Error", value = errorText or "-", warning = errorText ~= nil,
    })
end

function ISPNCPuppetOperaTraceTab:onResponsiveLayout()
    local scale = self.ownerWindow and self.ownerWindow.uiScale
    local pad = Layout.Pixels(8, scale)
    local split = math.floor(self:getWidth() * 0.64)
    Layout.SetBounds(self.trace, pad, pad,
        split - pad * 2, self:getHeight() - pad * 2)
    Layout.SetBounds(self.snapshot, split + pad, pad,
        self:getWidth() - split - pad * 2, self:getHeight() - pad * 2)
end

return ISPNCPuppetOperaTraceTab
