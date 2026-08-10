-- Dedicated radio console for scanning and reviewing strategic signals.

require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.WorldDiscoveryUI = PNC.WorldDiscoveryUI or {}

local DiscoveryUI = PNC.WorldDiscoveryUI
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout
local State = PNC.Network.ClientState

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key
        and value or fallback
end

local function drawSignal(list, y, entry, alternate)
    local entity = entry.item or {}
    UI.DrawListSelection(
        list, y, list.itemheight,
        list.selected == entry.index, alternate
    )
    local phase = tostring(entity.phaseName or "UNKNOWN")
    local color = phase == "CONTACTED" and Theme.colors.success
        or phase == "LOCATED" and Theme.colors.accent
        or Theme.colors.warning
    list:drawText(
        tostring(entity.name or "Unknown signal"),
        10, y + 7,
        Theme.colors.text.r, Theme.colors.text.g,
        Theme.colors.text.b, Theme.colors.text.a,
        UIFont.Small
    )
    list:drawText(
        phase .. " · " .. tostring(entity.kind or "signal"),
        10, y + 28,
        color.r, color.g, color.b, color.a,
        UIFont.Small
    )
    return y + list.itemheight
end

ISPNCWorldDiscoveryRadioWindow = PsychopatzWindow:derive(
    "ISPNCWorldDiscoveryRadioWindow"
)

function ISPNCWorldDiscoveryRadioWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCWorldDiscoveryRadioWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.signals = UI.CreateList(self, {
        itemHeight = 50,
        doDrawItem = drawSignal,
    })
    self.scanButton = UI.CreateButton(self, {
        id = "scan",
        title = getText("UI_PNC_DiscoveryScan"),
        target = self,
        onclick = ISPNCWorldDiscoveryRadioWindow.onScan,
        variant = "primary",
    })
    self.refreshButton = UI.CreateButton(self, {
        id = "refresh",
        title = getText("UI_PNC_DiscoveryRefresh"),
        target = self,
        onclick = ISPNCWorldDiscoveryRadioWindow.onRefresh,
        variant = "quiet",
    })
    self:requestResponsiveLayout(true)
    self:refresh()
end

function ISPNCWorldDiscoveryRadioWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 50, bottom = 54 })
    Layout.SetBounds(self.signals,
        rect.x, rect.y, rect.width, rect.height)
    local buttonY = rect.y + rect.height + Layout.Pixels(10, self.uiScale)
    local refreshWidth = Layout.Pixels(110, self.uiScale)
    Layout.SetBounds(self.scanButton,
        rect.x, buttonY,
        math.max(160, rect.width - refreshWidth - 8),
        Layout.Pixels(30, self.uiScale))
    Layout.SetBounds(self.refreshButton,
        rect.x + rect.width - refreshWidth, buttonY,
        refreshWidth, Layout.Pixels(30, self.uiScale))
end

function ISPNCWorldDiscoveryRadioWindow:onScan()
    if PNC.Client and PNC.Client.RequestWorldDiscovery then
        PNC.Client.RequestWorldDiscovery("radio_scan")
        self.statusText = "Scanning frequencies..."
    end
end

function ISPNCWorldDiscoveryRadioWindow:onRefresh()
    if PNC.Client and PNC.Client.RequestWorldDiscovery then
        PNC.Client.RequestWorldDiscovery("snapshot")
        self.statusText = "Refreshing receiver memory..."
    end
end

function ISPNCWorldDiscoveryRadioWindow:refresh()
    local snapshot = State.worldDiscovery or {}
    self.signals:clear()
    for _, entity in ipairs(snapshot.entities or {}) do
        self.signals:addItem(
            tostring(entity.name or entity.entityID),
            entity
        )
    end
    local result = snapshot.result
    if result then
        if result.ok == true then
            self.statusText = result.reason == "signal_detected"
                and "Weak signal detected. Its position is approximate."
                or result.reason == "signal_located"
                    and "Signal triangulated and added to the map."
                    or "Discovery data updated."
        elseif result.reason == "radio_cooldown" then
            self.statusText = "Receiver cooling down: "
                .. tostring(result.cooldownSeconds or 0) .. " seconds."
        elseif result.reason == "no_signal" then
            self.statusText = "No undiscovered signals are in radio range."
        else
            self.statusText = "Scan failed: "
                .. tostring(result.reason or "unknown")
        end
    elseif #(snapshot.entities or {}) == 0 then
        self.statusText = "No signals recorded. Start a frequency scan."
    else
        self.statusText = tostring(#(snapshot.entities or {}))
            .. " strategic signals stored."
    end
end

function ISPNCWorldDiscoveryRadioWindow:prerender()
    PsychopatzWindow.prerender(self)
    self:drawText(
        string.upper(tr(
            "UI_PNC_WorldSignalScanner",
            "World Signal Scanner"
        )),
        Layout.Pixels(14, self.uiScale),
        Layout.Pixels(32, self.uiScale),
        Theme.colors.accent.r, Theme.colors.accent.g,
        Theme.colors.accent.b, Theme.colors.accent.a,
        UIFont.Small
    )
    self:drawText(
        tostring(self.statusText or "Receiver ready."),
        Layout.Pixels(14, self.uiScale),
        Layout.Pixels(49, self.uiScale),
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a,
        UIFont.Small
    )
end

function ISPNCWorldDiscoveryRadioWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    DiscoveryUI.instance = nil
end

function ISPNCWorldDiscoveryRadioWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function DiscoveryUI.ReceiveSnapshot()
    if DiscoveryUI.instance then DiscoveryUI.instance:refresh() end
end

function DiscoveryUI.Open()
    local window = DiscoveryUI.instance
    if not window then
        window = UI.NewWindow(ISPNCWorldDiscoveryRadioWindow, {
            title = tr(
                "UI_PNC_WorldSignalScanner",
                "World Signal Scanner"
            ),
            resizable = true,
            persistenceKey = "PNC.WorldDiscoveryRadio",
            responsiveSpec = {
                width = 520,
                height = 520,
                minWidth = 420,
                minHeight = 380,
                maxWidth = 760,
                maxHeight = 800,
            },
        })
        window:initialise()
        window:instantiate()
        DiscoveryUI.instance = window
    end
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:onRefresh()
    return window
end

return DiscoveryUI
