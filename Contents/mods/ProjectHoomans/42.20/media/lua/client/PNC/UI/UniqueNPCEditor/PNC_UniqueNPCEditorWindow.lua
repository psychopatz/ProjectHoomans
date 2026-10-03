require "PsychopatzCore/UI/PsychopatzUI"
require "PsychopatzCore/UI/Components/PsychopatzPortraitPanel"
require "ISUI/ISLabel"
require "ISUI/ISComboBox"
require "ISUI/ISPanel"
require "ISUI/ISTabPanel"
require "PNC/Core/Archetypes/Registry/PNC_Archetypes"
require "PNC/Core/Skills/PNC_SkillCatalog"
require "PNC/Core/Traits/PNC_NPCTraitRegistry"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorModel"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorStorage"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCAppearanceWindow"
require "PNC/UI/Inventory/PNC_InventoryWindow"

PNC = PNC or {}
PNC.UniqueNPCEditorUI = PNC.UniqueNPCEditorUI or {}

local EditorUI = PNC.UniqueNPCEditorUI
local Model = PNC.UniqueNPCEditorModel
local Storage = PNC.UniqueNPCEditorStorage
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Theme = UI.Theme
local Archetypes = PNC.Archetypes

local Internal = EditorUI.Internal or {}
Internal.Model = Model
Internal.Storage = Storage
Internal.UI = UI
Internal.Layout = Layout
Internal.Theme = Theme
Internal.Archetypes = Archetypes
EditorUI.Internal = Internal
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Core"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Options"
local tr = Internal.tr


ISPNCUniqueNPCEditorWindow = PsychopatzWindow:derive(
    "ISPNCUniqueNPCEditorWindow")

function ISPNCUniqueNPCEditorWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCUniqueNPCEditorWindow:render()
    PsychopatzWindow.render(self)
    if self.layout then
        UI.DrawSectionTitle(self,
            tr("UI_PNC_UniqueNPCEditor_Preview", "PREVIEW"),
            self.layout.portraitX,
            self.layout.y - Layout.Pixels(18, self.uiScale),
            self.layout.portraitWidth)
    end
end

function ISPNCUniqueNPCEditorWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    EditorUI.instance = nil
end

function ISPNCUniqueNPCEditorWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end


ISPNCUniqueNPCEditorWindow.Internal = Internal
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Lifecycle"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Layout"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Actions"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Form"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Details"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Preview"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Persistence"

function EditorUI.Open()
    if not PNC.Client or not PNC.Client.CanUseDebug
        or not PNC.Client.CanUseDebug()
    then
        return nil
    end
    local window = EditorUI.instance
    if not window then
        window = UI.NewWindow(ISPNCUniqueNPCEditorWindow, {
            title = tr("UI_PNC_UniqueNPCEditor_Title", "UNIQUE NPC CREATOR"),
            resizable = true,
            responsiveSpec = {
                width = 1040, height = 760, minWidth = 820, minHeight = 620,
                maxWidth = 1600, maxHeight = 1100,
            },
        })
        window:initialise()
        window:instantiate()
        window:addToUIManager()
        EditorUI.instance = window
    else
        window:addToUIManager()
        window:setVisible(true)
        window:bringToTop()
    end
    return window
end

function EditorUI.Toggle()
    if EditorUI.instance and EditorUI.instance:getIsVisible() then
        EditorUI.instance:close()
        return false
    end
    return EditorUI.Open() ~= nil
end

return EditorUI
