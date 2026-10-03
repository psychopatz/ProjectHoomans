if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CampResourceService = PNC.CampResourceService or {}

local Service = PNC.CampResourceService
local Internal = Service.Internal or {}
Service.Internal = Internal
Service.Providers = Service.Providers or {}
local Resources = PNC.FacilityResources
local eachObject = Internal.EachObject
local describeSleepResource = Internal.DescribeSleepResource
local describeFaucet = Internal.DescribeFaucet
local describeSeat = Internal.DescribeSeat

function Service.RegisterProvider(id, provider)
    id = tostring(id or "")
    if id == "" or type(provider) ~= "table"
        or type(provider.CaptureSquare) ~= "function"
    then return false, "INVALID_CAMP_RESOURCE_PROVIDER" end
    provider.id = id
    Service.Providers[id] = provider
    return true, provider
end

Service.RegisterProvider("bed", {
    resourceKind = "sleep_surface",
    CaptureSquare = function(square, add)
        local detector = Resources and Resources.GetDetector
            and Resources.GetDetector("bed") or nil
        local emitted = {}
        if detector and detector.collect then
            detector.collect(square, function(object)
                emitted[object] = true
                add(describeSleepResource(square, object, "bed"))
            end)
        end
        eachObject(square, function(object)
            if not emitted[object] then
                add(describeSleepResource(square, object, "bed"))
            end
        end)
    end,
})

Service.RegisterProvider("sofa", {
    resourceKind = "sleep_surface",
    CaptureSquare = function(square, add)
        eachObject(square, function(object)
            add(describeSleepResource(square, object, "sofa"))
        end)
    end,
})

Service.RegisterProvider("faucet", {
    resourceKind = "water_source",
    CaptureSquare = function(square, add)
        eachObject(square, function(object, ordinal)
            add(describeFaucet(square, object, ordinal))
        end)
    end,
})

Service.RegisterProvider("seat", {
    resourceKind = "seating_surface",
    CaptureSquare = function(square, add, context)
        eachObject(square, function(object, ordinal)
            add(describeSeat(square, object, context, ordinal))
        end)
    end,
})


return Service
