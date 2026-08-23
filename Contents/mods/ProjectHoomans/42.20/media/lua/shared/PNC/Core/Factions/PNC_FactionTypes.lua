-- Pure serialization-safe faction and affiliation type entry point.

PNC = PNC or {}
PNC.FactionTypes = PNC.FactionTypes or {}
PNC.FactionTypes.Internal = PNC.FactionTypes.Internal or {}

require "PNC/Core/Factions/PNC_FactionTypes/Base"
require "PNC/Core/Factions/PNC_FactionTypes/Policy"
require "PNC/Core/Factions/PNC_FactionTypes/Diplomacy"
require "PNC/Core/Factions/PNC_FactionTypes/Incidents"
require "PNC/Core/Factions/PNC_FactionTypes/Relations"
require "PNC/Core/Factions/PNC_FactionTypes/Affiliations"
require "PNC/Core/Factions/PNC_FactionTypes/Factions"
require "PNC/Core/Factions/PNC_FactionTypes/Registry"
require "PNC/Core/Factions/PNC_FactionTypes/Equality"

return PNC.FactionTypes
