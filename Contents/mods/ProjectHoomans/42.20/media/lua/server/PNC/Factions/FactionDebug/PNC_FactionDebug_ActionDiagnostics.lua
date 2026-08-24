if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionDebug = PNC.FactionDebug or {}
PNC.FactionDebug.Internal = PNC.FactionDebug.Internal or {}

local Debug = PNC.FactionDebug
local Internal = Debug.Internal
local Factions = PNC.Factions
local Archetypes = PNC.FactionArchetypes
local Types = PNC.FactionTypes
local Core = PNC.Core
local Balance = PNC.FactionBalance


function Internal.handleDiagnosticAction(player, args, action, context)
    local ok
    local reason
    if action == "telemetry_clear" then
        ok, reason = PNC.FactionTelemetry.Clear()
    elseif action == "telemetry_toggle" then
        local config = PNC.Config.Factions
        config.EnableValidationTelemetry =
            config.EnableValidationTelemetry ~= true
        ok = true
        reason = config.EnableValidationTelemetry
            and "telemetry_enabled" or "telemetry_disabled"
    elseif action == "check_registry" then
        Debug.LastValidation = PNC.FactionValidation.CheckRegistry()
        ok = Debug.LastValidation.ok
        reason = ok and "registry_valid" or "registry_invalid"
    elseif action == "repair_indexes" then
        ok, reason = PNC.FactionValidation.RepairSecondaryIndexes()
        if ok == false and (reason == nil or reason == "unchanged") then
            ok, reason = true, "indexes_already_valid"
        end
        Debug.LastValidation = PNC.FactionValidation.CheckRegistry()
    elseif action == "check_relation" then
        if not context.factionID or not context.targetFactionID
            or context.factionID == context.targetFactionID
        then
            ok, reason = false, "select_distinct_factions"
        else
            Debug.LastValidation = PNC.FactionValidation.CheckRelation(
                context.factionID, context.targetFactionID)
            ok = Debug.LastValidation.ok
            reason = ok and "relation_valid" or "relation_invalid"
        end
    elseif action == "run_scenario" then
        Debug.LastScenario, reason = PNC.FactionValidation.RunScenario(
            args and args.scenarioName or "single_minor_attack")
        ok = Debug.LastScenario ~= nil
        reason = ok and "scenario_preview_complete" or reason
    elseif action == "reconcile_treaty" then
        if not context.factionID or not context.targetFactionID
            or context.factionID == context.targetFactionID
        then
            ok, reason = false, "select_distinct_factions"
        else
            ok, reason = PNC.FactionBehavior.QueueTreatyReconciliation(
                context.factionID, context.targetFactionID,
                "manual_debug_reconciliation", context.at)
        end
    elseif action == "export_snapshot" then
        local telemetry = PNC.FactionTelemetry.BuildSnapshot({ maximum = 128 })
        Core.LogInfo("Faction diagnostic snapshot schema="
            .. tostring(PNC.FactionConstants.REGISTRY_SCHEMA_VERSION)
            .. " registryRevision=" .. tostring(Factions.Registry.revision)
            .. " telemetryCount=" .. tostring(telemetry.count)
            .. " selected=" .. tostring(context.factionID)
            .. " target=" .. tostring(context.targetFactionID))
        for _, entry in ipairs(telemetry.entries or {}) do
            Core.LogInfo("Faction telemetry #" .. tostring(entry.sequence)
                .. " " .. tostring(entry.category)
                .. " op=" .. tostring(entry.operation)
                .. " result=" .. tostring(entry.result)
                .. " reason=" .. tostring(entry.reason))
        end
        ok, reason = true, "snapshot_exported_to_log"
    else
        return false
    end
    return true, ok, reason
end

return Debug
