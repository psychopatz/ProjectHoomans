if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Discovery = PNC.WorldDiscovery
local Internal = Discovery.RadioBroadcastsInternal
local Channel = PNC.RadioDiscoveryChannel
local Radio = PsychopatzCore.CustomRadio
local Broadcasts = PsychopatzCore.RadioBroadcasts
local PROVIDER_ID = "projecthoomans.world_discovery"

Discovery.RADIO_BROADCAST_PROVIDER_ID = PROVIDER_ID

local function onAired(result, specification)
    if result.eventType == "discovery" and specification.player then
        Internal.PersistIntroduction(specification.player, result.context)
    end
end

if Broadcasts and type(Broadcasts.RegisterProvider) == "function" then
    Broadcasts.RegisterProvider(PROVIDER_ID, {
        channelID = Channel.ID,
        onAired = onAired,
    })
end

local function air(eventType, player, context)
    if Broadcasts and type(Broadcasts.Air) == "function" then
        return Broadcasts.Air(PROVIDER_ID, {
            channelID = Channel.ID,
            eventType = eventType,
            context = context,
            player = player,
        })
    end
    if not Radio.AirEvent then return false, "radio_engine_unavailable" end
    local aired, reason = Radio.AirEvent(Channel.ID, eventType, context)
    if aired and eventType == "discovery" then
        Internal.PersistIntroduction(player, context)
    end
    return aired, reason, context
end

function Discovery.BroadcastRadioDiscovery(player, entity, phase)
    if not entity then return false, "entity_missing" end
    local context = Discovery.BuildRadioTemplateContext(player, entity, phase)
    local aired, reason, airedContext = air("discovery", player, context)
    return aired, reason, airedContext or context
end

function Discovery.BroadcastRadioAmbient(player)
    local context = Discovery.BuildAmbientTemplateContext()
    local aired, reason, airedContext = air("ambient", player, context)
    return aired, reason, airedContext or context
end

return Discovery
