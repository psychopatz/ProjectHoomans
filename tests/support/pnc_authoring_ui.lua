-- Widget-boundary fixture shared by composition, edit and geometry checks.
return function()
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
function Base:getIsVisible() return self.visible end
function Base:isReallyVisible() return self.visible and (not self.parent or self.parent:isReallyVisible()) end
function Base:setX(v) self.x = v end
function Base:setY(v) self.y = v end
function Base:setWidth(v) self.width = v end
function Base:setHeight(v) self.height = v end
function Base:addToUIManager() self.inUIManager = true end
function Base:removeFromUIManager() self.inUIManager = false end
function Base:setAlwaysOnTop(v) self.alwaysOnTop = v end
function Base:bringToTop() end
function Base:setEditable(v) self.editable = v end
function Base:focus() self.focused = true end
function Base:unfocus() self.focused = false; if self.onLostFocus then self:onLostFocus() end end
function Base:setImage(v) self.image = v end
function Base:forceImageSize(w,h) self.imageWidth, self.imageHeight = w,h end
function Base:setEnabled(v) self.enabled = v end
Base.setEnable = Base.setEnabled
function Base:setName(v) self.name = v end
function Base:setTitle(v) self.title = v end
function Base:setFont(font, pad) self.font, self.itemPadY = font, pad end
function Base:setScrollHeight(v) self.scrollHeight = v end
function Base:getYScroll() return self.yScroll or 0 end
function Base:setYScroll(v) self.yScroll = v end
function Base:onResize() end
function Base:setText(v)
    self.text = v; self.caret = #v
    if self.onTextChange then self:onTextChange() end
end
function Base:getText() return self.text or "" end
function Base:getWidth() return self.width end
function Base:getHeight() return self.height end
function Base:clear() self.items = {}; self.options = {}; self.selected = 0 end
function Base:addItem(label, row) self.items[#self.items + 1] = { item = row, text = label, index = #self.items + 1 } end
function Base:getItem() return self.items[self.selected] end
function Base:addOptionWithData(label, data) self.options[#self.options + 1] = { text = label, data = data }; if self.selected == 0 then self.selected = 1 end end
function Base:selectData(data) for i, option in ipairs(self.options) do if option.data == data then self.selected = i end end end
function Base:setOnMouseDownFunction(target, callback) self.target, self.onmousedown = target, callback end
ISPanel, ISLabel, ISComboBox = Base, Base, Base:derive()
function ISComboBox:new(x, y, w, h, target, onChange)
    local control = Base.new(self, x, y, w, h)
    control.target, control.onChange = target, onChange
    return control
end
package.loaded["ISUI/ISPanel"] = true
package.loaded["ISUI/ISComboBox"] = true
ISToolTip = Base:derive()
function ISToolTip:new() return Base.new(self, 0, 0, 0, 0) end
function ISToolTip:setOwner(owner) self.owner = owner end
function ISToolTip:prerender()
    if self.owner and not self.owner:isReallyVisible() then self:setVisible(false); self:removeFromUIManager(); return end
    self:doLayout()
end
package.loaded['ISUI/ISToolTip'] = ISToolTip
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
function Layout.Ellipsize(value) return value end
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
UI.PortraitPanel = Base:derive()
function UI.PortraitPanel:setTarget(actor, spec) self.actor, self.spec = actor, spec end
function UI.PortraitPanel:setPortraitBounds(x, y, width, height) self.bounds = { x, y, width, height } end
for _, method in ipairs({ "CreateButton", "CreateTextEntry", "CreateList", "CreateKeyValueList" }) do
    UI[method] = function(parent, options)
        local c = Base:new(0, 0, 1, 1)
        for key, value in pairs(options) do c[key] = value end
        c.internal = options.id
        parent:addChild(c)
        return c
    end
end
UI.AddKeyValue = function(list, label, value) list:addItem(label, { label = label, value = value }) end
UI.SetLabelText = function(c, value) c:setName(value) end
PsychopatzCore = { UI = UI }
PsychopatzPortraitPanel = UI.PortraitPanel
function UI.PortraitPanel:applyViewState() end
function UI.PortraitPanel:applyCameraState() end
T.load('PsychopatzCore', 'client', 'PsychopatzCore/UI/Components/PsychopatzPortraitPanel_Framing.lua')
local Model = { New = function() return { identity = { survivor = {} }, appearance = {} } end }
local Storage = { List = function() return {} end }
PNC = { UniqueNPCEditorModel = Model, UniqueNPCEditorStorage = Storage,
    NPCAuthoringVariation = { Includes = function() return false end },
    NPCAuthoringEditorProfile = { List = function() return {} end, IsVisible = function() return true end, SourceHelp = function() return "" end },
    Identity = { Appearance = { Normalize = function(v) return v or { slots = {} } end } },
    UniqueNPCAppearanceUI = { Internal = { locations = function() return {} end } },
    NPCAuthoringCatalog = { Search = function() return {} end, Find = function() end }, NPCAuthoringLoadout = {} }
local savedRequire = require
require = function() return {} end
T.load("ProjectHoomans", "client", "PNC/UI/NPCAuthoring/PNC_NPCAuthoringEditor.lua")
require = savedRequire
local Class = ISPNCNPCAuthoringEditor
local I = Class.Internal
T.load("ProjectHoomans", "client", "PNC/UI/NPCAuthoring/PNC_NPCAuthoringFields.lua")
T.load("ProjectHoomans", "client", "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Core.lua")
I.addOptions = function(combo, options) for _, o in ipairs(options) do combo:addOptionWithData(o.label, o.id) end end
T.load("ProjectHoomans", "client", "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Form.lua")
T.load("ProjectHoomans", "client", "PNC/UI/NPCAuthoring/PNC_NPCAuthoringEditor_Roster.lua")
for _, path in ipairs({ "PNC_NPCAuthoringLoadout", "PNC_NPCAuthoringCatalog" }) do
    package.loaded["PNC/UI/NPCAuthoring/" .. path] = true
end
T.load("ProjectHoomans", "client", "PNC/UI/NPCAuthoring/PNC_NPCAuthoringEditor_Loadout.lua")
package.loaded["PNC/Identity/PNC_NPCAuthoringVariation"] = true
T.load("ProjectHoomans", "client", "PNC/UI/NPCAuthoring/PNC_NPCAuthoringRelationshipPresentation.lua")
T.load("ProjectHoomans", "client", "PNC/UI/NPCAuthoring/PNC_NPCAuthoringRandomization.lua")
T.load("ProjectHoomans", "client", "PNC/UI/NPCAuthoring/PNC_NPCAuthoringAttributes.lua")
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

return { Class = Class, Base = Base, UI = UI, Model = Model }
end
