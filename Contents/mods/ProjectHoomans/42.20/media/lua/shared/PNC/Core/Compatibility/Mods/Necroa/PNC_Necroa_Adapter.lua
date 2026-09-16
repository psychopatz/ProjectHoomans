-- Stable Necroa compatibility entry point.
--
-- Necroa does not need an ActorRef provider while its special actors remain
-- native IsoZombie objects. This adapter only owns spawn policy hooks; native
-- Necroa actors stay on Necroa's own zombie behavior lane.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}

local API = PNC.Compatibility.API
    or require "PNC/Core/Compatibility/PNC_Compatibility_API"
local Policy = require "PNC/Core/Compatibility/Mods/Necroa/PNC_Necroa_Policy"

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

API.RegisterAdapter({
    id = "Necroa",
    version = "Necroa2-B42.20",
    apiVersion = 1,
    capabilities = { events = true },
    onEvent = onEvent,
})

return Policy
