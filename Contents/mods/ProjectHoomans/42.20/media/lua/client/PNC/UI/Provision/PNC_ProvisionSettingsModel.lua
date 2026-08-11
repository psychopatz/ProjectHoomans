PNC = PNC or {}
PNC.ProvisionSettingsModel = PNC.ProvisionSettingsModel or {}

local Model = PNC.ProvisionSettingsModel
local Policy = PNC.ProvisionPolicy
local Registry = PNC.ProvisionRuleRegistry

local function copy(value)
    return PNC.Core and PNC.Core.DeepCopy and PNC.Core.DeepCopy(value) or value
end

function Model.New(snapshot)
    local object = {
        policyId = "default",
        revision = 0,
        rules = {},
        changed = false,
        canEdit = false,
    }
    return setmetatable(object, { __index = Model }):Load(snapshot)
end

function Model:Load(snapshot)
    snapshot = type(snapshot) == "table" and snapshot or {}
    local provision = Policy.Normalize(snapshot.provision)
    self.policyId = snapshot.policyId or "default"
    self.revision = provision.revision
    self.rules = copy(provision.policies[self.policyId] or {})
    self.rules.parentPolicyId = nil
    self.canEdit = snapshot.canEdit == true
    self.permissionReason = snapshot.permissionReason
    self.changed = false
    self.lastError = nil
    return self
end

function Model:Get(ruleID)
    return self.rules[ruleID] and copy(self.rules[ruleID]) or nil
end

function Model:Set(ruleID, fieldID, value)
    if not Registry.Get(ruleID) then return false, "unknown_rule" end
    if not self.rules[ruleID] then return false, "rule_missing" end
    self.rules[ruleID][fieldID] = value
    self.changed = true
    return true
end

function Model:ResetDefaults()
    for _, definition in ipairs(Registry.List()) do
        self.rules[definition.id] = copy(definition.defaults)
    end
    self.changed = true
end

function Model:BuildSubmission()
    local rules = {}
    for _, definition in ipairs(Registry.List()) do
        local normalized, reason = Policy.ValidateRule(
            definition.id, self.rules[definition.id], true
        )
        if not normalized then
            self.lastError = reason
            return nil, reason
        end
        rules[definition.id] = normalized
    end
    return {
        schemaVersion = Policy.SCHEMA_VERSION,
        policyId = self.policyId,
        expectedRevision = self.revision,
        rules = rules,
    }
end

function Model:Submit()
    local submission, reason = self:BuildSubmission()
    if not submission then return false, reason end
    if not self.canEdit then
        return false, self.permissionReason or "not_authorized"
    end
    return PNC.Client.RequestColonyAction("provision_set", {
        submission = submission,
    })
end

return Model
