-- Worker scenario lifecycle composition root.

local ScenarioSession = { Internal = {} }

local installProjections = require "worker/ScenarioSession_Projections"
local installPayloads = require "worker/ScenarioSession_Payloads"
local installLifecycle = require "worker/ScenarioSession_Lifecycle"
local installDefaults = require "worker/ScenarioSession_Defaults"
local installSnapshots = require "worker/ScenarioSession_Snapshots"

-- Providers first, then payload assembly, orchestration, defaults, and the
-- public snapshot entry points. The returned table remains unchanged for the
-- worker and CommandRouter consumers.
installProjections(ScenarioSession)
installPayloads(ScenarioSession)
installLifecycle(ScenarioSession)
installDefaults(ScenarioSession)
installSnapshots(ScenarioSession)

return ScenarioSession
