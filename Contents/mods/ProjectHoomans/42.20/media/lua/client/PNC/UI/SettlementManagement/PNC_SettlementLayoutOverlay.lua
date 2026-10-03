-- Stable client settlement layout overlay entry point.
PNC = PNC or {}
PNC.SettlementLayoutOverlay = PNC.SettlementLayoutOverlay or {}

require "PNC/UI/SettlementManagement/PNC_SettlementLayoutOverlay_Core"
require "PNC/UI/SettlementManagement/PNC_SettlementLayoutOverlay_Model"
require "PNC/UI/SettlementManagement/PNC_SettlementLayoutOverlay_Render"

local Overlay = PNC.SettlementLayoutOverlay
if Overlay.eventsInstalled ~= true then
    if Events and Events.OnPreUIDraw then Events.OnPreUIDraw.Add(Overlay.Render) end
    if Events and Events.OnTick then Events.OnTick.Add(Overlay.SyncFromClientState) end
    if Events and Events.OnMainMenuEnter then Events.OnMainMenuEnter.Add(Overlay.Reset) end
    Overlay.eventsInstalled = true
end

return Overlay
