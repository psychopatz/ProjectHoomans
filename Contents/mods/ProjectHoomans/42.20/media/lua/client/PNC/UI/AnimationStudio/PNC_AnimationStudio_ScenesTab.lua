-- Unified Scenes tab for Animation Studio.
-- Combines Single-NPC Scenes (all 42 registered scenes: cigar/smoke, eat,
-- drink, sit, campfire, prop override, pool roll/auto-cycle) and Multi-Actor
-- Scenes (Choreography choreography studio) behind a [Single-NPC | Multi-Actor]
-- scope toggle.

require "ISUI/ISPanel"
require "ISUI/ISComboBox"
require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/Debug/PNC_AnimationSceneDebugModel"

PNC = PNC or {}
PNC.AnimationStudioTabs = PNC.AnimationStudioTabs or {}

local UI = PsychopatzCore.UI
local Layout = UI.Layout
local addDetail = UI.AddKeyValue
local SceneModel = PNC.AnimationSceneDebugModel

local function tr(key, fallback)
    local translation = PNC.Translation
    local value = translation and translation.GetKey
        and translation.GetKey(key, fallback) or fallback
    if not value or value == "" or value == key then return fallback end
    return value
end

local function setButtonState(button, title, variant)
    if not button then return end
    if button.setTitle then button:setTitle(title) else button.title = title end
    if UI.SetButtonVariant then UI.SetButtonVariant(button, variant) end
end

local function drawSingleSceneRow(list, y, row, alternate)
    local scene = row.item
    local selected = list.selected == row.index
    if selected then
        list:drawRect(0, y, list:getWidth(), list.itemheight, 0.35, 0.20, 0.52, 0.78)
    elseif alternate then
        list:drawRect(0, y, list:getWidth(), list.itemheight, 0.12, 0.16, 0.18, 0.20)
    end
    list:drawText(tostring(scene.label or scene.id), 8, y + 4, 0.92, 0.94, 1.00, 1, UIFont.Small)
    list:drawText(tostring(scene.id) .. " -> PNC_" .. tostring(scene.bump),
        8, y + 20, 0.58, 0.82, 0.95, 1, UIFont.Small)
    list:drawText("category=" .. tostring(scene.category)
        .. "  pool=" .. tostring(scene.pool or "-")
        .. "  weight=" .. tostring(scene.weight),
        8, y + 36, 0.70, 0.72, 0.74, 1, UIFont.Small)
    return y + list.itemheight
end

local PROP_PRESETS = {
    { label = "Prop: None", data = "" },
    { label = "Prop: Base.Cigarettes", data = "Base.Cigarettes" },
    { label = "Prop: Base.Apple", data = "Base.Apple" },
    { label = "Prop: Base.WaterBottleFull", data = "Base.WaterBottleFull" },
    { label = "Prop: Base.Bandage", data = "Base.Bandage" },
    { label = "Prop: Base.Hammer", data = "Base.Hammer" },
    { label = "Prop: Base.Axe", data = "Base.Axe" },
    { label = "Prop: Base.Book", data = "Base.Book" },
    { label = "Prop: Base.KitchenKnife", data = "Base.KitchenKnife" },
    { label = "Prop: Base.Pistol", data = "Base.Pistol" },
    { label = "Prop: Base.HuntingRifle", data = "Base.HuntingRifle" },
    { label = "Prop: Base.Bowl", data = "Base.Bowl" },
    { label = "Prop: Base.Flashlight", data = "Base.Flashlight" },
}

ISPNCAnimationStudioScenesTab = ISPanel:derive("ISPNCAnimationStudioScenesTab")

function ISPNCAnimationStudioScenesTab:initialise()
    ISPanel.initialise(self)
    self:noBackground()
end

function ISPNCAnimationStudioScenesTab:createChildren()
    ISPanel.createChildren(self)
    self.scope = "single"
    self.singleScenes = {}

    self.singleBtn = UI.CreateButton(self, {
        title = tr("UI_PNC_AnimationStudio_SingleScenes", "Single-NPC Scenes"),
        target = self,
        onclick = UI.ButtonCallback(function() self:setScope("single") end),
        variant = "selected",
    })
    self.multiBtn = UI.CreateButton(self, {
        title = tr("UI_PNC_AnimationStudio_MultiScenes", "Multi-Actor Scenes"),
        target = self,
        onclick = UI.ButtonCallback(function() self:setScope("multi") end),
        variant = "quiet",
    })

    self:buildSinglePanel()
    self:onResponsiveLayout()
end

function ISPNCAnimationStudioScenesTab:buildSinglePanel()
    local p = ISPanel:new(0, 0, 1, 1)
    p:initialise()
    p:noBackground()
    p:instantiate()
    self:addChild(p)
    self.singlePanel = p

    p.search = UI.CreateSearchEntry(p, {
        clearButton = true,
        width = 160,
        height = 26,
        onTextChange = function() self:refreshSingleCatalog() end,
    })
    p.groupFilter = ISComboBox:new(0, 0, 180, 26, self,
        ISPNCAnimationStudioScenesTab.onSingleGroupChanged)
    p.groupFilter:initialise()
    p.groupFilter:instantiate()
    p:addChild(p.groupFilter)

    p.gapEntry = UI.CreateTextEntry(p, {
        text = "750",
        width = 80,
        height = 26,
        onlyNumbers = true,
    })

    p.propCombo = ISComboBox:new(0, 0, 180, 26, self)
    p.propCombo:initialise()
    p.propCombo:instantiate()
    for _, preset in ipairs(PROP_PRESETS) do
        p.propCombo:addOptionWithData(preset.label, preset.data)
    end
    p.propCombo.selected = 1
    p:addChild(p.propCombo)

    p.propCustom = UI.CreateTextEntry(p, {
        text = "",
        width = 160,
        height = 26,
    })
    p.propHand = ISComboBox:new(0, 0, 130, 26, self)
    p.propHand:initialise()
    p.propHand:instantiate()
    p.propHand:addOptionWithData("Hand: Primary", "primary")
    p.propHand:addOptionWithData("Hand: Secondary", "secondary")
    p.propHand:addOptionWithData("Hand: Both", "both")
    p.propHand.selected = 1
    p:addChild(p.propHand)

    p.list = UI.CreateList(p, {
        itemHeight = 54,
        doDrawItem = drawSingleSceneRow,
        onMouseDown = function() self:refreshSingleDetails() end,
    })
    p.detail = UI.CreateKeyValueList(p, {
        itemHeight = 26,
        valueXMax = 150,
        valueXRatio = 0.34,
        ellipsize = false,
        labelX = 8,
        labelY = 6,
        valueY = 6,
        labelColor = { r = 0.62, g = 0.72, b = 0.80, a = 1 },
        valueColor = { r = 0.92, g = 0.92, b = 0.92, a = 1 },
        warningColor = { r = 1.0, g = 0.56, b = 0.30, a = 1 },
        alternateColor = { r = 0.16, g = 0.18, b = 0.20, a = 1 },
        alternateAlpha = 0.12,
        drawSelection = false,
    })

    p.buttons = {}
    for _, def in ipairs({
        { "play", tr("UI_PNC_AnimationStudio_PlayScene", "Play Scene"), "selected" },
        { "roll", tr("UI_PNC_AnimationStudio_RollPool", "Roll Pool Once"), "quiet" },
        { "cycle", tr("UI_PNC_AnimationStudio_AutoCycle", "Auto Cycle Pool"), "quiet" },
        { "stop", tr("UI_PNC_AnimationStudio_StopScene", "Stop Scene / Clear"), "danger" },
    }) do
        p.buttons[def[1]] = UI.CreateButton(p, {
            id = def[1],
            title = def[2],
            variant = def[3],
            target = self,
            onclick = UI.ButtonCallback(function(btn) self:onSingleAction(btn) end),
        })
    end

    self:rebuildSingleGroups()
    self:refreshSingleCatalog()
end

function ISPNCAnimationStudioScenesTab:ensureMultiPanel()
    if self.multiPanel then return self.multiPanel end
    require "PNC/UI/Choreography/PNC_ChoreographyDebugWindow"
    local WindowAPI = PNC.ChoreographyDebugWindow
    local Internal = WindowAPI and WindowAPI.Internal or nil
    if not Internal or not ISPNCChoreographyDebugWindow then return nil end

    -- Host the multi-actor builder natively as an embedded ISPanel without a
    -- nested window titlebar or resize chrome.
    local host = ISPanel:new(0, 0, 1, 1)
    host:initialise()
    host:noBackground()
    host:instantiate()
    host._embedded = true
    host.uiScale = self.host and self.host.uiScale or 1
    host.titleBarHeight = function() return 0 end
    host.resizeWidgetHeight = function() return 0 end
    host.requestResponsiveLayout = function(panel)
        if ISPNCChoreographyDebugWindow.onResponsiveLayout then
            ISPNCChoreographyDebugWindow.onResponsiveLayout(panel)
        end
    end
    for k, fn in pairs(ISPNCChoreographyDebugWindow) do
        if type(fn) == "function"
            and k ~= "new" and k ~= "initialise" and k ~= "close"
        then
            host[k] = fn
        end
    end
    self:addChild(host)
    ISPNCChoreographyDebugWindow.createChildren(host)
    -- Remove the duplicate NPC/Player clip tabs inside Multi-Actor since Tab 1
    -- (Clips) owns clip browsing for the entire studio.
    if host.tabPanel and host.tabPanel.removeView then
        if host.playerAnimationTab then
            host.tabPanel:removeView(host.playerAnimationTab)
        end
        if host.npcAnimationTab then
            host.tabPanel:removeView(host.npcAnimationTab)
        end
    end
    if Internal.Model and Internal.Model.ResetEditorSelection then
        Internal.Model.ResetEditorSelection()
    end
    if Internal.Model and Internal.Model.ClearActorBindings then
        Internal.Model.ClearActorBindings()
    end
    self.multiPanel = host
    if host.refreshViews then host:refreshViews() end
    if Internal.Client and Internal.Client.Refresh then
        Internal.Client.Refresh()
    end
    return host
end

function ISPNCAnimationStudioScenesTab:setScope(scope)
    self.scope = scope == "multi" and "multi" or "single"
    if self.scope == "multi" then
        self:ensureMultiPanel()
    end
    setButtonState(self.singleBtn, tr("UI_PNC_AnimationStudio_SingleScenes", "Single-NPC Scenes"),
        self.scope == "single" and "selected" or "quiet")
    setButtonState(self.multiBtn, tr("UI_PNC_AnimationStudio_MultiScenes", "Multi-Actor Scenes"),
        self.scope == "multi" and "selected" or "quiet")
    if self.singlePanel then self.singlePanel:setVisible(self.scope == "single") end
    if self.multiPanel then self.multiPanel:setVisible(self.scope == "multi") end
    self:onResponsiveLayout()
end

function ISPNCAnimationStudioScenesTab:rebuildSingleGroups()
    local p = self.singlePanel
    if not p or not p.groupFilter or not SceneModel then return end
    p.groupFilter:clear()
    local groups = SceneModel.GetGroups and SceneModel.GetGroups() or {}
    if #groups == 0 then
        p.groupFilter:addOptionWithData("All scenes", { kind = "all", label = "All scenes" })
    else
        for _, g in ipairs(groups) do
            p.groupFilter:addOptionWithData(tostring(g.label or g.key or "All scenes"), g)
        end
    end
    p.groupFilter.selected = 1
end

function ISPNCAnimationStudioScenesTab:onSingleGroupChanged()
    self:refreshSingleCatalog()
end

function ISPNCAnimationStudioScenesTab:refreshSingleCatalog()
    local p = self.singlePanel
    if not p or not p.list or not SceneModel then return end
    local group = p.groupFilter and p.groupFilter:getOptionData(p.groupFilter.selected)
        or { kind = "all" }
    local query = tostring(p.search and p.search:getText() or "")
    local scenes = SceneModel.GetScenes and SceneModel.GetScenes(query, group) or {}
    self.singleScenes = scenes
    p.list:clear()
    for _, scene in ipairs(scenes) do
        p.list:addItem(tostring(scene.label or scene.id), scene)
    end
    if #p.list.items > 0 then p.list.selected = 1 end
    self:refreshSingleDetails()
end

function ISPNCAnimationStudioScenesTab:selectedSingleScene()
    local p = self.singlePanel
    if not p or not p.list or not p.list.items then return nil end
    local row = p.list.items[p.list.selected]
    return row and row.item or nil
end

function ISPNCAnimationStudioScenesTab:selectedPropPayload()
    local p = self.singlePanel
    if not p then return nil, nil end
    local custom = tostring(p.propCustom and p.propCustom:getText() or "")
    custom = custom:match("^%s*(.-)%s*$") or ""
    local itemType = custom
    if itemType == "" and p.propCombo and p.propCombo.getOptionData then
        itemType = tostring(p.propCombo:getOptionData(p.propCombo.selected) or "")
    end
    if itemType == "" then return nil, nil end
    local hand = p.propHand and p.propHand:getOptionData(p.propHand.selected) or "primary"
    local primary = (hand == "primary" or hand == "both") and itemType or nil
    local secondary = (hand == "secondary" or hand == "both") and itemType or nil
    return primary, secondary
end

function ISPNCAnimationStudioScenesTab:sendSingleDebug(action, payload)
    local npcId = self.host and self.host.npcId or ""
    if npcId == "" or not PNC.Client or not PNC.Client.SendDebug then return end
    payload = payload or {}
    payload.id = npcId
    PNC.Client.SendDebug(action, payload)
end

function ISPNCAnimationStudioScenesTab:onSingleAction(button)
    local id = button and button.internal or ""
    local scene = self:selectedSingleScene()
    if id == "play" and scene then
        local propPrimary, propSecondary = self:selectedPropPayload()
        self:sendSingleDebug("animation_scene_play", {
            sceneId = scene.id,
            propPrimary = propPrimary,
            propSecondary = propSecondary,
        })
    elseif id == "roll" then
        local pool = scene and scene.pool or nil
        if pool then
            self:sendSingleDebug("animation_scene_pool_step", { pool = pool })
        end
    elseif id == "cycle" then
        local pool = scene and scene.pool or nil
        local gap = tonumber(self.singlePanel and self.singlePanel.gapEntry
            and self.singlePanel.gapEntry:getText()) or 750
        if pool then
            self:sendSingleDebug("animation_scene_pool_start", {
                pool = pool,
                gapMs = gap,
            })
        end
    elseif id == "stop" then
        self:sendSingleDebug("animation_scene_stop", {})
    end
    self:refreshSingleDetails()
end

function ISPNCAnimationStudioScenesTab:refreshSingleDetails()
    local p = self.singlePanel
    if not p or not p.detail then return end
    local scene = self:selectedSingleScene()
    p.detail:clear()
    addDetail(p.detail, "Target NPC", tostring(self.host and self.host.npcName or "None"))
    if not scene then
        addDetail(p.detail, "Scene", "No scene selected", true)
    else
        addDetail(p.detail, "Scene ID", tostring(scene.id))
        addDetail(p.detail, "Label", tostring(scene.label or "-"))
        addDetail(p.detail, "Description", tostring(scene.description or "-"))
        addDetail(p.detail, "Category", tostring(scene.category or "-"))
        addDetail(p.detail, "Pool", tostring(scene.pool or "-"))
        addDetail(p.detail, "Bump", tostring(scene.bump or "-"))
        if scene.propPrimary or scene.propSecondary then
            addDetail(p.detail, "Default Props", tostring(scene.propPrimary or "-")
                .. " / " .. tostring(scene.propSecondary or "-"))
        end
    end
    local hasNpc = self.host and tostring(self.host.npcId or "") ~= ""
    local hasPool = scene and scene.pool and tostring(scene.pool) ~= ""
    if p.buttons then
        if p.buttons.play then p.buttons.play:setEnable(hasNpc and scene ~= nil) end
        if p.buttons.roll then p.buttons.roll:setEnable(hasNpc and hasPool == true) end
        if p.buttons.cycle then p.buttons.cycle:setEnable(hasNpc and hasPool == true) end
        if p.buttons.stop then p.buttons.stop:setEnable(hasNpc) end
    end
end

function ISPNCAnimationStudioScenesTab:setContext(host)
    self.host = host
    self:refreshSingleDetails()
    if self.multiPanel and self.multiPanel.refreshViews then
        self.multiPanel:refreshViews()
    end
end

function ISPNCAnimationStudioScenesTab:update()
    ISPanel.update(self)
    if self.scope == "multi" and self.multiPanel and self.multiPanel.update then
        self.multiPanel:update()
    end
end

function ISPNCAnimationStudioScenesTab:onResponsiveLayout()
    local w = math.max(1, self.width)
    local h = math.max(1, self.height)
    local pad = 8
    local btnH = 26
    local btnW = 156
    Layout.SetBounds(self.singleBtn, pad, pad, btnW, btnH)
    Layout.SetBounds(self.multiBtn, pad + btnW + 6, pad, btnW, btnH)

    local bodyY = pad + btnH + 8
    local bodyH = math.max(1, h - bodyY - pad)
    local bodyW = math.max(1, w - pad * 2)

    local p = self.singlePanel
    if p then
        Layout.SetBounds(p, pad, bodyY, bodyW, bodyH)
        local gapW = 72
        local grpW = math.min(220, math.max(130, math.floor(bodyW * 0.25)))
        local searchW = math.max(100, bodyW - grpW - gapW - 12)
        Layout.SetBounds(p.search, 0, 0, searchW, btnH)
        Layout.SetBounds(p.groupFilter, searchW + 6, 0, grpW, btnH)
        Layout.SetBounds(p.gapEntry, bodyW - gapW, 0, gapW, btnH)

        local row2Y = btnH + 6
        local handW = 130
        local presetW = math.min(240, math.max(150, math.floor(bodyW * 0.35)))
        local customW = math.max(100, bodyW - presetW - handW - 12)
        Layout.SetBounds(p.propCombo, 0, row2Y, presetW, btnH)
        Layout.SetBounds(p.propCustom, presetW + 6, row2Y, customW, btnH)
        Layout.SetBounds(p.propHand, bodyW - handW, row2Y, handW, btnH)

        local footerY = bodyH - btnH
        local listY = row2Y + btnH + 8
        local listH = math.max(80, footerY - listY - 8)
        local listW = math.max(240, math.floor(bodyW * 0.56))
        Layout.SetBounds(p.list, 0, listY, listW, listH)
        Layout.SetBounds(p.detail, listW + 8, listY, math.max(120, bodyW - listW - 8), listH)

        local order = { "play", "roll", "cycle", "stop" }
        local bW = math.max(96, math.floor((bodyW - 6 * (#order - 1)) / #order))
        for i, key in ipairs(order) do
            Layout.SetBounds(p.buttons[key], (i - 1) * (bW + 6), footerY, bW, btnH)
        end
    end

    if self.multiPanel then
        Layout.SetBounds(self.multiPanel, pad, bodyY, bodyW, bodyH)
        if self.multiPanel.onResponsiveLayout then
            self.multiPanel:onResponsiveLayout()
        end
    end
end

function ISPNCAnimationStudioScenesTab:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    return o
end

return ISPNCAnimationStudioScenesTab
