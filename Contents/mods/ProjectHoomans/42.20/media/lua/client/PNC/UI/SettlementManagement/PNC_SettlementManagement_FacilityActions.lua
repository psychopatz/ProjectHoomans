local Shared = require "PNC/UI/Shared/PNC_ColonyUIShared"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Support = require "PNC/UI/SettlementManagement/PNC_SettlementManagement_SelectorSupport"
local Placement = require "PNC/UI/Base/PNC_BaseBuildingPlacement"
local BuildAudit = require "PNC/Core/Diagnostics/PNC_BuildAudit"
local Farming = PNC.Farming

local Facility = PNC.SettlementManagementFacilityActions or {}
PNC.SettlementManagementFacilityActions = Facility

-- Stable build boundary: the selector provider retains the failure route
-- `if not selector then return false` and propagates its reason.

local ANCHOR_LABELS = {
    ["sleep.bed"] = "UI_PNC_Facility_SleepSpot",
    ["work.research"] = "UI_PNC_Facility_ResearchTable",
    ["work.blueprint"] = "UI_PNC_Facility_ResearchTable",
    ["work.reverse"] = "UI_PNC_Facility_ResearchTable",
    ["work.craft"] = "UI_PNC_Facility_CraftingTable",
    ["work.disassemble"] = "UI_PNC_Facility_RecyclingSpot",
    ["dining.table"] = "UI_PNC_Facility_DiningTable",
    ["health.bed"] = "UI_PNC_Facility_HospitalBed",
}
local ANCHOR_SELECT_TITLES = {
    ["sleep.bed"] = "UI_PNC_Facility_SelectBed",
    ["work.research"] = "UI_PNC_Facility_SelectResearchTable",
    ["work.blueprint"] = "UI_PNC_Facility_SelectResearchTable",
    ["work.reverse"] = "UI_PNC_Facility_SelectResearchTable",
    ["work.craft"] = "UI_PNC_Facility_SelectCraftStation",
    ["work.disassemble"] = "UI_PNC_Facility_SelectDisassemblyStation",
    ["dining.table"] = "UI_PNC_Facility_SelectDiningTable",
    ["health.bed"] = "UI_PNC_Facility_SelectHospitalBed",
}
local ANCHOR_ASSIGN_TITLES = {
    ["sleep.bed"] = "UI_PNC_Facility_AssignBed",
    ["work.research"] = "UI_PNC_Facility_AssignResearchTable",
    ["work.blueprint"] = "UI_PNC_Facility_AssignResearchTable",
    ["work.reverse"] = "UI_PNC_Facility_AssignResearchTable",
    ["work.craft"] = "UI_PNC_Facility_AssignCraftStation",
    ["work.disassemble"] = "UI_PNC_Facility_AssignDisassemblyStation",
    ["dining.table"] = "UI_PNC_Facility_AssignDiningTable",
    ["health.bed"] = "UI_PNC_Facility_AssignHospitalBed",
}


Facility.Internal = Facility.Internal or {}
Facility.Internal.AnchorLabels = ANCHOR_LABELS
Facility.Internal.AnchorSelectTitles = ANCHOR_SELECT_TITLES
Facility.Internal.AnchorAssignTitles = ANCHOR_ASSIGN_TITLES

require "PNC/UI/SettlementManagement/PNC_SettlementManagement_FacilityActions_Area"
require "PNC/UI/SettlementManagement/PNC_SettlementManagement_FacilityActions_Build"
require "PNC/UI/SettlementManagement/PNC_SettlementManagement_FacilityActions_Anchors"

return Facility
