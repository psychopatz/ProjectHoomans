-- Contract smoke test for the reusable PsychopatzCore preview kernel.
-- This deliberately avoids Hoomans perception modules so the Core lifecycle
-- can be verified in isolation.
local T = require "tests/support/test"
T.addPackagePaths()
T.addPackagePaths({ { "PsychopatzCore", "client" } })

PsychopatzCore = {}

local function event()
    local value = { adds = {}, removes = {} }
    value.Add = function(callback)
        value.adds[#value.adds + 1] = callback
    end
    value.Remove = function(callback)
        value.removes[#value.removes + 1] = callback
    end
    return value
end

Events = {
    OnPreUIDraw = event(),
    OnMainMenuEnter = event(),
}

local Preview = T.load("PsychopatzCore", "client",
    "PsychopatzCore/Preview/PC_Preview.lua")
local providerID = "test.preview"
local refreshCount = 0
local source
local providerDefinition = {
    id = providerID,
    source = "preview smoke test",
    title = "Preview smoke test",
    refreshSnapshot = function()
        refreshCount = refreshCount + 1
        return source
    end,
    getSettings = function()
        return { showObjects = true, showZones = true }
    end,
    getSettingsRevision = function() return 1 end,
    objectVisible = function(record, settings)
        return settings.showObjects == true and record.tags
            and record.tags.target == true
    end,
    objectPriority = function() return 25 end,
    objectColor = function()
        return { r = 0.2, g = 0.9, b = 0.4, a = 0.8 }
    end,
    zoneVisible = function(record, settings)
        return settings.showZones == true and record.tags
            and record.tags.camp == true
    end,
    zoneColor = function()
        return { r = 0.9, g = 0.5, b = 0.1, a = 0.3 }
    end,
    tooltipLines = function(record)
        return record.details or {}
    end,
    layers = {
        {
            id = "objects",
            kind = "object",
            settingKey = "showObjects",
            tag = "target",
            priority = 25,
        },
        {
            id = "zones",
            kind = "zone",
            settingKey = "showZones",
            tag = "camp",
            priority = 10,
        },
    },
}

local registered, provider = Preview.RegisterProvider(providerDefinition)
T.truthy(registered, "Core accepts a valid preview provider")
T.equal(provider.id, providerID, "provider registration returns normalized ID")
T.truthy(Preview.GetProvider(providerID), "provider is discoverable by ID")
T.falsy(Preview.GetSession(providerID),
    "provider registration does not allocate a render session")
T.falsy(Preview.IsHookInstalled(),
    "provider registration does not install a frame hook")
T.equal(#Events.OnPreUIDraw.adds, 0,
    "idle provider registration performs no native event work")
T.truthy(Preview.HasRenderableLayers(providerID, {
    showObjects = true, showZones = false,
}), "enabled object layer is renderable")

source = {
    status = "READY",
    source = "local snapshot",
    objects = {
        {
            x = "12", y = 18, z = 0,
            tags = { target = true },
            details = { "target detail" },
            runtimeObject = function() return "must not cross boundary" end,
        },
    },
    zones = {
        {
            kind = "room",
            label = "bedroom",
            roomBounds = { minX = 10, minY = 16, maxX = 14, maxY = 20,
                z = 0 },
            tags = { camp = true },
        },
    },
}

local refreshed = Preview.Refresh(providerID)
T.equal(refreshCount, 1,
    "refresh callback runs only from the explicit refresh API")
T.equal(refreshed.status, "READY",
    "explicit refresh stores a normalized snapshot")
T.equal(#Events.OnPreUIDraw.adds, 0,
    "explicit refresh still leaves the render hook dormant")

local normalized = Preview.NormalizeSnapshot(source, providerID)
T.equal(normalized.status, "READY", "snapshot status is preserved")
T.equal(normalized.providerID, providerID,
    "snapshot receives its provider identity")
T.equal(normalized.objects[1].x, 12,
    "snapshot coordinates are normalized to numbers")
T.falsy(normalized.objects[1].runtimeObject,
    "snapshot boundary strips runtime functions")
T.equal(normalized.zones[1].x, 12,
    "bounds-only zones receive a derived anchor")
T.equal(normalized.zones[1].y, 18,
    "bounds-only zone anchor preserves its center")

local stored = Preview.SetSnapshot(providerID, source)
T.equal(stored.status, "READY", "Core stores a normalized snapshot")
T.equal(#Events.OnPreUIDraw.adds, 0,
    "snapshot refresh alone does not install a frame hook")
T.truthy(Preview.GetSnapshot(providerID),
    "stored snapshot is available to the session")

local enabled = Preview.SetEnabled(providerID, true)
T.truthy(enabled, "enabling a preview session succeeds")
T.truthy(Preview.IsHookInstalled(),
    "render hook starts only after explicit enable")
T.equal(#Events.OnPreUIDraw.adds, 1,
    "Core installs one shared frame callback")
T.equal(#Events.OnMainMenuEnter.adds, 1,
    "Core installs one lifecycle reset callback")

local sameEnabled = Preview.SetEnabled(providerID, true)
T.truthy(sameEnabled, "re-enabling an active session is harmless")
T.equal(#Events.OnPreUIDraw.adds, 1,
    "re-enabling does not duplicate the frame callback")

local disabled = Preview.SetEnabled(providerID, false)
T.falsy(disabled, "disabling a preview session succeeds")
T.falsy(Preview.IsHookInstalled(),
    "disabling removes the shared frame hook")
T.equal(#Events.OnPreUIDraw.removes, 1,
    "Core removes the frame callback")
T.equal(#Events.OnMainMenuEnter.removes, 1,
    "Core removes the lifecycle callback")
T.falsy(Preview.GetSnapshot(providerID),
    "disabling releases the retained snapshot")

Preview.UnregisterProvider(providerID)
T.falsy(Preview.GetProvider(providerID),
    "unregister removes the provider definition")

T.finish("psychopatz_preview_smoke")
