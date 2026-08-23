-- Stable entry point for NPC materialization and abstraction policy.

PNC = PNC or {}
PNC.Presence = PNC.Presence or {}
PNC.Presence.Internal = PNC.Presence.Internal or {}

require "PNC/Core/Presence/PNC_Presence/PNC_Presence_Budget"
require "PNC/Core/Presence/PNC_Presence/PNC_Presence_Position"
require "PNC/Core/Presence/PNC_Presence/PNC_Presence_Decisions"
require "PNC/Core/Presence/PNC_Presence/PNC_Presence_Materialize"
require "PNC/Core/Presence/PNC_Presence/PNC_Presence_Abstract"
require "PNC/Core/Presence/PNC_Presence/PNC_Presence_Reconcile"

return PNC.Presence
