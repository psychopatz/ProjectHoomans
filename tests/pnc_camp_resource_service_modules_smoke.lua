local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}
PNC = {
    Const = {
        ORDER_CAMP = "camp",
        CAMP_RADIUS = 3,
        CAMP_RESOURCE_RADIUS = 12,
    },
    Core = { Now = function() return 1000 end },
}

local Service = T.load("ProjectHoomans", "server",
    "PNC/World/PNC_CampResourceService.lua")

T.equal(Service, PNC.CampResourceService,
    "the compatibility entry point returns the canonical service table")
T.truthy(Service.Internal and Service.Internal.CampContext,
    "the context spoke publishes its bounded camp contract")
T.truthy(Service.Internal.SnapshotMatches,
    "the discovery spoke publishes snapshot validation")
T.truthy(Service.Internal.ResolveSleep and Service.Internal.Reserve,
    "the target spoke publishes selection and reservation adapters")
T.truthy(Service.Internal.ApplyTarget,
    "the activity spoke publishes the target application boundary")

T.truthy(Service.Capture and Service.GetSnapshot and Service.Pump,
    "discovery APIs remain available through the public service")
T.truthy(Service.FindSleep and Service.FindSeat and Service.FindWater,
    "target selection APIs remain available through the public service")
T.truthy(Service.AcquireSleep and Service.AcquireSeat
        and Service.AcquireWater and Service.RefreshActivity,
    "activity APIs remain available through the public service")

local record = {
    id = "npc:camp-modules",
    runtime = {},
    orderSpec = {
        kind = "camp", campId = "camp:modules", x = 10, y = 10, z = 0,
    },
}
local entry = Service.Attach(record, record.orderSpec)
T.truthy(entry and record.runtime.campCacheId,
    "context owns camp cache attachment")
T.truthy(Service.IsWithinCamp(record, { x = 10.5, y = 10.5, z = 0 }),
    "context owns camp target containment")
T.falsy(Service.IsWithinCamp(record, { x = 50, y = 50, z = 0 }),
    "camp target containment rejects stale distant targets")

Service.OnOrderChanged(record, nil, record.orderSpec)
T.truthy(record.runtime.campCacheId,
    "camp lifecycle keeps the shared cache attached")
Service.OnOrderChanged(record, record.orderSpec, { kind = "follow" })
T.falsy(record.runtime.campCacheId,
    "camp lifecycle detaches the cache when camp ends")

local accepted, provider = Service.RegisterProvider("module_smoke", {
    CaptureSquare = function() end,
})
T.truthy(accepted and provider and Service.Providers.module_smoke,
    "discovery accepts a valid provider through its explicit contract")
local rejected, reason = Service.RegisterProvider("", {})
T.falsy(rejected, "discovery rejects malformed providers")
T.equal(reason, "INVALID_CAMP_RESOURCE_PROVIDER",
    "malformed providers expose a stable failure reason")
Service.Providers.module_smoke = nil

T.finish("pnc_camp_resource_service_modules_smoke")
