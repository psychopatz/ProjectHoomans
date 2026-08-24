if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local H = PNC.ProvisionEvaluator.Internal
local SupplyInventory = PNC.SupplyInventory
local SupplyCommands = SupplyInventory.Commands or SupplyInventory

function H.EnsurePersonalInventory(record)
    if SupplyCommands.EnsurePersonalInventory then
        SupplyCommands.EnsurePersonalInventory(record)
    end
end

function H.ProvisionRuntime(record)
    record.runtime = record.runtime or {}
    record.runtime.provision = record.runtime.provision or {
        incoming = {}, refilling = {}, evaluations = {}, dirtyRules = {},
    }
    return record.runtime.provision
end

function H.RequestFor(definition)
    return {
        resourceKind = definition.resourceKind or definition.selector,
        treatment = definition.treatment,
        required = {},
    }
end
