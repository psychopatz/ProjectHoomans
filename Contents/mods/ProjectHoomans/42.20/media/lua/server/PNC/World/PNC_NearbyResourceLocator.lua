-- Stable loaded-world resource discovery entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NearbyResourceLocator = PNC.NearbyResourceLocator or {}
PNC.NearbyResourceLocator.Internal =
    PNC.NearbyResourceLocator.Internal or {}

local Locator = PNC.NearbyResourceLocator
Locator.Cache = Locator.Cache or {}
Locator.DEFAULT_RADIUS = 12
Locator.DEFAULT_CACHE_MS = 500

require "PNC/World/NearbyResourceLocator/PNC_NearbyResourceLocator_Core"
require "PNC/World/NearbyResourceLocator/PNC_NearbyResourceLocator_Items"
require "PNC/World/NearbyResourceLocator/PNC_NearbyResourceLocator_Objects"

return Locator
