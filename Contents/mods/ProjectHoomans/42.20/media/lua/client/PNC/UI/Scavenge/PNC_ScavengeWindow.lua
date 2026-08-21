require "ISUI/ISButton"
require "ISUI/ISTextEntryBox"
require "ISUI/ISScrollingListBox"
require "ISUI/ISContextMenu"
require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/Inventory/PNC_InventoryUI_List"
require "PNC/UI/Inventory/PNC_InventoryUI_Model"
require "PNC/UI/Scavenge/PNC_ScavengeUIModel"

PNC = PNC or {}
PNC.ScavengeUI = PNC.ScavengeUI or {}

local ScavengeUI = PNC.ScavengeUI
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Theme = UI.Theme
local Model = PNC.InventoryUIModel
local ScavengeModel = PNC.ScavengeUIModel

local function tr(key, fallback, ...)
    local value = getText and getText(key, ...) or nil
    if value and value ~= "" and value ~= key then return value end
    if select("#", ...) > 0 then return string.format(fallback, ...) end
    return fallback
end

local function readable(value)
    return tostring(value or ""):gsub("_", " ")
end

local function drawStatusRow(list, y, entry, alternate)
    local row = entry.item or {}
    UI.DrawListSelection(list, y, list.itemheight, false, alternate)
    local width = list:getWidth()
    local statusColor = row.status == "COLLECTED" and Theme.colors.success
        or row.status == "UNAVAILABLE" and Theme.colors.danger
        or row.status == "PAUSED_CAPACITY" and Theme.colors.warning
        or Theme.colors.text
    list:drawText(readable(row.status):upper(), 8, y + 5,
        statusColor.r, statusColor.g, statusColor.b, 1, UIFont.Small)
    list:drawText(Layout.Ellipsize(row.item or row.message or "",
        UIFont.Small, math.floor(width * 0.46)), math.floor(width * 0.25),
        y + 5, Theme.colors.text.r, Theme.colors.text.g,
        Theme.colors.text.b, 1, UIFont.Small)
    list:drawText(Layout.Ellipsize(row.detail or "", UIFont.Small,
        math.floor(width * 0.25)), math.floor(width * 0.73), y + 5,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, 1, UIFont.Small)
    return y + list.itemheight
end

local function eligible(entry)
    return entry and (entry.status == "AVAILABLE"
        or entry.status == "QUEUED")
end

ISPNCScavengeWindow = UI.Window:derive("ISPNCScavengeWindow")

function ISPNCScavengeWindow:initialise()
    UI.Window.initialise(self)
end

local function makeButton(owner, id, title, x, width)
    local button = ISButton:new(x, 0, width, 26, title, owner,
        ISPNCScavengeWindow.onAction)
    button.internal = id
    button:initialise()
    button:instantiate()
    owner:addChild(button)
    return button
end

function ISPNCScavengeWindow:createChildren()
    UI.Window.createChildren(self)
    self.searchEntry = ISTextEntryBox:new("", 0, 0, 200, 26)
    self.searchEntry:initialise()
    self.searchEntry:instantiate()
    if self.searchEntry.setClearButton then self.searchEntry:setClearButton(true) end
    self.searchEntry.onTextChange = function() self:rebuildManifest() end
    self:addChild(self.searchEntry)

    self.containerButton = makeButton(self, "containers", tr(
        "UI_PNC_Scavenge_Containers", "Containers"), 0, 118)
    self.floorButton = makeButton(self, "floorItems", tr(
        "UI_PNC_Scavenge_Floor", "Floor"), 0, 100)
    self.corpseButton = makeButton(self, "corpses", tr(
        "UI_PNC_Scavenge_Corpses", "Corpses"), 0, 105)
    self.searchButton = makeButton(self, "search", tr(
        "UI_PNC_Scavenge_Start", "Start Search"), 0, 112)

    self.manifestList = ISPNCInventoryList:new(0, 0, 100, 100,
        self, "scavenge")
    self.manifestList:initialise()
    self.manifestList:instantiate()
    self.manifestList.selectOnly = true
    self:addChild(self.manifestList)

    self.statusList = ISScrollingListBox:new(0, 0, 100, 100)
    self.statusList:initialise()
    self.statusList:instantiate()
    self.statusList.itemheight = 24
    self.statusList.doDrawItem = drawStatusRow
    self.statusList.drawBorder = true
    self.statusList.backgroundColor = { r = 0, g = 0, b = 0, a = 0.62 }
    self:addChild(self.statusList)

    self.takeButton = makeButton(self, "take_selected", tr(
        "UI_PNC_Scavenge_TakeSelected", "Take Selected"), 0, 130)
    self.takeAllButton = makeButton(self, "take_all", tr(
        "UI_PNC_Scavenge_TakeAll", "Take All Found"), 0, 126)
    self.autoButton = makeButton(self, "take_auto", tr(
        "UI_PNC_Scavenge_TakeAuto", "Take Auto Grab"), 0, 132)
    self.pauseButton = makeButton(self, "pause", tr(
        "UI_PNC_Scavenge_Pause", "Pause & Follow"), 0, 124)
    self.debugButton = makeButton(self, "debug_dump", tr(
        "UI_PNC_Scavenge_DumpDiagnostics", "Dump Diagnostics"), 0, 120)
    self.closeButton = makeButton(self, "close", tr(
        "UI_PNC_Close", "Close"), 0, 78)
    self:updateToggleTitles()
    self:requestResponsiveLayout(true)
end

function ISPNCScavengeWindow:onResponsiveLayout()
    if not self.manifestList then return end
    local rect = self:getContentRect({ top = 12, bottom = 12 })
    local gap = 7
    local controlsY = rect.y + 30
    Layout.SetBounds(self.containerButton, rect.x, controlsY, 118, 26)
    Layout.SetBounds(self.floorButton, rect.x + 125, controlsY, 100, 26)
    Layout.SetBounds(self.corpseButton, rect.x + 232, controlsY, 105, 26)
    Layout.SetBounds(self.searchEntry, rect.x + 344, controlsY,
        math.max(100, rect.width - 344 - 119), 26)
    Layout.SetBounds(self.searchButton, rect.x + rect.width - 112,
        controlsY, 112, 26)
    local manifestY = controlsY + 52
    local statusHeight = math.max(92, math.floor(rect.height * 0.22))
    local buttonsY = rect.y + rect.height - 28
    local statusY = buttonsY - statusHeight - 26
    Layout.SetBounds(self.manifestList, rect.x, manifestY, rect.width,
        math.max(100, statusY - manifestY - gap))
    Layout.SetBounds(self.statusList, rect.x, statusY, rect.width,
        statusHeight)
    local x = rect.x
    for _, button in ipairs({ self.takeButton, self.takeAllButton,
        self.autoButton, self.pauseButton })
    do
        Layout.SetBounds(button, x, buttonsY, button.width, 26)
        x = x + button.width + gap
    end
    Layout.SetBounds(self.closeButton, rect.x + rect.width - 78,
        buttonsY, 78, 26)
    local debugVisible = rect.width >= 760 and PNC.Client
        and PNC.Client.CanUseDebug and PNC.Client.CanUseDebug() == true
    self.debugButton:setVisible(debugVisible)
    Layout.SetBounds(self.debugButton, rect.x + rect.width - 205,
        buttonsY, 120, 26)
    self.layout = { rect = rect, controlsY = controlsY,
        manifestY = manifestY, statusY = statusY }
end

function ISPNCScavengeWindow:updateToggleTitles()
    local sourcePolicy = self.sourcePolicy
    if type(sourcePolicy) ~= "table" then
        sourcePolicy = { containers = true, floorItems = true, corpses = true }
        self.sourcePolicy = sourcePolicy
    end
    local enabled = tr("UI_PNC_Scavenge_On", "ON")
    local disabled = tr("UI_PNC_Scavenge_Off", "OFF")
    local containers = tr("UI_PNC_Scavenge_Containers", "Containers")
    local floorItems = tr("UI_PNC_Scavenge_Floor", "Floor")
    local corpses = tr("UI_PNC_Scavenge_Corpses", "Corpses")
    self.containerButton:setTitle(containers .. ": "
        .. (sourcePolicy.containers and enabled or disabled))
    self.floorButton:setTitle(floorItems .. ": "
        .. (sourcePolicy.floorItems and enabled or disabled))
    self.corpseButton:setTitle(corpses .. ": "
        .. (sourcePolicy.corpses and enabled or disabled))
end

function ISPNCScavengeWindow:setNPC(npcId, context)
    self.npcId = npcId and tostring(npcId) or nil
    self.npcIds = {}
    for _, value in ipairs(context and context.npcIds or { self.npcId }) do
        self.npcIds[#self.npcIds + 1] = tostring(value)
    end
    self.npcName = context and (context.name or context.displayName)
        or self.npcId or "Companion"
    local title = tr("UI_PNC_Scavenge_Title", "Scavenging")
        .. " — " .. tostring(self.npcName)
    self:setTitle(title)
end

function ISPNCScavengeWindow:toggleInventoryGroup(_, groupKey)
    self.expandedGroups[groupKey] = self.expandedGroups[groupKey] == false
    self:rebuildManifest()
end

function ISPNCScavengeWindow:onInventoryRowClick(_, row)
    local ids = row.entryIds or (row.entryId and { row.entryId }) or {}
    local select = false
    for _, id in ipairs(ids) do
        local entry = self.entryById[id]
        if eligible(entry) and self.selectedEntries[id] ~= true then
            select = true
            break
        end
    end
    for _, id in ipairs(ids) do
        local entry = self.entryById[id]
        if eligible(entry) then self.selectedEntries[id] = select or nil end
    end
    self:rebuildManifest()
end

function ISPNCScavengeWindow:showItemContext(_, row)
    if not row or not row.fullType then return end
    local menu = ISContextMenu.get(0, getMouseX(), getMouseY())
    local enabled = row.autoGrab == true
    local title = enabled and tr("UI_PNC_Scavenge_DisableAuto",
        "Disable Auto Grab") or tr("UI_PNC_Scavenge_EnableAuto",
        "Enable Auto Grab")
    menu:addOption(title, self, function(window)
            PNC.Client.SendScavengeRequest("set_auto_grab", {
                sessionId = window.snapshot and window.snapshot.sessionId,
                fullType = row.fullType, enabled = not enabled,
            })
        end)
end

function ISPNCScavengeWindow:filtered(entry)
    if entry.sourceType == "container" and not self.sourcePolicy.containers
        or entry.sourceType == "floor" and not self.sourcePolicy.floorItems
        or entry.sourceType == "corpse" and not self.sourcePolicy.corpses
    then return true end
    local query = string.lower(tostring(self.searchEntry:getText() or ""))
    return query ~= "" and not string.find(string.lower(
        tostring(entry.displayName or entry.fullType or "")), query, 1, true)
end

function ISPNCScavengeWindow:rebuildManifest()
    if not self.manifestList then return end
    self.manifestList:clear()
    self.entryById = {}
    for _, entry in ipairs(self.snapshot and self.snapshot.manifest or {}) do
        self.entryById[entry.entryId] = entry
    end
    local order = ScavengeModel.GroupManifestBySource(
        self.snapshot and self.snapshot.manifest or {},
        function(entry) return not self:filtered(entry) end)
    for _, source in ipairs(order) do
        local ids, selected, available = {}, 0, 0
        local statuses = {}
        for _, entry in ipairs(source.entries) do
            ids[#ids + 1] = entry.entryId
            statuses[entry.status] = true
            if eligible(entry) then
                available = available + 1
                if self.selectedEntries[entry.entryId] then selected = selected + 1 end
            end
        end
        local marker = available > 0 and selected == available and "[X] "
            or selected > 0 and "[-] " or "[ ] "
        local status = statuses.COLLECTED and "COLLECTED"
            or statuses.QUEUED and "QUEUED"
            or statuses.UNAVAILABLE and "UNAVAILABLE"
            or "AVAILABLE"
        local header = {
            name = marker .. tostring(source.sourceLabel),
            category = readable(source.sourceType):upper() .. " - " .. status,
            stack = source.quantity,
            groupHeader = true,
            groupKey = source.key,
            expanded = self.expandedGroups[source.key] ~= false,
            entryIds = ids,
            restricted = available < 1,
        }
        self.manifestList:addItem(header.name, header)
        if header.expanded then
            for _, item in ipairs(source.items) do
                local metadata = Model.Probe(item.fullType)
                local itemIds, itemSelected, itemAvailable = {}, 0, 0
                local itemStatus = {}
                for _, entry in ipairs(item.entries) do
                    itemIds[#itemIds + 1] = entry.entryId
                    itemStatus[entry.status] = true
                    if eligible(entry) then
                        itemAvailable = itemAvailable + 1
                        if self.selectedEntries[entry.entryId] then
                            itemSelected = itemSelected + 1
                        end
                    end
                end
                local itemMarker = itemAvailable > 0
                    and itemSelected == itemAvailable and "[X] "
                    or itemSelected > 0 and "[-] " or "[ ] "
                local statusText = itemStatus.COLLECTED and "COLLECTED"
                    or itemStatus.QUEUED and "QUEUED"
                    or itemStatus.UNAVAILABLE and "UNAVAILABLE"
                    or "AVAILABLE"
                self.manifestList:addItem(item.key, {
                    name = itemMarker .. (item.autoGrab and "* " or "")
                        .. tostring(item.displayName or item.fullType),
                    category = statusText,
                    texture = metadata.texture,
                    stack = item.quantity,
                    groupChild = true,
                    groupKey = source.key,
                    entryIds = itemIds,
                    fullType = item.fullType,
                    autoGrab = item.autoGrab,
                    restricted = itemAvailable < 1,
                })
            end
        end
    end
    if #order == 0 then
        self.manifestList:addItem("No matching loot", {
            name = "No matching loot", category = "Search or adjust filters",
            restricted = true,
        })
    end
end

function ISPNCScavengeWindow:rebuildStatus()
    self.statusList:clear()
    local rows = self.snapshot and self.snapshot.activity or {}
    for index = #rows, 1, -1 do
        local entry = rows[index]
        self.statusList:addItem(tostring(index), {
            status = entry.status,
            item = entry.displayName or entry.fullType or "",
            detail = entry.reason or readable(entry.sourceType),
        })
    end
    if #rows == 0 then
        self.statusList:addItem("empty", { status = "WAITING",
            message = "No scavenging activity yet", detail = "" })
    end
    local diagnostics = self.snapshot and self.snapshot.debugDiagnostics
    if diagnostics then
        local snapshot = self.snapshot
        local debugRows = {
            { "DEBUG", "Session", tostring(snapshot.sessionId or "none") },
            { "DEBUG", "State / task", tostring(snapshot.state or "none")
                .. " / " .. tostring(snapshot.taskPhase or "none") },
            { "DEBUG", "Current source",
                tostring(snapshot.currentSourceToken or "none") },
            { "DEBUG", "Queue", string.format("%d / %d",
                tonumber(snapshot.queueIndex) or 0, #(snapshot.queue or {})) },
            { "DEBUG", "Last failure",
                tostring(snapshot.lastFailure or diagnostics.lastFailure or "none") },
        }
        for _, row in ipairs(debugRows) do
            self.statusList:addItem(row[2], { status = row[1],
                item = row[2], detail = row[3] })
        end
        local names = {}
        for name, _ in pairs(diagnostics.counters or {}) do
            names[#names + 1] = name
        end
        table.sort(names)
        for _, name in ipairs(names) do
            self.statusList:addItem(name, { status = "METRIC",
                item = name, detail = tostring(diagnostics.counters[name]) })
        end
    end
end

function ISPNCScavengeWindow:applySnapshot(snapshot)
    if not snapshot or snapshot.requestFailed then
        self.lastFailure = snapshot and snapshot.reason or self.lastFailure
        return
    end
    if snapshot.policyOnly == true then
        if snapshot.sourcePolicy then
            self.sourcePolicy = {
                containers = snapshot.sourcePolicy.containers == true,
                floorItems = snapshot.sourcePolicy.floorItems == true,
                corpses = snapshot.sourcePolicy.corpses == true,
            }
            self:updateToggleTitles()
            self:rebuildManifest()
        end
        return
    end
    if self.snapshot and snapshot.sessionId ~= self.snapshot.sessionId then
        self.selectedEntries = {}
        self.expandedGroups = {}
    end
    if self.snapshot and snapshot.sessionId == self.snapshot.sessionId
        and tonumber(snapshot.revision) < tonumber(self.snapshot.revision)
    then return end
    self.snapshot = snapshot
    self.lastFailure = nil
    self.npcId = tostring(snapshot.npcId or self.npcId or "")
    self.npcName = snapshot.npcName or self.npcName
    if type(snapshot.npcIds) == "table" then
        self.npcIds = {}
        for _, npcId in ipairs(snapshot.npcIds) do
            self.npcIds[#self.npcIds + 1] = tostring(npcId)
        end
    end
    if snapshot.sourcePolicy then
        self.sourcePolicy = {
            containers = snapshot.sourcePolicy.containers == true,
            floorItems = snapshot.sourcePolicy.floorItems == true,
            corpses = snapshot.sourcePolicy.corpses == true,
        }
    end
    self:updateToggleTitles()
    self:rebuildManifest()
    self:rebuildStatus()
end

local function selectedIds(window, autoOnly)
    return ScavengeModel.SelectableEntryIDs(
        window.snapshot and window.snapshot.manifest or {},
        window.selectedEntries, autoOnly)
end

function ISPNCScavengeWindow:onAction(button)
    local action = button.internal
    if action == "containers" or action == "floorItems"
        or action == "corpses"
    then
        self.sourcePolicy[action] = self.sourcePolicy[action] ~= true
        self:updateToggleTitles()
        self:rebuildManifest()
        return
    end
    if action == "search" then
        local ok, reason = PNC.Client.SendScavengeRequest("start_search", {
            npcId = self.npcId, npcIds = self.npcIds,
            radius = PNC.Const.SCAVENGE_DEFAULT_RADIUS,
            sourcePolicy = self.sourcePolicy,
        })
        if ok ~= true then self.lastFailure = reason or "search_failed" end
        return ok, reason
    end
    if action == "take_all" then
        local ids = ScavengeModel.AllAvailableEntryIDs(
            self.snapshot and self.snapshot.manifest)
        if #ids < 1 then self.lastFailure = "selection_empty"; return false end
        return PNC.Client.SendScavengeRequest("queue_multiple", {
            sessionId = self.snapshot and self.snapshot.sessionId,
            revision = self.snapshot and self.snapshot.revision,
            entryIds = ids,
        })
    end
    if action == "take_selected" or action == "take_auto" then
        local ids = selectedIds(self, action == "take_auto")
        if #ids < 1 then self.lastFailure = "selection_empty"; return false end
        return PNC.Client.SendScavengeRequest("queue_multiple", {
            sessionId = self.snapshot and self.snapshot.sessionId,
            revision = self.snapshot and self.snapshot.revision,
            entryIds = ids,
        })
    end
    if action == "pause" then
        return PNC.Client.SendScavengeRequest("pause", {
            sessionId = self.snapshot and self.snapshot.sessionId,
            npcId = self.npcId,
        })
    end
    if action == "debug_dump" then
        return PNC.Client.SendScavengeRequest("debug_dump", {
            sessionId = self.snapshot and self.snapshot.sessionId,
        })
    end
    if action == "close" then self:close(); return true end
end

function ISPNCScavengeWindow:prerender()
    UI.Window.prerender(self)
    if not self.layout then return end
    local snapshot = self.snapshot or {}
    local progress = tonumber(snapshot.progress) or 0
    local rect = self.layout.rect
    local progressText = tr("UI_PNC_Scavenge_Progress",
        "Search: %s%%  |  %s searched  |  %s unreachable",
        progress, tonumber(snapshot.searchedCount) or 0,
        tonumber(snapshot.unreachableCount) or 0)
    self:drawText(progressText, rect.x,
        rect.y + 3, 0.72, 0.86, 0.94, 1, UIFont.Small)
    local carry = snapshot.carry
    local estimatedLoad = 0
    for _, entry in ipairs(snapshot.manifest or {}) do
        if self.selectedEntries[entry.entryId] == true
            or entry.status == "QUEUED"
        then
            local metadata = Model.Probe(entry.fullType)
            estimatedLoad = estimatedLoad + (tonumber(metadata.weight) or 0)
                * (tonumber(entry.quantity) or 1)
        end
    end
    local carryText = carry and tr("UI_PNC_Scavenge_Carry",
        "Carry %s / %s (%s)",
        tonumber(carry.usedWeight) or 0,
        tonumber(carry.maxWeight) or 0,
        readable(carry.level)) or tr("UI_PNC_Scavenge_CarryUnavailable",
            "Carry unavailable")
    carryText = carryText .. tr("UI_PNC_Scavenge_QueuedLoad",
        "  |  Queued ~%s", estimatedLoad)
    self:drawTextRight(carryText, rect.x + rect.width, rect.y + 3,
        0.72, 0.74, 0.78, 1, UIFont.Small)
    local manifestTitle = tr("UI_PNC_Scavenge_Manifest", "LOOT MANIFEST")
    self:drawText(manifestTitle, rect.x,
        self.manifestList:getY() - 19, 0.64, 0.78, 0.84, 1, UIFont.Small)
    self:drawTextRight(tostring(#(snapshot.manifest or {})),
        rect.x + rect.width, self.manifestList:getY() - 19,
        0.64, 0.78, 0.84, 1, UIFont.Small)
    local activityTitle = tr("UI_PNC_Scavenge_Activity", "STATUS / ACTIVITY")
    self:drawText(activityTitle, rect.x,
        self.statusList:getY() - 19, 0.64, 0.78, 0.84, 1, UIFont.Small)
    local status = self.lastFailure or snapshot.lastFailure
        or readable(snapshot.state or "ready")
    self:drawTextRight(string.upper(readable(status)), rect.x + rect.width,
        self.statusList:getY() - 19, 0.72, 0.74, 0.78, 1, UIFont.Small)
    if snapshot.debugDiagnostics then
        self:drawText(string.format("DEBUG task=%s source=%s queue=%d/%d",
            tostring(snapshot.taskPhase or "none"),
            tostring(snapshot.currentSourceToken or "none"),
            tonumber(snapshot.queueIndex) or 0, #(snapshot.queue or {})),
            rect.x + 260, self.statusList:getY() - 19,
            0.94, 0.70, 0.27, 1, UIFont.Small)
    end
end

function ISPNCScavengeWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    ScavengeUI.instance = nil
end

function ISPNCScavengeWindow:new(x, y, width, height, options)
    local o = UI.Window.new(self, x, y, width, height, options or {})
    o.resizable = true
    o.sourcePolicy = { containers = true, floorItems = true, corpses = true }
    o.expandedGroups = {}
    o.selectedEntries = {}
    o.entryById = {}
    return o
end

local function getOrCreate()
    if ScavengeUI.instance then return ScavengeUI.instance end
    local spec = { width = 900, height = 650, minWidth = 660,
        minHeight = 470, maxWidth = 1280, maxHeight = 900,
        anchor = "center" }
    local bounds = Layout.ResolveWindow(spec)
    local title = tr("UI_PNC_Scavenge_Title", "Scavenging")
    local window = ISPNCScavengeWindow:new(bounds.x, bounds.y,
        bounds.width, bounds.height, {
            title = title,
            responsiveSpec = spec,
            persistenceKey = "ProjectHoomans:ScavengeWindow",
            resizable = true,
        })
    window:initialise()
    window:instantiate()
    window:addToUIManager()
    ScavengeUI.instance = window
    return window
end

function ScavengeUI.OpenSetup(npcId, context)
    local window = getOrCreate()
    window:setNPC(npcId, context)
    window:setVisible(true)
    window:bringToTop()
    PNC.Client.SendScavengeRequest("request_policy", { npcId = npcId })
    local state = PNC.Network and PNC.Network.ClientState or nil
    local active = state and state.activeScavengeSessionId
    local snapshot = active and state.scavengeSessions
        and state.scavengeSessions[active] or nil
    if snapshot then
        window:applySnapshot(snapshot)
        -- The Colony tab is the assignment editor. Preserve its current team
        -- even while showing the previous run's manifest so Start Search uses
        -- the NPCs the player just selected.
        window:setNPC(npcId, context)
    end
    return true
end

function ScavengeUI.ReceiveSnapshot(snapshot)
    local window = ScavengeUI.instance
    if window then
        window:applySnapshot(snapshot)
        window:setVisible(true)
        window:bringToTop()
    end
    return window ~= nil
end

return ScavengeUI
