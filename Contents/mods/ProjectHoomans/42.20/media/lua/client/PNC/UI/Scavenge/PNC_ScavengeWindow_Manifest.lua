local Window = ISPNCScavengeWindow
if not Window then return end

local Internal = Window.Internal or {}
local Model = Internal.Model
local ScavengeModel = Internal.ScavengeModel
local tr = Internal.tr
local readable = Internal.readable
local eligible = Internal.eligible

function Window:toggleInventoryGroup(_, groupKey)
    self.expandedGroups[groupKey] = self.expandedGroups[groupKey] == false
    self:rebuildManifest()
end

function Window:onInventoryRowClick(_, row)
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

function Window:recalculateEstimatedLoad()
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

function Window:showItemContext(_, row)
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

function Window:filtered(entry)
    if entry.sourceType == "container" and not self.sourcePolicy.containers
        or entry.sourceType == "floor" and not self.sourcePolicy.floorItems
        or entry.sourceType == "corpse" and not self.sourcePolicy.corpses
    then return true end
    local query = string.lower(tostring(self.searchEntry:getText() or ""))
    return query ~= "" and not string.find(string.lower(
        tostring(entry.displayName or entry.fullType or "")), query, 1, true)
end

function Window:rebuildManifest()
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
