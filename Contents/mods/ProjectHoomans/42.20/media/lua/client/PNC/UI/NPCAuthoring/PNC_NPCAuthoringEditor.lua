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
require "PNC/UI/NPCAuthoring/PNC_NPCAuthoringFields"
require "PNC/UI/NPCAuthoring/PNC_NPCAuthoringRelationshipPresentation"

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
    self.backgroundColor = { r = 0.055, g = 0.065, b = 0.075, a = 0.98 }
    self.borderColor = { r = 0.22, g = 0.28, b = 0.30, a = 1 }
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

-- ISTabPanel owns the active page. A host selection/refresh must never reveal
-- inactive siblings, including when recovering from an empty roster.
function ISPNCNPCAuthoringEditor:syncPageVisibility()
    local tabs = self.tabPanel
    if not tabs then return end
    local active = tabs:getActiveView()
    if active ~= self.appearanceTab and self.appearanceTab and self.appearanceTab.onStopVoice then
        self.appearanceTab:onStopVoice()
    end
    for _, entry in ipairs(tabs.viewList or {}) do
        entry.view:setVisible(self.draft ~= nil and entry.view == active)
    end
    if self.syncPortraitView then self:syncPortraitView() end
end

function ISPNCNPCAuthoringEditor:setAdapter(adapter)
    if self.itemExplorer and self.itemExplorer:getIsVisible() then self.itemExplorer:Hide() end
    if not adapter then
        self:clearPresentation()
        return
    end
    self.previewCache = self.previewCache or {}
    local cache = self.previewCache
    for key, value in pairs(cache) do
        if value.traitID == (self.presentationAdapter and self.presentationAdapter.traitID) then cache[key] = nil end
    end
    if self.previewGenerationIdentity and self.previewDraft then
        self.previewCache[self.previewGenerationIdentity] = {
            preview = self.previewDraft, identity = self.previewIdentity, traitID = self.presentationAdapter and self.presentationAdapter.traitID,
        }
    end
    if self.appearanceTab then self.appearanceTab:onStopVoice() end
    self.textEdits = {}
    self.presentationAdapter = adapter
    if adapter.Attach then adapter:Attach(self) end
    self.inspectorVisible = false
    if self.configuredDetails and self.configuredDetails.setVisible then
        self.configuredDetails:setVisible(self.presentationMode == "companion")
    end
    local generation = adapter.PreviewGenerationIdentity and adapter:PreviewGenerationIdentity()
    local identity = adapter.PreviewIdentity and adapter:PreviewIdentity()
    local cached = generation and self.previewCache[generation]
    if cached and cached.identity == identity then
        self.previewDraft = cached.preview
        self.previewGenerationIdentity = generation
    else
        self.previewDraft = nil
    end
    self:refreshFromAdapter(not (cached and cached.identity == identity))
    self:syncPageVisibility()
end

-- Clear every visible preview surface when the host has no valid current
-- companion.  Detaching the adapter alone is not enough: the old draft and
-- portrait are independent UI state and would otherwise remain on screen.
function ISPNCNPCAuthoringEditor:clearPresentation()
    if self.appearanceTab and self.appearanceTab.onStopVoice then self.appearanceTab:onStopVoice() end
    self.presentationAdapter = nil
    self.draft = nil
    self.previewDraft = nil
    self.previewIdentity = nil
    self.previewGenerationIdentity = nil
    self.previewSpecKey = nil
    self.portraitSourceSpec = nil
    self.inspectorVisible = false
    self:syncPageVisibility()
    if self.formView and self.formView.setVisible then
        self.formView:setVisible(false)
    end
    if self.appearanceTab then
        self.appearanceTab.draft = nil
        if self.appearanceTab.setVisible then
            self.appearanceTab:setVisible(false)
        end
    end
    if self.configuredDetails and self.configuredDetails.setVisible then
        self.configuredDetails:setVisible(false)
    end
    if self.details and self.details.setVisible then
        self.details:setVisible(false)
    end
    if self.portraitPanel then
        self.portraitPanel.targetKey = nil
        self.portraitPanel.targetSpec = nil
        self.portraitPanel.targetCharacter = nil
        self.portraitPanel:setVisible(false)
    end
    if self.statusLabel then
        local message = PNC.Translation and PNC.Translation.GetKey
            and PNC.Translation.GetKey("UI_PNC_NPCAuthoring_NoSelection",
                "No companion selected") or "No companion selected"
        self:setStatus(message)
    end
    self:requestResponsiveLayout(true)
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
    local previousPreview = self.previewDraft
    local previousGenerationIdentity = self.previewGenerationIdentity
    local previewIdentity = adapter.PreviewIdentity
        and adapter:PreviewIdentity() or nil
    local generationIdentity = adapter.PreviewGenerationIdentity
        and adapter:PreviewGenerationIdentity() or previewIdentity
    local draft = adapter:BuildDraft()
    if not draft then return false end
    self.draft = draft
    self.previewIdentity = previewIdentity or draft.previewIdentity
    self.previewGenerationIdentity = generationIdentity
    if previousPreview and previousGenerationIdentity == generationIdentity
        and force ~= true and Internal.Model.UpdatePreviewDraft
    then
        -- Keep the existing runtime record for ordinary edits.  The model
        -- patches explicit fields in place, so generated clothing/traits do
        -- not reroll merely because a text field changed.
        self.previewDraft = Internal.Model.UpdatePreviewDraft(
            previousPreview, self.draft)
    else
        self.previewDraft = nil
    end
    if self.appearanceTab then
        self.appearanceTab.draft = self.draft
        if self.appearanceTab.refreshGenderOptions then
            self.appearanceTab:refreshGenderOptions()
        end
    end
    if self.syncControls then self:syncControls() end
    if self.refreshPreview then self:refreshPreview(force == true) end
    self:syncPageVisibility()
    return true
end

function ISPNCNPCAuthoringEditor:commitAdapterDraft()
    local adapter = self.presentationAdapter
    if not adapter or not adapter.CommitDraft or not self.draft then return false end
    if self._committingAdapter then return false end
    self._committingAdapter = true
    local changed, reason = adapter:CommitDraft(self.draft)
    self._committingAdapter = false
    if changed then
        self._skipAdapterCommit = true
        self:refreshFromAdapter(false)
        self._skipAdapterCommit = false
    end
    return changed == true, reason
end

function ISPNCNPCAuthoringEditor:invokeWorkflow(action)
    if action == "randomize" and not PNC.NPCAuthoringFields.CanRandomize(self) then return false end
    local adapter = self.presentationAdapter
    if not adapter then return false end
    local method = action == "randomize" and "Randomize"
        or action == "reset" and "Reset"
        or action == "revert" and "RevertToPreset" or nil
    if not method or type(adapter[method]) ~= "function" then return false end
    self.textEdits = {}
    local ok = adapter[method](adapter)
    self:refreshFromAdapter(true)
    return ok ~= nil and ok ~= false
end

ISPNCNPCAuthoringEditor.Internal = Internal

-- The body modules are the extracted implementation of the mature Unique NPC
-- editor. They are loaded once here and are shared by every host surface.
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Core"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Options"
require "PNC/UI/NPCAuthoring/PNC_NPCAuthoringEditor_Roster"
require "PNC/UI/NPCAuthoring/PNC_NPCAuthoringEditor_Loadout"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Lifecycle"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Layout"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Actions"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Form"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Details"
require "PNC/UI/NPCAuthoring/PNC_NPCAuthoringAttributes"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Preview"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Persistence"
require "PNC/UI/NPCAuthoring/PNC_NPCAuthoringPortraitView"
require "PNC/UI/NPCAuthoring/PNC_NPCAuthoringRandomization"

return Editor
