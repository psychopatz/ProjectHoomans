-- GUI view dispatcher for the faction debug inspector.

PNC = PNC or {}
PNC.FactionDebugModel = PNC.FactionDebugModel or {}

local Model = PNC.FactionDebugModel
local Internal = Model.Internal or {}
Model.Internal = Internal

require "PNC/UI/Factions/FactionDebugModel/PNC_FactionDebugModel_OverviewRows"
require "PNC/UI/Factions/FactionDebugModel/PNC_FactionDebugModel_DiplomacyRows"
require "PNC/UI/Factions/FactionDebugModel/PNC_FactionDebugModel_MembersRows"
require "PNC/UI/Factions/FactionDebugModel/PNC_FactionDebugModel_DiagnosticsRows"

Model.Views = {
    overview = true,
    diplomacy = true,
    members = true,
    diagnostics = true,
    mobile = true,
}

function Model.BuildGUIRows(
    snapshot,
    authorized,
    reason,
    requestedView
)
    local dashboard =
        Model.BuildDashboard(snapshot, authorized, reason)
    local view = Model.Views[requestedView]
        and requestedView or "overview"
    local rows = {}
    if dashboard.authorized ~= true then
        return {
            Internal.Row("Access", "Admin/debug mode required", "danger"),
        }
    end
    if view == "mobile" then
        return Model.BuildMobileRows(snapshot, authorized, reason)
    end
    if dashboard.status ~= "ready" then
        local population = snapshot and snapshot.populationDirector or {}
        local starter = population.starter or {}
        return {
            Internal.Row("Status", dashboard.status, "warning"),
            Internal.Row("Population starter", starter.completed and "READY" or "PENDING",
                starter.completed and "success" or "warning"),
            Internal.Row("Generated population", string.format(
                "settlements=%d groups=%d pending=%d/%d",
                population.currentSettlements or 0,
                population.currentGroups or 0,
                population.pendingSettlements or 0,
                population.pendingGroups or 0)),
            Internal.Row("Bootstrap phase", tostring(
                population.bootstrapPhase or "initializing")),
        }
    end
    if view == "overview" then
        Internal.AppendOverviewRows(rows, snapshot, dashboard)
    elseif view == "diplomacy" then
        Internal.AppendDiplomacyRows(rows, snapshot, dashboard)
    elseif view == "members" then
        Internal.AppendMembersRows(rows, snapshot, dashboard)
    else
        Internal.AppendDiagnosticsRows(rows, snapshot, dashboard)
    end
    return rows
end

return Model
