require "ISUI/ISPanel"
require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.FacilityBuildUI = PNC.FacilityBuildUI or {}

local BuildUI = PNC.FacilityBuildUI
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    if not value or value == key then return fallback end
    return value
end

local function playerCount(fullType)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local inventory = player and player.getInventory and player:getInventory() or nil
    local values = inventory and inventory.getItemsFromType
        and inventory:getItemsFromType(fullType, true) or nil
    return values and values.size and values:size() or 0
end

local function stockpileCount(storage, fullType)
    local total = 0
    for _, row in ipairs(storage and storage.rows or {}) do
        if tostring(row.fullType or "") == tostring(fullType or "") then
            total = total + math.max(0, math.floor(tonumber(row.quantity) or 0))
        end
    end
    return total
end

local function recipeFor(definition)
    local recipe = definition and (definition.buildCosts
        or definition.buildCost) or {}
    if recipe.fullType then return { recipe } end
    return recipe
end

local FacilityCard = ISPanel:derive("PNCFacilityBuildCard")

function FacilityCard:onMouseDown()
    self.owner:setSelected(self.option.id)
    return true
end

function FacilityCard:render()
    ISPanel.render(self)
    local selected = self.owner.selectedId == self.option.id
    local border = selected and Theme.colors.accent or Theme.colors.border
    local text = self.option.enabled and Theme.colors.text or Theme.colors.textMuted
    self:drawRect(0, 0, self.width, self.height, selected and 0.92 or 0.78,
        0.045, 0.06, 0.07)
    self:drawRectBorder(0, 0, self.width, self.height,
        border.a or 1, border.r, border.g, border.b)
    if self.option.texture then
        self:drawTextureScaledAspect(self.option.texture, 12, 12,
            self.width - 24, 150, self.option.enabled and 1 or 0.42,
            1, 1, 1)
    end
    self:drawTextCentre(self.option.name, self.width / 2, 170,
        text.r, text.g, text.b, text.a or 1, UIFont.Medium)
    self:drawTextCentre(self.option.costText, self.width / 2, 195,
        Theme.colors.warning.r, Theme.colors.warning.g,
        Theme.colors.warning.b, 1, UIFont.Small)
    self:drawTextCentre(self.option.sourceText, self.width / 2, 214,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, 1, UIFont.Small)
    self:drawTextCentre(self.option.status, self.width / 2, 237,
        self.option.enabled and Theme.colors.success.r or Theme.colors.danger.r,
        self.option.enabled and Theme.colors.success.g or Theme.colors.danger.g,
        self.option.enabled and Theme.colors.success.b or Theme.colors.danger.b,
        1, UIFont.Small)
end

function FacilityCard:new(x, y, width, height, owner, option)
    local object = ISPanel:new(x, y, width, height)
    setmetatable(object, self); self.__index = self
    object.owner, object.option = owner, option
    object.background = false
    return object
end

ISPNCFacilityBuildWindow = PsychopatzWindow:derive("ISPNCFacilityBuildWindow")

function ISPNCFacilityBuildWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCFacilityBuildWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.cards = {}
    for _, option in ipairs(self.options) do
        local card = FacilityCard:new(0, 0, 1, 1, self, option)
        card:initialise(); card:instantiate(); self:addChild(card)
        self.cards[#self.cards + 1] = card
    end
    self.confirmButton = UI.CreateButton(self, {
        id = "build", title = tr("UI_PNC_Facility_BuildConfirm", "BUILD"),
        target = self, onclick = ISPNCFacilityBuildWindow.onAction,
        variant = "success",
    })
    self.cancelButton = UI.CreateButton(self, {
        id = "cancel", title = tr("UI_Cancel", "CANCEL"), target = self,
        onclick = ISPNCFacilityBuildWindow.onAction, variant = "danger",
    })
    self:setSelected(self.options[1] and self.options[1].id or nil)
    self:requestResponsiveLayout(true)
end

function ISPNCFacilityBuildWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 18, bottom = 12 })
    local gap = Layout.Pixels(12, self.uiScale)
    local buttonHeight = Layout.Pixels(30, self.uiScale)
    local cardsHeight = math.max(250, rect.height - 105)
    local width = math.floor((rect.width - gap * math.max(0, #self.cards - 1))
        / math.max(1, #self.cards))
    local x = rect.x
    for _, card in ipairs(self.cards) do
        Layout.SetBounds(card, x, rect.y, width, cardsHeight)
        x = x + width + gap
    end
    self.descriptionX = rect.x
    self.descriptionY = rect.y + cardsHeight + 8
    Layout.SetBounds(self.confirmButton, rect.x,
        rect.y + rect.height - buttonHeight, 130, buttonHeight)
    Layout.SetBounds(self.cancelButton, rect.x + rect.width - 110,
        rect.y + rect.height - buttonHeight, 110, buttonHeight)
end

function ISPNCFacilityBuildWindow:setSelected(id)
    self.selectedId = id
    local option
    for _, value in ipairs(self.options) do
        if value.id == id then option = value; break end
    end
    self.selectedOption = option
    if self.confirmButton then
        self.confirmButton:setEnable(option and option.enabled == true)
    end
end

function ISPNCFacilityBuildWindow:prerender()
    PsychopatzWindow.prerender(self)
    local option = self.selectedOption
    if option and self.descriptionY then
        self:drawText(option.description, self.descriptionX,
            self.descriptionY, Theme.colors.textMuted.r,
            Theme.colors.textMuted.g, Theme.colors.textMuted.b, 1, UIFont.Small)
    end
end

function ISPNCFacilityBuildWindow:onAction(button)
    if button.internal == "build" and self.selectedOption
        and self.selectedOption.enabled
    then
        if self.onConfirm then self.onConfirm(self.selectedOption.id) end
    end
    self:close()
end

function ISPNCFacilityBuildWindow:close()
    self:setVisible(false); self:removeFromUIManager()
    if BuildUI.instance == self then BuildUI.instance = nil end
end

function ISPNCFacilityBuildWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self); self.__index = self
    object.options = options.options or {}
    object.onConfirm = options.onConfirm
    return object
end

local function technologyKnown(research, technologyId)
    if not technologyId then return true end
    for _, id in ipairs(research and research.learnedTechnologyIds or {}) do
        if tostring(id) == tostring(technologyId) then return true end
    end
    return false
end

local function buildOptions(settlement, storage, research)
    local values = {}
    local ids = {}
    for id, _ in pairs(PNC.FacilityDefinitions.ByID or {}) do ids[#ids + 1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do
        local definition = PNC.FacilityDefinitions.Get(id)
        local level = PNC.FacilityDefinitions.GetLevel(id, 1)
        local costParts, sourceParts = {}, {}
        local affordable = true
        for _, cost in ipairs(recipeFor(definition)) do
            local required = math.max(0, math.floor(tonumber(
                cost.amount or cost.quantity) or 0))
            local stored = stockpileCount(storage, cost.fullType)
            local available = stored
            if available < required then affordable = false end
            costParts[#costParts + 1] = tostring(required) .. " "
                .. tostring(cost.fullType) .. " (" .. tostring(available)
                .. " " .. tr("UI_PNC_Facility_MaterialTotal", "total") .. ")"
            sourceParts[#sourceParts + 1] = tostring(stored) .. " "
                .. tr("UI_PNC_Facility_MaterialStockpile", "stockpile")
        end
        local hqReady = (tonumber(settlement.hqLevel) or 0)
            >= (tonumber(level and level.requiredHQLevel) or 1)
        local technologyReady = technologyKnown(research,
            definition.requiredTechnology)
        local status = hqReady and affordable and technologyReady
            and tr("UI_PNC_Facility_Available", "AVAILABLE")
            or not hqReady and tr("UI_PNC_Facility_RequiresHQ", "HQ LEVEL TOO LOW")
            or not technologyReady and tr("UI_PNC_Facility_RequiresTechnology",
                "RESEARCH REQUIRED")
            or tr("UI_PNC_Facility_MissingMaterials", "NEED MORE MATERIALS")
        values[#values + 1] = {
            id = id,
            name = tr(definition.displayNameKey, id),
            description = tr(definition.descriptionKey, id),
            texture = getTexture and getTexture(definition.iconPath) or nil,
            costText = table.concat(costParts, " | "),
            sourceText = table.concat(sourceParts, " | "),
            enabled = hqReady and affordable and technologyReady,
            status = status,
        }
    end
    return values
end

BuildUI.BuildOptions = buildOptions

function BuildUI.Open(settlement, onConfirm, storage, research)
    if not settlement then return nil end
    if BuildUI.instance then BuildUI.instance:close() end
    local options = buildOptions(settlement, storage, research)
    local width, height = 690, 430
    local window = ISPNCFacilityBuildWindow:new(
        math.floor((getCore():getScreenWidth() - width) / 2),
        math.floor((getCore():getScreenHeight() - height) / 2),
        width, height, {
            title = tr("UI_PNC_Facility_BuildTitle", "BUILD A BUILDING"),
            options = options, onConfirm = onConfirm, resizable = false,
        })
    window:initialise(); window:instantiate(); window:addToUIManager()
    window:setVisible(true)
    if window.setAlwaysOnTop then window:setAlwaysOnTop(true) end
    window:bringToTop(); BuildUI.instance = window
    return window
end

return BuildUI
