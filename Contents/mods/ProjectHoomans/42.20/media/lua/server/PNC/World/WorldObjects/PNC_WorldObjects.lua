-- Canonical unified facade for NPC world-object discovery and registration.
--
-- Consolidates the legacy `PNC.FacilityResources` detector registry (used by
-- settlements, camps, and roaming autonomy) together with the unified
-- `PNC.WorldObjects.Scanner` so callers depend on one clean namespace regardless
-- of whether an NPC is at home, at camp, or roaming.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorldObjects = PNC.WorldObjects or {}

local WorldObjects = PNC.WorldObjects
local Registry = PNC.FacilityResources
    or require "PNC/Settlement/PNC_FacilityResources"
local Scanner = require "PNC/World/WorldObjects/PNC_WorldObjectScanner"

WorldObjects.VERSION = 1
WorldObjects.Registry = Registry
WorldObjects.Scanner = Scanner

-- Clean, capability-oriented public aliases over the canonical registry.
function WorldObjects.Register(id, definition)
    return Registry.Register(id, definition)
end

function WorldObjects.Unregister(id)
    Scanner.ClearCache()
    return Registry.Unregister(id)
end

function WorldObjects.GetDetector(id)
    return Registry.GetDetector(id)
end

function WorldObjects.ListDetectors(filter)
    return Registry.ListDetectors(filter)
end

function WorldObjects.ListByCapability(capability)
    return Registry.ListByCapability(capability)
end

function WorldObjects.InspectSquare(square, add, context, detectorIDs)
    return Registry.InspectSquare(square, add, context, detectorIDs)
end

function WorldObjects.ScanRadius(originX, originY, originZ, options)
    return Scanner.ScanRadius(originX, originY, originZ, options)
end

function WorldObjects.FindBestInRadius(record, origin, capability, options)
    return Scanner.FindBestInRadius(record, origin, capability, options)
end

function WorldObjects.ClearCache()
    Scanner.ClearCache()
    if Registry then Registry.Cache = {} end
end

return WorldObjects
