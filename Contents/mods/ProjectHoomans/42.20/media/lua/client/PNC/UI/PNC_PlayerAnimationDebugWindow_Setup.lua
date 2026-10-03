-- Catalog tabs, filtering, and list population.
local WindowAPI = PNC.PlayerAnimationDebugUI
local Internal = WindowAPI.Internal
local TEXT = Internal.TEXT
local Catalog = Internal.Catalog
local UI = Internal.UI
local Layout = Internal.Layout
local lower = Internal.lower
local searchText = Internal.searchText
local drawAnimationItem = Internal.drawAnimationItem
local buildFilters = Internal.buildFilters
local matchesFilter = Internal.matchesFilter

function ISPNCPlayerAnimationDebugWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCPlayerAnimationDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.activeSource = "player"
    self.filtersBySource = {
        player = buildFilters("player"),
        zombie = buildFilters("zombie"),
    }

    self.tabButtons = {}
    local tabDefinitions = {
        { "player", TEXT.playerTab, "selected" },
        { "zombie", TEXT.zombieTab, "quiet" },
    }
    for _, definition in ipairs(tabDefinitions) do
        local button = UI.CreateButton(self, {
            id = definition[1],
            title = definition[2],
            target = self,
            onclick = UI.ButtonCallback(function(clicked)
                return ISPNCPlayerAnimationDebugWindow.onTabAction(
                    self, clicked)
            end),
            variant = definition[3],
        })
        self.tabButtons[#self.tabButtons + 1] = button
        self[definition[1] .. "TabButton"] = button
    end

    self.search = UI.CreateTextEntry(self, {
        clearButton = true,
        width = 100,
        height = 26,
        tooltip = TEXT.search,
        onTextChange = function() self:refreshCatalog() end,
    })

    self.categoryFilter = ISComboBox:new(0, 0, 160, 26, self,
        ISPNCPlayerAnimationDebugWindow.onCategoryChanged)
    self.categoryFilter:initialise()
    self.categoryFilter:instantiate()
    self:addChild(self.categoryFilter)
    self:rebuildCategoryFilter()

    self.list = UI.CreateList(self, {
        itemHeight = 56,
        doDrawItem = drawAnimationItem,
    })
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = 26,
        valueXMax = 152,
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

    self.buttons = {}
    local definitions = {
        { "play", TEXT.play, "selected" },
        { "replay", TEXT.replay, "quiet" },
        { "stop", TEXT.stop, "danger" },
        { "dump", TEXT.dump, "quiet" },
        { "loop", TEXT.loop, "quiet" },
    }
    for _, definition in ipairs(definitions) do
        local button = UI.CreateButton(self, {
            id = definition[1],
            title = definition[2],
            target = self,
            onclick = UI.ButtonCallback(function(clicked)
                return ISPNCPlayerAnimationDebugWindow.onAction(self, clicked)
            end),
            variant = definition[3],
        })
        self.buttons[#self.buttons + 1] = button
        self[definition[1] .. "Button"] = button
    end
    self:refreshCatalog()
    self:requestResponsiveLayout(true)
end

function ISPNCPlayerAnimationDebugWindow:rebuildCategoryFilter()
    if not self.categoryFilter then return end
    local filters = self.filtersBySource[self.activeSource] or {}
    self.categoryFilter:clear()
    for _, filter in ipairs(filters) do
        self.categoryFilter:addOption(filter.label)
    end
    self.categoryFilter.selected = 1
    self.activeFilter = filters[1] or {}
end

function ISPNCPlayerAnimationDebugWindow:selectedFilter()
    local selected = tonumber(self.categoryFilter
        and self.categoryFilter.selected) or 1
    local filters = self.filtersBySource[self.activeSource] or {}
    return filters[selected] or filters[1] or {}
end

function ISPNCPlayerAnimationDebugWindow:onCategoryChanged()
    self.activeFilter = self:selectedFilter()
    self:refreshCatalog()
end

function ISPNCPlayerAnimationDebugWindow:setSource(source)
    if source ~= "player" and source ~= "zombie" then return end
    if self.activeSource == source then return end
    self.activeSource = source
    self:rebuildCategoryFilter()
    self:refreshCatalog()
    self:refreshControls()
end

function ISPNCPlayerAnimationDebugWindow:onTabAction(button)
    self:setSource(button and button.internal or "player")
end

function ISPNCPlayerAnimationDebugWindow:getSelectedEntry()
    local row = self.list and self.list:getItem() or nil
    return row and row.item or nil
end

function ISPNCPlayerAnimationDebugWindow:refreshCatalog()
    if not self.list then return end
    local previous = self:getSelectedEntry()
    local previousKey = previous
        and (tostring(previous.state) .. "/" .. tostring(previous.file)
            .. "/" .. tostring(previous.node)) or nil
    local query = lower(self.search and self.search:getText() or "")
    local filter = self:selectedFilter()
    self.list:clear()
    for _, entry in ipairs(Catalog.entries or {}) do
        if matchesFilter(entry, self.activeSource, filter)
            and (query == "" or string.find(searchText(entry), query, 1, true))
        then
            self.list:addItem(tostring(entry.node or entry.file), entry)
            local key = tostring(entry.state) .. "/" .. tostring(entry.file)
                .. "/" .. tostring(entry.node)
            if previousKey and previousKey == key then
                self.list.selected = #self.list.items
            end
        end
    end
    if #self.list.items > 0 and (tonumber(self.list.selected) or 0) < 1 then
        self.list.selected = 1
    end
    self.visibleCount = #self.list.items
    self:refreshDetails(true)
end


return WindowAPI
