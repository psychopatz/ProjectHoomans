local T = require "tests/support/test"
T.addPackagePaths()
UIFont = { Small = 1 }
getTextManager = function() return { getFontHeight = function() return 18 end } end
local function control()
    local c = { visible = true, height = 1, width = 1 }
    function c:setVisible(v) self.visible = v end
    function c:setEnabled(v) self.enabled = v end
    function c:setEnable(v) self.enabled = v end
    function c:setScrollHeight(v) self.scrollHeight = v end
    function c:getYScroll() return self.yScroll or 0 end
    function c:setYScroll(v) self.yScroll = v end
    function c:onResize() end
    return c
end
local Layout = {}
function Layout.Pixels(value, scale) return math.floor(value * (scale or 1)) end
function Layout.SetBounds(c, x, y, w, h)
    c.x, c.y, c.width, c.height = x, y, w, h
end
function Layout.Flow(controls, rect, options)
    local size, gap = Layout.Pixels(100, options.scale), Layout.Pixels(6, options.scale)
    local x, y, h = rect.x, rect.y, Layout.Pixels(30, options.scale)
    for _, c in ipairs(controls) do
        if x > rect.x and x + size > rect.x + rect.width then x, y = rect.x, y + h + gap end
        Layout.SetBounds(c, x, y, size, h)
        x = x + size + gap
    end
    return { bottom = y + h }
end
ISPNCNPCAuthoringEditor = { Internal = { Layout = Layout } }
T.load("ProjectHoomans", "client", "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Layout.lua")
local Class = ISPNCNPCAuthoringEditor
local e = setmetatable({ toolbar = { control(), control(), control(), control() },
    coreRows = {}, addRows = {}, sectionLabels = {}, draft = {},
    pages = {}, roster = control(), rosterLabel = control(), tabPanel = control(),
    fileLabel = control(), fileCombo = control(), configuredDetails = control(),
    removeConfiguredButton = control(), details = control(), resetDetailsButton = control(),
    removeButton = control(), statusLabel = control(), portraitPanel = control(),
}, { __index = Class })
for _, id in ipairs({ "bio", "appearance", "attributes", "loadout", "relations" }) do e.pages[id] = control() end
 e.formView, e.appearanceTab = e.pages.bio, e.pages.appearance
 e.tabPanel.tabHeight = 24
function e.appearanceTab:onResponsiveLayout() end
function e:layoutLoadoutPage() end
function e.portraitPanel:setPortraitBounds(x, y, w, h)
    self.nativeWidth, self.nativeHeight = w, h
end
function e:getContentRect() return { x = 0, y = 0, width = self.width, height = self.height } end
function e:fieldCapability(id) return { visible = id ~= "faction", editable = id ~= "surname" } end
for _, id in ipairs({ "forename", "surname", "nickname", "gender", "archetype", "faction", "hair", "beard", "equipmentMode" }) do
    e.coreRows[#e.coreRows + 1] = { id = id, fieldID = id, labelControl = control(), entry = control(), readOnlyValue = control() }
end
for index = 1, 4 do
    e.addRows[index] = { fieldID = "skill", labelControl = control(), button = control(), entries = index == 1 and { control(), control() } or { control() } }
end
local function inside(c, w, h, message)
    T.truthy(c.x >= 0 and c.y >= 0 and c.x + c.width <= w + 1 and c.y + c.height <= h + 1, message)
end
for _, mode in ipairs({ "companion", "debug" }) do
    e.presentationMode = mode
    for _, scale in ipairs({ 1, 1.25, 1.5 }) do
        for _, size in ipairs({ { 780, 420 }, { 1060, 620 }, { 1540, 900 }, { 2480, 1300 } }) do
            e.width, e.height, e.uiScale = size[1], size[2], scale
            e:onResponsiveLayout()
            inside(e.roster, e.width, e.height, "roster bounded")
            inside(e.tabPanel, e.width, e.height, "tab viewport bounded")
            inside(e.statusLabel, e.width, e.height, "status bounded")
            if e.portraitPanel.visible then inside(e.portraitPanel, e.width, e.height, "portrait bounded") end
            T.equal(e.portraitPanel.nativeWidth, e.portraitPanel.width, "native model viewport follows panel width")
            T.equal(e.portraitPanel.nativeHeight, e.portraitPanel.height, "native model viewport follows panel height")
            for _, row in ipairs(e.coreRows) do
                if row.labelControl.visible then
                    inside(row.labelControl, e.formView.width, e.formView.contentHeight, "Bio label bounded")
                    inside(row.readOnlyValue.visible and row.readOnlyValue or row.entry, e.formView.width, e.formView.contentHeight, "Bio value bounded")
                end
            end
            for _, row in ipairs(e.addRows) do
                inside(row.button, e.pages.attributes.width, e.pages.attributes.contentHeight, "attribute action bounded")
                for _, c in ipairs(row.entries) do inside(c, e.pages.attributes.width, e.pages.attributes.contentHeight, "attribute input bounded") end
            end
            if e.layout.compact then
                e.previewExpanded = true
                e:onResponsiveLayout()
                T.falsy(e.tabPanel.visible, "compact preview replaces form instead of overlapping it")
                T.truthy(e.portraitPanel.visible, "compact preview is accessible")
                inside(e.portraitPanel, e.width, e.height, "expanded preview bounded")
                e.previewExpanded = false
            end
        end
    end
end
T.finish("pnc_starting_companion_ui_layout_smoke")
