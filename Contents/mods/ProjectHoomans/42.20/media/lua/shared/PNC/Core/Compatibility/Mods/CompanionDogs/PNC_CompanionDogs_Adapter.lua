-- Companion Dogs compatibility composition root.
--
-- This file is intentionally only a stable entry point. The compatibility
-- surface remains PNC.Compatibility.CompanionDogs while its cohesive pieces
-- live beside it, so another animal mod can reuse the same shape later.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}

local Bridge = PNC.Compatibility.CompanionDogs or {}
Bridge.Internal = Bridge.Internal or {}
PNC.Compatibility.CompanionDogs = Bridge

require "PNC/Core/Compatibility/Mods/CompanionDogs/PNC_CompanionDogs_Access"
require "PNC/Core/Compatibility/Mods/CompanionDogs/PNC_CompanionDogs_Presentation"
require "PNC/Core/Compatibility/Mods/CompanionDogs/PNC_CompanionDogs_Feed"
require "PNC/Core/Compatibility/Mods/CompanionDogs/PNC_CompanionDogs_Interaction"
require "PNC/Core/Compatibility/Mods/CompanionDogs/PNC_CompanionDogs_Runtime"

return Bridge
