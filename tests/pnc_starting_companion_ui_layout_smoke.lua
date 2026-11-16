local T = require "tests/support/test"

T.addPackagePaths()

local function control(title)
    local value = { title = title or "", visible = true }
    function value:getTitle() return self.title end
    function value:setVisible(nextVisible) self.visible = nextVisible end
    function value:setTitle(nextTitle) self.title = nextTitle end
    function value:setEnabled(enabled) self.enabled = enabled end
    function value:setEnable(enabled) self.enabled = enabled end
    return value
end

local Layout = {}
function Layout.Pixels(value) return value end
function Layout.SetBounds(target, x, y, width, height)
    target.x, target.y, target.width, target.height = x, y, width, height
end
function Layout.Flow(controls, rect)
    local x = rect.x
    for _, target in ipairs(controls or {}) do
        local width = target.preferredWidth or 80
        Layout.SetBounds(target, x, rect.y, width, 28)
        x = x + width + 6
    end
    return { bottom = rect.y + 28 }
end

local function makeList()
    local list = control()
    function list:clear() self.items = {} end
    list.items = {}
    function list:addItem(label, item)
        self.items[#self.items + 1] = { label = label, item = item }
    end
    return list
end

local editorWindow = {
    Internal = { Layout = Layout, Presentation = {} },
}
editorWindow.presentationMode = "companion"
editorWindow.uiScale = 1
editorWindow.width = 1000
editorWindow.height = 620
editorWindow.toolbar = { control("INSPECTOR") }
editorWindow.tabPanel = { tabHeight = 20 }
editorWindow.formView = control()
editorWindow.formView.height = 500
function editorWindow.formView:setScrollHeight(value) self.scrollHeight = value end
editorWindow.appearanceTab = control()
function editorWindow.appearanceTab:onResponsiveLayout() self.responsive = true end
editorWindow.portraitPanel = control()
function editorWindow.portraitPanel:setPortraitBounds(x, y, width, height)
    self.portraitBounds = { x = x, y = y, width = width, height = height }
end
editorWindow.sectionLabels = {
    identity = control(), background = control(), skills = control(), traits = control(),
}
editorWindow.details = makeList()
editorWindow.configuredDetails = makeList()
editorWindow.removeConfiguredButton = control()
editorWindow.removeButton = control()
editorWindow.resetDetailsButton = control()
editorWindow.statusLabel = control()
editorWindow.draft = {}
editorWindow.inspectorVisible = false
editorWindow.coreRows = {}
for _, id in ipairs({ "forename", "nickname", "surname", "gender",
    "archetype", "faction", "hair", "beard", "equipmentMode" }) do
    local row = {
        id = id, fieldID = id, labelControl = control(), entry = control(),
    }
    if id == "surname" or id == "gender" then
        row.readOnlyValue = control()
    end
    editorWindow.coreRows[#editorWindow.coreRows + 1] = row
end
editorWindow.addRows = {}
for _, id in ipairs({ "skill", "npcTrait", "vanillaTrait", "dynamicTrait" }) do
    editorWindow.addRows[#editorWindow.addRows + 1] = {
        id = id, fieldID = id, labelControl = control(), button = control(),
        entries = { control() },
    }
end
function editorWindow:getContentRect()
    return { x = 0, y = 0, width = self.width, height = self.height }
end
function editorWindow:fieldCapability(fieldID)
    if fieldID == "factionID" or fieldID == "faction" then
        return { visible = false, editable = false }
    end
    if fieldID == "identity.surname" or fieldID == "surname" then
        return { visible = true, editable = false, sourceLabel = "Inherited from Player" }
    end
    if fieldID == "identity.isFemale" or fieldID == "gender" then
        return { visible = true, editable = false, sourceLabel = "Relationship Rule" }
    end
    return { visible = true, editable = true }
end

ISPNCNPCAuthoringEditor = editorWindow
T.load("ProjectHoomans", "client",
    "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Layout.lua")

editorWindow:onResponsiveLayout()
T.truthy(editorWindow.layout, "shared editor exposes layout evidence")
T.truthy(editorWindow.layout.companion.scrollBounded,
    "companion General uses a bounded scroll surface")
T.truthy(editorWindow.layout.portraitX + editorWindow.layout.portraitWidth
    <= editorWindow.width, "portrait remains inside the editor")
T.truthy(editorWindow.layout.leftWidth <= editorWindow.width,
    "General tab remains inside the editor")
T.truthy(editorWindow.layout.companion.statusY
    + editorWindow.layout.companion.statusHeight
    <= editorWindow.layout.companion.contentHeight,
    "status remains inside the General content")
for _, row in ipairs(editorWindow.coreRows) do
    if row.labelControl.width then
        T.truthy(row.labelControl.x + row.labelControl.width
            <= editorWindow.layout.leftWidth,
            "General labels stay inside the tab")
    end
end

editorWindow.width = 640
editorWindow.height = 460
editorWindow:onResponsiveLayout()
T.truthy(editorWindow.layout.stacked, "small layout stacks the portrait")
T.truthy(editorWindow.layout.portraitY + editorWindow.layout.portraitHeight
    <= editorWindow.height, "stacked portrait remains bounded")

local appearance = {
    Internal = { Layout = Layout, tr = function(_, fallback) return fallback end },
    parentEditor = { presentationMode = "companion" },
    uiScale = 1, width = 560, height = 330,
    topControls = { control("RANDOMIZE"), control("PLAY VOICE"), control("ADVANCED") },
    content = {
        width = 520, height = 270, contentHeight = 0,
        vscroll = {
            width = 16,
            setX = function(self, value) self.x = value end,
            setHeight = function(self, value) self.height = value end,
        },
    },
    rows = {}, advancedVisible = false,
    outfitLabel = control(), outfitCombo = control(),
    voiceLabel = control(), voiceCombo = control(),
    voiceSampleLabel = control(), voiceSampleCombo = control(),
    voicePitchLabel = control(), voicePitch = control(), voicePitchValue = control(),
    skinLabel = control(), skinModeCombo = control(), skinSwatch = control(),
    skinValue = control(), hairLabel = control(), hairCombo = control(),
    beardLabel = control(), beardCombo = control(), advancedLabel = control(),
    advancedClothingButton = control("ADVANCED"),
}
function appearance.content:setScrollHeight(value) self.scrollHeight = value end
function appearance.content:setYScroll(value) self.yScroll = value end
function appearance.content:getYScroll() return self.yScroll or 0 end
function appearance.content:onResize() self.resized = true end
for _ = 1, 8 do
    appearance.rows[#appearance.rows + 1] = {
        labelControl = control(), policy = control(), item = control(),
    }
end
ISPNCUniqueNPCAppearanceWindow = appearance
T.load("ProjectHoomans", "client",
    "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCAppearanceWindow_Layout.lua")

appearance:onResponsiveLayout()
T.falsy(appearance.layout.advancedVisible,
    "normal Appearance keeps advanced clothing collapsed")
for _, row in ipairs(appearance.rows) do
    T.falsy(row.item.width > 0, "normal Appearance hides raw clothing rows")
end
T.truthy(appearance.content.height <= appearance.height,
    "normal Appearance scroll region is bounded")

appearance.advancedVisible = true
appearance:onResponsiveLayout()
T.truthy(appearance.layout.advancedVisible,
    "Advanced Clothing Overrides can be opened")
T.truthy(appearance.layout.scrollBounded,
    "advanced clothing owns a bounded scroll surface")
for _, row in ipairs(appearance.rows) do
    T.truthy(row.item.x + row.item.width <= appearance.content.width,
        "advanced clothing rows stay inside the scroll region")
end

T.finish("pnc_starting_companion_ui_layout_smoke")
