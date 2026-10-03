-- Physical sleep-surface detector registration.
--
-- Bed and sofa descriptors are registered here; the public detector registry
-- and validation contract remain owned by the FacilityResources root.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityResources = PNC.FacilityResources or {}

local Resources = PNC.FacilityResources
local SquareRules = require "PsychopatzCore/World/PsychopatzSquareRules"

Resources.Register("bed", {
    resourceKind = "sleep_surface",
    role = "sleep.bed",
    sleepSurface = "bed",
    sleepPriority = 100,
    collect = function(square, add)
        local object = SquareRules.FindBed(square)
        if object then add(object) end
    end,
    matches = function(_, object)
        return SquareRules.ClassifySleepSurface(object) == "bed"
    end,
    describe = function(square, object)
        local bed = SquareRules.DescribeSleepSurface(square, object)
        if not bed then return nil end
        if SquareRules.ClassifySleepSurface(object) ~= "bed" then return nil end
        bed.resourceKind = "sleep_surface"
        bed.role = "sleep.bed"
        bed.sleepSurface = "bed"
        bed.sleepCapacity = Resources.GetSleepCapacity(bed)
        bed.bedCapacity = bed.sleepCapacity
        return bed
    end,
    key = function(resource)
        return "bed:" .. tostring(math.floor((tonumber(resource.x) or 0) * 2 + 0.5))
            .. ":" .. tostring(math.floor((tonumber(resource.y) or 0) * 2 + 0.5))
            .. ":" .. tostring(tonumber(resource.z) or 0)
    end,
})

Resources.Register("sofa", {
    resourceKind = "sleep_surface",
    role = "sleep.sofa",
    sleepSurface = "sofa",
    sleepPriority = 50,
    matches = function(_, object)
        return SquareRules.ClassifySleepSurface(object) == "sofa"
    end,
    describe = function(square, object)
        local sofa = SquareRules.DescribeSleepSurface(square, object)
        if not sofa then return nil end
        if SquareRules.ClassifySleepSurface(object) ~= "sofa" then return nil end
        sofa.resourceKind = "sleep_surface"
        sofa.role = "sleep.sofa"
        sofa.sleepSurface = "sofa"
        sofa.sleepCapacity = 1
        return sofa
    end,
    key = function(resource)
        return "sofa:" .. tostring(math.floor((tonumber(resource.x) or 0) * 2 + 0.5))
            .. ":" .. tostring(math.floor((tonumber(resource.y) or 0) * 2 + 0.5))
            .. ":" .. tostring(tonumber(resource.z) or 0)
    end,
})
return Resources
