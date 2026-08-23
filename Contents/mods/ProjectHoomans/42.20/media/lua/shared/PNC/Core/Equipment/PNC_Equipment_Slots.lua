-- Stable entry point for equipment loadout, slot, and visual-state contracts.

PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}

require "PNC/Core/Equipment/PNC_Equipment_Slots/Locations"
require "PNC/Core/Equipment/PNC_Equipment_Slots/VisualNormalization"
require "PNC/Core/Equipment/PNC_Equipment_Slots/SlotMetadata"
require "PNC/Core/Equipment/PNC_Equipment_Slots/LoadoutState"
require "PNC/Core/Equipment/PNC_Equipment_Slots/AttachmentResolution"
require "PNC/Core/Equipment/PNC_Equipment_Slots/Ordering"
require "PNC/Core/Equipment/PNC_Equipment_Slots/VisualCapture"
require "PNC/Core/Equipment/PNC_Equipment_Slots/VisualSummaries"
require "PNC/Core/Equipment/PNC_Equipment_Slots/CharacterCapture"
