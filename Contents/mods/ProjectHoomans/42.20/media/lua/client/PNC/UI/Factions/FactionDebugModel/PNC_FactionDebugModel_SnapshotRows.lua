-- Snapshot row composition and compatibility API.

PNC = PNC or {}
PNC.FactionDebugModel = PNC.FactionDebugModel or {}

local Model = PNC.FactionDebugModel
local Internal = Model.Internal or {}
Model.Internal = Internal

require "PNC/UI/Factions/FactionDebugModel/PNC_FactionDebugModel_SnapshotFactionRows"
require "PNC/UI/Factions/FactionDebugModel/PNC_FactionDebugModel_SnapshotDiplomacyRows"
require "PNC/UI/Factions/FactionDebugModel/PNC_FactionDebugModel_SnapshotDiagnosticsRows"

function Model.BuildRows(snapshot, authorized, reason)
    if authorized ~= true then
        return {
            Internal.Row("Access", "Admin/debug mode required", "danger"),
        }
    end
    if not snapshot then
        return {
            Internal.Row("Status", reason or "Select a faction",
                reason and "warning" or "textMuted"),
        }
    end
    local rows = {}
    Internal.AppendSnapshotFactionRows(rows, snapshot)
    Internal.AppendSnapshotDiplomacyRows(rows, snapshot)
    Internal.AppendSnapshotDiagnosticsRows(rows, snapshot)
    return rows
end

return Model
