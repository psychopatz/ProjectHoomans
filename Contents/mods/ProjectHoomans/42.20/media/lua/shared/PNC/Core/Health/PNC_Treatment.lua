-- Stable entry point for NPC medical treatment policy and actions.

PNC = PNC or {}
PNC.Treatment = PNC.Treatment or {}
PNC.Treatment.Internal = PNC.Treatment.Internal or {}

require "PNC/Core/Health/PNC_Treatment/PNC_Treatment_Policy"
require "PNC/Core/Health/PNC_Treatment/PNC_Treatment_Inventory"
require "PNC/Core/Health/PNC_Treatment/PNC_Treatment_Diagnostics"
require "PNC/Core/Health/PNC_Treatment/PNC_Treatment_Actions"
require "PNC/Core/Health/PNC_Treatment/PNC_Treatment_Snapshot"

return PNC.Treatment
