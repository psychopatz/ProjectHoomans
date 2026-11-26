-- Unified Clips tab for Animation Studio.
-- Combines Selected NPC clip preview and Local Player clip preview behind a
-- single [Selected NPC | Local Player] mode switch. Both large clip catalogs
-- remain lazy-loaded on first use.

require "ISUI/ISPanel"
require "ISUI/ISComboBox"
require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.AnimationStudioTabs = PNC.AnimationStudioTabs or {}

local UI = PsychopatzCore.UI
local Layout = UI.Layout
local addDetail = UI.AddKeyValue

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

local function drawPlayerClipRow(list, y, row, alternate)
    local entry = row.item
    local selected = list.selected == row.index
    if selected then
        list:drawRect(0, y, list:getWidth(), list.itemheight, 0.35, 0.20, 0.52, 0.78)
    elseif alternate then
        list:drawRect(0, y, list:getWidth(), list.itemheight, 0.12, 0.16, 0.18, 0.20)
    end
    local title = "[" .. tostring(entry.state or "?") .. "] " .. tostring(entry.node or entry.anim or "?")
    local clip = tostring(entry.anim or "(no clip)")
    list:drawText(title, 8, y + 4, 0.92, 0.94, 1.00, 1, UIFont.Small)
    list:drawText(clip, 8, y + 20, 0.58, 0.82, 0.95, 1, UIFont.Small)
    list:drawText(tostring(entry.file or ""), 8, y + 36, 0.68, 0.72, 0.76, 1, UIFont.Small)
    return y + list.itemheight
end

ISPNCAnimationStudioClipsTab = ISPanel:derive("ISPNCAnimationStudioClipsTab")

function ISPNCAnimationStudioClipsTab:initialise()
    ISPanel.initialise(self)
    self:noBackground()
end

function ISPNCAnimationStudioClipsTab:createChildren()
    ISPanel.createChildren(self)
    self.mode = "npc"
    self.playerSource = "player"
    self.playerLoop = false
    self.playerEntries = {}

    self.modeNpcBtn = UI.CreateButton(self, {
        title = tr("UI_PNC_AnimationStudio_ModeNPC", "Selected NPC"),
        target = self,
        onclick = UI.ButtonCallback(function() self:setMode("npc") end),
        variant = "selected",
    })
    self.modePlayerBtn = UI.CreateButton(self, {
        title = tr("UI_PNC_AnimationStudio_ModePlayer", "Local Player"),
        target = self,
        onclick = UI.ButtonCallback(function() self:setMode("player") end),
        variant = "quiet",
    })

    self:ensureNpcPanel()
    self:onResponsiveLayout()
end

function ISPNCAnimationStudioClipsTab:ensureNpcPanel()
    if self.npcPanel then return self.npcPanel end
    require "PNC/Debug/PNC_AnimationDebugPlayer"
    require "PNC/UI/AnimationStudio/PNC_AnimationStudio_NPCClipsPanel"
    self.npcPanel = ISPNCNPCPresentationDebugAnimationTab:new(0, 0, 1, 1)
    self.npcPanel:initialise()
    self.npcPanel:instantiate()
    self:addChild(self.npcPanel)
    if self.host and self.npcPanel.setContext then
        self.npcPanel:setContext(self.host)
    end
    return self.npcPanel
end

function ISPNCAnimationStudioClipsTab:ensurePlayerPanel()
    if self.playerPanel then return self.playerPanel end
    require "PNC/Debug/PNC_PlayerAnimationDebug"
    require "PNC/Debug/PNC_PlayerAnimationDebugCatalog"

    local panel = ISPanel:new(0, 0, 1, 1)
    panel:initialise()
    panel:noBackground()
    panel:instantiate()
    self:addChild(panel)
    self.playerPanel = panel

    panel.srcPlayerBtn = UI.CreateButton(panel, {
        title = tr("UI_PNC_PlayerAnimation_PlayerTab", "PLAYER"),
        target = self,
        onclick = UI.ButtonCallback(function() self:setPlayerSource("player") end),
        variant = "selected",
    })
    panel.srcZombieBtn = UI.CreateButton(panel, {
        title = tr("UI_PNC_PlayerAnimation_ZombieTab", "ZOMBIE"),
        target = self,
        onclick = UI.ButtonCallback(function() self:setPlayerSource("zombie") end),
        variant = "quiet",
    })
    panel.search = UI.CreateSearchEntry(panel, {
        clearButton = true,
        width = 160,
        height = 26,
        onTextChange = function() self:refreshPlayerCatalog() end,
    })
    panel.categoryCombo = ISComboBox:new(0, 0, 180, 26, self,
        ISPNCAnimationStudioClipsTab.onPlayerCategoryChanged)
    panel.categoryCombo:initialise()
    panel.categoryCombo:instantiate()
    panel:addChild(panel.categoryCombo)

    panel.list = UI.CreateList(panel, {
        itemHeight = 54,
        doDrawItem = drawPlayerClipRow,
        onMouseDown = function() self:refreshPlayerDetails() end,
    })
    panel.detail = UI.CreateKeyValueList(panel, {
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

    panel.buttons = {}
    for _, def in ipairs({
        { "play", tr("UI_PNC_PlayerAnimation_Play", "PLAY"), "selected" },
        { "replay", tr("UI_PNC_PlayerAnimation_Replay", "REPLAY"), "quiet" },
        { "loop", tr("UI_PNC_PlayerAnimation_Loop", "LOOP: OFF"), "quiet" },
        { "stop", tr("UI_PNC_PlayerAnimation_Stop", "STOP / RESTORE"), "danger" },
        { "dump", tr("UI_PNC_PlayerAnimation_Dump", "DUMP TRACE"), "quiet" },
    }) do
        panel.buttons[def[1]] = UI.CreateButton(panel, {
            id = def[1],
            title = def[2],
            variant = def[3],
            target = self,
            onclick = UI.ButtonCallback(function(btn) self:onPlayerAction(btn) end),
        })
    end

    self:rebuildPlayerCategories()
    self:refreshPlayerCatalog()
    return panel
end

function ISPNCAnimationStudioClipsTab:setMode(mode)
    self.mode = mode == "player" and "player" or "npc"
    if self.mode == "player" then
        self:ensurePlayerPanel()
    else
        self:ensureNpcPanel()
    end
    setButtonState(self.modeNpcBtn, tr("UI_PNC_AnimationStudio_ModeNPC", "Selected NPC"),
        self.mode == "npc" and "selected" or "quiet")
    setButtonState(self.modePlayerBtn, tr("UI_PNC_AnimationStudio_ModePlayer", "Local Player"),
        self.mode == "player" and "selected" or "quiet")
    if self.npcPanel then self.npcPanel:setVisible(self.mode == "npc") end
    if self.playerPanel then self.playerPanel:setVisible(self.mode == "player") end
    self:onResponsiveLayout()
end

function ISPNCAnimationStudioClipsTab:setPlayerSource(source)
    self.playerSource = source == "zombie" and "zombie" or "player"
    local p = self.playerPanel
    if p then
        setButtonState(p.srcPlayerBtn, tr("UI_PNC_PlayerAnimation_PlayerTab", "PLAYER"),
            self.playerSource == "player" and "selected" or "quiet")
        setButtonState(p.srcZombieBtn, tr("UI_PNC_PlayerAnimation_ZombieTab", "ZOMBIE"),
            self.playerSource == "zombie" and "selected" or "quiet")
    end
    self:rebuildPlayerCategories()
    self:refreshPlayerCatalog()
end

function ISPNCAnimationStudioClipsTab:onPlayerCategoryChanged()
    self:refreshPlayerCatalog()
end

local function playerCatalogEntries(source)
    local Catalog = PNC.PlayerAnimationDebugCatalog
    local all = Catalog and Catalog.entries or {}
    local out = {}
    local wantZombie = source == "zombie"
    for _, entry in ipairs(all) do
        local isZombie = entry and entry.source == "zombie"
        if isZombie == wantZombie then
            out[#out + 1] = entry
        end
    end
    return out
end

function ISPNCAnimationStudioClipsTab:rebuildPlayerCategories()
    local p = self.playerPanel
    if not p or not p.categoryCombo then return end
    p.categoryCombo:clear()
    local all = playerCatalogEntries(self.playerSource)
    local seen = {}
    local states = {}
    for _, entry in ipairs(all) do
        local st = tostring(entry.state or "other")
        if not seen[st] then
            seen[st] = 0
            states[#states + 1] = st
        end
        seen[st] = seen[st] + 1
    end
    table.sort(states)
    p.categoryCombo:addOptionWithData("All (" .. tostring(#all) .. ")", "__all__")
    for _, st in ipairs(states) do
        p.categoryCombo:addOptionWithData(st .. " (" .. tostring(seen[st]) .. ")", st)
    end
    p.categoryCombo.selected = 1
end

function ISPNCAnimationStudioClipsTab:refreshPlayerCatalog()
    local p = self.playerPanel
    if not p or not p.list then return end
    local all = playerCatalogEntries(self.playerSource)
    local query = string.lower(tostring(p.search and p.search:getText() or ""))
    local cat = p.categoryCombo and p.categoryCombo:getOptionData(p.categoryCombo.selected) or "__all__"
    p.list:clear()
    for _, entry in ipairs(all) do
        local st = tostring(entry.state or "other")
        local matchesCat = cat == "__all__" or st == cat
        if matchesCat then
            local hay = string.lower(st .. " " .. tostring(entry.node or "")
                .. " " .. tostring(entry.anim or "") .. " " .. tostring(entry.file or ""))
            if query == "" or string.find(hay, query, 1, true) then
                p.list:addItem(tostring(entry.node or entry.anim or "?"), entry)
            end
        end
    end
    if #p.list.items > 0 then p.list.selected = 1 end
    self:refreshPlayerDetails()
end

function ISPNCAnimationStudioClipsTab:selectedPlayerEntry()
    local p = self.playerPanel
    if not p or not p.list or not p.list.items then return nil end
    local row = p.list.items[p.list.selected]
    return row and row.item or nil
end

function ISPNCAnimationStudioClipsTab:refreshPlayerDetails()
    local p = self.playerPanel
    if not p or not p.detail then return end
    local entry = self:selectedPlayerEntry()
    p.detail:clear()
    if not entry then
        addDetail(p.detail, "Selection", "No animation selected", true)
    else
        addDetail(p.detail, "State", tostring(entry.state or "-"))
        addDetail(p.detail, "Node", tostring(entry.node or "-"))
        addDetail(p.detail, "Clip", tostring(entry.anim or "(none)"))
        addDetail(p.detail, "Route", tostring(entry.route or "-"))
        addDetail(p.detail, "Action / Emote", tostring(entry.action or entry.emote or "-"))
        addDetail(p.detail, "File", tostring(entry.file or "-"))
        addDetail(p.detail, "Loop", self.playerLoop and "ON" or "OFF")
    end
end

function ISPNCAnimationStudioClipsTab:onPlayerAction(button)
    local id = button and button.internal or ""
    local Debug = PNC.PlayerAnimationDebug
    local entry = self:selectedPlayerEntry()
    if id == "loop" then
        self.playerLoop = not self.playerLoop
        if Debug and Debug.SetLoopEnabled then
            Debug.SetLoopEnabled(self.playerLoop)
        end
        setButtonState(self.playerPanel and self.playerPanel.buttons.loop,
            self.playerLoop and "LOOP: ON" or "LOOP: OFF",
            self.playerLoop and "selected" or "quiet")
        self:refreshPlayerDetails()
        return
    end
    if not Debug then return end
    if id == "play" and entry and Debug.Play then
        if Debug.SetLoopEnabled then Debug.SetLoopEnabled(self.playerLoop) end
        Debug.Play(entry)
    elseif id == "replay" and Debug.Replay then
        if Debug.SetLoopEnabled then Debug.SetLoopEnabled(self.playerLoop) end
        Debug.Replay()
    elseif id == "stop" and Debug.Stop then
        Debug.Stop("animation_studio_stop")
    elseif id == "dump" and Debug.Dump then
        Debug.Dump()
    end
    self:refreshPlayerDetails()
end

function ISPNCAnimationStudioClipsTab:setContext(host)
    self.host = host
    if self.npcPanel and self.npcPanel.setContext then
        self.npcPanel:setContext(host)
    end
end

function ISPNCAnimationStudioClipsTab:onResponsiveLayout()
    local w = math.max(1, self.width)
    local h = math.max(1, self.height)
    local pad = 8
    local btnH = 26
    local btnW = 132
    Layout.SetBounds(self.modeNpcBtn, pad, pad, btnW, btnH)
    Layout.SetBounds(self.modePlayerBtn, pad + btnW + 6, pad, btnW, btnH)

    local bodyY = pad + btnH + 8
    local bodyH = math.max(1, h - bodyY - pad)
    local bodyW = math.max(1, w - pad * 2)
    if self.npcPanel then
        Layout.SetBounds(self.npcPanel, pad, bodyY, bodyW, bodyH)
        if self.npcPanel.onResponsiveLayout then
            self.npcPanel:onResponsiveLayout()
        end
    end
    local p = self.playerPanel
    if p then
        Layout.SetBounds(p, pad, bodyY, bodyW, bodyH)
        local row1Y = 0
        Layout.SetBounds(p.srcPlayerBtn, 0, row1Y, 96, btnH)
        Layout.SetBounds(p.srcZombieBtn, 102, row1Y, 96, btnH)
        local catW = math.min(240, math.max(140, math.floor(bodyW * 0.28)))
        local searchX = 206
        local searchW = math.max(100, bodyW - searchX - catW - 6)
        Layout.SetBounds(p.search, searchX, row1Y, searchW, btnH)
        Layout.SetBounds(p.categoryCombo, bodyW - catW, row1Y, catW, btnH)

        local footerY = bodyH - btnH
        local listY = btnH + 8
        local listH = math.max(80, footerY - listY - 8)
        local listW = math.max(220, math.floor(bodyW * 0.56))
        Layout.SetBounds(p.list, 0, listY, listW, listH)
        Layout.SetBounds(p.detail, listW + 8, listY, math.max(120, bodyW - listW - 8), listH)

        local order = { "play", "replay", "loop", "stop", "dump" }
        local bW = math.max(84, math.floor((bodyW - 6 * (#order - 1)) / #order))
        for i, key in ipairs(order) do
            Layout.SetBounds(p.buttons[key], (i - 1) * (bW + 6), footerY, bW, btnH)
        end
    end
end

function ISPNCAnimationStudioClipsTab:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    return o
end

return ISPNCAnimationStudioClipsTab
