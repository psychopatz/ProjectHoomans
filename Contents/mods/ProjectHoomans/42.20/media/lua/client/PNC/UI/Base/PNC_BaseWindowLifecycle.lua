local BaseTab = require
    "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_Tab"
local BuildingTab = require "PNC/UI/Base/PNC_BaseBuildingTab"
local Queue = require "PNC/UI/Base/PNC_BaseQueue"
local Territory = require
    "PNC/UI/CommandHub/PNC_CommandHub_BaseTerritoryActions"
local Placement = require
    "PNC/UI/Communities/ColonyManagement/PNC_BuildingPlacement"
local Options = require "PsychopatzCore/UI/PsychopatzCommandHubOptions"
local Layout = PsychopatzCore.UI.Layout
local WidgetWindow = PsychopatzCore.UI.WidgetWindow
local Client = PNC.ColonyManagementClient

local function applyReadableSurface(control, role, minimum)
    if not control then return nil end
    local alpha = Options.ApplySurfaceOpacity(control, role)
    if control.backgroundColor then
        control.backgroundColor.a = math.max(tonumber(minimum) or 0.72,
            tonumber(alpha) or 0)
        control.commandHubSurfaceOpacity = control.backgroundColor.a
    end
    return control.backgroundColor and control.backgroundColor.a or alpha
end

function ISPNCBaseWindow:applyContentStyle()
    local signature = Options.GetContentOpacitySignature()
    if self.lastContentOpacitySignature == signature then return end

    local panels = {
        self.baseSummary,
        self.baseFacilityPane, self.baseComponentPane, self.baseQueuePane,
        self.baseBuildingDetails, self.baseBuildingMaterialPane,
        self.baseBuildingNativeQueuePane, self.buildRecipePreview,
    }
    for _, panel in ipairs(panels) do
        applyReadableSurface(panel, "surface", 0.72)
    end

    local lists = {
        self.baseFacilityList, self.baseComponentList, self.baseQueueList,
        self.baseBuildingMaterialList, self.baseBuildingNativeQueue,
        self.buildCategoryList, self.buildRecipeList, self.buildQueueList,
        self.buildMaterialList,
    }
    for _, list in ipairs(lists) do
        if list then list.readableRestricted = true end
        applyReadableSurface(list, "detail", 0.76)
    end

    self.contentSurfaceAlpha = Options.GetContentOpacity("surface")
    self.contentDetailAlpha = Options.GetContentOpacity("detail")
    self.lastContentOpacitySignature = signature
end

function ISPNCBaseWindow:requestSnapshot(source)
    local request = Client.RequestBaseSnapshot or Client.RequestSnapshot
    local _, _, requestedAt = request()
    self.lastRequestAt = requestedAt
    if PNC.CommandHub and PNC.CommandHub.Trace then
        PNC.CommandHub.Trace("pnc_base_snapshot_requested",
            "source=" .. tostring(source or "automatic")
            .. " tab=" .. tostring(self.tab))
    end
end

function ISPNCBaseWindow:refresh(update)
    update = update or (Client.ReadBaseSnapshot and Client.ReadBaseSnapshot()
        or Client.ReadSnapshot())
    self.snapshot = update.snapshot or {}
    Territory.ApplyResult(self, self.snapshot)
    self:applyContentStyle()
    BaseTab.Rebuild(self, self.snapshot)
    Queue.Rebuild(self, self.snapshot)
    BuildingTab.Rebuild(self, self.snapshot)
    BaseTab.Apply(self, self.tab == "base")
    Queue.Apply(self, self.tab == "base")
    BuildingTab.Apply(self, self.tab == "facilities"
        or self.tab == "buildings")
    self.baseSummary.owner = self
    self.lastReceiveAt = update.receivedAt or PNC.Core.Now()
    self.lastReceiveRevision = tonumber(update.revision) or 0
    -- Rebuilds may create category buttons/cards after the initial window
    -- layout. Mark the host dirty, but let the normal non-forced pass place
    -- them so a snapshot never resets a live list during interaction.
    self:invalidateLayout("base_snapshot")
    -- Snapshot delivery is frequent. Re-layout only when the layout host is
    -- dirty or the window changed size; forcing a full layout on every poll
    -- makes native lists visibly blink and can interrupt mouse capture.
    self:requestResponsiveLayout(false)
end

function ISPNCBaseWindow:prerender()
    if self.owner and self.owner.getIsVisible
        and not self.owner:getIsVisible()
    then
        self:close()
        return
    end
    if self.uiScale ~= Layout.Scale() then
        self.uiScale = Layout.Scale()
        self:requestResponsiveLayout(true)
    end
    self:applyContentStyle()
    local now = PNC.Core.Now()
    if now - (tonumber(self.lastRequestAt) or 0) >= 2000 then
        self:requestSnapshot("poll")
    end
    local hasUpdate = Client.HasBaseUpdate or Client.HasUpdate
    local changed, update = hasUpdate(
        self.lastReceiveRevision, self.lastReceiveAt)
    if changed then self:refresh(update) end
    PsychopatzWindow.prerender(self)
    if WidgetWindow then WidgetWindow.Sync(self) end
end

function ISPNCBaseWindow:close()
    Placement.Cancel(self, { restorePrevious = false })
    self:saveGeometry(true)
    self:setVisible(false)
    self:removeFromUIManager()
    if PNC.BaseUI.instance == self then PNC.BaseUI.instance = nil end
end

return ISPNCBaseWindow
