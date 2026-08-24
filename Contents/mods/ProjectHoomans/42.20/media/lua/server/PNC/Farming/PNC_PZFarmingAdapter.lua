-- Stable Project Zomboid farming adapter entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PZFarmingAdapter = PNC.PZFarmingAdapter or {}

require "PNC/Farming/PZFarmingAdapter/PNC_PZFarmingAdapter_Context"
require "PNC/Farming/PZFarmingAdapter/PNC_PZFarmingAdapter_Inspection"
require "PNC/Farming/PZFarmingAdapter/PNC_PZFarmingAdapter_PlotActions"
require "PNC/Farming/PZFarmingAdapter/PNC_PZFarmingAdapter_Inventory"
require "PNC/Farming/PZFarmingAdapter/PNC_PZFarmingAdapter_Cultivation"
require "PNC/Farming/PZFarmingAdapter/PNC_PZFarmingAdapter_Research"

return PNC.PZFarmingAdapter
