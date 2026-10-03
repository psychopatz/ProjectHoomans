-- Stable husk-ledger entry point. Storage, matching, identity policy, and
-- diagnostics remain ordered providers so the public BodyLifecycle API stays
-- available at the original load path.
PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_HuskLedger_Store"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_HuskLedger_Match"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_HuskLedger_Identity"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_HuskLedger_Debug"

return PNC.BodyLifecycle
