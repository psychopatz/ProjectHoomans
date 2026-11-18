local T = require "tests/support/test"
T.addPackagePaths()

-- Load the production component without its engine/UI dependency graph. The
-- methods under test are not replaced by an imitation editor.
ISPanel = { derive = function(_, name) return { Type = name } end }
PsychopatzCore = { UI = {} }
PNC = { UniqueNPCEditorModel = { UpdatePreviewDraft = function(previous) return previous end }, NPCAuthoringEditorProfile = {} }
local savedRequire = require
require = function() return {} end
T.load("ProjectHoomans", "client", "PNC/UI/NPCAuthoring/PNC_NPCAuthoringEditor.lua")
require = savedRequire
local Editor = ISPNCNPCAuthoringEditor
local function page()
    return { setVisible = function(self, value) self.visible = value end }
end
local bio, appearance, attributes = page(), page(), page()
local tabs = { viewList = {
    { name = "Bio", view = bio }, { name = "Appearance", view = appearance },
    { name = "Attributes", view = attributes },
} }
tabs.activeView = tabs.viewList[2]
function tabs:getActiveView() return self.activeView.view end
function tabs:activateView(name)
    for _, entry in ipairs(self.viewList) do
        if entry.name == name then
            self.activeView.view:setVisible(false)
            entry.view:setVisible(true)
            self.activeView = entry
        end
    end
end
local editor = setmetatable({
    tabPanel = tabs, formView = bio, appearanceTab = appearance,
    portraitPanel = page(), presentationMode = "companion",
}, { __index = Editor })
function editor:requestResponsiveLayout() end
function editor:syncControls() end
function editor:refreshPreview()
    self.portraitPanel:setVisible(self.draft ~= nil)
    self.previewDraft = self.previewDraft or { id = self.draft.id }
end
local function adapter(id)
    return { traitID = id, BuildDraft = function() return { id = id } end,
        PreviewGenerationIdentity = function() return "seed:" .. id end,
        PreviewIdentity = function() return "intent:" .. id end }
end
local function assertPage(expected, message)
    for _, entry in ipairs(tabs.viewList) do
        T.equal(entry.view.visible == true, entry.view == expected, message .. entry.name)
    end
end
editor:setAdapter(adapter("brother"))
assertPage(appearance, "selection preserves active page: ")
editor:setAdapter(adapter("sister"))
T.equal(editor.draft.id, "sister", "selection replaces the draft")
assertPage(appearance, "switching NPC leaves exactly one page visible: ")
local sisterPreview = editor.previewDraft
editor:setAdapter(adapter("brother"))
editor:setAdapter(adapter("sister"))
T.equal(editor.previewDraft, sisterPreview, "switching away and back retains the generated preview")
tabs:activateView("Attributes")
editor:refreshFromAdapter(true)
assertPage(attributes, "refresh preserves page: ")
editor:setAdapter(nil)
assertPage(nil, "empty selection hides every page: ")
T.falsy(editor.portraitPanel.visible, "empty selection clears portrait")
editor:setAdapter(adapter("friend"))
assertPage(attributes, "selection recovery restores only active page: ")
T.equal(editor.draft.id, "friend", "selection recovery replaces cleared draft")
T.finish("pnc_npc_authoring_page_lifecycle_smoke")
