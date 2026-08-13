if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Discovery = PNC.WorldDiscovery
local Internal = Discovery.RadioBroadcastsInternal
local Channel = PNC.RadioDiscoveryChannel
local Radio = PsychopatzCore.CustomRadio

function Discovery.BroadcastRadioDiscovery(player, entity, phase)
    if not entity then return false, "entity_missing" end
    if not Radio.AirEvent then return false, "radio_engine_unavailable" end
    local context = Discovery.BuildRadioTemplateContext(player, entity, phase)
    local aired, reason = Radio.AirEvent(Channel.ID, "discovery", context)
    if aired then Internal.PersistIntroduction(player, context) end
    return aired, reason, context
end

return Discovery
