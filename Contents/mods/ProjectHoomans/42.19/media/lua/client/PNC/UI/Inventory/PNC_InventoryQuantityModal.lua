require "ISUI/ISPanel"
require "ISUI/ISButton"
require "RadioCom/ISUIRadio/ISSliderPanel"

PNC = PNC or {}
PNC.InventoryQuantityModal = PNC.InventoryQuantityModal or {}

local QuantityModal = PNC.InventoryQuantityModal

ISPNCInventoryQuantityModal = ISPanel:derive(
    "ISPNCInventoryQuantityModal"
)

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

function ISPNCInventoryQuantityModal:initialise()
    ISPanel.initialise(self)
end

function ISPNCInventoryQuantityModal:createChildren()
    ISPanel.createChildren(self)
    self.slider = ISSliderPanel:new(
        22, 72, self.width - 44, 22,
        self, ISPNCInventoryQuantityModal.onQuantityChanged
    )
    self.slider:initialise()
    self.slider:instantiate()
    self.slider:setValues(1, self.maximum, 1, 10)
    self.slider:setCurrentValue(1, true)
    self:addChild(self.slider)

    self.confirmButton = ISButton:new(
        22, self.height - 38, 100, 24,
        tr("UI_PNC_Inventory_Transfer", "Transfer"),
        self, ISPNCInventoryQuantityModal.onButton
    )
    self.confirmButton.internal = "CONFIRM"
    self.confirmButton:initialise()
    self.confirmButton:instantiate()
    self:addChild(self.confirmButton)

    self.cancelButton = ISButton:new(
        self.width - 122, self.height - 38, 100, 24,
        tr("UI_Cancel", "Cancel"),
        self, ISPNCInventoryQuantityModal.onButton
    )
    self.cancelButton.internal = "CANCEL"
    self.cancelButton:initialise()
    self.cancelButton:instantiate()
    self:addChild(self.cancelButton)
end

function ISPNCInventoryQuantityModal:onQuantityChanged(value)
    self.quantity = math.max(
        1,
        math.min(self.maximum, math.floor(tonumber(value) or 1))
    )
end

function ISPNCInventoryQuantityModal:onButton(button)
    if button and button.internal == "CONFIRM" then
        local callback = self.callback
        local target = self.callbackTarget
        local quantity = self.quantity
        self:close()
        if callback then callback(target, quantity) end
        return
    end
    self:close()
end

function ISPNCInventoryQuantityModal:prerender()
    ISPanel.prerender(self)
    self:drawRect(0, 0, self.width, self.height, 0.96, 0.04, 0.04, 0.04)
    self:drawRectBorder(0, 0, self.width, self.height, 0.95, 0.65, 0.65, 0.65)
    self:drawTextCentre(
        tr("UI_PNC_Inventory_SelectQuantity", "Select transfer quantity"),
        self.width / 2, 14, 0.95, 0.95, 0.95, 1, UIFont.Medium
    )
    self:drawTextCentre(
        tostring(self.itemLabel or tr("UI_PNC_Inventory_Item", "Item")),
        self.width / 2, 43, 0.76, 0.76, 0.84, 1, UIFont.Small
    )
    self:drawTextCentre(
        tostring(self.quantity) .. " / " .. tostring(self.maximum),
        self.width / 2, 101, 1.00, 0.82, 0.48, 1, UIFont.Medium
    )
end

function ISPNCInventoryQuantityModal:close()
    if self.setCapture then self:setCapture(false) end
    self:setVisible(false)
    self:removeFromUIManager()
    if QuantityModal.instance == self then QuantityModal.instance = nil end
end

function ISPNCInventoryQuantityModal:new(
    x,
    y,
    width,
    height,
    maximum,
    itemLabel,
    callbackTarget,
    callback
)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.maximum = math.max(2, math.floor(tonumber(maximum) or 2))
    o.quantity = 1
    o.itemLabel = itemLabel
    o.callbackTarget = callbackTarget
    o.callback = callback
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o.moveWithMouse = true
    return o
end

function QuantityModal.Open(maximum, itemLabel, callbackTarget, callback)
    if QuantityModal.instance then QuantityModal.instance:close() end
    local width = 360
    local height = 150
    local screenWidth = getCore and getCore():getScreenWidth() or 1280
    local screenHeight = getCore and getCore():getScreenHeight() or 720
    local modal = ISPNCInventoryQuantityModal:new(
        math.floor((screenWidth - width) / 2),
        math.floor((screenHeight - height) / 2),
        width,
        height,
        maximum,
        itemLabel,
        callbackTarget,
        callback
    )
    modal:initialise()
    modal:instantiate()
    modal:addToUIManager()
    if modal.setAlwaysOnTop then modal:setAlwaysOnTop(true) end
    if modal.setCapture then modal:setCapture(true) end
    modal:bringToTop()
    QuantityModal.instance = modal
    return modal
end

return QuantityModal
