require "PsychopatzCore/Radio/CustomChannels/PsychopatzCustomRadio"

PNC = PNC or {}
PNC.RadioDiscoveryChannel = PNC.RadioDiscoveryChannel or {
    ID = "projecthoomans.frequency_scan",
    GUID = "PNC-SCAN-69000",
    FREQUENCY = 69000,
}

PsychopatzCore.CustomRadio.RegisterChannel({
    id = PNC.RadioDiscoveryChannel.ID,
    guid = PNC.RadioDiscoveryChannel.GUID,
    frequency = PNC.RadioDiscoveryChannel.FREQUENCY,
    name = "Scan for Frequencies",
    nameKey = "UI_PNC_FrequencyScanChannel",
    category = "Amateur",
    autoPreset = true,
    airCounterMultiplier = 0.75,
})

return PNC.RadioDiscoveryChannel
