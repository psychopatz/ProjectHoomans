-- Existing animation catalogs presented as assignable Puppet Opera tracks.

require "ISUI/ISPanel"
require "ISUI/ISComboBox"
require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}

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

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function conditionText(condition)
    return tostring(condition.name or "?") .. "="
        .. tostring(condition.value or "?")
end

local function selectorText(entry)
    local values = {}
    for _, condition in ipairs(entry.conditions or {}) do
        if condition.name ~= "PNCActor" and condition.name ~= "BumpType"
        then
            values[#values + 1] = conditionText(condition)
        end
    end
    return table.concat(values, ", ")
end

local function drawCatalogItem(list, y, row, alternate)
    local entry = row.item
    local selected = list.selected == row.index
    if selected then
        list:drawRect(0, y, list:getWidth(), list.itemheight,
            0.38, 0.20, 0.48, 0.82)
    elseif alternate then
        list:drawRect(0, y, list:getWidth(), list.itemheight,
            0.12, 0.16, 0.18, 0.20)
    end
    local title = tostring(entry.node or entry.file or "?")
    local clip = tostring(entry.anim or "(no direct clip)")
    local selector = selectorText(entry)
    list:drawText(title, 8, y + 4,
        entry.playable and 0.92 or 0.62,
        entry.playable and 0.94 or 0.62,
        entry.playable and 1.00 or 0.62, 1, UIFont.Small)
    list:drawText(clip, 8, y + 21,
        0.62, 0.82, 0.95, 1, UIFont.Small)
    list:drawText(
        selector ~= "" and selector or tostring(entry.path or "-"),
        8, y + 38,
        0.66, 0.70, 0.74, 1, UIFont.Small
    )
    local approved = entry.puppetOperaApproved == true
    list:drawTextRight(
        approved and "SERVER OK" or "catalog",
        list:getWidth() - 8,
        y + 4,
        approved and 0.42 or 0.70,
        approved and 0.92 or 0.72,
        approved and 0.58 or 0.72,
        1,
        UIFont.Small
    )
    return y + list.itemheight
end

ISPNCPuppetOperaAnimationTab = ISPanel:derive(
    "ISPNCPuppetOperaAnimationTab")

function ISPNCPuppetOperaAnimationTab:initialise()
    ISPanel.initialise(self)
    self:noBackground()
end

function ISPNCPuppetOperaAnimationTab:createChildren()
    ISPanel.createChildren(self)
    self.search = UI.CreateTextEntry(self, {
        clearButton = true,
        width = 100,
        height = 26,
        onTextChange = function()
            self:updateQuery()
            self:refreshCatalog()
        end,
    })
    self.filter = ISComboBox:new(0, 0, 190, 26, self,
        ISPNCPuppetOperaAnimationTab.onFilterChanged)
    self.filter:initialise()
    self.filter:instantiate()
    self:addChild(self.filter)

    self.list = UI.CreateList(self, {
        itemHeight = 56,
        doDrawItem = drawCatalogItem,
    })
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = 25,
        valueXRatio = 0.34,
        ellipsize = false,
        labelX = 8,
        labelY = 6,
        valueY = 6,
        drawSelection = false,
    })
    self.assignButton = UI.CreateButton(self, {
        id = "assign",
        title = tr("UI_PNC_PuppetOpera_AssignSelectedBeat",
            "Assign to selected beat"),
        target = self,
        onclick = UI.ButtonCallback(function(button)
            return ISPNCPuppetOperaAnimationTab.onAction(self, button)
        end),
        variant = "selected",
    })
    self.catalogName = "player"
    self.ownerWindow = nil
    self:rebuildFilter()
end

function ISPNCPuppetOperaAnimationTab:setContext(window, catalogName)
    self.ownerWindow = window
    self.catalogName = catalogName or self.catalogName
    self:rebuildFilter()
    self:refreshCatalog()
end

function ISPNCPuppetOperaAnimationTab:updateQuery()
    local model = self.ownerWindow and self.ownerWindow.model
    if not model then return end
    if self.catalogName == "player" then
        model.SetPlayerQuery(self.search:getText())
    else
        model.SetNPCQuery(self.search:getText())
    end
end

function ISPNCPuppetOperaAnimationTab:rebuildFilter()
    if not self.filter or not self.ownerWindow then return end
    self.filter:clear()
    if self.catalogName == "player" then
        self.filter:addOption(tr("UI_PNC_PuppetOpera_PlayerCatalog",
            "Player catalog"))
        self.filter:addOption(tr("UI_PNC_PuppetOpera_ZombieSourceBridges",
            "Zombie-source bridges"))
        self.filter.selected = self.ownerWindow.model.GetPlayerSource() == "zombie"
            and 2 or 1
    else
        self.filter:addOption(tr("UI_PNC_PuppetOpera_AllStates",
            "All states"))
        self.states = self.ownerWindow.model.GetNPCStates()
        for _, state in ipairs(self.states) do
            self.filter:addOption(tostring(state))
        end
        local selected = self.ownerWindow.model.GetNPCState()
        self.filter.selected = 1
        for index, state in ipairs(self.states) do
            if state == selected then self.filter.selected = index + 1 end
        end
    end
end

function ISPNCPuppetOperaAnimationTab:onFilterChanged()
    if not self.ownerWindow then return end
    if self.catalogName == "player" then
        self.ownerWindow.model.SetPlayerSource(
            tonumber(self.filter.selected) == 2 and "zombie" or "player"
        )
    else
        local selected = tonumber(self.filter.selected) or 1
        self.ownerWindow.model.SetNPCState(
            selected <= 1 and nil or self.states[selected - 1]
        )
    end
    self:refreshCatalog()
end

function ISPNCPuppetOperaAnimationTab:getSelectedEntry()
    local row = self.list and self.list:getItem() or nil
    return row and row.item or nil
end

function ISPNCPuppetOperaAnimationTab:refreshCatalog()
    if not self.list or not self.ownerWindow then return end
    local model = self.ownerWindow.model
    local previous = self:getSelectedEntry()
    local previousID = previous and (
        self.catalogName == "player"
            and model.PlayerEntryID(previous)
            or model.NPCEntryID(previous)
    ) or nil
    self.list:clear()
    local entries = self.catalogName == "player"
        and model.GetPlayerCatalogEntries()
        or model.GetNPCCatalogEntries()
    for _, entry in ipairs(entries) do
        entry.puppetOperaApproved = self.catalogName == "player"
            and model.IsPlayerEntryServerApproved(entry)
            or model.IsNPCEntryServerApproved(entry)
        self.list:addItem(
            tostring(entry.node or entry.file or "entry"),
            entry
        )
        local currentID = self.catalogName == "player"
            and model.PlayerEntryID(entry)
            or model.NPCEntryID(entry)
        if previousID and currentID == previousID then
            self.list.selected = #self.list.items
        end
    end
    if #self.list.items > 0 and (tonumber(self.list.selected) or 0) < 1 then
        self.list.selected = 1
    end
    self.visibleCount = #self.list.items
    self:refreshDetails()
end

function ISPNCPuppetOperaAnimationTab:refreshDetails()
    if not self.details then return end
    self.details:clear()
    local entry = self:getSelectedEntry()
    if not entry then
        addDetail(self.details, "Selection", "No matching catalog entry", true)
        return
    end
    local model = self.ownerWindow.model
    addDetail(self.details, "Catalog", self.catalogName)
    addDetail(self.details, "State", entry.state)
    addDetail(self.details, "Source", entry.source or entry.folder)
    addDetail(self.details, "Route", entry.route or "zombie_bump")
    addDetail(self.details, "Node", entry.node)
    addDetail(self.details, "Clip", entry.anim or "(none)", not entry.anim)
    addDetail(self.details, "File", entry.path or entry.file)
    if self.catalogName == "player" then
        addDetail(self.details, "Action", entry.action or entry.emote or "-")
        addDetail(self.details, "Mode", entry.mode)
        addDetail(self.details, "Entry ID", model.PlayerEntryID(entry))
        addDetail(self.details, "MP policy",
            model.IsPlayerEntryServerApproved(entry)
                and "server-approved" or "local preview only",
            not model.IsPlayerEntryServerApproved(entry))
    else
        local bump = model.EntryBumpType(entry)
        addDetail(self.details, "BumpType", bump or "-", not bump)
        addDetail(self.details, "Selectors", selectorText(entry) or "none",
            selectorText(entry) ~= "")
        addDetail(self.details, "Direct route",
            entry.puppetOperaDirect and "yes" or "requires selectors",
            not entry.puppetOperaDirect)
        addDetail(self.details, "Entry ID", model.NPCEntryID(entry))
        addDetail(self.details, "MP policy",
            model.IsNPCEntryServerApproved(entry)
                and "server-approved" or "local preview only",
            not model.IsNPCEntryServerApproved(entry))
    end
    addDetail(self.details, "Playback",
        (entry.looped and "looped" or "one-shot") .. " @ "
            .. tostring(entry.speed or 1.0))
    addDetail(self.details, "Events", tostring(#(entry.events or {})))
end

function ISPNCPuppetOperaAnimationTab:onAction(button)
    if not self.ownerWindow then return false end
    local entry = self:getSelectedEntry()
    if not entry then return false end
    local actorID = self.catalogName == "player" and "player" or "npc"
    local accepted, reason = self.ownerWindow.model.AssignAnimation(actorID, entry)
    if not accepted then
        self.ownerWindow:setEditorStatus(reason)
        return false
    end
    self.ownerWindow:setEditorStatus("assigned:" .. actorID)
    self.ownerWindow:refreshViews()
    return true
end

function ISPNCPuppetOperaAnimationTab:onResponsiveLayout()
    local pad = Layout.Pixels(8, self.ownerWindow and self.ownerWindow.uiScale)
    local filterWidth = Layout.Pixels(190, self.ownerWindow
        and self.ownerWindow.uiScale)
    local searchWidth = math.max(
        Layout.Pixels(180, self.ownerWindow and self.ownerWindow.uiScale),
        math.floor(self:getWidth() * 0.26)
    )
    local top = Layout.Pixels(38, self.ownerWindow and self.ownerWindow.uiScale)
    local split = math.floor(self:getWidth() * 0.54)
    Layout.SetBounds(self.search, pad, pad, searchWidth,
        Layout.Pixels(26, self.ownerWindow and self.ownerWindow.uiScale))
    Layout.SetBounds(self.filter, pad + searchWidth + pad, pad,
        filterWidth, Layout.Pixels(26, self.ownerWindow and self.ownerWindow.uiScale))
    Layout.SetBounds(self.list, pad, top,
        split - pad * 2, self:getHeight() - top - pad)
    Layout.SetBounds(self.details, split + pad, top,
        self:getWidth() - split - pad * 2,
        self:getHeight() - top - Layout.Pixels(42,
            self.ownerWindow and self.ownerWindow.uiScale))
    Layout.SetBounds(self.assignButton, split + pad,
        self:getHeight() - Layout.Pixels(34,
            self.ownerWindow and self.ownerWindow.uiScale),
        self:getWidth() - split - pad * 2,
        Layout.Pixels(26, self.ownerWindow and self.ownerWindow.uiScale))
end

return ISPNCPuppetOperaAnimationTab
