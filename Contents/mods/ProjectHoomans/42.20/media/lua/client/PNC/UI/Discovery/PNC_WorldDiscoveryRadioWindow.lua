-- Contact directory for discovered settlements and mobile groups.

require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.ContactsUI = PNC.ContactsUI or PNC.WorldDiscoveryUI or {}
PNC.WorldDiscoveryUI = PNC.ContactsUI

local DiscoveryUI = PNC.ContactsUI
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
        phase .. " · " .. tostring(entity.kind or "contact"),
        10, y + 28,
        color.r, color.g, color.b, color.a,
        UIFont.Small
    )
    local factionText = entity.factionKnown == true
        and entity.factionName
        and ("Faction: " .. tostring(entity.factionName))
        or "Faction not disclosed"
    list:drawText(
        factionText,
        10, y + 47,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a,
        UIFont.Small
    )
    return y + list.itemheight
end

ISPNCContactsWindow = PsychopatzWindow:derive(
    "ISPNCContactsWindow"
)

function ISPNCContactsWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCContactsWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.signals = UI.CreateList(self, {
        itemHeight = 68,
        doDrawItem = drawSignal,
    })
    self.signals.onMouseDown = function(list, x, y)
        if ISScrollingListBox and ISScrollingListBox.onMouseDown then
            ISScrollingListBox.onMouseDown(list, x, y)
        end
        local rowIndex = list:rowAt(x, y)
        if rowIndex > 0 then
            list.selected = rowIndex
            self:onSelectionChanged()
        end
        return true
    end
    self.callButton = UI.CreateButton(self, {
        id = "call_contact",
        title = tr("UI_PNC_DiscoveryCall", "Call / triangulate"),
        target = self,
        onclick = ISPNCContactsWindow.onCallContact,
        variant = "quiet",
    })
    self.refreshButton = UI.CreateButton(self, {
        id = "refresh",
        title = getText("UI_PNC_DiscoveryRefresh"),
        target = self,
        onclick = ISPNCContactsWindow.onRefresh,
        variant = "quiet",
    })
    self:requestResponsiveLayout(true)
    self:refresh()
end

function ISPNCContactsWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 50, bottom = 54 })
    Layout.SetBounds(self.signals,
        rect.x, rect.y, rect.width, rect.height)
    local buttonY = rect.y + rect.height + Layout.Pixels(10, self.uiScale)
    local gap = Layout.Pixels(8, self.uiScale)
    local buttonWidth = (rect.width - gap) / 2
    Layout.SetBounds(self.callButton,
        rect.x, buttonY, buttonWidth, Layout.Pixels(30, self.uiScale))
    Layout.SetBounds(self.refreshButton,
        rect.x + buttonWidth + gap, buttonY, buttonWidth,
        Layout.Pixels(30, self.uiScale))
end

function ISPNCContactsWindow:onRefresh()
    if PNC.Client and PNC.Client.RequestWorldDiscovery then
        PNC.Client.RequestWorldDiscovery("snapshot")
        self.statusText = "Refreshing receiver memory..."
    end
end

function ISPNCContactsWindow:onSelectionChanged()
    local row = self.signals
        and self.signals.items[self.signals.selected] or nil
    self.selectedEntity = row and row.item or nil
    self.selectedEntityID = self.selectedEntity
        and tostring(self.selectedEntity.entityID or "") or nil
    if self.callButton and self.callButton.setEnable then
        self.callButton:setEnable(self.selectedEntity ~= nil)
    end
end

function ISPNCContactsWindow:onCallContact()
    local entity = self.selectedEntity
    if not entity then
        self.statusText = "Select a known channel first."
        return
    end
    if not PNC.Client or not PNC.Client.RequestWorldDiscovery then
        self.statusText = "Discovery service unavailable."
        return
    end
    local sent, payload = PNC.Client.RequestWorldDiscovery(
        "call_contact", {
            kind = entity.kind,
            entityID = entity.entityID,
        })
    if not sent then
        self.statusText = "Call failed: " .. tostring(payload or "unknown")
    elseif not payload then
        self.statusText = "Calling channel..."
    end
end

function ISPNCContactsWindow:refresh()
    local snapshot = State.worldDiscovery or {}
    local previous = self.selectedEntityID
    self.signals:clear()
    for _, entity in ipairs(snapshot.entities or {}) do
        self.signals:addItem(
            tostring(entity.name or entity.entityID),
            entity
        )
    end
    local selectedIndex
    for index, entry in ipairs(self.signals.items or {}) do
        local entity = entry.item
        if tostring(entity and entity.entityID or "")
            == tostring(previous or "")
        then
            selectedIndex = index
            break
        end
    end
    self.signals.selected = selectedIndex
        or (#(self.signals.items or {}) > 0 and 1 or 0)
    self:onSelectionChanged()
    local result = snapshot.result
    if result then
        if result.ok == true then
            self.statusText = result.reason == "signal_detected"
                and "Weak signal detected. Its position is approximate."
                or result.reason == "signal_located"
                    and "Signal triangulated and added to the map."
                    or result.reason == "contact_located"
                        and "Channel triangulated; map updated."
                        or result.reason == "contact_already_located"
                            and "Channel already has an exact map position."
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
        self.statusText = "No contacts recorded. Listen to the scan channel."
    else
        self.statusText = tostring(#(snapshot.entities or {}))
            .. " contacts recorded."
    end
end

function ISPNCContactsWindow:prerender()
    PsychopatzWindow.prerender(self)
    self:drawText(
        string.upper(tr(
            "UI_PNC_Contacts",
            "Contacts"
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

function ISPNCContactsWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    DiscoveryUI.instance = nil
end

function ISPNCContactsWindow:new(x, y, width, height, options)
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
        window = UI.NewWindow(ISPNCContactsWindow, {
            title = tr(
                "UI_PNC_Contacts",
                "Contacts"
            ),
            resizable = true,
            persistenceKey = "PNC.Contacts",
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
