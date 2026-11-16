-- Shared primitive NPC authoring presentation component.
--
-- The debug creator and starting-companion window both host this component.
-- Their outer windows own only workflow actions and policy adapters.

require "ISUI/ISPanel"
require "ISUI/ISComboBox"
require "ISUI/ISTabPanel"
require "PsychopatzCore/UI/PsychopatzUI"
require "PsychopatzCore/UI/Components/PsychopatzPortraitPanel"
require "PNC/Core/Archetypes/Registry/PNC_Archetypes"
require "PNC/Core/Skills/PNC_SkillCatalog"
require "PNC/Core/Traits/PNC_NPCTraitRegistry"
require "PNC/Identity/PNC_UniqueNPCDefinitionStore"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCAppearanceWindow"
require "PNC/UI/Inventory/PNC_InventoryWindow"
require "PNC/UI/NPCAuthoring/PNC_NPCAuthoringEditor_Profile"

PNC = PNC or {}
PNC.NPCAuthoringEditor = PNC.NPCAuthoringEditor or {}

local Editor = PNC.NPCAuthoringEditor
local EditorUI = PNC.UniqueNPCEditorUI or {}
local Internal = EditorUI.Internal or {}
local Profile = PNC.NPCAuthoringEditorProfile
local UI = PsychopatzCore.UI

Internal.Model = Internal.Model or PNC.UniqueNPCEditorModel
Internal.Storage = Internal.Storage or PNC.UniqueNPCEditorStorage
Internal.UI = Internal.UI or UI
Internal.Layout = Internal.Layout or UI.Layout
Internal.Theme = Internal.Theme or UI.Theme
Internal.Archetypes = Internal.Archetypes or PNC.Archetypes
Internal.Presentation = Profile
EditorUI.Internal = Internal
PNC.UniqueNPCEditorUI = EditorUI

ISPNCNPCAuthoringEditor = ISPanel:derive("ISPNCNPCAuthoringEditor")

function ISPNCNPCAuthoringEditor:initialise()
    ISPanel.initialise(self)
    self:noBackground()
end

function ISPNCNPCAuthoringEditor:new(x, y, width, height, options)
    local object = ISPanel.new(self, x, y, width, height)
    options = type(options) == "table" and options or {}
    setmetatable(object, self)
    self.__index = self
    object.presentationMode = options.mode or "debug"
    object.presentationAdapter = options.adapter
    object.parentEditor = options.parent
    object.uiScale = options.uiScale
    object.inspectorVisible = false
    return object
end

function ISPNCNPCAuthoringEditor:getContentRect()
    return {
        x = 0, y = 0,
        width = math.max(1, self:getWidth()),
        height = math.max(1, self:getHeight()),
    }
end

function ISPNCNPCAuthoringEditor:requestResponsiveLayout()
    if self.tabPanel and self.onResponsiveLayout then
        self:onResponsiveLayout()
    end
end

function ISPNCNPCAuthoringEditor:onResize()
    self:requestResponsiveLayout()
end

function ISPNCNPCAuthoringEditor:createChildren()
    ISPanel.createChildren(self)
    self:buildAuthoringEditorBody()
end

function ISPNCNPCAuthoringEditor:setAdapter(adapter)
    self.presentationAdapter = adapter
    if adapter and adapter.Attach then adapter:Attach(self) end
    if not adapter then
        self.inspectorVisible = false
        if self.details then self.details:setVisible(false) end
    end
    if self.draft and self.presentationAdapter then
        self:refreshFromAdapter(true)
    end
end

function ISPNCNPCAuthoringEditor:isFieldVisible(fieldID)
    return Profile.IsVisible(self.presentationMode, fieldID)
end

function ISPNCNPCAuthoringEditor:fieldCapability(fieldID)
    if self.presentationAdapter and self.presentationAdapter.FieldCapability then
        return self.presentationAdapter:FieldCapability(fieldID)
    end
    return { visible = self:isFieldVisible(fieldID), editable = true,
        source = "explicit", sourceLabel = Profile.SourceHelp("explicit") }
end

function ISPNCNPCAuthoringEditor:refreshFromAdapter(force)
    local adapter = self.presentationAdapter
    if not adapter or not adapter.BuildDraft then return false end
    local draft = adapter:BuildDraft()
    if not draft then return false end
    self.draft = draft
    self.previewDraft = nil
    if self.appearanceTab then
        self.appearanceTab.draft = self.draft
        if self.appearanceTab.refreshGenderOptions then
            self.appearanceTab:refreshGenderOptions()
        end
    end
    if self.syncControls then self:syncControls() end
    if self.refreshPreview then self:refreshPreview(force == true) end
    return true
end

function ISPNCNPCAuthoringEditor:commitAdapterDraft()
    local adapter = self.presentationAdapter
    if not adapter or not adapter.CommitDraft or not self.draft then return false end
    if self._committingAdapter then return false end
    self._committingAdapter = true
    local changed = adapter:CommitDraft(self.draft)
    self._committingAdapter = false
    if changed then
        self._skipAdapterCommit = true
        self:refreshFromAdapter(false)
        self._skipAdapterCommit = false
    end
    return changed == true
end

function ISPNCNPCAuthoringEditor:invokeWorkflow(action)
    local adapter = self.presentationAdapter
    if not adapter then return false end
    local method = action == "randomize" and "Randomize"
        or action == "reset" and "Reset"
        or action == "revert" and "RevertToPreset" or nil
    if not method or type(adapter[method]) ~= "function" then return false end
    local ok = adapter[method](adapter)
    self:refreshFromAdapter(true)
    return ok ~= nil and ok ~= false
end

ISPNCNPCAuthoringEditor.Internal = Internal

-- The body modules are the extracted implementation of the mature Unique NPC
-- editor. They are loaded once here and are shared by every host surface.
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Core"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Options"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Lifecycle"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Layout"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Actions"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Form"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Details"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Preview"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Persistence"

return Editor
