-- Domain registration: World. Ordered startup only; no gameplay policy.
if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end
require "PNC/World/PNC_NearbyResourceLocator"
require "PNC/World/PNC_NearbyWaterService"
require "PNC/World/PNC_WaterContainerService"
require "PNC/World/PNC_CampResourceService"
