PNC = PNC or {}
PNC.ProvisionSettingsModel = PNC.ProvisionSettingsModel or {}
PNC.ProvisionSettingsClient = PNC.ProvisionSettingsClient or {}

local Model = PNC.ProvisionSettingsModel
local Client = PNC.ProvisionSettingsClient
local Policy = PNC.ProvisionPolicy
local Registry = PNC.ProvisionRuleRegistry

local function copy(value)
    return PNC.Core and PNC.Core.DeepCopy and PNC.Core.DeepCopy(value) or value
end

local function clientState()
    return PNC.Network and PNC.Network.ClientState or {}
end

function Client.CurrentSnapshot()
    local colony = clientState().colonyManagement
    return colony and colony.provisionSettings or nil
end

function Client.ReadUpdate(lastReceiveAt)
    local state = clientState()
    local receivedAt = tonumber(state.lastColonyManagementReceiveAt) or 0
    if receivedAt <= (tonumber(lastReceiveAt) or 0) then return nil end
    local colony = state.colonyManagement
    return {
        receivedAt = receivedAt,
        snapshot = colony and colony.provisionSettings or nil,
        result = colony and colony.actionResult or nil,
    }
end

function Client.RequestSnapshot()
    return PNC.Client.RequestColonyManagement()
end

function Client.Submit(submission)
    return PNC.Client.RequestColonyAction("provision_set", {
        submission = submission,
    })
end

function Client.Now()
    return PNC.Core.Now()
end

function Model.New(snapshot, client)
    local object = {
        policyId = "default",
        revision = 0,
        rules = {},
        changed = false,
        canEdit = false,
        client = client or Client,
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

function Model:MarkChanged()
    self.changed = true
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
    return self.client.Submit(submission)
end

return Model
