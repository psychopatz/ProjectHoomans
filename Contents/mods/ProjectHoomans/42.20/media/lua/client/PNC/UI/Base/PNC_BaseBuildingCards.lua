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
    local value = getText and PNC.Translation.GetKey(key) or nil
    if not value or value == key then return fallback end
    return value
end

local function humanize(value)
    local text = string.gsub(tostring(value or ""), "[_%-]+", " ")
    if text == "" then return text end
    return string.upper(string.sub(text, 1, 1)) .. string.sub(text, 2)
end

-- Text metrics come from the shared theme, exactly like the facility card and
-- the rest of the window. Bare fontHeight()/textWidth() globals do not exist in
-- this Lua environment: calling one raised "Object tried to call nil in render"
-- every frame and blanked the whole Facilities tab.
local function fontHeight(font)
    if type(Theme.FontHeight) == "function" then
        local ok, value = pcall(Theme.FontHeight, font)
        if ok and tonumber(value) then return tonumber(value) end
    end
    return 16
end

local function textWidth(font, value)
    value = tostring(value or "")
    if type(Theme.TextWidth) == "function" then
        local ok, width = pcall(Theme.TextWidth, font, value)
        if ok and tonumber(width) then return tonumber(width) end
    end
    return #value * 7
end

-- Greedy word wrap bounded by both width and line count, so a long facility
-- description can never bleed out of the details strip.
local function wrapText(value, font, maxWidth, maxLines)
    local text = tostring(value or "")
    local lines = {}
    if text == "" or maxWidth <= 0 or maxLines <= 0 then return lines end
    local current = ""
    for word in string.gmatch(text, "%S+") do
        local candidate = current == "" and word or (current .. " " .. word)
        if textWidth(font, candidate) <= maxWidth then
            current = candidate
        else
            if current ~= "" then lines[#lines + 1] = current end
            current = word
            if #lines >= maxLines then return lines end
        end
    end
    if current ~= "" and #lines < maxLines then lines[#lines + 1] = current end
    return lines
end

local DetailsPanel = ISPanel:derive("PNCBaseBuildingDetails")

local detailsWarned

--[[
    The card above already renders the facility name, status, cost and skill.
    This strip exists for the one thing the card cannot fit: the full
    description. Repeating the name here produced two stacked copies of the same
    title inside the same tab.

    The body runs inside pcall: a Lua error inside a child's render aborts the
    whole UIManager pass, so a mistake here blanks every control in the Base
    window (that is exactly what a nil text-metric call did). Failing as an
    empty strip is recoverable; failing as a blank window is not.
]]
local function renderDetails(self)
    local option = self.owner and Data.SelectedOption(self.owner) or nil
    local muted = Theme.colors.textMuted
    if not option then
        self:drawTextCentre(tr("UI_PNC_Base_SelectBuilding",
            "SELECT A BUILDING TO REVIEW ITS REQUIREMENTS"),
            self.width / 2, math.max(8, self.height / 2 - 8),
            muted.r, muted.g, muted.b, muted.a, UIFont.Small)
        return
    end
    local lineHeight = math.max(14, fontHeight(UIFont.Small))
    local available = math.max(1, math.floor(
        (self.height - 10) / lineHeight))
    local lines = wrapText(tostring(option.description or ""), UIFont.Small,
        self.width - 24, math.min(2, available))
    for index, line in ipairs(lines) do
        self:drawText(line, 12, 6 + (index - 1) * lineHeight,
            muted.r, muted.g, muted.b, muted.a, UIFont.Small)
    end
end

function DetailsPanel:render()
    ISPanel.render(self)
    if self.setStencilRect then
        self:setStencilRect(0, 0, self.width, self.height)
    end
    local ok, err = pcall(renderDetails, self)
    if self.clearStencilRect then self:clearStencilRect() end
    if not ok and not detailsWarned then
        detailsWarned = true
        if PNC.Core and PNC.Core.LogWarn then
            PNC.Core.LogWarn("facility details strip render failed: "
                .. tostring(err))
        end
    end
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
            -- The REQUIREMENTS pane below lists every material with its
            -- required/available counts. Repeating them on the card only
            -- produced two truncated lines over the preview image.
            card.showMaterialLines = false
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
