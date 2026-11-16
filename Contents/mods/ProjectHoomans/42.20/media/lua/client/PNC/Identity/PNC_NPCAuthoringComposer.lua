-- Reusable composer facade for any NPC authoring surface.
--
-- This module deliberately has no companion-only field vocabulary.  It reads
-- field descriptors and source metadata from the canonical registry/resolver,
-- and delegates all mutations to the shared blueprint/session model.

require "PNC/Core/Identity/PNC_NPCAuthoring"

PNC = PNC or {}
PNC.NPCAuthoringComposer = PNC.NPCAuthoringComposer or {}

local Composer = PNC.NPCAuthoringComposer
local Authoring = PNC.NPCAuthoring
local Registry = Authoring.Registry
local Blueprint = Authoring.Blueprint
local Resolver = Authoring.Resolver

Composer.SOURCE_LABELS = {
    explicit = "Custom",
    generated = "Generated",
    inherited = "Inherited from Player",
    derived = "Relationship Rule",
    authoritative = "Server Controlled",
}

local function copy(value)
    return Registry.Copy(value)
end

local function traceFor(slot, fieldID)
    return slot and slot.trace and slot.trace.fields
        and slot.trace.fields[fieldID] or nil
end

local function capability(policy, field)
    local binding = policy and policy.bindings
        and policy.bindings[field.id] or nil
    local hidden = policy and policy.hiddenFields
        and policy.hiddenFields[field.id] == true
    local allowed = policy and policy.allowedValues
        and policy.allowedValues[field.id] or nil
    return {
        visible = field.authorable and not hidden,
        editable = field.authorable
            and not (binding and binding.editable == false)
            and not (policy and policy.serverControlledFields
                and policy.serverControlledFields[field.id]),
        required = policy and policy.required
            and policy.required[field.id] == true or false,
        inherited = binding and binding.source == "inherited" or false,
        derived = binding and binding.source == "derived" or false,
        locked = binding and binding.editable == false or false,
        allowedValues = copy(allowed),
        binding = binding and {
            source = binding.source,
            rule = binding.rule,
            dependencies = copy(binding.dependencies or {}),
            mandatory = binding.mandatory == true,
        } or nil,
    }
end

function Composer.SourceLabel(source)
    return Composer.SOURCE_LABELS[source] or tostring(source or "Generated")
end

function Composer.FieldRowsForSlot(slot, policy, limit)
    local output = {}
    local maximum = math.max(1, math.floor(tonumber(limit) or Registry.MAX_FIELDS))
    local count = 0
    local state
    local value
    local trace
    local row
    for _, field in ipairs(Registry.List()) do
        if field.authorable then
            count = count + 1
            if count > maximum then break end
            state, value = Blueprint.Get(slot.blueprint, field.id)
            trace = traceFor(slot, field.id)
            row = capability(policy, field)
            row.fieldID = field.id
            row.valueType = field.valueType
            row.clearable = field.clearable == true
            row.state = state
            row.authoredValue = value
            row.source = trace and trace.source or "generated"
            row.sourceLabel = Composer.SourceLabel(row.source)
            row.rule = trace and trace.rule or row.binding
                and row.binding.rule or nil
            row.dependencies = trace and copy(trace.dependencies or {})
                or row.binding and copy(row.binding.dependencies or {}) or {}
            row.resolvedValue = trace and copy(trace.value) or nil
            row.clearIgnored = trace and trace.clearIgnored == true or false
            output[#output + 1] = row
        end
    end
    return output
end

function Composer.New(options)
    options = type(options) == "table" and options or {}
    return setmetatable({
        session = options.session,
        traitID = options.traitID,
        policy = options.policy,
    }, { __index = Composer })
end

function Composer:Slot()
    return self.session and self.session.GetSlot
        and self.session:GetSlot(self.traitID, true) or nil
end

function Composer:Policy()
    if self.policy then return self.policy end
    local slot = self:Slot()
    self.policy = slot and Resolver.PolicyForStartingCompanion(slot.spec)
        or Resolver.Policies.Debug
    return self.policy
end

function Composer:FieldRows(limit)
    local slot = self:Slot()
    if not slot then return {} end
    return Composer.FieldRowsForSlot(slot, self:Policy(), limit)
end

function Composer:BlueprintIntent()
    local slot = self:Slot()
    return slot and Blueprint.Clone(slot.blueprint) or nil
end

function Composer:ResolvedPreview()
    local slot = self:Slot()
    return slot and copy(slot.resolvedDefinition) or nil
end

function Composer:ResolutionTrace(limit)
    local slot = self:Slot()
    if not slot or not slot.trace then return {} end
    return Resolver.BuildResolutionSummary(slot.trace, limit)
end

function Composer:SetField(fieldID, value)
    if not self.session then return nil, "session_invalid" end
    return self.session:SetField(self.traitID, fieldID, value)
end

function Composer:ClearField(fieldID)
    if not self.session then return nil, "session_invalid" end
    return self.session:ClearField(self.traitID, fieldID)
end

function Composer:Randomize()
    if not self.session then return nil, "session_invalid" end
    return self.session:RandomizeSlot(self.traitID)
end

function Composer:Reset()
    if not self.session then return nil, "session_invalid" end
    return self.session:ResetSlot(self.traitID)
end

function Composer:RevertToPreset()
    if not self.session then return nil, "session_invalid" end
    return self.session:RevertToPreset(self.traitID)
end

return Composer
