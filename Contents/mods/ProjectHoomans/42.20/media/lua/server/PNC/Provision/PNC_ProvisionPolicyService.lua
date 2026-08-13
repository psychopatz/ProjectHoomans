if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ProvisionPolicyService = PNC.ProvisionPolicyService or {}

local Service = PNC.ProvisionPolicyService
local Policy = PNC.ProvisionPolicy

local function playerKey(player)
    return PNC.PlayerCharacters and PNC.PlayerCharacters.GetEntityKey
        and PNC.PlayerCharacters.GetEntityKey(player, {
            callback = "provision_policy", ensure = false,
        }) or nil
end

function Service.CanManage(player, faction)
    if not player or not faction then return false, "faction_unavailable" end
    local key = playerKey(player)
    if not key then return false, "player_identity_unavailable" end
    if faction.ownerPlayerKey ~= key then return false, "not_faction_owner" end
    return true
end

function Service.BuildSnapshot(player)
    local faction, reason = PNC.Factions.GetPlayerFaction(player)
    if not faction then return nil, reason end
    local allowed, permissionReason = Service.CanManage(player, faction)
    return {
        factionId = faction.id,
        factionName = faction.name,
        policyId = "default",
        provision = Policy.Normalize(faction.provision),
        canEdit = allowed == true,
        permissionReason = permissionReason,
    }
end

function Service.Apply(player, submission)
    local faction, reason = PNC.Factions.GetPlayerFaction(player)
    if not faction then return false, reason end
    local allowed
    allowed, reason = Service.CanManage(player, faction)
    if not allowed then return false, reason end
    local validated
    validated, reason = Policy.ValidateSubmission(submission)
    if not validated then return false, reason end
    local current = Policy.Normalize(faction.provision)
    if tonumber(submission.expectedRevision) == nil then
        return false, "revision_required"
    end
    if tonumber(submission.expectedRevision) ~= current.revision then
        return false, "revision_conflict"
    end
    current.policies[validated.policyId] = {
        parentPolicyId = nil,
    }
    for ruleID, values in pairs(validated.rules) do
        current.policies[validated.policyId][ruleID] = values
    end
    current.revision = current.revision + 1
    local ok
    ok, reason = PNC.Factions.SetProvisionPolicy(faction.id, current)
    if not ok then return false, reason end
    PNC.Factions.Save()
    if GlobalModData and GlobalModData.save then GlobalModData.save() end
    if PNC.ProvisionScheduler then
        PNC.ProvisionScheduler.MarkFactionDirty(faction.id)
    end
    PNC.SupplyMetrics.Set("provisionPolicyRevision", current.revision)
    return true, "updated", Service.BuildSnapshot(player)
end

return Service
