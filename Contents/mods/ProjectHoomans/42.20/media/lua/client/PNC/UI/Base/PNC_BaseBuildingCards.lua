require "ISUI/ISPanel"
require "PsychopatzCore/UI/PsychopatzUI"

local Components = require
    "PNC/UI/Shared/PNC_ColonyUIComponents"
local Data = require "PNC/UI/Base/PNC_BaseBuildingData"
local BuildUI = require
    "PNC/UI/SettlementManagement/PNC_SettlementManagement_FacilityBuildModal"

local Cards = {}
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout
local CATEGORY_LABELS = {
    ALL = "ALL", housing = "HOUSING", food = "FOOD",
    technology = "TECHNOLOGY", utilities = "UTILITIES",
    production = "PRODUCTION",
}

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    if not value or value == key then return fallback end
    return value
end

local function humanize(value)
    local text = string.gsub(tostring(value or ""), "[_%-]+", " ")
    if text == "" then return text end
    return string.upper(string.sub(text, 1, 1)) .. string.sub(text, 2)
end

local DetailsPanel = ISPanel:derive("PNCBaseBuildingDetails")

function DetailsPanel:render()
    ISPanel.render(self)
    local option = self.owner and Data.SelectedOption(self.owner) or nil
    local accent, muted = Theme.colors.accent, Theme.colors.textMuted
    if not option then
        self:drawTextCentre(tr("UI_PNC_Base_SelectBuilding",
            "SELECT A BUILDING TO REVIEW ITS REQUIREMENTS"),
            self.width / 2, math.max(8, self.height / 2 - 8),
            muted.r, muted.g, muted.b, muted.a, UIFont.Small)
        return
    end
    self:drawText(Layout.Ellipsize(option.name or option.id, UIFont.Medium,
        self.width - 24), 12, 8, Theme.colors.text.r, Theme.colors.text.g,
        Theme.colors.text.b, Theme.colors.text.a, UIFont.Medium)
    local status = option.enabled and Theme.colors.success or Theme.colors.warning
    self:drawText(Layout.Ellipsize(option.status or "", UIFont.Small,
        self.width - 24), 12, 31, status.r, status.g, status.b,
        status.a or 1, UIFont.Small)
    self:drawText(Layout.Ellipsize(option.description or "", UIFont.Small,
        self.width - 24), 12, 52, muted.r, muted.g, muted.b, muted.a,
        UIFont.Small)
    self:drawTextRight(option.skillText or "", self.width - 12, 8,
        accent.r, accent.g, accent.b, accent.a, UIFont.Small)
end

function Cards.Create(window)
    window.baseBuildingCategoryButtons = {}
    window.baseBuildingCards = {}
    window.baseBuildCardOwner = {
        selectedId = nil,
        window = window,
        setSelected = function(_, id) window.baseBuildingSelectedID = id end,
    }
    window.baseBuildingDetails = DetailsPanel:new(0, 0, 1, 1)
    window.baseBuildingDetails:initialise()
    window.baseBuildingDetails:instantiate()
    window.baseBuildingDetails.owner = window
    window:addChild(window.baseBuildingDetails)
end

function Cards.EnsureCategoryButton(window, category)
    for _, button in ipairs(window.baseBuildingCategoryButtons or {}) do
        if button.category == category then return button end
    end
    local button = UI.CreateButton(window, {
        id = "building_category:" .. tostring(category),
        title = tr("UI_PNC_Facility_Category_" .. tostring(category),
            CATEGORY_LABELS[category] or string.upper(humanize(category))),
        target = window, onclick = window.onBaseBuildingControl,
        variant = "quiet",
    })
    button.category = category
    window.baseBuildingCategoryButtons[#window.baseBuildingCategoryButtons + 1]
        = button
    return button
end

function Cards.RebuildCategories(window)
    local categories, seen = Data.Categories(window.baseBuildingOptions)
    for _, category in ipairs(categories) do
        Cards.EnsureCategoryButton(window, category)
    end
    if not seen[window.baseBuildingCategory] then
        -- The reference opens on the first real build category. ALL remains
        -- an internal empty-state fallback, but is not rendered as a tab.
        window.baseBuildingCategory = categories[1] or "ALL"
    end
    for _, button in ipairs(window.baseBuildingCategoryButtons or {}) do
        local visible = seen[button.category] == true
        button.baseCategoryVisible = visible
        button:setVisible(visible)
        UI.SetButtonVariant(button,
            button.category == window.baseBuildingCategory
                and "selected" or "quiet")
    end
end

function Cards.Rebuild(window, select)
    local options = Data.FilteredOptions(window)
    local pageCount = math.max(1, math.ceil(#options / Data.PAGE_SIZE))
    window.baseBuildingPage = math.max(1, math.min(pageCount,
        tonumber(window.baseBuildingPage) or 1))
    local first = (window.baseBuildingPage - 1) * Data.PAGE_SIZE + 1
    local last = math.min(#options, first + Data.PAGE_SIZE - 1)
    for index = 1, #options do
        local option, card = options[index], window.baseBuildingCards[index]
        if not card then
            card = BuildUI.FacilityCard:new(0, 0, 1, 1,
                window.baseBuildCardOwner, option)
            card:initialise(); card:instantiate(); window:addChild(card)
            window.baseBuildingCards[index] = card
        end
        card.option = option
        card:setVisible(index >= first and index <= last)
    end
    for index = #options + 1, #window.baseBuildingCards do
        window.baseBuildingCards[index]:setVisible(false)
    end
    local chosen = Data.SelectedOption(window)
    local visibleChosen = false
    for index = first, last do
        if options[index] and chosen
            and tostring(options[index].id) == tostring(chosen.id)
        then visibleChosen = true end
    end
    select(visibleChosen and chosen.id
        or options[first] and options[first].id or nil)
    window.baseBuildingPageCount = pageCount
end

return Cards
