require "PsychopatzCore/UI/PsychopatzUI"

local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
local Support = require "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_SelectorSupport"

PNC = PNC or {}
PNC.FacilityCapacityModal = PNC.FacilityCapacityModal or {}

local CapacityModal = PNC.FacilityCapacityModal
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Theme = UI.Theme

ISPNCFacilityCapacityWindow = PsychopatzWindow:derive(
    "ISPNCFacilityCapacityWindow"
)

function ISPNCFacilityCapacityWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCFacilityCapacityWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.capacityEntry = UI.CreateTextEntry(self, {
        width = 1,
        height = 1,
        text = self.facility.capacity and tostring(self.facility.capacity) or "",
        onlyNumbers = true,
        maxTextLength = 3,
    })
    self.saveButton = UI.CreateButton(self, {
        id = "save",
        title = Shared.Tr("UI_PNC_Facility_SaveCapacity", "SAVE"),
        target = self,
        onclick = ISPNCFacilityCapacityWindow.onSave,
        variant = "primary",
    })
    self.autoButton = UI.CreateButton(self, {
        id = "automatic",
        title = Shared.Tr("UI_PNC_Facility_AutomaticCapacity", "AUTOMATIC"),
        target = self,
        onclick = ISPNCFacilityCapacityWindow.onAutomatic,
        variant = "quiet",
    })
    self.cancelButton = UI.CreateButton(self, {
        id = "cancel",
        title = Shared.Tr("UI_Cancel", "CANCEL"),
        target = self,
        onclick = ISPNCFacilityCapacityWindow.onCancel,
        variant = "quiet",
    })
    self:requestResponsiveLayout(true)
end

function ISPNCFacilityCapacityWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 30, bottom = 12 })
    local entryY = rect.y + 38
    Layout.SetBounds(self.capacityEntry, rect.x, entryY, rect.width,
        Layout.Pixels(28, self.uiScale))
    local buttons = Layout.Flow(
        { self.saveButton, self.autoButton, self.cancelButton },
        { x = rect.x, y = entryY + Layout.Pixels(40, self.uiScale),
            width = rect.width },
        { scale = self.uiScale, minWidth = 100 }
    )
    self.buttonsBottom = buttons.bottom
end

function ISPNCFacilityCapacityWindow:submit(value)
    local capacity = value
    if capacity ~= nil then
        capacity = tonumber(capacity)
        local maximum = PNC.FacilityResources
            and PNC.FacilityResources.MAX_CAPACITY or 999
        if not capacity or capacity ~= math.floor(capacity)
            or capacity < 1 or capacity > maximum
        then
            self.errorText = Shared.Tr("UI_PNC_Facility_InvalidCapacity",
                "Enter a whole number from 1 to 999, or choose Automatic.")
            return false
        end
    end
    local ok, reason
    if PNC.Client and PNC.Client.RequestSetFacilityCapacity then
        ok, reason = PNC.Client.RequestSetFacilityCapacity({
                facilityId = self.facility.id,
                expectedRevision = self.facility.revision,
                capacity = capacity,
            })
    else
        ok, reason = false, "capacity_update_unavailable"
    end
    if not ok then
        self.errorText = Shared.SettlementReason(reason)
        return false
    end
    Support.ApplyLocalResult(self.context)
    self:close()
    return true
end

function ISPNCFacilityCapacityWindow:onSave()
    local text = self.capacityEntry and self.capacityEntry:getText() or ""
    return self:submit(text ~= "" and text or nil)
end

function ISPNCFacilityCapacityWindow:onAutomatic()
    return self:submit(nil)
end

function ISPNCFacilityCapacityWindow:onCancel()
    self:close()
end

function ISPNCFacilityCapacityWindow:render()
    PsychopatzWindow.render(self)
    local rect = self:getContentRect({ top = 30, bottom = 12 })
    self:drawText(
        Shared.Tr("UI_PNC_Facility_CapacityPrompt",
            "Maximum colonists allowed to sleep in this room:"),
        rect.x, rect.y + 8,
        Theme.colors.text.r, Theme.colors.text.g, Theme.colors.text.b,
        Theme.colors.text.a, UIFont.Small
    )
    if self.errorText then
        self:drawText(
            self.errorText,
            rect.x, (self.buttonsBottom or rect.y) + 6,
            Theme.colors.danger.r, Theme.colors.danger.g,
            Theme.colors.danger.b, Theme.colors.danger.a, UIFont.Small
        )
    end
end

function ISPNCFacilityCapacityWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if CapacityModal.instance == self then CapacityModal.instance = nil end
end

function ISPNCFacilityCapacityWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    object.context = options.context
    object.facility = options.facility
    return object
end

function CapacityModal.Open(context, facility)
    if not context or not facility or not facility.id then return false end
    if CapacityModal.instance then CapacityModal.instance:close() end
    local window = UI.NewWindow(ISPNCFacilityCapacityWindow, {
        title = Shared.Tr("UI_PNC_Facility_SetCapacityTitle",
            "SET ROOM CAPACITY"),
        context = context,
        facility = facility,
        resizable = false,
        persistGeometry = false,
        responsiveSpec = {
            width = 460,
            height = 190,
            minWidth = 460,
            minHeight = 190,
            maxWidth = 460,
            maxHeight = 190,
            anchor = "center",
        },
    })
    window:initialise()
    window:instantiate()
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    if window.capacityEntry and window.capacityEntry.focus then
        window.capacityEntry:focus()
    end
    CapacityModal.instance = window
    return window
end

return CapacityModal
