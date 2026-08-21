require "ISUI/ISButton"
require "ISUI/ISPanel"
require "ISUI/ISTextEntryBox"
require "ISUI/ISScrollingListBox"
require "ISUI/ISContextMenu"
require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/Inventory/PNC_InventoryUI_List"
require "PNC/UI/Inventory/PNC_InventoryUI_Model"
require "PNC/UI/Scavenge/PNC_ScavengeUIModel"

PNC = PNC or {}
PNC.ScavengeUI = PNC.ScavengeUI or {}

local Controller = require "PNC/Scavenge/PNC_ScavengeController"
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

local ISPNCScavengeSection = ISPanel:derive("ISPNCScavengeSection")

function ISPNCScavengeSection:prerender()
    ISPanel.prerender(self)
    local suffix = self.owner and self.owner.sectionSuffix
        and self.owner:sectionSuffix(self.kind) or ""
    UI.DrawSectionTitle(self, self.title, 8, 5,
        math.max(1, self:getWidth() - 16), suffix)
end

function ISPNCScavengeSection:new(owner, kind, title)
    local o = ISPanel:new(0, 0, 1, 1)
    setmetatable(o, self)
    self.__index = self
    o.owner = owner
    o.kind = kind
    o.title = title
    o.backgroundColor = Theme.Color("surface")
    o.borderColor = Theme.Color("border")
    return o
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
    button.psychopatzBaseWidth = width
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
    self.searchButton = UI.CreateToggleButton(self, {
        id = "search",
        offTitle = tr("UI_PNC_Scavenge_Start", "Start Search"),
        onTitle = tr("UI_PNC_Scavenge_Stop", "Stop Search"),
        target = self,
        onclick = ISPNCScavengeWindow.onAction,
        offVariant = "primary",
        onVariant = "danger",
        width = 112,
    })

    self.manifestPanel = ISPNCScavengeSection:new(self, "manifest",
        tr("UI_PNC_Scavenge_Manifest", "LOOT MANIFEST"))
    self.manifestPanel:initialise()
    self.manifestPanel:instantiate()
    self:addChild(self.manifestPanel)

    self.manifestList = ISPNCInventoryList:new(0, 0, 100, 100,
        self, "scavenge")
    self.manifestList:initialise()
    self.manifestList:instantiate()
    self.manifestList.selectOnly = true
    self.manifestPanel:addChild(self.manifestList)

    self.statusPanel = ISPNCScavengeSection:new(self, "activity",
        tr("UI_PNC_Scavenge_ActivityLog", "ACTIVITY LOG"))
    self.statusPanel:initialise()
    self.statusPanel:instantiate()
    self:addChild(self.statusPanel)
    self.statusList = ISScrollingListBox:new(0, 0, 100, 100)
    self.statusList:initialise()
    self.statusList:instantiate()
    self.statusList.itemheight = 24
    self.statusList.doDrawItem = drawStatusRow
    self.statusList.drawBorder = true
    self.statusList.backgroundColor = { r = 0, g = 0, b = 0, a = 0.62 }
    self.statusPanel:addChild(self.statusList)

    self.takeButton = makeButton(self, "take_selected", tr(
        "UI_PNC_Scavenge_TakeSelected", "Take Selected"), 0, 130)
    self.takeAllButton = makeButton(self, "take_all", tr(
        "UI_PNC_Scavenge_TakeAll", "Take All Found"), 0, 126)
    self.autoButton = makeButton(self, "take_auto", tr(
        "UI_PNC_Scavenge_TakeAuto", "Take Auto Grab"), 0, 132)
    self.disbandButton = makeButton(self, "disband", tr(
        "UI_PNC_Scavenge_Disband", "Disband & Follow"), 0, 145)
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
    local scale = self.uiScale or Layout.Scale()
    local function px(value) return Layout.Pixels(value, scale) end
    local gap, controlHeight = px(7), px(26)
    local controlsY = rect.y + px(28)
    local containerWidth, floorWidth = px(118), px(100)
    local corpseWidth, searchWidth = px(105), px(112)
    Layout.SetBounds(self.containerButton, rect.x, controlsY,
        containerWidth, controlHeight)
    Layout.SetBounds(self.floorButton, rect.x + containerWidth + gap,
        controlsY, floorWidth, controlHeight)
    Layout.SetBounds(self.corpseButton,
        rect.x + containerWidth + floorWidth + gap * 2,
        controlsY, corpseWidth, controlHeight)
    local filtersWidth = containerWidth + floorWidth + corpseWidth + gap * 3
    local compact = rect.width < px(790)
    local searchY = compact and controlsY + controlHeight + gap or controlsY
    local searchX = compact and rect.x or rect.x + filtersWidth
    local entryWidth = compact and rect.width - searchWidth - gap
        or rect.width - filtersWidth - searchWidth
    Layout.SetBounds(self.searchEntry, searchX, searchY,
        math.max(px(100), entryWidth), controlHeight)
    Layout.SetBounds(self.searchButton, rect.x + rect.width - searchWidth,
        searchY, searchWidth, controlHeight)
    local manifestY = searchY + controlHeight + px(10)
    local sectionHeaderHeight = px(28)
    local statusRatio = self.debugEnabled and 0.44 or 0.30
    local statusHeight = math.max(px(120),
        math.min(px(self.debugEnabled and 330 or 240),
            math.floor(rect.height * statusRatio)))
    local buttonsY = rect.y + rect.height - controlHeight
    local statusY = buttonsY - statusHeight - gap
    local manifestHeight = math.max(px(120), statusY - manifestY - gap)
    Layout.SetBounds(self.manifestPanel, rect.x, manifestY, rect.width,
        manifestHeight)
    Layout.SetBounds(self.manifestList, 1, sectionHeaderHeight,
        math.max(1, rect.width - 2),
        math.max(1, manifestHeight - sectionHeaderHeight - 1))
    Layout.SetBounds(self.statusPanel, rect.x, statusY, rect.width,
        statusHeight)
    Layout.SetBounds(self.statusList, 1, sectionHeaderHeight,
        math.max(1, rect.width - 2),
        math.max(1, statusHeight - sectionHeaderHeight - 1))
    local x = rect.x
    for _, button in ipairs({ self.takeButton, self.takeAllButton,
        self.autoButton, self.disbandButton })
    do
        local width = px(button.psychopatzBaseWidth or button.width)
        Layout.SetBounds(button, x, buttonsY, width, controlHeight)
        x = x + width + gap
    end
    local closeWidth, debugWidth = px(78), px(132)
    Layout.SetBounds(self.closeButton, rect.x + rect.width - closeWidth,
        buttonsY, closeWidth, controlHeight)
    local debugVisible = rect.width >= px(760) and PNC.Client
        and PNC.Client.CanUseDebug and PNC.Client.CanUseDebug() == true
    self.debugButton:setVisible(debugVisible)
    Layout.SetBounds(self.debugButton,
        rect.x + rect.width - closeWidth - debugWidth - gap,
        buttonsY, debugWidth, controlHeight)
    self.layout = { rect = rect, controlsY = controlsY,
        manifestY = manifestY, statusY = statusY }
end

function ISPNCScavengeWindow:sectionSuffix(kind)
    local snapshot = self.snapshot or {}
    if kind == "manifest" then
        return tostring(#(snapshot.manifest or {}))
    end
    local status = self.lastFailure or snapshot.lastFailure
        or readable(snapshot.state or "ready")
    return string.upper(readable(status))
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

function ISPNCScavengeWindow:updateSearchControl(active)
    if self.searchButton and self.searchButton.setToggleState then
        self.searchButton:setToggleState(active == true)
    end
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
    self:recalculateEstimatedLoad()
end

function ISPNCScavengeWindow:recalculateEstimatedLoad()
    local total, weightByType = 0, {}
    for _, entry in ipairs(self.snapshot and self.snapshot.manifest or {}) do
        if self.selectedEntries[entry.entryId] == true
            or entry.status == "QUEUED"
        then
            local fullType = tostring(entry.fullType or "")
            local weight = weightByType[fullType]
            if weight == nil then
                local metadata = Model.Probe(fullType)
                weight = tonumber(metadata and metadata.weight) or 0
                weightByType[fullType] = weight
            end
            total = total + weight * (tonumber(entry.quantity) or 1)
        end
    end
    self.estimatedLoad = total
    return total
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
    local rows = not self.debugEnabled and self.snapshot
        and self.snapshot.activity or {}
    for index = #rows, 1, -1 do
        local entry = rows[index]
        local actor = tostring(entry.npcName or entry.npcId
            or tr("UI_PNC_Scavenge_Team", "Team"))
        local source = tostring(entry.sourceLabel
            or readable(entry.sourceType) or "")
        local item = tostring(entry.displayName or entry.fullType
            or tr("UI_PNC_Scavenge_Item", "item"))
        local message = item
        local detail = entry.reason or source
        if entry.status == "SOURCE_SEARCHED" then
            message = tr("UI_PNC_Scavenge_LogSearched",
                "%s searched %s", actor, source)
            detail = tr("UI_PNC_Scavenge_LogFound",
                "%s items found", tonumber(entry.itemCount) or 0)
        elseif entry.status == "COLLECTED" then
            message = tr("UI_PNC_Scavenge_LogCollected",
                "%s collected %s x%s", actor, item,
                tonumber(entry.quantity) or 1)
            detail = source ~= "" and tr("UI_PNC_Scavenge_LogFrom",
                "from %s", source) or ""
        elseif entry.status == "SEARCHING" then
            message = tr("UI_PNC_Scavenge_LogSearching",
                "%s is searching %s", actor, source)
            detail = ""
        elseif entry.status == "TAKING" then
            message = tr("UI_PNC_Scavenge_LogTaking",
                "%s is taking %s", actor, item)
            detail = source
        elseif entry.status == "SOURCE_SKIPPED"
            or entry.status == "SOURCE_INVALID"
        then
            message = tr("UI_PNC_Scavenge_LogSkipped",
                "%s could not search %s", actor, source)
        elseif entry.status == "QUEUED" then
            message = tr("UI_PNC_Scavenge_LogQueued",
                "Queued %s", item)
        elseif entry.status == "SEARCH_COMPLETE" then
            message = tr("UI_PNC_Scavenge_LogComplete",
                "Search complete")
        end
        self.statusList:addItem(tostring(index), {
            status = entry.status,
            item = message,
            detail = detail,
        })
    end
    if #rows == 0 and not self.debugEnabled then
        self.statusList:addItem("empty", { status = "WAITING",
            message = "No scavenging activity yet", detail = "" })
    end
    local diagnostics = self.snapshot and self.snapshot.debugDiagnostics
    local live = self.snapshot and self.snapshot.scavengeDebug
    if self.debugEnabled and live then
        self.statusList:addItem("debug-session", { status = "SESSION",
            item = tostring(live.state or "none") .. " / "
                .. tostring(live.phase or "none"),
            detail = string.format("sources %d/%d  next %d",
                tonumber(live.processedCount) or 0,
                tonumber(live.candidateCount) or 0,
                tonumber(live.nextCandidateIndex) or 0) })
        for _, worker in ipairs(live.workers or {}) do
            self.statusList:addItem("worker:" .. tostring(worker.npcId), {
                status = "WORKER", item = tostring(worker.npcName)
                    .. " — " .. readable(worker.workerPhase),
                detail = tostring(worker.waitReason or worker.leasePhase or "active") })
            local source = worker.currentSource
            if source then
                self.statusList:addItem("source:" .. tostring(worker.npcId), {
                    status = "SOURCE", item = tostring(source.sourceLabel
                        or readable(source.sourceType) or source.sourceToken),
                    detail = string.format("%s  %.1f,%.1f,%d  d2=%s  %s",
                        tostring(source.sourceType or "source"),
                        tonumber(source.x) or 0, tonumber(source.y) or 0,
                        tonumber(source.z) or 0,
                        tostring(source.workerDistanceSq or "?"),
                        source.valid and "valid" or "INVALID") })
            end
            local path = worker.path or {}
            local intent = worker.moveIntent or {}
            self.statusList:addItem("move:" .. tostring(worker.npcId), {
                status = "MOVE", item = tostring(worker.lastMovement
                    or intent.kind or "none"),
                detail = tostring(path.phase or "no lane") .. " / "
                    .. tostring(path.reason or path.intentReason
                        or intent.reason or worker.lastFailure or "ready") })
        end
        for _, source in ipairs(live.pendingSources or {}) do
            self.statusList:addItem("pending:" .. tostring(source.index), {
                status = source.status or "PENDING",
                item = string.format("#%d %s", tonumber(source.index) or 0,
                    tostring(source.sourceLabel or readable(source.sourceType))),
                detail = string.format("%s  %.1f,%.1f,%d  %s",
                    tostring(source.sourceType or "source"),
                    tonumber(source.x) or 0, tonumber(source.y) or 0,
                    tonumber(source.z) or 0,
                    source.valid and "valid" or "INVALID") })
        end
    end
    if self.debugEnabled and diagnostics then
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
        if snapshot and snapshot.requestAction == "start_search" then
            self:updateSearchControl(false)
        elseif snapshot and snapshot.requestAction == "cancel_search" then
            self:updateSearchControl(true)
        end
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
    if snapshot.disbanded == true then
        self.npcIds = {}
        self.selectedEntries = {}
        self.expandedGroups = {}
    end
    if snapshot.sourcePolicy then
        self.sourcePolicy = {
            containers = snapshot.sourcePolicy.containers == true,
            floorItems = snapshot.sourcePolicy.floorItems == true,
            corpses = snapshot.sourcePolicy.corpses == true,
        }
    end
    self:updateToggleTitles()
    self:updateSearchControl(Controller.IsSearchActive(snapshot))
    self:rebuildManifest()
    self:recalculateEstimatedLoad()
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
        local stopping = self.searchButton.getToggleState
            and self.searchButton:getToggleState()
            or Controller.IsSearchActive(self.snapshot)
        local ok, reason
        if stopping then
            ok, reason = Controller.StopSearch(self.snapshot, self.npcId)
        else
            ok, reason = Controller.StartSearch({
                npcId = self.npcId, npcIds = self.npcIds,
                radius = PNC.Const.SCAVENGE_DEFAULT_RADIUS,
                sourcePolicy = self.sourcePolicy,
            })
        end
        if ok == true then self:updateSearchControl(not stopping) end
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
    if action == "disband" then
        return Controller.Disband(self.snapshot, self.npcId)
    end
    if action == "debug_dump" then
        self.debugEnabled = not self.debugEnabled
        self.debugButton:setTitle(self.debugEnabled and "Live Debug: ON"
            or "Live Debug: OFF")
        self.nextDebugRequestAt = 0
        self:requestResponsiveLayout(true)
        self:rebuildStatus()
        if not self.debugEnabled then return true end
        return PNC.Client.SendScavengeRequest("debug_dump", {
            sessionId = self.snapshot and self.snapshot.sessionId,
        })
    end
    if action == "close" then self:close(); return true end
end

function ISPNCScavengeWindow:prerender()
    UI.Window.prerender(self)
    if self.debugEnabled and self.snapshot and self.snapshot.sessionId then
        local now = getTimeInMillis and getTimeInMillis() or 0
        if now >= (tonumber(self.nextDebugRequestAt) or 0) then
            self.nextDebugRequestAt = now + 750
            PNC.Client.SendScavengeRequest("debug_dump", {
                sessionId = self.snapshot.sessionId,
            })
        end
    end
    if not self.layout then return end
    local snapshot = self.snapshot or {}
    local progress = tonumber(snapshot.progress) or 0
    local rect = self.layout.rect
    local progressText = tr("UI_PNC_Scavenge_Progress",
        "Search: %s%%  |  %s searched  |  %s unreachable",
        progress, tonumber(snapshot.searchedCount) or 0,
        tonumber(snapshot.unreachableCount) or 0)
    local scavengerCount = tonumber(snapshot.scavengerCount)
        or #(snapshot.scavengers or self.npcIds or {})
    progressText = tr("UI_PNC_Scavenge_SearcherCount",
        "Scavengers: %s", scavengerCount) .. "  |  " .. progressText
    self:drawText(progressText, rect.x,
        rect.y + 3, 0.72, 0.86, 0.94, 1, UIFont.Small)
    local carry = snapshot.carry
    local carryText = carry and tr("UI_PNC_Scavenge_Carry",
        "Carry %s / %s (%s)",
        string.format("%.2f", tonumber(carry.usedWeight) or 0),
        string.format("%.2f", tonumber(carry.maxWeight) or 0),
        readable(carry.level)) or tr("UI_PNC_Scavenge_CarryUnavailable",
            "Carry unavailable")
    carryText = carryText .. tr("UI_PNC_Scavenge_QueuedLoad",
        "  |  Queued ~%s", string.format("%.2f",
            tonumber(self.estimatedLoad) or 0))
    self:drawTextRight(carryText, rect.x + rect.width, rect.y + 3,
        0.72, 0.74, 0.78, 1, UIFont.Small)
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
    o.debugEnabled = false
    o.nextDebugRequestAt = 0
    o.estimatedLoad = 0
    return o
end

local function getOrCreate()
    if ScavengeUI.instance then return ScavengeUI.instance end
    local spec = { width = 820, height = 600, minWidth = 700,
        minHeight = 500, maxWidth = 1050, maxHeight = 760,
        anchor = "center" }
    local bounds = Layout.ResolveWindow(spec)
    local title = tr("UI_PNC_Scavenge_Title", "Scavenging")
    local window = ISPNCScavengeWindow:new(bounds.x, bounds.y,
        bounds.width, bounds.height, {
            title = title,
            responsiveSpec = spec,
            persistenceKey = "ProjectHoomans:ScavengeWindow:v2",
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
    end
    return window ~= nil
end

return ScavengeUI
