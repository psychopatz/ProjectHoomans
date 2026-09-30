-- Necroa compatibility entry point.
--
-- Integration class: policy hook. Necroa owns no foreign actor system here --
-- its special actors remain native IsoZombie objects -- so this adapter
-- deliberately registers NO `detect` predicate and claims no targeting,
-- relationship, or damage capability. It only owns the hooks that keep managed
-- Hoomans bodies out of Necroa's infection lane and default a spawned actor's
-- mask state.
--
-- Public contract:
--   PNC.Compatibility.Necroa.Mask      -- susceptibility/mask access
--   PNC.Compatibility.Necroa.<policy>  -- infection and incoming-damage rules
--   returns the PNC.Compatibility.Necroa namespace table

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
local Bridge = PNC.Compatibility.Necroa or {}
PNC.Compatibility.Necroa = Bridge

local API = PNC.Compatibility.API
    or require "PNC/Core/Compatibility/PNC_Compatibility_API"

require "PNC/Core/Compatibility/Mods/Necroa/PNC_Necroa_Mask"
require "PNC/Core/Compatibility/Mods/Necroa/PNC_Necroa_Policy"

local Policy = Bridge

-- Inbound provider events. Single consumer: the registration spec below.
local function onEvent(context)
    local record = context and context.context and context.context.record
    if not context or context.event ~= "npc_spawn"
        or not Policy.IsActive()
        or not Policy.Mask
    then
        return false
    end
    local changed = Policy.Mask.EnsureDefault(record)
    return changed == true
end

if not API or type(API.RegisterAdapter) ~= "function" then
    return Bridge
end

API.RegisterAdapter({
    id = "Necroa",
    version = "Necroa2-B42.20",
    apiVersion = 1,
    capabilities = { events = true },
    onEvent = onEvent,
})

return Bridge
