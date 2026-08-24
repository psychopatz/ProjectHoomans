-- Whole-registry faction invariant checks and telemetry.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionValidation = PNC.FactionValidation or {}
local Validation = PNC.FactionValidation
local Internal = Validation.Internal
local Factions = PNC.Factions
local addIssue = Internal.AddIssue
local newResult = Internal.NewResult
local safePersistent = Internal.SafePersistent

function Validation.CheckRegistry()
    Factions.EnsureLoaded()
    local result = newResult("registry")
    local memberships = {}
    for factionID, faction in pairs(Factions.Registry.byID or {}) do
        local factionResult = Validation.CheckFaction(factionID)
        result.checks = result.checks + factionResult.checks
        for _, issue in ipairs(factionResult.errors) do
            addIssue(result, "error", issue.code, issue.detail)
        end
        for _, issue in ipairs(factionResult.warnings) do
            addIssue(result, "warning", issue.code, issue.detail)
        end
        for npcID, _ in pairs(faction.memberIDs or {}) do
            local prior = memberships[npcID]
            if prior
                and prior.factionID ~= factionID
                and prior.active == true
                and faction.status == "active"
            then
                addIssue(result, "error",
                    "duplicate_active_membership", npcID)
            else
                memberships[npcID] = {
                    factionID = factionID,
                    active = faction.status == "active",
                }
            end
        end
        for targetID, relation in pairs(faction.relations or {}) do
            local reverse = Factions.Registry.byID[targetID]
                and Factions.Registry.byID[targetID]
                    .relations[factionID] or nil
            if relation.atWar == true
                and (not reverse or reverse.atWar ~= true)
            then
                addIssue(result, "error", "asymmetric_war",
                    factionID .. "->" .. targetID)
            end
            if relation.allied == true
                and (not reverse or reverse.allied ~= true)
            then
                addIssue(result, "error", "asymmetric_alliance",
                    factionID .. "->" .. targetID)
            end
            if (tonumber(relation.truceUntil) or 0)
                ~= (tonumber(reverse and reverse.truceUntil) or 0)
            then
                addIssue(result, "error", "asymmetric_truce",
                    factionID .. "->" .. targetID)
            end
        end
    end
    safePersistent(Factions.Registry, "registry", result, {})
    if PNC.FactionTelemetry then
        PNC.FactionTelemetry.RecordValidation({
            operation = "check_registry",
            worldAgeHours = 0,
            result = result.ok and "valid" or "invalid",
            reason = result.ok and "all_invariants_hold"
                or "invariant_failure",
            errorCount = #result.errors,
            warningCount = #result.warnings,
        })
    end
    return result
end

return Validation
