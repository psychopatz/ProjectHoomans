local T = require "tests/support/test"

local definitionsSource = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Settlement/PNC_FacilityDefinitions.lua"
)
local settlementSource = T.read(
    "ProjectHoomans",
    "server",
    "PNC/Settlement/PNC_Settlement.lua"
)
T.falsy(definitionsSource:find("PNC_FacilityDefinitions_Water", 1, true),
    "settlement definitions no longer load the water facility")
T.falsy(settlementSource:find("PNC_WaterUtilityService", 1, true),
    "settlement no longer loads the abstract water utility")
T.finish("pnc_water_utility_smoke")
