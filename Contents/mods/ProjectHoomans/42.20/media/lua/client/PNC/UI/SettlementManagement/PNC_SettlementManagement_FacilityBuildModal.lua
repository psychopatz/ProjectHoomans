require "ISUI/ISPanel"
require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.FacilityBuildUI = PNC.FacilityBuildUI or {}

local BuildUI = PNC.FacilityBuildUI
require "PNC/UI/SettlementManagement/PNC_SettlementManagement_FacilityBuildCatalog"
require "PNC/UI/SettlementManagement/PNC_SettlementManagement_FacilityBuildCard"
local FacilityCard = BuildUI.FacilityCard
BuildUI.lastOpenArgs = BuildUI.lastOpenArgs or nil
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout
local CATEGORY_ORDER = { "housing", "food", "technology", "utilities",
    "production" }
local CATEGORY_LABELS = {
    housing = "HOUSING", food = "FOOD", production = "PRODUCTION",
    technology = "TECHNOLOGY", utilities = "UTILITIES",
}
local PAGE_SIZE = 4
local FACILITY_WINDOW_SPEC = {
    -- Logical pixels scaled from PsychopatzCore's 1920x1080 baseline.
    width = 1180,
    height = 760,
    minWidth = 760,
    minHeight = 540,
    maxWidth = 1440,
    maxHeight = 920,
    screenMargin = 24,
}

local function facilityWindowSpec()
    local spec = {}
    for key, value in pairs(FACILITY_WINDOW_SPEC) do spec[key] = value end
    return spec
end

BuildUI.WindowSpec = facilityWindowSpec

local function tr(key, fallback)
    local value = getText and PNC.Translation.GetKey(key) or nil
    if not value or value == key then return fallback end
    return value
end

local function canUseDebug()
    local client = PNC.Client
    return client and client.CanUseDebug
        and client.CanUseDebug() == true
end

local BuildInternal = BuildUI.Internal or {}
BuildUI.Internal = BuildInternal
BuildInternal.BuildUI = BuildUI
BuildInternal.UI = UI
BuildInternal.Layout = Layout
BuildInternal.Translate = tr
BuildInternal.CanUseDebug = canUseDebug
BuildInternal.WindowSpec = facilityWindowSpec
BuildInternal.Theme = Theme
BuildInternal.FacilityCard = FacilityCard
BuildInternal.CategoryOrder = CATEGORY_ORDER
BuildInternal.CategoryLabels = CATEGORY_LABELS
BuildInternal.PageSize = PAGE_SIZE

ISPNCFacilityBuildWindow = PsychopatzWindow:derive("ISPNCFacilityBuildWindow")

function ISPNCFacilityBuildWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCFacilityBuildWindow:close()
    self:setVisible(false); self:removeFromUIManager()
    if BuildUI.instance == self then BuildUI.instance = nil end
end

function ISPNCFacilityBuildWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self); self.__index = self
    object.options = options.options or {}
    object.onConfirm = options.onConfirm
    object.focusDefinitionId = options.focusDefinitionId
    object.settlement = options.settlement
    object.storage = options.storage
    object.research = options.research
    object.snapshotRevision = tonumber(options.snapshotRevision) or 0
    object.debugMaterialsPending = false
    object.openArgs = options.openArgs
    return object
end


require "PNC/UI/SettlementManagement/PNC_SettlementManagement_FacilityBuildPresentation"
require "PNC/UI/SettlementManagement/PNC_SettlementManagement_FacilityBuildInteraction"

return BuildUI
