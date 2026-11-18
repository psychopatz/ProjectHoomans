local T = require "tests/support/test"
T.addPackagePaths()
UIFont = { Small = 1 }
getText = function(key) return key end
getTextManager = function() return { getFontHeight = function() return 18 end } end
local Base = {}
function Base:derive() local out = {}; setmetatable(out, { __index = self }); return out end
function Base:new(x, y, w, h)
    return setmetatable({ x = x, y = y, width = w, height = h, visible = true,
        children = {}, items = {}, options = {}, selected = 0 }, { __index = self })
end
function Base:initialise() end
function Base:instantiate() if not self.built then self.built = true; self:createChildren() end end
function Base:createChildren() end
function Base:addChild(c) self.children[c] = c; c.parent = self end
function Base:removeChild(c) self.children[c] = nil; c.parent = nil end
function Base:noBackground() end
function Base:setVisible(v) self.visible = v end
function Base:setEnabled(v) self.enabled = v end
Base.setEnable = Base.setEnabled
function Base:setName(v) self.name = v end
function Base:setScrollHeight(v) self.scrollHeight = v end
function Base:getYScroll() return self.yScroll or 0 end
function Base:setYScroll(v) self.yScroll = v end
function Base:onResize() end
function Base:setText(v) self.text = v end
function Base:getText() return self.text or "" end
function Base:getWidth() return self.width end
function Base:getHeight() return self.height end
function Base:clear() self.items = {}; self.options = {}; self.selected = 0 end
function Base:addItem(label, row) self.items[#self.items + 1] = { item = row, index = #self.items + 1 } end
function Base:getItem() return self.items[self.selected] end
function Base:addOptionWithData(label, data) self.options[#self.options + 1] = { text = label, data = data }; if self.selected == 0 then self.selected = 1 end end
function Base:selectData(data) for i, option in ipairs(self.options) do if option.data == data then self.selected = i end end end
function Base:setOnMouseDownFunction(target, callback) self.target, self.onmousedown = target, callback end
ISPanel, ISLabel, ISComboBox = Base, Base, Base
ISPNCUniqueNPCAppearanceScrollPanel = Base
ISTabPanel = Base:derive()
function ISTabPanel:createChildren() self.viewList = {}; self.tabHeight = 24 end
function ISTabPanel:addView(name, page)
    local v = { name = name, view = page }
    self.viewList[#self.viewList + 1] = v
    self:addChild(page)
    page:setVisible(#self.viewList == 1)
    if not self.activeView then self.activeView = v end
end
function ISTabPanel:getActiveView() return self.activeView.view end
function ISTabPanel:activateView(name)
    for _, v in ipairs(self.viewList) do
        if v.name == name then self.activeView.view:setVisible(false); self.activeView = v; v.view:setVisible(true) end
    end
end
local Layout = {}
function Layout.Pixels(v, scale) return math.floor(v * (scale or 1)) end
function Layout.SetBounds(c, x, y, w, h) c.x, c.y, c.width, c.height = x, y, w, h end
function Layout.Flow(controls, rect, options)
    local x, y, h = rect.x, rect.y, Layout.Pixels(30, options.scale)
    for _, c in ipairs(controls) do
        if x > rect.x and x + 110 > rect.x + rect.width then x = rect.x; y = y + h + 6 end
        Layout.SetBounds(c, x, y, math.min(110, rect.width), h); x = x + 116
    end
    return { bottom = y + h }
end
local UI = { Layout = Layout, Theme = { colors = {} }, PortraitPanel = Base }
for _, method in ipairs({ "CreateButton", "CreateTextEntry", "CreateList" }) do
    UI[method] = function(parent, options)
        local c = Base:new(0, 0, 1, 1)
        for key, value in pairs(options) do c[key] = value end
        c.internal = options.id
        parent:addChild(c)
        return c
    end
end
UI.SetLabelText = function(c, value) c:setName(value) end
PsychopatzCore = { UI = UI }
local Model = { New = function() return { identity = { survivor = {} }, appearance = {} } end }
local Storage = { List = function() return {} end }
PNC = { UniqueNPCEditorModel = Model, UniqueNPCEditorStorage = Storage,
    NPCAuthoringEditorProfile = { IsVisible = function() return true end, SourceHelp = function() return "" end },
    Identity = { Appearance = { Normalize = function(v) return v or { slots = {} } end } },
    UniqueNPCAppearanceUI = { Internal = { locations = function() return {} end } },
    NPCAuthoringCatalog = { Search = function() return {} end }, NPCAuthoringLoadout = {} }
local savedRequire = require
require = function() return {} end
T.load("ProjectHoomans", "client", "PNC/UI/NPCAuthoring/PNC_NPCAuthoringEditor.lua")
require = savedRequire
local Class = ISPNCNPCAuthoringEditor
local I = Class.Internal
T.load("ProjectHoomans", "client", "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Core.lua")
I.addOptions = function(combo, options) for _, o in ipairs(options) do combo:addOptionWithData(o.label, o.id) end end
T.load("ProjectHoomans", "client", "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Form.lua")
T.load("ProjectHoomans", "client", "PNC/UI/NPCAuthoring/PNC_NPCAuthoringEditor_Roster.lua")
for _, path in ipairs({ "PNC_NPCAuthoringLoadout", "PNC_NPCAuthoringCatalog" }) do
    package.loaded["PNC/UI/NPCAuthoring/" .. path] = true
end
T.load("ProjectHoomans", "client", "PNC/UI/NPCAuthoring/PNC_NPCAuthoringEditor_Loadout.lua")
T.load("ProjectHoomans", "client", "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Lifecycle.lua")
T.load("ProjectHoomans", "client", "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Layout.lua")
ISPNCUniqueNPCAppearanceWindow = Base:derive()
function ISPNCUniqueNPCAppearanceWindow:createChildren()
    self.content = Base:new(0, 0, 1, 1); self:addChild(self.content)
    for _, name in ipairs({ "outfitLabel", "outfitCombo" }) do self[name] = Base:new(0, 0, 1, 1); self.content:addChild(self[name]) end
end
function ISPNCUniqueNPCAppearanceWindow:onResponsiveLayout() end
for _, method in ipairs({ "refreshArchetypeOptions", "refreshGenderOptions", "refreshEquipmentOptions",
    "refreshStyleOptions", "refreshRepeaterOptions", "refreshFiles", "syncControls", "refreshPreview", "refreshDetails" }) do
    Class[method] = function() end
end
for _, mode in ipairs({ "companion", "debug" }) do
    local e = Class:new(0, 0, 1000, 620, { mode = mode, uiScale = 1 })
    e:initialise(); e:instantiate()
    T.equal(#e.tabPanel.viewList, 5, "both hosts use the same five pages")
    T.equal(e.forenameEntry.parent, e.pages.bio, "identity belongs to Bio")
    T.equal(e.skillCombo.parent, e.pages.attributes, "skills belong to Attributes")
    T.equal(e.details.parent, e.pages.relations, "inspector belongs to Details")
    T.equal(e.equipmentModeCombo.parent, e.pages.loadout, "generation policy belongs to Loadout")
    T.equal(e.appearanceTab.outfitCombo.parent, e.pages.loadout, "outfit has one control on Loadout")
    T.equal(e.loadoutResults.parent, e.pages.loadout, "catalog picker is embedded")
    e:setRoster({ { id = "brother", label = "Phil" }, { id = "sister", label = "Fran" } }, "brother", function(id) e.chosen = id end)
    function e:pullForm() self.flushed = true end
    e.roster.onmousedown(e, e.roster.items[2].item)
    T.truthy(e.flushed, "selection flushes the focused form")
    T.equal(e.chosen, "sister", "roster callback identifies the selected NPC")
    e:onResponsiveLayout()
    T.truthy(e.loadoutResults.y + e.loadoutResults.height < e.pages.loadout.contentHeight, "catalog fits in scroll content")
    T.truthy(e.pages.loadout.contentHeight > e.pages.loadout.height, "long page has a bounded scroll viewport")
end
T.finish("pnc_npc_authoring_composition_smoke")
