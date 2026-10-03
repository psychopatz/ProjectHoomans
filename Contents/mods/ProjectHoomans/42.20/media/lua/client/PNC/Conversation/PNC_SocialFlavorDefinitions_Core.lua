-- Project Hoomans' authored relationship-aware social flavor definitions.
-- Registration is client-side presentation data; gameplay remains authoritative
-- in the server relationship service.

require "PsychopatzCore/Conversation/PsychopatzSocialFlavor"

PNC = PNC or {}
PNC.SocialFlavorDefinitions = PNC.SocialFlavorDefinitions or {}

local Flavor = PsychopatzCore.SocialFlavor

local function translatedLine(key, fallback)
    local translation = PNC.Translation
    local value = translation and type(translation.GetKey) == "function"
        and translation.GetKey(key, fallback) or fallback
    return { key = key, fallback = value }
end

PNC.SocialFlavorDefinitions.Internal =
    PNC.SocialFlavorDefinitions.Internal or {}
local Internal = PNC.SocialFlavorDefinitions.Internal
Internal.Flavor = Flavor
Internal.translatedLine = translatedLine

return PNC.SocialFlavorDefinitions
