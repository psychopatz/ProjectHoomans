require "PsychopatzCore/Radio/CustomChannels/PsychopatzCustomRadio"

PNC = PNC or {}
PNC.RadioDiscoveryChannel = PNC.RadioDiscoveryChannel
    or PsychopatzCore.RadioBroadcastChannel
    or {
        ID = "projecthoomans.frequency_scan",
        GUID = "PNC-SCAN-69000",
        FREQUENCY = 69000,
    }

-- Compatibility fallback for isolated adopters that provide only the legacy
-- channel module; normal Core composition has already registered the shared
-- open band above.
if not PsychopatzCore.RadioBroadcastChannel
    and PsychopatzCore.CustomRadio.RegisterChannel
then
    PsychopatzCore.CustomRadio.RegisterChannel({
        id = PNC.RadioDiscoveryChannel.ID,
        guid = PNC.RadioDiscoveryChannel.GUID,
        frequency = PNC.RadioDiscoveryChannel.FREQUENCY,
        name = "Scan for Frequencies",
        category = "Amateur",
        autoPreset = true,
        airCounterMultiplier = 0.75,
    })
end

return PNC.RadioDiscoveryChannel
