-- Faction debug window responsive layout.

PNC = PNC or {}
PNC.FactionDebugUI = PNC.FactionDebugUI or {}

local FactionUI = PNC.FactionDebugUI
local Internal = FactionUI.Internal or {}
FactionUI.Internal = Internal
local Layout = Internal.Layout
local CONTROLS = Internal.Controls

local function setMobileLayout(self, rect, top, height, gap)
    local mobileWidth = math.max(
        260,
        math.min(420, math.floor((rect.width - gap) * 0.38))
    )
    self.layout = {
        mobile = {
            x = rect.x, y = top,
            width = mobileWidth, height = height,
        },
        detail = {
            x = rect.x + mobileWidth + gap,
            y = top,
            width = rect.width - mobileWidth - gap,
            height = height,
        },
    }
    self.factions:setVisible(false)
    self.targets:setVisible(false)
    self.npcs:setVisible(false)
    self.mobileGroups:setVisible(true)
    Layout.SetBounds(
        self.mobileGroups,
        self.layout.mobile.x,
        self.layout.mobile.y,
        self.layout.mobile.width,
        self.layout.mobile.height
    )
    Layout.SetBounds(
        self.details,
        self.layout.detail.x,
        self.layout.detail.y,
        self.layout.detail.width,
        self.layout.detail.height
    )
    Layout.SetBounds(
        self.dashboard,
        self.layout.detail.x,
        self.layout.detail.y,
        self.layout.detail.width,
        self.layout.detail.height
    )
    self.dashboard:setVisible(false)
    self.details:setVisible(true)
end

local function setPersistentLayout(self, rect, top, height, gap)
    local listWidth = math.max(
        150,
        math.floor((rect.width - gap * 3) * 0.19)
    )
    self.factions:setVisible(true)
    self.targets:setVisible(true)
    self.npcs:setVisible(true)
    self.mobileGroups:setVisible(false)
    self.layout = {
        faction = {
            x = rect.x, y = top,
            width = listWidth, height = height,
        },
        target = {
            x = rect.x + listWidth + gap, y = top,
            width = listWidth, height = height,
        },
        npc = {
            x = rect.x + listWidth * 2 + gap * 2, y = top,
            width = listWidth, height = height,
        },
        detail = {
            x = rect.x + listWidth * 3 + gap * 3,
            y = top,
            width = rect.width - listWidth * 3 - gap * 3,
            height = height,
        },
    }
    for widget, bounds in pairs({
        [self.factions] = self.layout.faction,
        [self.mobileGroups] = self.layout.faction,
        [self.targets] = self.layout.target,
        [self.npcs] = self.layout.npc,
        [self.details] = self.layout.detail,
        [self.dashboard] = self.layout.detail,
    }) do
        Layout.SetBounds(
            widget,
            bounds.x, bounds.y, bounds.width, bounds.height
        )
    end
    self.dashboard:setVisible(self.viewMode == "overview")
    self.details:setVisible(self.viewMode ~= "overview")
end

function ISPNCFactionDebugWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 28, bottom = 12 })
    local visibleControls = {}
    for index, button in ipairs(self.controls) do
        local definition = CONTROLS[index]
        local visible = definition.views == nil
            or definition.views[self.viewMode] == true
        button:setVisible(visible)
        if visible then
            visibleControls[#visibleControls + 1] = button
            if definition.id == "population_label" then
                self.groupSizeEntry:setVisible(true)
                visibleControls[#visibleControls + 1] =
                    self.groupSizeEntry
            end
        end
    end
    if self.viewMode ~= "overview"
        and self.viewMode ~= "mobile"
    then
        self.groupSizeEntry:setVisible(false)
    end
    local controls = Layout.Flow(
        visibleControls,
        { x = rect.x, y = rect.y, width = rect.width },
        { scale = self.uiScale, minWidth = 76 }
    )
    local top = controls.bottom + Layout.Pixels(25, self.uiScale)
    local height = math.max(100, rect.y + rect.height - top)
    local gap = Layout.Pixels(8, self.uiScale)
    if self.viewMode == "mobile" then
        setMobileLayout(self, rect, top, height, gap)
        return
    end
    setPersistentLayout(self, rect, top, height, gap)
end
