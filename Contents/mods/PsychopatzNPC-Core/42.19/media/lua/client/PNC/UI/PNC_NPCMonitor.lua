require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISScrollingListBox"

PNC = PNC or {}
PNC.NPCMonitor = PNC.NPCMonitor or {}

local Monitor = PNC.NPCMonitor
local ClientState = PNC.Network.ClientState
local FILTERS = { "All", "Live", "Abstract", "Corpse", "Problems" }

local function diagnosticProblem(item)
    if not item then
        return false
    end
    if item.lastError then
        return true
    end
    if item.presenceState == "live" then
        return item.bodyState ~= "bound"
    end
    if item.bodyState == "duplicate" or item.bodyState == "stale_cleaned" then
        return true
    end
    if item.lastCleanupState == "duplicate" or item.lastCleanupState == "stale_cleaned" then
        return true
    end
    return item.presenceState == "corpse"
        and item.corpseState ~= "inert_loaded"
        and item.corpseState ~= "unloaded"
end

local function matchesFilter(item, filter)
    if filter == "Live" then
        return item.presenceState == "live"
    elseif filter == "Abstract" then
        return item.presenceState == "abstract"
    elseif filter == "Corpse" then
        return item.presenceState == "corpse"
    elseif filter == "Problems" then
        return diagnosticProblem(item)
    end
    return true
end

local function findBody(item)
    local sync = PNC.ClientPresenceSync
    local body
    if not item or not sync then
        return nil
    end
    if item.bodyLease and sync.BodyByLease then
        body = sync.BodyByLease[tostring(item.id) .. ":" .. tostring(item.bodyLease)]
    end
    return body or (sync.BodyByID and sync.BodyByID[tostring(item.id)] or nil)
end

local function setOutlined(body, enabled)
    if not body then
        return
    end
    if body.setOutlineHighlightCol then
        pcall(body.setOutlineHighlightCol, body, 0.15, 0.85, 1.0, 1.0)
    end
    if body.setOutlineHighlight then
        pcall(body.setOutlineHighlight, body, enabled == true)
    end
end

ISPNCNPCMonitor = ISCollapsableWindow:derive("ISPNCNPCMonitor")

function ISPNCNPCMonitor:initialise()
    ISCollapsableWindow.initialise(self)
end

function ISPNCNPCMonitor:createChildren()
    local x = 10
    local i
    local filter
    ISCollapsableWindow.createChildren(self)
    self.filterButtons = {}
    for i = 1, #FILTERS do
        filter = FILTERS[i]
        self.filterButtons[filter] = ISButton:new(x, 26, 80, 23, filter, self, ISPNCNPCMonitor.onFilter)
        self.filterButtons[filter].internal = filter
        self.filterButtons[filter]:initialise()
        self:addChild(self.filterButtons[filter])
        x = x + 84
    end
    self.focus = ISButton:new(700, 26, 80, 23, getText("UI_PNC_MonitorFocus"), self, ISPNCNPCMonitor.onFocus)
    self.focus:initialise()
    self:addChild(self.focus)

    self.list = ISScrollingListBox:new(10, 56, 455, 465)
    self.list:initialise()
    self.list:instantiate()
    self.list.itemheight = 24
    self.list.drawBorder = true
    self:addChild(self.list)

    self.forceLive = ISButton:new(10, 530, 92, 24, getText("UI_PNC_MonitorForceLive"), self, ISPNCNPCMonitor.onAction)
    self.forceLive.internal = "force_live"
    self.forceAbstract = ISButton:new(106, 530, 108, 24, getText("UI_PNC_MonitorForceAbstract"), self, ISPNCNPCMonitor.onAction)
    self.forceAbstract.internal = "force_abstract"
    self.heal = ISButton:new(218, 530, 70, 24, getText("UI_PNC_MonitorHeal"), self, ISPNCNPCMonitor.onAction)
    self.heal.internal = "heal"
    self.damage = ISButton:new(292, 530, 82, 24, getText("UI_PNC_MonitorDamage"), self, ISPNCNPCMonitor.onAction)
    self.damage.internal = "damage"
    self.toggleDebug = ISButton:new(378, 530, 104, 24, getText("UI_PNC_MonitorRecordDebug"), self, ISPNCNPCMonitor.onAction)
    self.toggleDebug.internal = "toggle_debug"
    self.audit = ISButton:new(486, 530, 96, 24, getText("UI_PNC_MonitorAuditBodies"), self, ISPNCNPCMonitor.onAudit)
    self.refresh = ISButton:new(586, 530, 82, 24, getText("UI_PNC_MonitorRefresh"), self, ISPNCNPCMonitor.onRefresh)
    self.overlay = ISButton:new(672, 530, 108, 24, getText("UI_PNC_MonitorToggleOverlay"), self, ISPNCNPCMonitor.onOverlay)
    local buttons = { self.forceLive, self.forceAbstract, self.heal, self.damage, self.toggleDebug, self.audit, self.refresh, self.overlay }
    for i = 1, #buttons do
        buttons[i]:initialise()
        self:addChild(buttons[i])
    end
    self:requestRoster(false)
end

function ISPNCNPCMonitor:onFilter(button)
    self.filter = button and button.internal or "All"
    self:refreshList()
end

function ISPNCNPCMonitor:getSelectedDiagnostic()
    local entry = self.list and self.list:getItem() or nil
    return entry and entry.item or nil
end

function ISPNCNPCMonitor:onAction(button)
    local item = self:getSelectedDiagnostic()
    if not item or not PNC.Client then
        return
    end
    PNC.Client.SendDebug(button.internal, {
        id = item.id,
        amount = button.internal == "damage" and 25 or nil,
    })
    self:requestRoster(false)
end

function ISPNCNPCMonitor:onAudit()
    self:requestRoster(true)
end

function ISPNCNPCMonitor:onRefresh()
    self:requestRoster(false)
end

function ISPNCNPCMonitor:onOverlay()
    if PNC.Nameplates and PNC.Nameplates.ToggleDebug then
        PNC.Nameplates.ToggleDebug()
    end
end

function ISPNCNPCMonitor:onFocus()
    local item = self:getSelectedDiagnostic()
    local body = findBody(item)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not body then
        return
    end
    setOutlined(body, true)
    self.outlinedBody = body
    self.outlinedId = tostring(item.id)
    if player and player.faceThisObject then
        player:faceThisObject(body)
    end
end

function ISPNCNPCMonitor:requestRoster(forceAudit)
    if PNC.Client and PNC.Client.RequestDebugRoster then
        PNC.Client.RequestDebugRoster(forceAudit == true)
    end
    self.lastRequestAt = PNC.Core.Now()
end

function ISPNCNPCMonitor:refreshList()
    local selected = self:getSelectedDiagnostic()
    local selectedId = selected and tostring(selected.id) or self.selectedId
    local roster = ClientState.debugRoster or {}
    local i
    local item
    local label
    local added
    self.list:clear()
    for i = 1, #roster do
        item = roster[i]
        if matchesFilter(item, self.filter) then
            label = string.format(
                "%s | %s/%s | %s | HP %s/%s",
                tostring(item.name or item.id),
                string.upper(tostring(item.presenceState or "?")),
                string.upper(tostring(item.bodyState or "?")),
                tostring(item.activeBehavior or item.activeJob or "Idle"),
                tostring(math.floor(tonumber(item.hpCurrent) or 0)),
                tostring(math.floor(tonumber(item.hpMax) or 0))
            )
            self.list:addItem(label, item)
            added = self.list.items[#self.list.items]
            if selectedId and tostring(item.id) == selectedId then
                self.list.selected = #self.list.items
            end
            if diagnosticProblem(item) and added then
                added.color = { r = 1, g = 0.42, b = 0.28, a = 1 }
            end
        end
    end
    self.selectedId = selectedId
    self.lastRosterReceiveAt = tonumber(ClientState.lastDebugRosterReceiveAt) or tonumber(ClientState.lastDebugRosterRequestAt) or PNC.Core.Now()
end

function ISPNCNPCMonitor:updateOutline()
    local item = self:getSelectedDiagnostic()
    local id = item and tostring(item.id) or nil
    local body = findBody(item)
    if self.outlinedBody and self.outlinedBody ~= body then
        setOutlined(self.outlinedBody, false)
        self.outlinedBody = nil
    end
    if body and id ~= self.outlinedId then
        setOutlined(body, true)
        self.outlinedBody = body
        self.outlinedId = id
    elseif not body then
        self.outlinedId = nil
    end
    self.selectedId = id or self.selectedId
end

function ISPNCNPCMonitor:prerender()
    local now = PNC.Core.Now()
    local receiveAt = tonumber(ClientState.lastDebugRosterReceiveAt) or tonumber(ClientState.lastDebugRosterRequestAt) or 0
    ISCollapsableWindow.prerender(self)
    if (now - (tonumber(self.lastRequestAt) or 0)) >= 1000 then
        self:requestRoster(false)
    end
    if receiveAt > (tonumber(self.lastRosterReceiveAt) or 0) then
        self:refreshList()
    end
    self:updateOutline()
end

function ISPNCNPCMonitor:render()
    local item = self:getSelectedDiagnostic()
    local x = 480
    local y = 62
    local lines
    local i
    local audit = ClientState.debugAudit or {}
    ISCollapsableWindow.render(self)
    for i = 1, #FILTERS do
        local filter = FILTERS[i]
        self.filterButtons[filter]:setTitle(self.filter == filter and ("[" .. filter .. "]") or filter)
    end
    if not ClientState.debugAuthorized then
        self:drawText(getText("UI_PNC_MonitorUnauthorized"), x, y, 1, 0.35, 0.25, 1, UIFont.Small)
        return
    end
    if not item then
        self:drawText(getText("UI_PNC_MonitorSelectNPC"), x, y, 0.85, 0.85, 0.85, 1, UIFont.Small)
        return
    end
    lines = {
        "Name: " .. tostring(item.name or "-"),
        "UUID: " .. tostring(item.id or "-"),
        "Faction: " .. tostring(item.faction or "-"),
        "Presence: " .. tostring(item.presenceState or "-") .. " / " .. tostring(item.phase or "-"),
        "Body: " .. tostring(item.bodyState or "-") .. "  Corpse: " .. tostring(item.corpseState or "-"),
        "Last cleanup: " .. tostring(item.lastCleanupState or "-") .. " / " .. tostring(item.lastCleanupReason or "-"),
        "Lease: " .. tostring(item.bodyLease or "-"),
        "Online ID: " .. tostring(item.liveBodyOnlineID or "-") .. "  Outfit ID: " .. tostring(item.liveBodyInstanceID or "-"),
        string.format("Position: %.2f, %.2f, %.0f", tonumber(item.x) or 0, tonumber(item.y) or 0, tonumber(item.z) or 0),
        "AI: " .. tostring(item.activeBehavior or item.activeJob or "Idle"),
        "Health: " .. tostring(item.healthState or "-") .. " " .. tostring(item.hpCurrent or 0) .. "/" .. tostring(item.hpMax or 0),
        "Target: " .. tostring(item.targetKind or "none"),
        "Block: " .. tostring(item.combatBlockReason or "-"),
        "Body action: " .. tostring(item.bodyActionState or "-"),
        "Last transition: " .. tostring(item.lastReason or "-"),
        "Error: " .. tostring(item.lastError or "-"),
        "Bite: " .. tostring(item.bite and item.bite.phase or "-") .. " / " .. tostring(item.bite and item.bite.actionState or "-"),
        "Bite reason/times: " .. tostring(item.bite and item.bite.reason or "-")
            .. "  " .. tostring(item.bite and item.bite.startedAt or "-")
            .. "/" .. tostring(item.bite and item.bite.impactAt or "-")
            .. "/" .. tostring(item.bite and item.bite.releaseAt or "-"),
        "",
        "Last audit: scanned=" .. tostring(audit.scanned or 0)
            .. " removed=" .. tostring(audit.removed or 0)
            .. " rebound=" .. tostring(audit.rebound or 0)
            .. " duplicates=" .. tostring(audit.duplicates or 0),
    }
    for i = 1, #lines do
        self:drawText(lines[i], x, y, 0.9, 0.9, 0.9, 1, UIFont.Small)
        y = y + 22
    end
end

function ISPNCNPCMonitor:close()
    if self.outlinedBody then
        setOutlined(self.outlinedBody, false)
    end
    self.outlinedBody = nil
    self:setVisible(false)
    self:removeFromUIManager()
    Monitor.instance = nil
end

function ISPNCNPCMonitor:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.title = getText("UI_PNC_MonitorTitle")
    o.filter = "All"
    o.resizable = false
    return o
end

function Monitor.Toggle()
    local window = Monitor.instance
    if not PNC.Client or not PNC.Client.CanUseDebug or not PNC.Client.CanUseDebug() then
        return nil
    end
    if not window then
        window = ISPNCNPCMonitor:new(120, 80, 800, 570)
        window:initialise()
        window:instantiate()
        Monitor.instance = window
    elseif window:getIsVisible() then
        window:close()
        return nil
    end
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:requestRoster(false)
    return window
end

local function onResetLua()
    if Monitor.instance then
        Monitor.instance:close()
    end
end

if Events and Events.OnResetLua then
    Events.OnResetLua.Add(onResetLua)
end
