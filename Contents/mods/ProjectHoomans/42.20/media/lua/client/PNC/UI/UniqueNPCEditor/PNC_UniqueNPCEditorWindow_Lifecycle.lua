local Window = ISPNCUniqueNPCEditorWindow
local Internal = Window.Internal or {}
local Model = Internal.Model
local UI = Internal.UI
local Layout = Internal.Layout
local tr = Internal.tr
local addLabel = Internal.addLabel
local newCombo = Internal.newCombo
local addOptions = Internal.addOptions
local drawDetail = Internal.drawDetail

local function initializeEditorState(self)
    self.draft = Model.New()
    self.previewDraft = nil
    self.coreRows = {}
    self.addRows = {}
    self.toolbar = {}
end

local function buildEditorToolbar(self)
    for _, button in ipairs({
        { "new", "UI_PNC_UniqueNPCEditor_New", "NEW", "quiet" },
        { "load", "UI_PNC_UniqueNPCEditor_Load", "LOAD", "quiet" },
        { "save", "UI_PNC_UniqueNPCEditor_Save", "SAVE", "quiet" },
        { "produce", "UI_PNC_UniqueNPCEditor_Produce", "PRODUCE", "primary" },
        { "randomize", "UI_PNC_UniqueNPCEditor_Randomize", "RANDOMIZE", "selected" },
        { "inventory", "UI_PNC_UniqueNPCEditor_Inventory", "INVENTORY", "selected" },
    }) do
        local control = UI.CreateButton(self, {
            id = button[1],
            title = tr(button[2], button[3]),
            target = self,
            onclick = ISPNCUniqueNPCEditorWindow.onAction,
            variant = button[4],
        })
        self.toolbar[#self.toolbar + 1] = control
        self[button[1] .. "Button"] = control
    end

end

local function buildEditorTabs(self)
    self.tabPanel = ISTabPanel:new(0, 0, 1, 1)
    self.tabPanel:initialise()
    self.tabPanel:instantiate()
    self.tabPanel.tabPadX = Layout.Pixels(10, self.uiScale)
    self.tabPanel.equalTabWidth = false
    self.tabPanel.allowDraggingTabs = false
    self.tabPanel.allowTornOffTabs = false
    self:addChild(self.tabPanel)

    self.formView = ISPanel:new(0, 0, 1, 1)
    self.formView:initialise()
    self.formView:instantiate()
    self.formView:noBackground()
    self.generalTabName = tr("UI_PNC_UniqueNPCEditor_GeneralTab", "GENERAL")
    self.tabPanel:addView(self.generalTabName, self.formView)

    self.appearanceTab = ISPNCUniqueNPCAppearanceWindow:new(0, 0, 1, 1)
    self.appearanceTab.parentEditor = self
    self.appearanceTab.draft = self.draft
    self.appearanceTab.uiScale = self.uiScale
    self.appearanceTab:initialise()
    self.appearanceTab:instantiate()
    self.appearanceTabName = tr(
        "UI_PNC_UniqueNPCEditor_AppearanceTab", "APPEARANCE")
    self.tabPanel:addView(self.appearanceTabName, self.appearanceTab)
end

local function buildEditorForm(self)
    self.fileLabel = addLabel(self.formView,
        tr("UI_PNC_UniqueNPCEditor_LoadFile", "Load draft"))
    self.fileCombo = newCombo(self.formView, nil)

    self.forenameEntry = self:addTextRow("forename",
        "UI_PNC_UniqueNPCEditor_Forename", "First name", false, true)
    self.surnameEntry = self:addTextRow("surname",
        "UI_PNC_UniqueNPCEditor_Surname", "Surname", false, true)
    self.genderCombo = self:addComboRow("gender",
        "UI_PNC_UniqueNPCEditor_Gender", "Gender")
    self.archetypeCombo = self:addComboRow("archetype",
        "UI_PNC_UniqueNPCEditor_Archetype", "Archetype")
    self.factionEntry = self:addTextRow("faction",
        "UI_PNC_UniqueNPCEditor_Faction", "Faction ID", false, false)
    self.hairCombo = self:addComboRow("hair",
        "UI_PNC_UniqueNPCEditor_Hair", "Hair")
    self.beardCombo = self:addComboRow("beard",
        "UI_PNC_UniqueNPCEditor_Beard", "Beard")
    self.equipmentModeCombo = self:addComboRow("equipmentMode",
        "UI_PNC_UniqueNPCEditor_EquipmentMode", "Equipment")

    self.skillCombo = newCombo(self.formView, nil)
    self.skillLevelCombo = newCombo(self.formView, nil)
    self.addRows[#self.addRows + 1] = self:addRepeaterRow("skill",
        "UI_PNC_UniqueNPCEditor_AddSkill", "Skill", {
            self.skillCombo, self.skillLevelCombo,
        }, "UI_PNC_UniqueNPCEditor_Add")
    self.npcTraitCombo = newCombo(self.formView, nil)
    self.addRows[#self.addRows + 1] = self:addRepeaterRow("npcTrait",
        "UI_PNC_UniqueNPCEditor_AddNPCTrait", "NPC trait",
        { self.npcTraitCombo }, "UI_PNC_UniqueNPCEditor_Add")
    self.vanillaTraitCombo = newCombo(self.formView, nil)
    self.addRows[#self.addRows + 1] = self:addRepeaterRow("vanillaTrait",
        "UI_PNC_UniqueNPCEditor_AddVanillaTrait", "Vanilla trait",
        { self.vanillaTraitCombo }, "UI_PNC_UniqueNPCEditor_Add")
    self.dynamicTraitCombo = newCombo(self.formView, nil)
    self.addRows[#self.addRows + 1] = self:addRepeaterRow("dynamicTrait",
        "UI_PNC_UniqueNPCEditor_AddDynamicTrait", "Dynamic trait",
        { self.dynamicTraitCombo }, "UI_PNC_UniqueNPCEditor_Add")

    self.details = UI.CreateList(self.formView, {
        itemHeight = Layout.Pixels(25, self.uiScale),
        doDrawItem = drawDetail,
    })
    self.removeButton = UI.CreateButton(self.formView, {
        id = "remove_detail",
        title = tr("UI_PNC_UniqueNPCEditor_Remove", "REMOVE"),
        target = self,
        onclick = ISPNCUniqueNPCEditorWindow.onAction,
        variant = "quiet",
    })
    self.resetDetailsButton = UI.CreateButton(self.formView, {
        id = "reset_details",
        title = tr("UI_PNC_UniqueNPCEditor_ResetDetails", "RESET DETAILS"),
        target = self,
        onclick = ISPNCUniqueNPCEditorWindow.onAction,
        variant = "quiet",
    })
    self.statusLabel = addLabel(self.formView, "")
end

local function buildEditorPortrait(self)
    self.portraitPanel = UI.PortraitPanel:new(0, 0, 260, 390, {
        zoom = -3,
        yOffset = 0,
        direction = IsoDirections and IsoDirections.S,
        animSetName = false,
        stateName = "idle",
        animate = true,
    })
    self.portraitPanel:initialise()
    self.portraitPanel:instantiate()
    self:addChild(self.portraitPanel)
end

local function refreshEditorOptions(self)
    self:refreshArchetypeOptions()
    self:refreshGenderOptions()
    self:refreshEquipmentOptions()
    self:refreshStyleOptions()
    self:refreshRepeaterOptions()
    self:refreshFiles()
    self:requestResponsiveLayout(true)
    self:syncControls()
    self:refreshPreview(true)
end

function ISPNCUniqueNPCEditorWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    initializeEditorState(self)
    buildEditorToolbar(self)
    buildEditorTabs(self)
    buildEditorForm(self)
    buildEditorPortrait(self)
    refreshEditorOptions(self)
end


