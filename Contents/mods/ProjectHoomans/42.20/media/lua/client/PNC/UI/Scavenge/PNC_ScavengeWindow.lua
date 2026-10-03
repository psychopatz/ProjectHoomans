require "ISUI/ISButton"
require "ISUI/ISPanel"
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
    return PNC.Translation.TrFormat(key, fallback, ...)
end

local function readable(value)
    return tostring(value or ""):gsub("_", " ")
end

local function eligible(entry)
    return entry and (entry.status == "AVAILABLE"
        or entry.status == "QUEUED")
end

ISPNCScavengeWindow = UI.Window:derive("ISPNCScavengeWindow")

function ISPNCScavengeWindow:initialise()
    UI.Window.initialise(self)
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

ISPNCScavengeWindow.Internal = {
    Controller = Controller,
    Model = Model,
    ScavengeModel = ScavengeModel,
    tr = tr,
    readable = readable,
    eligible = eligible,
    UI = UI,
    Layout = Layout,
    Theme = Theme,
}
require "PNC/UI/Scavenge/PNC_ScavengeWindow_Manifest"
require "PNC/UI/Scavenge/PNC_ScavengeWindow_Status"
require "PNC/UI/Scavenge/PNC_ScavengeWindow_Actions"
require "PNC/UI/Scavenge/PNC_ScavengeWindow_View"
require "PNC/UI/Scavenge/PNC_ScavengeWindow_Render"
require "PNC/UI/Scavenge/PNC_ScavengeWindow_Lifecycle"

return ScavengeUI
