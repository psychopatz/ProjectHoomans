require "ISUI/ISPanel"
require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.FarmingPlantUI = PNC.FarmingPlantUI or {}

local PlantUI = PNC.FarmingPlantUI
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout
local Catalog = PNC.FarmingCatalog
local PAGE_SIZE = 6

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    if not value or value == key then return fallback end
    return value
end

local function monthList(months)
    local output = {}
    for _, month in ipairs(months or {}) do
        local key = "Farming_Month_" .. tostring(month)
        output[#output + 1] = tr(key, tostring(month))
    end
    return table.concat(output, ", ")
end

local function seasonText(crop)
    local sow = monthList(crop.sowMonth)
    local best = monthList(crop.bestMonth)
    local risk = monthList(crop.riskMonth)
    local bad = monthList(crop.badMonth)
    local parts = {}
    if sow ~= "" then parts[#parts + 1] = "SOW " .. sow end
    if best ~= "" then parts[#parts + 1] = "BEST " .. best end
    if risk ~= "" then parts[#parts + 1] = "RISK " .. risk end
    if bad ~= "" then parts[#parts + 1] = "BAD " .. bad end
    return #parts > 0 and table.concat(parts, "  |  ")
        or tr("UI_PNC_Farming_SeasonUnavailable", "SEASON DATA UNAVAILABLE")
end

local function temperatureText(crop)
    if crop.minTemperature or crop.maxTemperature then
        local minimum = crop.minTemperature and tostring(crop.minTemperature) or "-"
        local maximum = crop.maxTemperature and tostring(crop.maxTemperature) or "-"
        return minimum .. " to " .. maximum .. " C"
    end
    if crop.coldHardy then
        return tr("UI_PNC_Farming_ColdHardy", "COLD HARDY")
            .. "  |  " .. tr("UI_PNC_Farming_VanillaColdRule", "VANILLA STRESS <= 10 C")
    end
    return tr("UI_PNC_Farming_WarmSeason", "WARM SEASON")
        .. "  |  " .. tr("UI_PNC_Farming_VanillaColdRule", "VANILLA STRESS <= 10 C")
end

local function textureFor(crop)
    local values = { crop.icon, crop.texture }
    for _, value in ipairs(values) do
        value = tostring(value or "")
        if value ~= "" and getTexture then
            local candidates = {}
            if string.find(value, "/", 1, true) or string.find(value, "%.png$") then
                candidates[#candidates + 1] = value
            else
                candidates[#candidates + 1] = "media/textures/" .. value .. ".png"
                candidates[#candidates + 1] = "media/ui/" .. value .. ".png"
                candidates[#candidates + 1] = value
            end
            for _, path in ipairs(candidates) do
                local ok, texture = pcall(getTexture, path)
                if ok and texture then return texture end
            end
        end
    end
    return nil
end

local function optionsFor(storage)
    local output = {}
    Catalog.Refresh()
    for _, crop in ipairs(Catalog.ListPlantable(storage)) do
        output[#output + 1] = {
            id = crop.id,
            crop = crop,
            name = tostring(crop.displayName or crop.id),
            texture = textureFor(crop),
            seedText = tostring(crop.seedCount or 0) .. " "
                .. tr("UI_PNC_Farming_SeedsAvailable", "SEEDS AVAILABLE"),
            season = seasonText(crop),
            temperature = temperatureText(crop),
            growth = crop.timeToGrow and (tostring(crop.timeToGrow)
                .. " " .. tr("UI_PNC_Farming_HOURS_TO_GROW", "HOURS TO GROW"))
                or tr("UI_PNC_Farming_GrowthUnavailable", "GROWTH DATA UNAVAILABLE"),
            water = crop.waterLvl and ("WATER " .. tostring(crop.waterLvl)) or nil,
        }
    end
    table.sort(output, function(a, b)
        return string.lower(a.name) < string.lower(b.name)
    end)
    return output
end

local PlantCard = ISPanel:derive("PNCFarmingPlantCard")

function PlantCard:onMouseDown()
    self.owner:setSelected(self.option.id)
    return true
end

function PlantCard:render()
    ISPanel.render(self)
    local selected = self.owner.selectedId == self.option.id
    local border = selected and Theme.colors.accent or Theme.colors.border
    self:drawRect(0, 0, self.width, self.height, selected and 0.92 or 0.78,
        0.045, 0.06, 0.07)
    self:drawRectBorder(0, 0, self.width, self.height,
        border.a or 1, border.r, border.g, border.b)
    if self.option.texture then
        self:drawTextureScaledAspect(self.option.texture, 10, 10,
            self.width - 20, 98, 1, 1, 1, 1)
    end
    self:drawTextCentre(self.option.name, self.width / 2, 114,
        Theme.colors.text.r, Theme.colors.text.g, Theme.colors.text.b, 1,
        UIFont.Medium)
    local muted = Theme.colors.textMuted
    local y = 138
    for _, line in ipairs({ self.option.seedText, self.option.season,
        self.option.temperature, self.option.growth, self.option.water }) do
        if line then
            line = Layout.Ellipsize(line, UIFont.Small, self.width - 12)
            self:drawTextCentre(line, self.width / 2, y, muted.r, muted.g,
                muted.b, muted.a or 1, UIFont.Small)
            y = y + 17
        end
    end
end

function PlantCard:new(x, y, width, height, owner, option)
    local object = ISPanel:new(x, y, width, height)
    setmetatable(object, self); self.__index = self
    object.owner, object.option = owner, option
    object.background = false
    return object
end

ISPNCFarmingPlantWindow = PsychopatzWindow:derive("ISPNCFarmingPlantWindow")

function ISPNCFarmingPlantWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCFarmingPlantWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.cards = {}
    for _, option in ipairs(self.options) do
        local card = PlantCard:new(0, 0, 1, 1, self, option)
        card:initialise(); card:instantiate(); self:addChild(card)
        self.cards[#self.cards + 1] = card
    end
    self.confirmButton = UI.CreateButton(self, {
        id = "confirm", title = tr("UI_PNC_Farming_SetSeeds", "SET SEEDS"),
        target = self, onclick = ISPNCFarmingPlantWindow.onAction,
        variant = "success",
    })
    self.cancelButton = UI.CreateButton(self, {
        id = "cancel", title = tr("UI_Cancel", "CANCEL"), target = self,
        onclick = ISPNCFarmingPlantWindow.onAction, variant = "danger",
    })
    self.previousPageButton = UI.CreateButton(self, {
        id = "page_previous", title = "<", target = self,
        onclick = ISPNCFarmingPlantWindow.onAction, variant = "quiet",
    })
    self.nextPageButton = UI.CreateButton(self, {
        id = "page_next", title = ">", target = self,
        onclick = ISPNCFarmingPlantWindow.onAction, variant = "quiet",
    })
    self.utilityButtons = {}
    for _, definition in ipairs({
        { "toggle_policy", "UI_PNC_Facility_ToggleAutomation", "TOGGLE AUTOMATION" },
        { "edit_rectangle", "UI_PNC_Facility_EditPlotRectangle", "EDIT RECTANGLE" },
    }) do
        self.utilityButtons[#self.utilityButtons + 1] = UI.CreateButton(self, {
            id = definition[1], title = tr(definition[2], definition[3]),
            target = self, onclick = ISPNCFarmingPlantWindow.onAction,
            variant = "quiet",
        })
    end
    self.debugButtons = {}
    if self.debugVisible then
        for _, definition in ipairs({
            { "debug_grow", "UI_PNC_Farming_DebugGrow", "AUTO GROW" },
            { "debug_water", "UI_PNC_Farming_DebugWater", "FORCE WATER" },
            { "debug_harvest", "UI_PNC_Farming_DebugHarvest", "HARVEST" },
            { "debug_clear", "UI_PNC_Farming_DebugClear", "CLEAR PLANTS" },
        }) do
            self.debugButtons[#self.debugButtons + 1] = UI.CreateButton(self, {
                id = definition[1], title = tr(definition[2], definition[3]),
                target = self, onclick = ISPNCFarmingPlantWindow.onAction,
                variant = "quiet",
            })
        end
    end
    self:setSelected(self.initialSelectedId
        or self.options[1] and self.options[1].id or nil)
    self:requestResponsiveLayout(true)
end

function ISPNCFarmingPlantWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 18, bottom = 12 })
    local gap = Layout.Pixels(10, self.uiScale)
    local buttonHeight = Layout.Pixels(30, self.uiScale)
    local debugRow = #(self.debugButtons or {}) > 0
    local utilityRow = #(self.utilityButtons or {}) > 0
    local rowCount = 1 + (utilityRow and 1 or 0) + (debugRow and 1 or 0)
    local contentHeight = rect.height - buttonHeight * rowCount
        - gap * (rowCount + 1)
    local columns = math.min(3, math.max(1, #self.cards))
    local width = math.floor((rect.width - gap * (columns - 1)) / columns)
    local cardHeight = math.max(210, math.floor((contentHeight - gap) / 2))
    local first = ((self.page or 1) - 1) * PAGE_SIZE + 1
    local last = math.min(#self.cards, first + PAGE_SIZE - 1)
    for _, card in ipairs(self.cards) do card:setVisible(false) end
    local visible = {}
    for index = first, last do
        local card = self.cards[index]
        if card then card:setVisible(true); visible[#visible + 1] = card end
    end
    for index, card in ipairs(visible) do
        local column = (index - 1) % columns
        local row = math.floor((index - 1) / columns)
        Layout.SetBounds(card, rect.x + column * (width + gap),
            rect.y + row * (cardHeight + gap), width, cardHeight)
    end
    local pageCount = math.max(1, math.ceil(#self.cards / PAGE_SIZE))
    local actionY = rect.y + rect.height - buttonHeight
    local utilityY = actionY - buttonHeight - gap
    local debugY = utilityY
    if utilityRow then debugY = utilityY - buttonHeight - gap end
    local x = rect.x
    for _, button in ipairs(self.utilityButtons or {}) do
        Layout.SetBounds(button, x, utilityY, 150, buttonHeight)
        x = x + 150 + gap
    end
    x = rect.x
    for _, button in ipairs(self.debugButtons or {}) do
        Layout.SetBounds(button, x, debugY, 118, buttonHeight)
        x = x + 118 + gap
    end
    Layout.SetBounds(self.confirmButton, rect.x, actionY, 120, buttonHeight)
    Layout.SetBounds(self.cancelButton, rect.x + rect.width - 100,
        actionY, 100, buttonHeight)
    Layout.SetBounds(self.previousPageButton,
        rect.x + math.floor(rect.width / 2) - 42, actionY, 36, buttonHeight)
    Layout.SetBounds(self.nextPageButton,
        rect.x + math.floor(rect.width / 2) + 6, actionY, 36, buttonHeight)
    self.previousPageButton:setEnable((self.page or 1) > 1)
    self.nextPageButton:setEnable((self.page or 1) < pageCount)
    self.previousPageButton:setVisible(pageCount > 1)
    self.nextPageButton:setVisible(pageCount > 1)
    self.confirmButton:setEnable(self.selectedOption ~= nil)
end

function ISPNCFarmingPlantWindow:setSelected(id)
    self.selectedId = id
    self.selectedOption = nil
    for _, option in ipairs(self.options) do
        if option.id == id then self.selectedOption = option; break end
    end
    if self.confirmButton then self.confirmButton:setEnable(self.selectedOption ~= nil) end
end

function ISPNCFarmingPlantWindow:setPage(page)
    local count = math.max(1, math.ceil(#self.cards / PAGE_SIZE))
    self.page = math.max(1, math.min(count, math.floor(tonumber(page) or 1)))
    self:requestResponsiveLayout(true)
end

function ISPNCFarmingPlantWindow:onAction(button)
    local action = tostring(button.internal or "")
    if action == "page_previous" then self:setPage((self.page or 1) - 1); return end
    if action == "page_next" then self:setPage((self.page or 1) + 1); return end
    if action == "confirm" and self.selectedOption and self.onConfirm then
        self.onConfirm(self.selectedOption.id)
    elseif action:find("^debug_") and self.onDebug then
        self.onDebug(string.sub(action, 7))
    elseif action == "toggle_policy" and self.onTogglePolicy then
        self.onTogglePolicy()
    elseif action == "edit_rectangle" and self.onEditRectangle then
        self.onEditRectangle()
    end
    if action == "cancel" or action == "confirm" or action:find("^debug_")
        or action == "toggle_policy" or action == "edit_rectangle" then
        self:close()
    end
end

function ISPNCFarmingPlantWindow:prerender()
    PsychopatzWindow.prerender(self)
    if #self.options <= 0 then
        local rect = self:getContentRect({ top = 18, bottom = 12 })
        self:drawTextCentre(tr("UI_PNC_Farming_NoSeeds",
            "NO VALID PLANTABLE SEEDS IN BASE STORAGE"),
            self.width / 2, rect.y + 100, Theme.colors.warning.r,
            Theme.colors.warning.g, Theme.colors.warning.b, 1, UIFont.Medium)
    end
end

function ISPNCFarmingPlantWindow:close()
    self:setVisible(false); self:removeFromUIManager()
    if PlantUI.instance == self then PlantUI.instance = nil end
end

function ISPNCFarmingPlantWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self); self.__index = self
    object.options = options.options or {}
    object.onConfirm = options.onConfirm
    object.onDebug = options.onDebug
    object.onTogglePolicy = options.onTogglePolicy
    object.onEditRectangle = options.onEditRectangle
    object.debugVisible = options.debugVisible == true
    object.initialSelectedId = options.initialSelectedId
    object.page = 1
    return object
end

function PlantUI.Open(storage, plot, onConfirm, onDebug, onTogglePolicy, onEditRectangle)
    if PlantUI.instance then PlantUI.instance:close() end
    local options = optionsFor(storage)
    local width, height = 900, 650
    local window = ISPNCFarmingPlantWindow:new(
        math.floor((getCore():getScreenWidth() - width) / 2),
        math.floor((getCore():getScreenHeight() - height) / 2),
        width, height, {
            title = tr("UI_PNC_Farming_SelectPlant", "SELECT PLANT"),
            options = options, onConfirm = onConfirm, onDebug = onDebug,
            onTogglePolicy = onTogglePolicy, onEditRectangle = onEditRectangle,
            initialSelectedId = plot and plot.desiredCrop,
            debugVisible = PNC.Client and PNC.Client.CanUseDebug
                and PNC.Client.CanUseDebug() == true,
            resizable = false,
        })
    window:initialise(); window:instantiate(); window:addToUIManager()
    window:setVisible(true)
    if window.setAlwaysOnTop then window:setAlwaysOnTop(true) end
    window:bringToTop(); PlantUI.instance = window
    return window
end

return PlantUI
