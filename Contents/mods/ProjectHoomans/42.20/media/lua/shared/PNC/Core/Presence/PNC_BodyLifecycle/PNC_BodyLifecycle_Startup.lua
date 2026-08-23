-- Stable entry point for persisted live-body shell startup reconciliation.

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Startup/PNC_BodyLifecycle_Startup_Identity"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Startup/PNC_BodyLifecycle_Startup_Removal"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Startup/PNC_BodyLifecycle_Startup_RecordCleanup"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Startup/PNC_BodyLifecycle_Startup_Sweep"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Startup/PNC_BodyLifecycle_Startup_Coordinator"

return PNC.BodyLifecycle
