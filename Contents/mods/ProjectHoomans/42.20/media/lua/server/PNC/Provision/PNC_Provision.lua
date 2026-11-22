-- Canonical server entry for Provision. Require order is contractual.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Provision = PNC.Provision or {}

require "PNC/Provision/PNC_ProvisionResolver"
require "PNC/Provision/PNC_ProvisionEvaluator"
require "PNC/Provision/PNC_ProvisionScheduler"
require "PNC/Provision/PNC_ProvisionPolicyService"
local Events = require "PsychopatzCore/Events/PC_EventBus"
local EventTypes = require "PNC/Core/Events/PNC_EventDefinitions"

local Provision = PNC.Provision
Provision.Evaluator = PNC.ProvisionEvaluator
Provision.Scheduler = PNC.ProvisionScheduler
Provision.Policy = PNC.ProvisionPolicyService

local IGNORED_COMBAT_REASONS = {
    combat_round_fired = true,
    combat_condition = true,
    combat_magazine_init = true,
    combat_magazine_clamp = true,
    combat_reload_unlimited_reserve = true,
}

local function onInventoryChanged(record, _, reason)
    if reason and IGNORED_COMBAT_REASONS[reason] then return end
    Provision.Scheduler.MarkInventoryDirty(record)
end

Events.subscribe(EventTypes.NPC_INVENTORY_CHANGED, onInventoryChanged,
    Provision)

return Provision
