require "ISUI/ISPanel"
require "ISUI/ISButton"

PNC = PNC or {}
PNC.FactionMemberModal = PNC.FactionMemberModal or {}

local MemberModal = PNC.FactionMemberModal

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key
        and value or fallback
end

ISPNCFactionMemberModal = ISPanel:derive(
    "ISPNCFactionMemberModal"
)

function ISPNCFactionMemberModal:initialise()
    ISPanel.initialise(self)
end

function ISPNCFactionMemberModal:createChildren()
    ISPanel.createChildren(self)
    self.confirmButton = ISButton:new(
        22,
        self.height - 42,
        150,
        26,
        self.confirmLabel,
        self,
        ISPNCFactionMemberModal.onButton
    )
    self.confirmButton.internal = "CONFIRM"
    self.confirmButton:initialise()
    self.confirmButton:instantiate()
    self.confirmButton.backgroundColor =
        self.danger and {
            r = 0.40, g = 0.06, b = 0.05, a = 0.92,
        } or {
            r = 0.05, g = 0.32, b = 0.14, a = 0.92,
        }
    self:addChild(self.confirmButton)

    self.cancelButton = ISButton:new(
        self.width - 142,
        self.height - 42,
        120,
        26,
        tr("UI_Cancel", "Cancel"),
        self,
        ISPNCFactionMemberModal.onButton
    )
    self.cancelButton.internal = "CANCEL"
    self.cancelButton:initialise()
    self.cancelButton:instantiate()
    self:addChild(self.cancelButton)
end

function ISPNCFactionMemberModal:onButton(button)
    if button and button.internal == "CONFIRM" then
        local callback = self.onConfirm
        local context = self.context
        self:close()
        if callback then callback(context) end
        return
    end
    self:close()
end

function ISPNCFactionMemberModal:prerender()
    ISPanel.prerender(self)
    self:drawRect(
        0, 0, self.width, self.height,
        0.97, 0.025, 0.025, 0.028
    )
    self:drawRectBorder(
        0, 0, self.width, self.height,
        0.96,
        self.danger and 0.90 or 0.22,
        self.danger and 0.18 or 0.72,
        self.danger and 0.12 or 0.35
    )
    self:drawTextCentre(
        self.title,
        self.width / 2,
        16,
        0.95, 0.95, 0.95, 1,
        UIFont.Medium
    )
    self:drawTextCentre(
        self.message,
        self.width / 2,
        58,
        0.78, 0.81, 0.84, 1,
        UIFont.Small
    )
    if self.detail and self.detail ~= "" then
        self:drawTextCentre(
            self.detail,
            self.width / 2,
            82,
            0.96,
            self.danger and 0.48 or 0.78,
            self.danger and 0.42 or 0.55,
            1,
            UIFont.Small
        )
    end
end

function ISPNCFactionMemberModal:close()
    if self.setCapture then self:setCapture(false) end
    self:setVisible(false)
    self:removeFromUIManager()
    if MemberModal.instance == self then
        MemberModal.instance = nil
    end
end

function ISPNCFactionMemberModal:new(
    x,
    y,
    width,
    height,
    options
)
    local object = ISPanel:new(x, y, width, height)
    setmetatable(object, self)
    self.__index = self
    options = type(options) == "table" and options or {}
    object.title = tostring(options.title or "Confirm")
    object.message = tostring(options.message or "")
    object.detail = tostring(options.detail or "")
    object.confirmLabel = tostring(
        options.confirmLabel or "Confirm"
    )
    object.danger = options.danger == true
    object.onConfirm = options.onConfirm
    object.context = options.context
    object.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    object.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    object.moveWithMouse = true
    return object
end

function MemberModal.Open(options)
    if MemberModal.instance then
        MemberModal.instance:close()
    end
    local width = 480
    local height = 150
    local screenWidth = getCore and getCore():getScreenWidth()
        or 1280
    local screenHeight = getCore and getCore():getScreenHeight()
        or 720
    local modal = ISPNCFactionMemberModal:new(
        math.floor((screenWidth - width) / 2),
        math.floor((screenHeight - height) / 2),
        width,
        height,
        options
    )
    modal:initialise()
    modal:instantiate()
    modal:addToUIManager()
    if modal.setAlwaysOnTop then modal:setAlwaysOnTop(true) end
    if modal.setCapture then modal:setCapture(true) end
    modal:bringToTop()
    MemberModal.instance = modal
    return modal
end

return MemberModal
