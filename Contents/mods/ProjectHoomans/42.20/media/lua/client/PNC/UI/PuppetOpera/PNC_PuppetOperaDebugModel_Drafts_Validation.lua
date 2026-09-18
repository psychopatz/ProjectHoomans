-- Schema and runtime validation projection for Puppet Opera drafts.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Internal = Model.Internal or {}
local Blueprints = Internal.Blueprints
local currentDraft = Internal.currentDraft

function Model.GetValidation()
    local draft = currentDraft()
    if not draft or not Blueprints then return false, "blueprint_not_found" end
    local normalized, reason = Blueprints.Normalize(draft.id, draft)
    if not normalized then return false, reason end
    local runtimeOK, runtimeReason = Blueprints.ValidateRuntime(normalized)
    return true, runtimeOK and nil or runtimeReason, normalized
end

return Model
