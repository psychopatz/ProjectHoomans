-- Catalog filtering, selection retention, and detail projection.

PNC = PNC or {}

local Internal = PNC.PuppetOperaAnimationTabInternal
local tr = Internal.tr
local Class = ISPNCPuppetOperaAnimationTab

function Class:updateQuery()
    local model = self.ownerWindow and self.ownerWindow.model
    if not model then return end
    local query = self.search and self.search.getText
        and self.search:getText() or ""
    if self.catalogName == "player" then
        model.SetPlayerQuery(query)
    else
        model.SetNPCQuery(query)
    end
end

function Class:rebuildFilter()
    local model = self.ownerWindow and self.ownerWindow.model
    if not self.filter or not model then return end
    self.filter:clear()
    if self.catalogName == "player" then
        self.filter:addOption(tr("UI_PNC_PuppetOpera_PlayerCatalog",
            "Player catalog"))
        self.filter:addOption(tr("UI_PNC_PuppetOpera_ZombieSourceBridges",
            "Player-compatible bridges"))
        self.filter.selected = model.GetPlayerSource() == "bridge"
            and 2 or 1
    else
        self.filter:addOption(tr("UI_PNC_PuppetOpera_AllStates",
            "All states"))
        self.states = model.GetNPCStates()
        for _, state in ipairs(self.states or {}) do
            self.filter:addOption(tostring(state))
        end
        local selected = model.GetNPCState()
        self.filter.selected = 1
        for index, state in ipairs(self.states or {}) do
            if state == selected then self.filter.selected = index + 1 end
        end
    end
end

function Class:onFilterChanged()
    local model = self.ownerWindow and self.ownerWindow.model
    if not model then return false end
    if self.catalogName == "player" then
        model.SetPlayerSource(
            tonumber(self.filter.selected) == 2 and "bridge" or "player"
        )
    else
        local selected = tonumber(self.filter.selected) or 1
        model.SetNPCState(
            selected <= 1 and nil or self.states[selected - 1]
        )
    end
    self:refreshCatalog()
end

function Class:refreshTargets()
    -- Actor identity is selected once by the parent window. Keeping a second
    -- target selector here made it possible to preview one live body and
    -- assign another scene slot, which was the source of the old ambiguity.
    self.targets = {}
end

function Class:onTargetChanged()
    return false
end

function Class:getSelectedEntry()
    local row = self.list and self.list:getItem() or nil
    return row and row.item or nil
end

function Class:refreshCatalog()
    local owner = self.ownerWindow
    local model = owner and owner.model
    if not self.list or not model then return end
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
    for _, entry in ipairs(entries or {}) do
        if type(entry) == "table" then
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
    end
    if #self.list.items > 0 and (tonumber(self.list.selected) or 0) < 1 then
        self.list.selected = 1
    end
    self.visibleCount = #self.list.items
    self:refreshTargets()
    self:refreshDetails()
end

return Class
