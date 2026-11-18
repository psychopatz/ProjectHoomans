local Window = ISPNCNPCAuthoringEditor
local Internal = Window.Internal or {}
local Model = Internal.Model
local UI = Internal.UI
local Layout = Internal.Layout
local tr = Internal.tr
local addLabel = Internal.addLabel
local newCombo = Internal.newCombo
local addOptions = Internal.addOptions
local drawDetail = Internal.drawDetail
local Profile = Internal.Presentation

local function initializeEditorState(self)
    self.draft = Model.New()
    self.previewDraft = nil
    self.previewIdentity = nil
    self.previewGenerationIdentity = nil
    self.previewSpecKey = nil
    self.portraitTarget = nil
    self.coreRows = {}
    self.addRows = {}
    self.toolbar = {}
end

local function buildEditorToolbar(self)
    local buttons = self.presentationMode == "companion" and {} or {
        { "new", "UI_PNC_UniqueNPCEditor_New", "NEW", "quiet" },
        { "presets", "UI_PNC_Authoring_Presets", "Presets...", "quiet" },
        { "save", "UI_PNC_UniqueNPCEditor_Save", "Save NPC preset...", "quiet",
            "UI_PNC_Authoring_SaveNPCHelp", "Save the selected NPC, including every tab and its loadout, as a reusable preset." },
        { "produce", "UI_PNC_UniqueNPCEditor_Produce", "Save encounter NPC...", "primary",
            "UI_PNC_Authoring_SaveEncounterHelp", "Save this NPC as a reusable preset and offer it for world encounters. Multiplayer publication requires an administrator." },
    }
    buttons[#buttons + 1] = { "preview", "UI_PNC_Authoring_Preview", "Preview", "quiet" }
    for _, button in ipairs(buttons) do
        local control = UI.CreateButton(self, {
            id = button[1],
            title = tr(button[2], button[3]),
            target = self,
            onclick = ISPNCNPCAuthoringEditor.onAction,
            variant = button[4],
        })
        if button[5] then control.tooltip = tr(button[5], button[6]) end
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

    local formClass = ISPNCUniqueNPCAppearanceScrollPanel
    self.formView = formClass:new(0, 0, 1, 1)
    self.formView:initialise()
    self.formView:instantiate()
    self.formView:noBackground()
    self.generalTabName = tr("UI_PNC_Authoring_Bio", "Bio")
    self.tabPanel:addView(self.generalTabName, self.formView)

    self.appearanceTab = ISPNCUniqueNPCAppearanceWindow:new(0, 0, 1, 1)
    self.appearanceTab.parentEditor = self
    self.appearanceTab.integrated = true
    self.appearanceTab.draft = self.draft
    self.appearanceTab.uiScale = self.uiScale
    self.appearanceTab:initialise()
    self.appearanceTab:instantiate()
    self.appearanceTabName = tr(
        "UI_PNC_UniqueNPCEditor_AppearanceTab", "APPEARANCE")
    self.tabPanel:addView(self.appearanceTabName, self.appearanceTab)
    self.pages = { bio = self.formView, appearance = self.appearanceTab }
    for _, spec in ipairs({
        { "attributes", "UI_PNC_Authoring_Attributes", "Attributes" },
        { "loadout", "UI_PNC_Authoring_Loadout", "Loadout" },
        { "relations", "UI_PNC_Authoring_Details", "Details" },
    }) do
        local page = formClass:new(0, 0, 1, 1)
        page:initialise()
        page:instantiate()
        page:noBackground()
        self.pages[spec[1]] = page
        local name = spec[1] == "relations" and self.presentationMode == "companion"
            and tr("UI_PNC_Authoring_Relationships", "Relationships") or tr(spec[2], spec[3])
        self.tabPanel:addView(name, page)
    end
    self.tabPanel.target = self
    self.tabPanel.onActivateView = function(target)
        target:syncPageVisibility()
    end
end

local function buildEditorForm(self)
    self.fileLabel = addLabel(self.formView,
        tr("UI_PNC_UniqueNPCEditor_LoadFile", "Load draft"))
    self.fileCombo = newCombo(self.formView, nil)

    self.forenameEntry = self:addTextRow("forename",
        "UI_PNC_UniqueNPCEditor_Forename", "First name", false, true,
        "identity.forename")
    self.nicknameEntry = self:addTextRow("nickname",
        "UI_PNC_NPCAuthoring_Nickname", "Nickname", false, false,
        "identity.nickname")
    self.surnameEntry = self:addTextRow("surname",
        "UI_PNC_UniqueNPCEditor_Surname", "Surname", false, true,
        "identity.surname")
    self.genderCombo = self:addComboRow("gender",
        "UI_PNC_UniqueNPCEditor_Gender", "Gender", "identity.isFemale")
    self.archetypeCombo = self:addComboRow("archetype",
        "UI_PNC_UniqueNPCEditor_Archetype", "Archetype", "archetypeID")
    self.factionEntry = self:addTextRow("faction",
        "UI_PNC_UniqueNPCEditor_Faction", "Faction ID", false, false,
        "factionID")
    self.hairCombo = self:addComboRow("hair",
        "UI_PNC_UniqueNPCEditor_Hair", "Hair", "appearance.hairModel")
    self.beardCombo = self:addComboRow("beard",
        "UI_PNC_UniqueNPCEditor_Beard", "Beard", "appearance.beardModel")
    self.equipmentModeCombo = self:addComboRow("equipmentMode",
        "UI_PNC_UniqueNPCEditor_EquipmentMode", "Equipment",
        "equipmentSpawnMode")

    self.controlParent = self.pages.attributes
    self.skillCombo = newCombo(self.controlParent, nil)
    self.skillLevelCombo = PNC.NPCAuthoringFields.Level(self.controlParent)
    self.addRows[#self.addRows + 1] = self:addRepeaterRow("skill",
        "UI_PNC_UniqueNPCEditor_AddSkill", "Skill", {
            self.skillCombo, self.skillLevelCombo,
        }, "UI_PNC_UniqueNPCEditor_Add", "skills.baseLevels")
    self.npcTraitCombo = newCombo(self.controlParent, nil)
    self.addRows[#self.addRows + 1] = self:addRepeaterRow("npcTrait",
        "UI_PNC_UniqueNPCEditor_AddNPCTrait", "NPC trait",
        { self.npcTraitCombo }, "UI_PNC_UniqueNPCEditor_Add",
        "traits.npc")
    self.vanillaTraitCombo = newCombo(self.controlParent, nil)
    self.addRows[#self.addRows + 1] = self:addRepeaterRow("vanillaTrait",
        "UI_PNC_UniqueNPCEditor_AddVanillaTrait", "Vanilla trait",
        { self.vanillaTraitCombo }, "UI_PNC_UniqueNPCEditor_Add",
        "traits.physiological")
    self.dynamicTraitCombo = newCombo(self.controlParent, nil)
    self.addRows[#self.addRows + 1] = self:addRepeaterRow("dynamicTrait",
        "UI_PNC_UniqueNPCEditor_AddDynamicTrait", "Dynamic trait",
        { self.dynamicTraitCombo }, "UI_PNC_UniqueNPCEditor_Add",
        "traits.dynamic")

    self.controlParent = nil
    self.sectionLabels = {
        identity = addLabel(self.formView,
            tr("UI_PNC_NPCAuthoring_IdentitySection", "IDENTITY")),
        background = addLabel(self.formView,
            tr("UI_PNC_NPCAuthoring_BackgroundSection", "BACKGROUND")),
        skills = addLabel(self.formView,
            tr("UI_PNC_NPCAuthoring_SkillsSection", "SKILLS")),
        traits = addLabel(self.formView,
            tr("UI_PNC_NPCAuthoring_TraitsSection", "TRAITS")),
    }
    for _, label in pairs(self.sectionLabels) do
        label:setVisible(self.presentationMode == "companion")
    end

    do
        self.configuredDetails = UI.CreateList(self.pages.attributes, {
            itemHeight = Layout.Pixels(25, self.uiScale),
            doDrawItem = drawDetail,
        })
        self.removeConfiguredButton = UI.CreateButton(self.pages.attributes, {
            id = "remove_configured",
            title = tr("UI_PNC_UniqueNPCEditor_Remove", "REMOVE"),
            target = self,
            onclick = ISPNCNPCAuthoringEditor.onAction,
            variant = "quiet",
        })
        self.configuredDetails:setVisible(false)
        self.removeConfiguredButton:setVisible(false)
    end

    self:buildAttributeGroups()

    self.relationshipDetails = UI.CreateList(self.pages.relations, {
        itemHeight = Layout.Pixels(32, self.uiScale), virtualized = false,
        doDrawItem = PNC.NPCAuthoringRelationshipPresentation.DrawRow,
    })
    self.details = UI.CreateList(self.pages.relations, {
        itemHeight = Layout.Pixels(25, self.uiScale),
        doDrawItem = drawDetail,
    })
    self.removeButton = UI.CreateButton(self.pages.relations, {
        id = "remove_detail",
        title = tr("UI_PNC_UniqueNPCEditor_Remove", "REMOVE"),
        target = self,
        onclick = ISPNCNPCAuthoringEditor.onAction,
        variant = "quiet",
    })
    self.resetDetailsButton = UI.CreateButton(self.pages.relations, {
        id = "reset_details",
        title = tr("UI_PNC_UniqueNPCEditor_ResetDetails", "RESET DETAILS"),
        target = self,
        onclick = ISPNCNPCAuthoringEditor.onAction,
        variant = "quiet",
    })
    if self.presentationMode == "companion" then
        self.inspectorButton = UI.CreateButton(self.pages.relations, {
            id = "inspector", title = tr("UI_PNC_Authoring_AdvancedDetails", "Advanced details"),
            target = self, onclick = ISPNCNPCAuthoringEditor.onAction, variant = "quiet",
        })
    end
    self:buildTabRandomizers()
    self.statusLabel = addLabel(self, "")
end

local function buildEditorPortrait(self)
    self.portraitPanel = UI.PortraitPanel:new(0, 0, 260, 390, {
        zoom = -3,
        yOffset = 0,
        direction = IsoDirections and IsoDirections.S,
        portraitAnimation = true,
        stateName = "idle",
        animate = true,
    })
    self.portraitPanel:initialise()
    self.portraitPanel:instantiate()
    self:addChild(self.portraitPanel)
    self.portraitControls = {}
    for _, spec in ipairs({
        { "rotate_left", "<", "UI_PNC_Authoring_RotateLeft", "Rotate left" },
        { "rotate_right", ">", "UI_PNC_Authoring_RotateRight", "Rotate right" },
        { "zoom_out", "-", "UI_PNC_Authoring_ZoomOut", "Zoom out" },
        { "zoom_in", "+", "UI_PNC_Authoring_ZoomIn", "Zoom in" },
    }) do
        local button = UI.CreateButton(self, { id = spec[1], title = spec[2],
            target = self, onclick = ISPNCNPCAuthoringEditor.onAction, variant = "quiet" })
        button.tooltip = tr(spec[3], spec[4])
        self.portraitControls[#self.portraitControls + 1] = button
    end
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

function ISPNCNPCAuthoringEditor:buildAuthoringEditorBody()
    if not self.presentationMode then self.presentationMode = "debug" end
    initializeEditorState(self)
    buildEditorToolbar(self)
    buildEditorTabs(self)
    self:buildRoster()
    buildEditorForm(self)
    buildEditorPortrait(self)
    self:buildLoadoutPage()
    refreshEditorOptions(self)
    if self.presentationMode == "companion" then
        self.fileLabel:setVisible(false)
        self.fileCombo:setVisible(false)
        self.details:setVisible(false)
        self.removeButton:setVisible(false)
        self.resetDetailsButton:setVisible(false)
        self.inspectorVisible = false
        self:refreshDetails()
    end
end


