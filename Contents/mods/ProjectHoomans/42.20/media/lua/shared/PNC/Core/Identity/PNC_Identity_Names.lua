PNC = PNC or {}
PNC.IdentityNames = PNC.IdentityNames or {}

local Names = PNC.IdentityNames
-- Compatibility facade: deterministic identity mechanics now live in Core so
-- DynamicTrading and future adopters can consume the same contract without
-- loading Project Hoomans.
local CoreNames = require "PsychopatzCore/Actors/PsychopatzActorNames"

-- Preserve the legacy provider handle for older Hoomans server spokes while
-- the reusable implementation is now owned by PsychopatzCore.
PNC.DeterministicContent = PsychopatzCore
    and PsychopatzCore.DeterministicContent

Names.VERSION = CoreNames.VERSION
Names.NICKNAME_GENERATOR_VERSION = CoreNames.NICKNAME_GENERATOR_VERSION
Names.Normalize = CoreNames.Normalize
Names.Split = CoreNames.Split
Names.Compose = CoreNames.Compose
Names.FormatDisplayName = CoreNames.FormatDisplayName
Names.ResolveParts = CoreNames.ResolveParts
Names.ResolveNickname = CoreNames.ResolveNickname
Names.Generate = CoreNames.Generate

function Names.CatalogInfo(catalog)
    return CoreNames.CatalogInfo(catalog)
end

return Names
