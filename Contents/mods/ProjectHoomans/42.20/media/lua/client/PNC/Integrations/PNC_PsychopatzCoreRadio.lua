-- Requiring the host here makes the integration deterministic even when the
-- engine's automatic client-file order changes between Build 42 revisions.
require "PsychopatzCore/UI/Radio/PsychopatzRadioSignalHost"

PNC = PNC or {}

local RadioActions = PsychopatzCore and PsychopatzCore.RadioActions

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

if RadioActions and RadioActions.Register then
    RadioActions.Register({
        id = "projecthoomans.colony_management",
        label = tr("UI_PNC_ProjectHoomansColony", "Project Hoomans Colony"),
        signalLabel = tr(
            "UI_PNC_ProjectHoomansColony",
            "Project Hoomans Colony"
        ),
        placement = RadioActions.PLACEMENT_SIGNAL or "psychopatz.radio.signal",
        order = 100,
        isAvailable = function()
            return PNC.ColonyManagementUI and PNC.ColonyManagementUI.Open ~= nil
        end,
        onClick = function()
            PNC.ColonyManagementUI.Open()
            return true
        end,
    })
end

return RadioActions
